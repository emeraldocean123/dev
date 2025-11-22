# Backup Infrastructure Overview

**Last Updated:** October 13, 2025
**Status:** Fully Operational - 3-Tier Automated Backup System

## Executive Summary

Complete **3-tier automated backup infrastructure** providing enterprise-grade data protection with automatic power management, incremental replication, and on-demand tertiary backups.

**Key Features:**
- ✅ **Zero-downtime backups** via LXC snapshots
- ✅ **Automatic off-host replication** with RTC wake/sleep
- ✅ **On-demand tertiary backup** with auto-detection
- ✅ **Power-efficient design** (~70 kWh/year savings)
- ✅ **Deduplication** via Proxmox Backup Server
- ✅ **Comprehensive retention** (3 years of backups)

## 3-Tier Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   COMPLETE BACKUP SYSTEM                      │
└──────────────────────────────────────────────────────────────┘

Layer 1: Primary Backup (On-Host - Fast Storage)
┌────────────────────────────────────────────┐
│  intel-1250p (192.168.1.40)                │
│  ├─ PBS Container (LXC 1002 - 192.168.1.52)│
│  ├─ Storage: Single 4TB NVMe (ZFS)         │
│  ├─ Dataset: rpool/intel-1250p-proxmox-    │
│  │           backup-server (374GB)         │
│  ├─ Backup Schedule: Daily at 2:00 AM      │
│  ├─ Containers: 1000-1004 (5 containers)   │
│  └─ ZFS Auto-Snapshots: Frequent → Monthly │
└────────────────────────────────────────────┘
                 ↓
         ZFS send/receive @ 3:00 AM
         (Incremental, block-level)
                 ↓
Layer 2: Off-Host Replication (RTC Automated)
┌────────────────────────────────────────────┐
│  intel-n6005 (192.168.1.41)                │
│  ├─ Dataset: rpool/intel-1250p-proxmox-    │
│  │           backup-server (374GB replicated)│
│  ├─ Power: RTC wake at 2:50 AM             │
│  ├─ Replication: 3:00 AM (30-60s typical)  │
│  ├─ Auto-shutdown: ~3:05 AM                │
│  ├─ Snapshots: Last 7 replication points   │
│  └─ Savings: ~70 kWh/year (~$10.50)        │
└────────────────────────────────────────────┘
                 ↓
      rsync @ on-demand (when powered on)
      (File-level sync via NFS)
                 ↓
Layer 3: Tertiary Backup (Auto on Power-On)
┌────────────────────────────────────────────┐
│  Synology NAS (192.168.1.10)               │
│  ├─ Storage: /volume1/backup-proxmox-      │
│  │           backup-server (371GB)         │
│  ├─ Method: rsync via NFS mount            │
│  ├─ Detection: Auto-detect power-on        │
│  ├─ Workflow: rsync → verify → shutdown    │
│  ├─ Cooldown: 1 hour between runs          │
│  └─ Service: synology-auto-backup (active) │
└────────────────────────────────────────────┘
```

## Backup Schedule

### Daily Automated Workflow

```
Timeline:
├─ 2:00 AM: PBS Backup (intel-1250p)
│           ├─ Backs up all LXC containers (1000-1004)
│           ├─ Zero-downtime snapshot mode
│           ├─ zstd compression
│           └─ Stores in PBS datastore (374GB)
│
├─ 2:50 AM: N6005 RTC Wake (BIOS-level)
│           ├─ Hardware clock triggers power-on
│           ├─ System boots automatically
│           └─ No network/software dependency
│
├─ 3:00 AM: ZFS Replication (intel-1250p → N6005)
│           ├─ Cron trigger on intel-1250p
│           ├─ Creates snapshot: pbs-repl-YYYYMMDD-HHMMSS
│           ├─ Incremental ZFS send/receive
│           ├─ Typical duration: 30-60 seconds
│           └─ Cleans up old snapshots (keeps last 7)
│
└─ 3:05 AM: N6005 Auto-Shutdown with RTC Alarm
            ├─ 30-second grace period
            ├─ Sets RTC alarm for 2:50 AM tomorrow
            └─ Powers off N6005
```

### On-Demand Workflow (Synology)

```
User Action: Power on Synology manually
                 ↓
