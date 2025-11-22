# PBS Backup Automation - Complete Change Log

**Date:** October 11, 2025
**Purpose:** Document all system modifications for automated PBS backup infrastructure with power management

## Overview

This document lists every file created, modified, or configured across all devices to implement:
- Automated container backups
- Automated host filesystem backups
- PBS replication between hosts
- Off-site backup to Synology NAS
- Automated power management (n6005 and Synology)
- Boot-time backup catch-up capabilities

---

## intel-1250p (192.168.1.40) - Primary Proxmox Host

### Files Created

**1. `/etc/systemd/system/pbs-backup-media.service`**
- **Type:** New file
- **Purpose:** Systemd service for automated media directory backups
- **Function:** Backs up `/mnt/media` (330GB) to PBS using `proxmox-backup-client`
- **Schedule:** Triggered by timer
- **Configuration:**
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

**2. `/etc/systemd/system/pbs-backup-media.timer`**
- **Type:** New file
- **Purpose:** Timer for media backup service
- **Schedule:** Daily at 03:00 AM
- **Boot trigger:** Runs 5 minutes after boot (`OnBootSec=5min`)
- **Configuration:**
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

### Files Modified

**3. `/etc/pve/jobs.cfg`**
- **Type:** Modified (Proxmox cluster configuration)
- **Purpose:** Added automated container backup job
- **Changes:** Added `backup-all-containers` job
- **Configuration:**
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
- **Details:**
  - Backs up all LXC containers automatically
  - Runs daily at 02:00 AM
  - Uses snapshot mode (zero downtime)
  - Compresses with zstd
  - Automatically discovers new containers (`all 1`)

### Systemd Services Enabled

```bash
# Enable and start media backup timer
systemctl daemon-reload
systemctl enable pbs-backup-media.timer
systemctl start pbs-backup-media.timer
```

### Verification Commands

```bash
# Check timer status
systemctl status pbs-backup-media.timer
systemctl list-timers pbs-backup-media.timer

# Check service status
systemctl status pbs-backup-media.service

# View logs
journalctl -u pbs-backup-media.service -f

# Manual test
systemctl start pbs-backup-media.service
```

---

## intel-1250p LXC 1002 (192.168.1.52) - Primary PBS Container

### PBS Configuration Changes

**1. PBS Prune Job Created**
- **Type:** PBS internal configuration
- **Purpose:** Automated retention policy management
- **Job Name:** `daily-prune`
- **Schedule:** Daily
- **Command:**
  ```bash
  proxmox-backup-manager prune-job create daily-prune \
    --store local \
    --schedule daily \
    --keep-last 3 \
    --keep-daily 30 \
    --keep-weekly 8 \
    --keep-monthly 12 \
    --keep-yearly 3
  ```
- **Retention Settings:**
  - Keep last 3 backups always
  - Keep 30 daily backups
  - Keep 8 weekly backups (2 months)
  - Keep 12 monthly backups (1 year)
  - Keep 3 yearly backups (3 years)

### PBS Users (No changes - already configured)

- `backup@pbs` - DatastoreBackup role
- `sync@pbs` - DatastoreReader role

### Verification Commands

```bash
# List prune jobs
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager prune-job list"

# Check prune job status
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager task log | grep prune"

# Manual prune test
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager prune-job run daily-prune"
```

---

## intel-n6005 (192.168.1.41) - Backup Replication Host

### Files Created

**1. `/usr/local/bin/schedule-wake.sh`**
- **Type:** New file
- **Purpose:** RTC wake alarm scheduler script
- **Function:** Calculates and sets wake alarm for 3:00 AM next day
- **Permissions:** `chmod +x`
- **Configuration:**
  ```bash
  #!/bin/bash
  # Schedule next RTC wake for n6005
  # Run daily to set wake alarm for 3:00 AM next day

  # Calculate seconds until tomorrow 3:00 AM
  TOMORROW_3AM=$(date -d 'tomorrow 03:00' +%s)

  # Clear any existing alarm
  echo 0 > /sys/class/rtc/rtc0/wakealarm

  # Set new alarm
  echo $TOMORROW_3AM > /sys/class/rtc/rtc0/wakealarm

  # Log the scheduled wake time
  logger "RTC wake scheduled for $(date -d @$TOMORROW_3AM)"
  ```

