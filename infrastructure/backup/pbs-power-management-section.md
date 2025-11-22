## Automated Power Management

### intel-n6005 RTC Wake and Shutdown

The intel-n6005 host features automated power scheduling using RTC (Real-Time Clock) wake alarms and systemd timers for power-efficient operation.

**Power Schedule:**
- **Power On:** 3:00 AM daily (RTC wake alarm)
- **Power Off:** 6:00 AM daily (systemd timer)
- **Daily Runtime:** 3 hours (sufficient for all backup operations)

**Wake Scheduling Script:** `/usr/local/bin/schedule-wake.sh` (on intel-n6005)
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

**Wake Scheduling Service:** `/etc/systemd/system/schedule-wake.service` (on intel-n6005)
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

**Automated Shutdown Service:** `/etc/systemd/system/auto-shutdown.service` (on intel-n6005)
```bash
[Unit]
Description=Automated Daily Shutdown at 6:00 AM

[Service]
Type=oneshot
ExecStart=/sbin/shutdown -h now

[Install]
WantedBy=multi-user.target
```

**Automated Shutdown Timer:** `/etc/systemd/system/auto-shutdown.timer` (on intel-n6005)
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

**Setup Commands (on intel-n6005):**
```bash
# Create wake script
chmod +x /usr/local/bin/schedule-wake.sh

# Enable wake scheduling (runs before shutdown)
systemctl daemon-reload
systemctl enable schedule-wake.service

# Enable automated shutdown timer
systemctl enable auto-shutdown.timer
systemctl start auto-shutdown.timer

# Set initial wake alarm
/usr/local/bin/schedule-wake.sh

# Verify wake alarm
cat /sys/class/rtc/rtc0/wakealarm
date -d @$(cat /sys/class/rtc/rtc0/wakealarm)

# Check shutdown timer
systemctl status auto-shutdown.timer
```

**How It Works:**
1. Before every shutdown/reboot, `schedule-wake.service` runs and sets RTC wake alarm for 3:00 AM next day
2. System powers off at 6:00 AM via `auto-shutdown.timer`
3. Hardware RTC wakes system at 3:00 AM
4. All backup operations complete during 3:00-6:00 AM window
5. Cycle repeats daily

**Benefits:**
- Power savings: 21 hours/day offline (~87.5% reduction)
- Automated hands-free operation
- Perfect timing with Synology power schedule
- No manual intervention required

### Synology NAS Power Schedule

**Synology Schedule (configured via DSM Power Schedule):**
- **Power On:** 3:30 AM daily
- **Power Off:** 6:30 AM daily
- **HyperBackup:** 5:00 AM daily
- **Daily Runtime:** 3 hours

**Coordination with n6005:**
- n6005 powers on 30 minutes before Synology (allows PBS sync to complete)
- rsync completes by 4:30 AM, before HyperBackup starts at 5:00 AM
- No conflicts between rsync and HyperBackup operations

## Daily Backup Schedule

Complete automated backup timeline with zero manual intervention required.

### Full Daily Schedule (24-Hour View)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        DAILY BACKUP TIMELINE                               │
└────────────────────────────────────────────────────────────────────────────┘

TIME      INTEL-1250P              INTEL-N6005           SYNOLOGY NAS
────────  ───────────────────────  ────────────────────  ──────────────────────
02:00 AM  📦 Container Backups     [OFFLINE]             [OFFLINE]
          └─ LXC 1000-1003
          └─ To PBS .52

03:00 AM  💾 Media Backup          ⚡ POWER ON (RTC)     [OFFLINE]
          └─ /mnt/media (336GB)    └─ Boot sequence
          └─ To PBS .52

03:15 AM  [Running...]             🔄 PBS Sync Starts    [OFFLINE]
                                   └─ Pull from .52
                                   └─ Daily replication

03:30 AM  [Running...]             [Running...]          ⚡ POWER ON
                                                          └─ Boot sequence

04:00 AM  ✅ Backups Complete      [ONLINE]              🔄 Rsync Receiving
                                                          └─ PBS backup mirror

04:30 AM  [ONLINE]                 ✅ Rsync Complete     [Waiting...]