Service Detects: Within ~60 seconds
                 ↓
Auto-Workflow:
├─ 1. Rsync PBS datastore to Synology (via NFS)
├─ 2. Verify sync (compare sizes and file counts)
├─ 3. Wait 60s grace period
└─ 4. Shutdown Synology automatically

Cooldown: 1 hour (prevents excessive runs)
```

### ZFS Auto-Snapshot Schedule

```
Frequent:  Every 15 minutes (keep 8 = 2 hours)
Hourly:    Every hour (keep 24 = 24 hours)
Daily:     Every day at midnight (keep 7 = 7 days)
Weekly:    Every week (keep 4 = 4 weeks)
Monthly:   Every month (keep 12 = 12 months)
```

## Storage Summary

### Layer 1: intel-1250p (Primary)
- **Type:** ZFS dataset on single 4TB NVMe
- **Dataset:** `rpool/intel-1250p-proxmox-backup-server`
- **Size:** 374GB used, 2.77TB available
- **Contents:** PBS datastore with all backups
- **Redundancy:** None (fast primary storage)
- **Auto-Snapshots:** Yes (frequent through monthly)

### Layer 2: intel-n6005 (Off-Host Replication)
- **Type:** ZFS dataset on 2×4TB NVMe RAID1
- **Dataset:** `rpool/intel-1250p-proxmox-backup-server`
- **Size:** 374GB replicated, 3.14TB available
- **Contents:** Exact ZFS replica of Layer 1
- **Redundancy:** RAID1 mirror (high reliability)
- **Snapshots:** Last 7 replication points (pbs-repl-*)
- **Power:** Automated RTC wake/sleep

### Layer 3: Synology NAS (Tertiary/Cold Storage)
- **Type:** NFS share, rsync target
- **Path:** `/volume1/backup-proxmox-backup-server`
- **Size:** 371GB synced, 12.8TB available
- **Contents:** File-level copy of PBS datastore
- **Redundancy:** Synology RAID (varies by config)
- **Power:** Manual power-on, auto-shutdown
- **Detection:** Automatic via monitoring service

## Backed Up Containers

| Container | ID | Hostname | Last Backup | Size | Notes |
|-----------|-----|----------|-------------|------|-------|
| docker | 1000 | pve-docker-lxc | Oct 13, 19:02 | ~2GB | Docker services |
| immich | 1001 | pve-immich-lxc | Oct 13, 19:03 | ~8GB | Photo management |
| pbs | 1002 | pve-proxmox-backup-server-lxc | Oct 13, 19:04 | ~2GB | PBS itself |
| syncthing | 1003 | pve-syncthing-lxc | Oct 13, 19:04 | ~1.5GB | File sync |
| tailscale | 1004 | pve-tailscale-lxc | Oct 13, 19:04 | ~1GB | VPN |

**Total:** 5 containers, ~374GB deduplicated in PBS

## Retention Policies

### PBS Prune Policy (Layer 1)
- **keep-last:** 3 backups
- **keep-daily:** 30 backups (1 month)
- **keep-weekly:** 8 backups (2 months)
- **keep-monthly:** 12 backups (1 year)
- **keep-yearly:** 3 backups (3 years)

**Total retention:** Up to 56 backup snapshots spanning 3 years

### ZFS Auto-Snapshots (Layer 1)
- **Frequent:** 8 snapshots (2 hours)
- **Hourly:** 24 snapshots (24 hours)
- **Daily:** 7 snapshots (7 days)
- **Weekly:** 4 snapshots (4 weeks)
- **Monthly:** 12 snapshots (12 months)

**Total retention:** Up to 55 snapshots spanning 1+ years

### ZFS Replication Snapshots (Layer 2)
- **Replication:** Last 7 snapshots (7 days)
- **Naming:** `pbs-repl-YYYYMMDD-HHMMSS`
- **Cleanup:** Automatic (old snapshots removed after 7th)

### Synology Sync (Layer 3)
- **Method:** Mirror (rsync --delete)
- **Retention:** Latest sync only
- **Frequency:** On-demand (manual power-on)
- **Cooldown:** 1 hour between syncs

## Automation Components

### Scripts (intel-1250p)
1. **`/root/sh/zfs-replicate-pbs.sh`** - ZFS replication with RTC
   - Creates snapshots
   - Sends incremental to N6005
   - Cleans up old snapshots
   - Triggers RTC shutdown

2. **`/root/sh/rsync-pbs-to-synology.sh`** - Rsync to Synology
   - Mounts NFS if needed
   - Syncs PBS datastore
   - Verifies sizes and counts
   - Logs to `/tmp/rsync-pbs-synology.log`

3. **`/root/sh/synology-auto-backup.sh`** - Auto-detect and backup
   - Monitors for Synology online (every 60s)
   - Triggers rsync automatically
   - Optionally runs HyperBackup
   - Auto-shutdowns Synology
   - Logs to `/var/log/synology-auto-backup.log`

### Scripts (intel-n6005)
1. **`/root/sh/shutdown-with-rtc-wake.sh`** - RTC alarm + shutdown
   - Calculates next 2:50 AM
   - Sets RTC wake alarm
   - Shuts down system

### Systemd Services (intel-1250p)
1. **`synology-auto-backup.service`** - Synology monitor
   - Status: Active and running
   - Mode: Continuous monitoring
   - Check interval: 60 seconds
   - Resource limits: 256MB RAM, 10% CPU

### Cron Jobs (intel-1250p)
1. **`/etc/cron.d/zfs-pbs-replication`** - Daily ZFS replication
   ```
   0 3 * * * root /root/sh/zfs-replicate-pbs.sh >/var/log/zfs-pbs-replication.log 2>&1
   ```

### Proxmox Backup Jobs (intel-1250p)
1. **`backup-all-containers`** - Daily backup job
   - Schedule: 02:00 daily
   - Target: All containers
   - Storage: pbs-local (192.168.1.52)
   - Mode: snapshot (zero downtime)
   - Compression: zstd

## Power Management

### N6005 Automated Power
- **On-Time:** 2:50 AM - 3:05 AM (~15 minutes/day)
- **Off-Time:** 3:05 AM - 2:50 AM (~23h 45m/day)
- **Power Draw:**
  - Active: ~20-25W (replication)
  - Off: <2W (standby)
- **Annual Savings:** ~70 kWh (~$10.50/year)
- **Method:** RTC (Real-Time Clock) wake via BIOS

### Synology On-Demand Power
- **Trigger:** Manual power-on button press
- **Detection:** Automatic within ~60 seconds
- **Active Time:** ~2-5 minutes (rsync + verification)
- **Shutdown:** Automatic after completion
- **Cooldown:** 1 hour between runs

## Monitoring and Logs

### Log Files (intel-1250p)
- **ZFS replication:** `/var/log/zfs-pbs-replication.log`
- **Synology rsync:** `/tmp/rsync-pbs-synology.log`
- **Synology auto-backup:** `/var/log/synology-auto-backup.log`
- **Proxmox backup jobs:** Web UI → Datacenter → Tasks

### Service Status Commands
```bash
# ZFS replication cron
ssh intel-1250p "systemctl status cron"