**2. `/etc/systemd/system/schedule-wake.service`**
- **Type:** New file
- **Purpose:** Runs wake scheduler script before shutdown
- **Function:** Automatically sets next wake alarm when system shuts down
- **Trigger:** Runs before `shutdown.target`, `reboot.target`, `halt.target`
- **Configuration:**
  ```bash
  [Unit]
  Description=Schedule RTC Wake Alarm for 3:00 AM
  Before=shutdown.target reboot.target halt.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/schedule-wake.sh

  [Install]
  WantedBy=shutdown.target reboot.target halt.target
  ```

**3. `/etc/systemd/system/auto-shutdown.service`**
- **Type:** New file
- **Purpose:** Automated daily shutdown service
- **Function:** Shuts down system at scheduled time
- **Configuration:**
  ```bash
  [Unit]
  Description=Automated Daily Shutdown at 6:00 AM

  [Service]
  Type=oneshot
  ExecStart=/sbin/shutdown -h now

  [Install]
  WantedBy=multi-user.target
  ```

**4. `/etc/systemd/system/auto-shutdown.timer`**
- **Type:** New file
- **Purpose:** Timer for automated shutdown
- **Schedule:** Daily at 06:00 AM
- **Configuration:**
  ```bash
  [Unit]
  Description=Daily Shutdown Timer at 6:00 AM

  [Timer]
  OnCalendar=daily
  OnCalendar=06:00
  Persistent=true

  [Install]
  WantedBy=timers.target
  ```

**5. `/etc/systemd/system/pbs-sync-to-synology.service`**
- **Type:** New file
- **Purpose:** Syncs PBS backups to Synology NAS
- **Function:** Weekly rsync mirror to off-site storage
- **Configuration:**
  ```bash
  [Unit]
  Description=Sync PBS Backups to Synology NAS
  After=network-online.target

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/rsync -avz --delete /mnt/backup-1250p/ synology:/volume1/pbs-backup/
  StandardOutput=journal
  StandardError=journal

  [Install]
  WantedBy=multi-user.target
  ```

**6. `/etc/systemd/system/pbs-sync-to-synology.timer`**
- **Type:** New file
- **Purpose:** Timer for Synology sync
- **Schedule:** Weekly on Sundays at 04:00 AM
- **Boot trigger:** Runs 10 minutes after boot (`OnBootSec=10min`)
- **Configuration:**
  ```bash
  [Unit]
  Description=Weekly PBS Backup Sync to Synology
  Requires=pbs-sync-to-synology.service

  [Timer]
  OnCalendar=weekly
  OnCalendar=Sun 04:00
  OnBootSec=10min
  Persistent=true

  [Install]
  WantedBy=timers.target
  ```

**7. `~/.ssh/config`**
- **Type:** New file (or appended if exists)
- **Purpose:** SSH alias for Synology NAS
- **Configuration:**
  ```bash
  Host synology
      HostName 192.168.1.10
      User joseph
      IdentityFile ~/.ssh/id_ed25519_unified
      StrictHostKeyChecking no
  ```

**8. `~/.ssh/id_ed25519_unified` and `~/.ssh/id_ed25519_unified.pub`**
- **Type:** Copied from intel-1250p
- **Purpose:** Unified SSH key for password-less authentication
- **Permissions:**
  - Private key: `chmod 600 ~/.ssh/id_ed25519_unified`
  - Public key: `chmod 644 ~/.ssh/id_ed25519_unified.pub`

### Systemd Services Enabled

