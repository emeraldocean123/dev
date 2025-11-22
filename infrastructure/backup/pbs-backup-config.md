# PBS Backup Configuration

**Last Updated:** October 14, 2025
**Status:** Operational - 3-Tier Automated System

> **📘 For high-level overview and complete 3-tier architecture, see [`backup-infrastructure-overview.md`](backup-infrastructure-overview.md)**
>
> This document contains detailed PBS configuration, setup commands, and troubleshooting.

## Overview

Complete **3-tier automated backup infrastructure** with Proxmox Backup Server (PBS) as the primary layer, ZFS replication to N6005 as the secondary off-host layer, and rsync to Synology NAS as the tertiary cold storage layer.

**Quick Architecture:**
- **Layer 1:** PBS on intel-1250p (375GB) - Daily backups at 2 AM + daily verification
- **Layer 2:** ZFS replication to N6005 (375GB) - RTC wake at 2:50 AM, replication at 3 AM
- **Layer 3:** rsync to Synology (371GB) - On-demand auto-detection and sync

For complete architecture diagrams, schedules, and monitoring, see [`backup-infrastructure-overview.md`](backup-infrastructure-overview.md).

## Architecture

### Primary Backup Server (intel-1250p)

**Host:** intel-1250p (192.168.1.40)
**PBS Container:** LXC 1002 (192.168.1.52)
**Role:** Primary backup server for all LXC containers

**Storage Configuration:**
- **Container rootfs:** `rpool/data/subvol-1002-disk-0` (10GB allocated, 860M used)
- **Backup datastore:** `rpool/pbs-local` mounted at `/mnt/pbs-local`
- **Storage type:** Single 4TB NVMe (no RAID, high performance)
- **Available space:** 3.18TB
- **Current usage:** 4.33GB (4 LXC backups)

**Bind Mount Configuration:**
```bash
# /etc/pve/lxc/1002.conf
mp0: /mnt/pbs-local,mp=/mnt/pbs-local
```

**PBS Datastore:**
- **Name:** `local`
- **Path:** `/mnt/pbs-local`
- **Storage ID in Proxmox:** `pbs-local`

**PBS Users:**
- `backup@pbs` - DatastoreBackup role (for Proxmox to backup containers)
- `sync@pbs` - DatastoreReader role (for n6005 to read/sync backups)

### Backup Replication Server (intel-n6005)

**Host:** intel-n6005 (192.168.1.41)
**PBS Container:** LXC 1000
**Role:** Backup replication target with RAID1 redundancy

**Storage Configuration:**
- **Container rootfs:** `rpool/data/subvol-1000-disk-0` (10GB allocated, 683M used)
- **Backup datastore:** `rpool/backup-1250p` mounted at `/mnt/backup-1250p`
- **Storage type:** 2×4TB NVMe RAID1 mirror (redundant, safe storage)
- **Available space:** 3.50TB
- **Current usage:** 4.33GB (replicated from intel-1250p)

**Bind Mount Configuration:**
```bash
# /etc/pve/lxc/1000.conf
mp0: /mnt/backup-1250p,mp=/mnt/backup-1250p
```

**PBS Datastore:**
- **Name:** `backup-1250p`
- **Path:** `/mnt/backup-1250p`

**PBS Users:**
- `sync@pbs` - DatastoreReader role (read from remote)
- `pull@pbs` - DatastoreBackup role (write to local datastore)

**PBS Remote Connection:**
- **Name:** `1250p-pbs`
- **Host:** 192.168.1.52
- **Port:** 8007
- **Auth:** sync@pbs
- **Fingerprint:** `1d:1b:35:2c:cd:bd:14:d0:f3:e0:54:1b:56:13:81:1c:94:18:95:e8:b7:89:2b:ca:10:cc:94:39:9d:ed:37:09`

**PBS Sync Job:**
- **Name:** `pull-from-1250p`
- **Direction:** Pull (n6005 pulls from 1250p)
- **Remote:** `1250p-pbs`
- **Remote Store:** `local`
- **Local Store:** `backup-1250p`
- **Schedule:** Daily
- **Remove Vanished:** true

## Backed Up Containers

All LXC containers on intel-1250p are backed up to local PBS and replicated to intel-n6005:

| Container | ID | Hostname | Size | Notes |
|-----------|------|----------|------|-------|
| docker | 1000 | pve-docker-lxc | 1.49GB | Docker services |
| immich | 1001 | pve-immich-lxc | 7.27GB | Photo management (largest backup) |
| pbs | 1002 | pve-proxmox-backup-server-lxc | 1.41GB | PBS application itself |
| syncthing | 1003 | pve-syncthing-lxc | 1.28GB | File synchronization |