# Synology auto-backup service
ssh intel-1250p "systemctl status synology-auto-backup.service"

# Check synology auto-backup logs
ssh intel-1250p "tail -50 /var/log/synology-auto-backup.log"

# Check synology auto-backup status
ssh intel-1250p "/root/sh/synology-auto-backup.sh --status"
```

### Verification Commands
```bash
# Layer 1: Check PBS backups
ssh intel-1250p "zfs list rpool/intel-1250p-proxmox-backup-server"

# Layer 2: Check N6005 replication
ssh intel-n6005 "zfs list rpool/intel-1250p-proxmox-backup-server"

# Layer 2: Check replication snapshots
ssh intel-n6005 "zfs list -t snapshot rpool/intel-1250p-proxmox-backup-server | grep pbs-repl"

# Layer 3: Check Synology sync (when online)
ssh intel-1250p "du -sh /mnt/backup-proxmox-backup-server"

# Check N6005 status (should be offline most of the time)
ping -c 1 192.168.1.41 && echo "Online" || echo "Offline (expected)"
```

## Documentation References

### Complete Documentation Set
1. **`backup-infrastructure-overview.md`** - This document (high-level overview)
2. **`pbs-backup-config.md`** - Detailed PBS configuration and setup
3. **`zfs-wol-replication.md`** - ZFS replication with RTC wake details
4. **`synology-auto-backup.md`** - Synology auto-backup system documentation

### Script Documentation
- **`C:/Users/josep/Documents/dev/sh/README.md`** - Complete script suite documentation
- All scripts include inline documentation and `--help` flags

## Key Benefits

### Reliability
- ✅ **3 independent copies** on different hardware
- ✅ **2 different technologies** (ZFS + rsync)
- ✅ **Geographic diversity** (different physical hosts)
- ✅ **BIOS-level wake** (more reliable than network-based)
- ✅ **Automatic monitoring** (no manual intervention)

### Efficiency
- ✅ **Incremental everything** (ZFS blocks, rsync files)
- ✅ **Power-efficient** (~70 kWh/year savings)
- ✅ **Deduplication** (PBS reduces storage)
- ✅ **Fast recovery** (Layer 1 is local and fast)
- ✅ **Zero downtime** (snapshot-based backups)

### Automation
- ✅ **Fully automated** daily backups
- ✅ **Self-healing** (RTC wake self-perpetuates)
- ✅ **On-demand tertiary** (just power on Synology)
- ✅ **Automatic cleanup** (old snapshots pruned)
- ✅ **Comprehensive logging** (audit trail)

## Recovery Procedures

### Scenario 1: Restore Single Container (Recent Failure)
**Source:** Layer 1 (intel-1250p PBS)
**Speed:** Very fast (local, deduplicated)
**Steps:**
1. Proxmox Web UI → Storage → pbs-local → CT Backups
2. Select backup → Restore
3. 2-5 minutes typical restore time

### Scenario 2: Intel-1250p Failure (Hardware)
**Source:** Layer 2 (N6005 ZFS replica)
**Speed:** Fast (ZFS send to new host)
**Steps:**
1. Power on N6005 manually
2. `zfs send` dataset to new host
3. Mount dataset and restore from PBS backups
4. ~30-60 minutes for full recovery

### Scenario 3: Complete Site Disaster
**Source:** Layer 3 (Synology cold storage)
**Speed:** Moderate (file-level copy)
**Steps:**
1. Power on Synology
2. Copy PBS datastore to new infrastructure
3. Set up new PBS and restore containers
4. ~2-4 hours for full recovery

## Troubleshooting

### N6005 Doesn't Wake at 2:50 AM
1. Check RTC alarm: `ssh intel-n6005 "rtcwake -m show"`
2. Verify BIOS RTC wake enabled
3. Check cron log: `ssh intel-1250p "tail /var/log/zfs-pbs-replication.log"`
4. Test RTC manually: `ssh intel-n6005 "rtcwake -m no -s 120"` then shutdown

### Synology Not Detected
1. Verify online: `ping -c 3 192.168.1.10`
2. Check service: `ssh intel-1250p "systemctl status synology-auto-backup.service"`
3. Check logs: `ssh intel-1250p "tail -20 /var/log/synology-auto-backup.log"`
4. Force run: `ssh intel-1250p "/root/sh/synology-auto-backup.sh --oneshot --force"`

### ZFS Replication Fails
1. Check N6005 online: `ping -c 1 192.168.1.41`
2. Check SSH access: `ssh intel-n6005 "echo test"`
3. Check ZFS snapshots: `ssh intel-1250p "zfs list -t snapshot | grep pbs-repl"`
4. Review log: `ssh intel-1250p "cat /var/log/zfs-pbs-replication.log"`

## Summary

The **3-tier automated backup infrastructure** provides:

- ✅ **Enterprise-grade reliability** with multiple redundant copies
- ✅ **Power-efficient design** with automated wake/sleep
- ✅ **Zero-touch operation** for daily backups and replication
- ✅ **On-demand tertiary** backup with auto-detection
- ✅ **Comprehensive retention** spanning 3 years
- ✅ **Fast local recovery** from Layer 1 (minutes)
- ✅ **Off-host disaster recovery** from Layer 2 (under 1 hour)
- ✅ **Cold storage fallback** from Layer 3 (2-4 hours)

**Total Infrastructure:** 1 primary host + 1 replication host + 1 cold storage = **100% automated** backup protection.