```bash
# Enable wake scheduling (runs before shutdown)
systemctl daemon-reload
systemctl enable schedule-wake.service

# Enable automated shutdown timer
systemctl enable auto-shutdown.timer
systemctl start auto-shutdown.timer

# Enable Synology sync timer
systemctl enable pbs-sync-to-synology.timer
systemctl start pbs-sync-to-synology.timer

# Set initial wake alarm
/usr/local/bin/schedule-wake.sh
```

### Verification Commands

```bash
# Check wake alarm
cat /sys/class/rtc/rtc0/wakealarm
date -d @$(cat /sys/class/rtc/rtc0/wakealarm)

# Check shutdown timer
systemctl status auto-shutdown.timer
systemctl list-timers auto-shutdown.timer

# Check Synology sync timer
systemctl status pbs-sync-to-synology.timer
systemctl list-timers pbs-sync-to-synology.timer

# Test Synology SSH connection
ssh synology "hostname && df -h /volume1/pbs-backup"

# Manual sync test
systemctl start pbs-sync-to-synology.service

# View sync logs
journalctl -u pbs-sync-to-synology.service -f
```

---

## intel-n6005 LXC 1000 (192.168.1.70) - Replication PBS Container

### PBS Configuration (Already configured - no changes needed)

**Existing Configuration:**
- PBS Remote: `1250p-pbs` pointing to 192.168.1.52:8007
- PBS Sync Job: `pull-from-1250p` (daily pull replication)
- PBS Users: `sync@pbs` (reader), `pull@pbs` (writer)
- Datastore: `backup-1250p` at `/mnt/backup-1250p`

**Note:** All PBS replication was previously configured. No changes were made to the container itself during this automation update.

### Verification Commands

```bash
# Check sync job status
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager sync-job list"

# Check datastore
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager datastore list"

# Manual sync test
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager sync-job run pull-from-1250p"

# View sync logs
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager task log | grep sync"
```

---

## Synology NAS (192.168.1.10)

### Configuration Changes (via DSM Web Interface)

**1. Power Schedule Created**
- **Location:** Control Panel → Hardware & Power → Power Schedule
- **Power On:** Daily at 3:30 AM
- **Power Off:** Daily at 6:30 AM
- **Purpose:** Automated power management for backup operations

**2. HyperBackup Schedule Configured**
- **Location:** HyperBackup application
- **Schedule:** Daily at 5:00 AM
- **Source:** `/volume1/pbs-backup/` (PBS backup mirror)
- **Destination:** Cloud storage (configured via DSM)
- **Purpose:** Final tier of 3-2-1 backup strategy

**3. Shared Folder Created**
- **Location:** Control Panel → Shared Folder
- **Name:** `pbs-backup`
- **Path:** `/volume1/pbs-backup`
- **Permissions:** Read/Write for user `joseph`

**4. SSH Access Configured**
- **Location:** Control Panel → Terminal & SNMP → Terminal
- **SSH:** Enabled
- **User:** `joseph`
- **Authorized Keys:** Added `~/.ssh/id_ed25519_unified.pub` from intel-n6005

### SSH Key Installation

```bash
# From intel-n6005, copy public key to Synology
ssh joseph@192.168.1.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
cat ~/.ssh/id_ed25519_unified.pub | ssh joseph@192.168.1.10 "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Verification Commands

```bash
# Test SSH from n6005
ssh synology "hostname"

# Check shared folder
ssh synology "ls -lh /volume1/pbs-backup"

# Check disk space
ssh synology "df -h /volume1"