**Total backup size:** ~11.5GB (deduplicated to 4.33GB in PBS)

## Host Filesystem Backups

### Media Directory Backup

The `/mnt/media` directory on intel-1250p host is backed up separately using `proxmox-backup-client`.

**Media Storage:**
- **Location:** `/mnt/media` (ZFS dataset `rpool/media`)
- **Size:** 330GB
- **Type:** Host filesystem (not container)
- **Backup target:** PBS local datastore at 192.168.1.52

**Automated Backup Configuration:**

Systemd service and timer handle daily automated backups at 03:00 AM (1 hour after container backups).

**Service:** `/etc/systemd/system/pbs-backup-media.service`
```bash
[Unit]
Description=PBS Media Directory Backup
After=network-online.target

[Service]
Type=oneshot
Environment="PBS_REPOSITORY=backup@pbs@192.168.1.52:local"
Environment="PBS_PASSWORD=jacobjoshua02"
Environment="PBS_FINGERPRINT=1d:1b:35:2c:cd:bd:14:d0:f3:e0:54:1b:56:13:81:1c:94:18:95:e8:b7:89:2b:ca:10:cc:94:39:9d:ed:37:09"
ExecStart=/usr/bin/proxmox-backup-client backup media.pxar:/mnt/media
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Timer:** `/etc/systemd/system/pbs-backup-media.timer`
```bash
[Unit]
Description=Daily PBS Media Backup Timer
Requires=pbs-backup-media.service

[Timer]
OnCalendar=daily
OnCalendar=03:00
OnBootSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

**Setup Commands:**
```bash
# Enable and start timer
systemctl daemon-reload
systemctl enable pbs-backup-media.timer
systemctl start pbs-backup-media.timer

# Check timer status
systemctl status pbs-backup-media.timer

# Manual backup (for testing)
systemctl start pbs-backup-media.service

# View logs
journalctl -u pbs-backup-media.service -f
```

**Backup Performance:**
- Initial backup: 336GB in ~50 minutes (~115 MiB/s)
- Incremental backups: Only changed blocks (much faster due to deduplication)
- Network: Local (host to LXC container on same machine)

## Backup Process

### Automated Backup Schedule

**Backup Job Configuration:** `/etc/pve/jobs.cfg`

```bash
backup: backup-all-containers
	schedule 02:00
	all 1
	storage pbs-local
	mode snapshot
	compress zstd
	notes-template {{guestname}}
	enabled 1
```

**Schedule Details:**
- **Job Name:** `backup-all-containers`
- **Frequency:** Daily at 02:00 (2:00 AM)
- **Target:** All containers (automatic discovery)
- **Storage:** pbs-local (PBS at 192.168.1.52)
- **Mode:** snapshot (zero downtime)
- **Compression:** zstd
- **Notes:** Auto-populated with container name

**Containers Backed Up Automatically:**
- LXC 1000 (docker)
- LXC 1001 (immich)
- LXC 1002 (pbs)
- LXC 1003 (syncthing)

### Manual Backup (if needed)

```bash
# Manual backup of all containers
vzdump 1000 1001 1002 1003 \
  --storage pbs-local \
  --mode snapshot \
  --compress zstd \
  --notes-template '{{guestname}}'
```

**Performance:**
- Average backup speed: 174-215 MiB/s
- Compression: zstd
- Mode: snapshot (no downtime)

## Retention Policy

### PBS Prune Job Configuration

**Prune Job:** `daily-prune` (configured on intel-1250p PBS)

```bash
# View current prune job
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager prune-job list"
```

**Retention Settings:**
- **keep-last:** 3 (always keep the 3 most recent backups)
- **keep-daily:** 30 (keep 1 backup per day for 30 days)
- **keep-weekly:** 8 (keep 1 backup per week for 8 weeks / 2 months)
- **keep-monthly:** 12 (keep 1 backup per month for 12 months / 1 year)
- **keep-yearly:** 3 (keep 1 backup per year for 3 years)

**Schedule:** Daily (runs automatically)

**Disk Space Planning:**

With current backup sizes (4.33GB deduplicated) and generous retention:
- **Estimated maximum storage:** ~500GB (worst case with 50+ snapshots)
- **Available space:** 3.18TB (1250p), 3.50TB (n6005)
- **Usage percentage:** ~15% of available space at maximum
- **Deduplication benefit:** PBS reduces actual storage through block-level deduplication