05:00 AM  [ONLINE]                 [ONLINE]              💾 HyperBackup Starts
                                                          └─ PBS data → Cloud
                                                          └─ Clean backup state

06:00 AM  [ONLINE]                 🔌 POWER OFF          [Running...]
                                   └─ Auto shutdown
                                   └─ RTC alarm set

06:30 AM  [ONLINE]                 [OFFLINE]             🔌 POWER OFF
                                                          └─ Auto shutdown

07:00 AM+ [ONLINE - 24/7]          [OFFLINE - 21hrs]     [OFFLINE - 21hrs]
          └─ Primary services      └─ Power saving       └─ Power saving
────────  ───────────────────────  ────────────────────  ──────────────────────
```

### Backup Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW & REPLICATION                        │
└─────────────────────────────────────────────────────────────────────────┘

STEP 1: Container Backups (02:00 AM)
┌──────────────┐
│ LXC 1000-1003│────┐
└──────────────┘    │ vzdump (snapshot mode)
                    ↓
                ┌────────────────────┐
                │ PBS .52 (1250p)    │
                │ Datastore: local   │
                └────────────────────┘

STEP 2: Media Backup (03:00 AM)
┌──────────────┐
│ /mnt/media   │────┐
│ (336GB ZFS)  │    │ proxmox-backup-client
└──────────────┘    ↓
                ┌────────────────────┐
                │ PBS .52 (1250p)    │
                │ + media.pxar       │
                └────────────────────┘

STEP 3: PBS Replication (03:15 AM - Daily)
┌────────────────────┐
│ PBS .52 (1250p)    │────┐
│ Datastore: local   │    │ PBS Sync (pull)
└────────────────────┘    │ Daily + remove-vanished
                          ↓
                    ┌────────────────────┐
                    │ PBS .70 (n6005)    │
                    │ Datastore:         │
                    │ backup-1250p       │
                    └────────────────────┘

STEP 4: Off-Site Mirror (Mondays 00:00 - Weekly)
┌────────────────────┐
│ PBS .70 (n6005)    │────┐
│ /mnt/backup-1250p  │    │ rsync -avz --delete
└────────────────────┘    │ Weekly mirror
                          ↓
                    ┌────────────────────────────────────┐
                    │ Synology NAS                       │
                    │ /volume1/backup-proxmox-backup-    │
                    │ server                             │
                    └────────────────────────────────────┘

STEP 5: Cloud Backup (05:00 AM - Daily)
┌────────────────────────────────────┐
│ Synology NAS                       │────┐
│ /volume1/backup-proxmox-backup-    │    │ HyperBackup
│ server                             │    │ Daily incremental
└────────────────────────────────────┘    ↓
                                    ┌────────────────────┐
                                    │ Cloud Storage      │
                                    │ (Configured in DSM)│
                                    └────────────────────┘

═══════════════════════════════════════════════════════════════════════
RESULT: 3-2-1 Backup Strategy
═══════════════════════════════════════════════════════════════════════
✓ 3 Copies:  1250p NVMe → n6005 RAID1 → Synology HDD → Cloud
✓ 2 Media:   NVMe (fast) + HDD (reliable) + Cloud (off-site)
✓ 1 Off-site: Synology (separate hardware) + Cloud (geographic)
```

### Boot-Time Backup Triggers

All backup timers include `OnBootSec` to run backups after system boot (power-saving friendly):

**intel-1250p Media Backup:**
- `OnBootSec=5min` - Runs 5 minutes after host boot
- Catches up if missed during scheduled time

**intel-n6005 Synology Sync:**
- `OnBootSec=10min` - Runs 10 minutes after host boot
- Ensures PBS sync completes first
- Syncs any missed weekly runs

**Persistent Timers:**
- All timers use `Persistent=true`
- Missed runs execute on next boot
- Ensures no backups are skipped

### Power Efficiency

**Daily Power Consumption:**
- intel-1250p: 24/7 operation (primary services)
- intel-n6005: 3 hours/day (87.5% power savings)
- Synology: 3 hours/day (87.5% power savings)

**Estimated Savings:**
- n6005: ~21 kWh/day saved (assuming 100W idle)
- Synology: ~18 kWh/day saved (assuming 85W idle)
- Combined: ~39 kWh/day, ~1,170 kWh/month