# Verify rsync works
ssh intel-n6005 "rsync -avz --dry-run --delete /mnt/backup-1250p/ synology:/volume1/pbs-backup/"
```

---

## Summary of All Changes

### Files Created (Total: 9 files)

**intel-1250p:**
1. `/etc/systemd/system/pbs-backup-media.service`
2. `/etc/systemd/system/pbs-backup-media.timer`

**intel-n6005:**
3. `/usr/local/bin/schedule-wake.sh`
4. `/etc/systemd/system/schedule-wake.service`
5. `/etc/systemd/system/auto-shutdown.service`
6. `/etc/systemd/system/auto-shutdown.timer`
7. `/etc/systemd/system/pbs-sync-to-synology.service`
8. `/etc/systemd/system/pbs-sync-to-synology.timer`
9. `~/.ssh/config` (SSH alias)

### Files Modified (Total: 1 file)

**intel-1250p:**
1. `/etc/pve/jobs.cfg` (added `backup-all-containers` job)

### PBS Internal Configurations (Total: 1 config)

**intel-1250p LXC 1002:**
1. PBS Prune Job `daily-prune` created

### Synology Configurations (via DSM Web Interface)

1. Power Schedule (3:30 AM on, 6:30 AM off)
2. HyperBackup Schedule (5:00 AM daily)
3. Shared Folder `/volume1/pbs-backup` created
4. SSH authorized keys for user `joseph`

### SSH Keys Distributed

- Unified ED25519 key (`id_ed25519_unified`) copied from intel-1250p to intel-n6005
- Public key added to Synology `authorized_keys`

---

## Operational Timeline

### Daily Automated Schedule

```
02:00 AM - Container backups (intel-1250p → PBS .52)
03:00 AM - Media backup (intel-1250p → PBS .52)
03:00 AM - n6005 powers on (RTC wake)
03:15 AM - PBS sync (PBS .52 → PBS .70)
03:30 AM - Synology powers on
04:00 AM - Rsync to Synology (Sundays only)
05:00 AM - Synology HyperBackup to cloud
06:00 AM - n6005 powers off (scheduled)
06:30 AM - Synology powers off (scheduled)
```

### Boot-Time Behavior

**If systems were powered off during scheduled times:**
- **intel-1250p media backup:** Runs 5 minutes after boot
- **intel-n6005 Synology sync:** Runs 10 minutes after boot
- **All timers:** Use `Persistent=true` to catch up on missed runs

---

## Rollback Procedures

### To Disable Automation (if needed)

**intel-1250p:**
```bash
systemctl stop pbs-backup-media.timer
systemctl disable pbs-backup-media.timer
```

**intel-n6005:**
```bash
systemctl stop auto-shutdown.timer
systemctl disable auto-shutdown.timer
systemctl stop pbs-sync-to-synology.timer
systemctl disable pbs-sync-to-synology.timer
systemctl disable schedule-wake.service
```

**To remove automated container backups:**
```bash
# Edit /etc/pve/jobs.cfg and remove or comment out the backup job
nano /etc/pve/jobs.cfg
```

**To remove PBS prune job:**
```bash
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager prune-job remove daily-prune"
```

---

## Maintenance Notes

### Regular Checks

**Weekly:**
- Verify backup jobs completed successfully
- Check disk space on both PBS datastores
- Verify Synology sync completed (check logs)

**Monthly:**
- Test restore operation from primary PBS
- Test restore operation from n6005 PBS
- Verify Synology data integrity
- Review retention policy effectiveness

**Commands:**
```bash
# Check all timers
ssh intel-1250p "systemctl list-timers"
ssh intel-n6005 "systemctl list-timers"

# Check PBS task logs
ssh intel-1250p "pct exec 1002 -- proxmox-backup-manager task log"
ssh intel-n6005 "pct exec 1000 -- proxmox-backup-manager task log"

# Check disk usage
ssh intel-1250p "zfs list | grep pbs"
ssh intel-n6005 "zfs list | grep backup"
ssh synology "df -h /volume1/pbs-backup"

# Check service statuses
ssh intel-1250p "systemctl status pbs-backup-media.timer"
ssh intel-n6005 "systemctl status auto-shutdown.timer pbs-sync-to-synology.timer"
```

---

## Documentation Files

All documentation created in `~/Documents/dev/md/`:

1. **pbs-backup-config.md** - Complete PBS infrastructure documentation (updated)
2. **pbs-power-management-section.md** - Power management documentation (to be merged)
3. **pbs-automation-changelog.md** - This file (complete change log)

---

**END OF CHANGE LOG**