**Retention Timeline Example:**
- Days 1-30: Daily backups (30 backups)
- Weeks 5-8: Weekly backups (4 backups)
- Months 2-12: Monthly backups (11 backups)
- Years 2-3: Yearly backups (2 backups)
- Plus: Last 3 backups regardless of age

**Configuration Command (already applied):**
```bash
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager prune-job create daily-prune \
  --store local \
  --schedule daily \
  --keep-last 3 \
  --keep-daily 30 \
  --keep-weekly 8 \
  --keep-monthly 12 \
  --keep-yearly 3"
```

### Backup Verification (intel-1250p)

**Verify Job:** `v-9b5e203b-a416` (configured on intel-1250p PBS)

```bash
# View current verify job
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager verify-job list"
```

**Verification Settings:**
- **Schedule:** Daily (automated)
- **Datastore:** intel-1250p-pbs (local)
- **ignore-verified:** Yes (skip already verified chunks)
- **outdated-after:** 30 days (re-verify chunks after 30 days)

**How It Works:**
- Runs daily to verify backup integrity
- Checks deduplicated chunks for corruption/bit rot
- Skips chunks already verified within 30 days
- Re-verifies chunks older than 30 days
- Catches data corruption within 30-day window

**Benefits:**
- **Early corruption detection:** Identifies bit rot before restore is needed
- **Efficient I/O:** Skip-if-verified minimizes redundant verification
- **Regular validation:** 30-day window balances thoroughness with performance
- **Peace of mind:** Ensures backups are restorable when needed

**Configuration Command (already applied):**
```bash
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager verify-job create v-9b5e203b-a416 \
  --store intel-1250p-pbs \
  --schedule daily \
  --ignore-verified true \
  --outdated-after 30"
```

**Manual Verification (if needed):**
```bash
# Run verify job manually
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager verify-job run v-9b5e203b-a416"

# Check verify job status
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager task log"
```

### Automated Replication (intel-n6005)

The sync job runs automatically on a daily schedule:

```bash
# Manual sync (if needed)
ssh intel-n6005
pct exec 1000 -- proxmox-backup-manager sync-job run pull-from-1250p
```

**Replication Performance:**
- Initial sync: 4.2GB at 146 MiB/s
- Network: 10GbE (achieved ~700 MiB/s in testing)
- Direction: n6005 pulls from 1250p

### Off-Site Backup Copy (Synology NAS)

**3-2-1 Backup Strategy Implemented:**
- **3** copies: intel-1250p (primary), intel-n6005 (RAID1 mirror), Synology NAS (cold storage)
- **2** different media types: NVMe (fast) + HDD (reliable long-term storage)
- **1** off-site/separate system: Synology NAS (different hardware, different location)

**Synology NAS Configuration:**
- **Host:** synology-nas (192.168.1.10)
- **Shared Folder:** `/volume1/backup-proxmox-backup-server`
- **Storage:** 13TB total, 12.8TB available
- **SSH Access:** `joseph@192.168.1.10` (unified ED25519 key)
- **Purpose:** Weekly cold storage backup copy for disaster recovery

**Automated Weekly Sync:**

Rsync runs weekly on Sundays at 04:00 AM from n6005 to Synology.

**Service:** `/etc/systemd/system/pbs-sync-to-synology.service` (on intel-n6005)
```bash
[Unit]
Description=Sync PBS Backups to Synology NAS
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -avz --delete /mnt/backup-1250p/ synology:/volume1/backup-proxmox-backup-server/
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Timer:** `/etc/systemd/system/pbs-sync-to-synology.timer` (on intel-n6005)
```bash
[Unit]
Description=Weekly PBS Backup Sync to Synology
Requires=pbs-sync-to-synology.service

[Timer]
OnCalendar=Mon 00:00
OnBootSec=10min
Persistent=true

[Install]
WantedBy=timers.target
```

**SSH Configuration:** `~/.ssh/config` (on intel-n6005)
```bash
Host synology
    HostName 192.168.1.10
    User joseph
    IdentityFile ~/.ssh/id_ed25519_unified
    StrictHostKeyChecking no
```

**Setup Commands (on intel-n6005):**
```bash
# Enable and start timer
systemctl daemon-reload
systemctl enable pbs-sync-to-synology.timer
systemctl start pbs-sync-to-synology.timer

# Check timer status
systemctl status pbs-sync-to-synology.timer

# Manual sync (for testing)
systemctl start pbs-sync-to-synology.service

# View logs
journalctl -u pbs-sync-to-synology.service -f
```

**Sync Performance:**
- Frequency: Weekly (Mondays at midnight)
- Initial sync: ~357GB (all PBS backup data)
- Incremental syncs: Only changed/new files
- Direction: n6005 → Synology (one-way push)
- Method: rsync with --delete flag (mirrors source)

## Configuration Commands

### intel-1250p Setup

```bash
# Create ZFS dataset for backups
zfs create rpool/pbs-local
zfs set mountpoint=/mnt/pbs-local rpool/pbs-local

# Add bind mount to container (edit /etc/pve/lxc/1002.conf)
mp0: /mnt/pbs-local,mp=/mnt/pbs-local

# Restart container
pct restart 1002

# Create PBS datastore
pct exec 1002 -- proxmox-backup-manager datastore create local /mnt/pbs-local

# Create PBS users
pct exec 1002 -- proxmox-backup-manager user create backup@pbs --password jacobjoshua02
pct exec 1002 -- proxmox-backup-manager acl update / DatastoreBackup --auth-id backup@pbs

pct exec 1002 -- proxmox-backup-manager user create sync@pbs --password jacobjoshua02
pct exec 1002 -- proxmox-backup-manager acl update /datastore/local DatastoreReader --auth-id sync@pbs

# Get PBS fingerprint
pct exec 1002 -- proxmox-backup-manager cert info | grep Fingerprint

# Add PBS storage to Proxmox
pvesm add pbs pbs-local \
  --server 192.168.1.52 \
  --datastore local \
  --username backup@pbs \
  --password jacobjoshua02 \
  --fingerprint '1D:1B:35:2C:CD:BD:14:D0:F3:E0:54:1B:56:13:81:1C:94:18:95:E8:B7:89:2B:CA:10:CC:94:39:9D:ED:37:09'
```

### intel-n6005 Setup

```bash
# Create ZFS dataset for backup replication
zfs create rpool/backup-1250p
zfs set mountpoint=/mnt/backup-1250p rpool/backup-1250p

# Add bind mount to container (edit /etc/pve/lxc/1000.conf)
mp0: /mnt/backup-1250p,mp=/mnt/backup-1250p

# Restart container
pct restart 1000

# Create PBS datastore
pct exec 1000 -- proxmox-backup-manager datastore create backup-1250p /mnt/backup-1250p

# Create PBS users
pct exec 1000 -- proxmox-backup-manager user create sync@pbs --password jacobjoshua02
pct exec 1000 -- proxmox-backup-manager acl update / DatastoreReader --auth-id sync@pbs

pct exec 1000 -- proxmox-backup-manager user create pull@pbs --password jacobjoshua02
pct exec 1000 -- proxmox-backup-manager acl update / DatastoreBackup --auth-id pull@pbs

# Create remote connection
pct exec 1000 -- proxmox-backup-manager remote create 1250p-pbs \
  --host 192.168.1.52 \
  --port 8007 \
  --auth-id sync@pbs \
  --password jacobjoshua02 \
  --fingerprint 1d:1b:35:2c:cd:bd:14:d0:f3:e0:54:1b:56:13:81:1c:94:18:95:e8:b7:89:2b:ca:10:cc:94:39:9d:ed:37:09

# Create sync job
pct exec 1000 -- proxmox-backup-manager sync-job create pull-from-1250p \
  --remote 1250p-pbs \
  --remote-store local \
  --store backup-1250p \
  --schedule daily \
  --remove-vanished true
```

## Verification Commands

### Check Backup Status (intel-1250p)

```bash
# Storage status
ssh intel-1250p "pvesm status | grep pbs"

# ZFS dataset status
ssh intel-1250p "zfs list | grep pbs-local"

# PBS datastore info
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager datastore list"

# List backups
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager backup list local"
```

### Check Replication Status (intel-n6005)

```bash
# ZFS dataset status
ssh intel-n6005 "zfs list | grep backup-1250p"

# PBS datastore info
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager datastore list"

# Sync job status
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager sync-job list"

# List replicated backups
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager backup list backup-1250p"

# Check last sync job run
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager task log --limit 5"
```

### Container Health Check

```bash
# intel-1250p PBS container
ssh intel-1250p "pct status 1002 && pct exec 1002 -- df -h / && zfs list rpool/data/subvol-1002-disk-0 rpool/pbs-local"

# intel-n6005 PBS container
ssh intel-n6005 "pct status 1000 && pct exec 1000 -- df -h / && zfs list rpool/data/subvol-1000-disk-0 rpool/backup-1250p"
```

## Restore Operations

### Restore from Primary Backup (intel-1250p)

```bash
# List available backups
pct exec 1002 -- proxmox-backup-manager backup list local

# Restore via Proxmox web UI:
# Datacenter → Storage → pbs-local → CT Backups → Restore

# Or via command line:
pct restore <new-vmid> pbs-local:ct/<vmid>/<backup-time>/ct-<vmid>-<backup-time>.pxar.didx
```

### Restore from Replicated Backup (intel-n6005)

```bash
# SSH to n6005
ssh intel-n6005

# List available backups
pct exec 1000 -- proxmox-backup-manager backup list backup-1250p

# Copy backup to 1250p if needed, or restore locally on n6005
```

## Monitoring

### Disk Space Monitoring

```bash
# Check PBS datastore usage
ssh intel-1250p "zfs list rpool/pbs-local"
ssh intel-n6005 "zfs list rpool/backup-1250p"

# Check container rootfs (should stay under 1GB)
ssh intel-1250p "zfs list rpool/data/subvol-1002-disk-0"
ssh intel-n6005 "zfs list rpool/data/subvol-1000-disk-0"
```

### Backup Job Monitoring

```bash
# Check recent backup tasks (intel-1250p)
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager task log"

# Check recent sync tasks (intel-n6005)
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager task log"
```

### Sync Job Status

```bash
# Manual sync execution (for testing)
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager sync-job run pull-from-1250p"

# Check sync schedule
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager sync-job list"
```

## Important Notes

### Storage Architecture

- **Backups are stored OUTSIDE containers** on host ZFS datasets via bind mounts
- **Container rootfs** contains only PBS application (~680-860MB)
- **Backup data** is stored on host ZFS for performance and safety
- Do NOT store backups inside container rootfs (causes disk exhaustion)

### RAID Configuration

- **intel-1250p:** Single NVMe (fast primary storage, no redundancy)
- **intel-n6005:** RAID1 mirror (slower but redundant, safe backup copy)
- Replication provides geographic/host diversity

### Performance Expectations

- **Local backup:** 174-215 MiB/s (varies by container size)
- **Network replication:** Up to 700 MiB/s over 10GbE
- **Actual sync speed:** ~146 MiB/s (PBS overhead + deduplication)

### Security

- All PBS users use password authentication
- PBS API uses certificate fingerprint validation
- Sync user has read-only access to source datastore
- Pull user has write access only to destination datastore

### Maintenance

- **Prune old backups** automated via `daily-prune` job (runs daily)
- **Verify backups** periodically by testing restores
- **Monitor backup job** to ensure daily backups succeed at 02:00
- **Monitor sync job** to ensure daily replication succeeds
- **Check ZFS health** on both hosts regularly
- **Review retention policy** if storage usage approaches 50% of available space

## Troubleshooting

### Sync Job Fails

```bash
# Check network connectivity
ssh intel-n6005 "pct exec 1000 -- curl -k https://192.168.1.52:8007"

# Verify credentials
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager remote list"

# Check remote fingerprint
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager cert info"
```

### Container Disk Full

```bash
# Check what's using space (exclude bind mounts)
pct exec <vmid> -- du -sh /* --exclude=/mnt 2>/dev/null | sort -h

# Verify bind mount is working
pct exec <vmid> -- mount | grep backup

# Check host ZFS datasets
zfs list | grep -E '(pbs-local|backup-1250p|subvol-<vmid>)'
```

### Backup Performance Issues

```bash
# Check PBS service status
pct exec <vmid> -- systemctl status proxmox-backup

# Check network performance
ssh intel-n6005 "iperf3 -c 192.168.1.40 -t 10"

# Check ZFS performance
zpool iostat -v 1 5
```

## Web Interfaces

- **intel-1250p PBS:** https://192.168.1.52:8007
- **intel-n6005 PBS:** https://192.168.1.41:8007 (container on n6005, no external IP)

**Login:**
- Username: `root@pam`
- Password: `jacobjoshua02`

## Implemented Features

- ✅ **3-tier automated backup system** (PBS → ZFS replication → rsync to NAS)
- ✅ **Daily backup verification** (v-9b5e203b-a416 with 30-day reverify)
- ✅ **Automated retention policy** (daily-prune with 3-year history)
- ✅ **Off-site backup sync** (Synology NAS via rsync)
- ✅ **RTC-based power management** (N6005 auto-wake/shutdown)

## Future Enhancements

- Configure email notifications for backup/prune/sync/verify job failures
- Add more containers to backup rotation as created (automatic via `all 1`)
- Set up additional off-site backup location (if needed)
