# ZFS Replication with RTC Wake

**Date:** October 13, 2025
**Status:** Active - Automatic power management configured with RTC wake

## Overview

The ZFS replication script uses **Real-Time Clock (RTC) wake** for the N6005 backup server. This allows N6005 to stay powered off when not needed, saving energy while maintaining reliable automatic backup replication.

## How It Works

1. **N6005 wakes automatically** via RTC alarm at 2:50 AM (BIOS-level)
2. **intel-1250p runs replication** at 3:00 AM via cron (gives N6005 10 min boot time)
3. **Performs ZFS replication**: Incremental backup transfer
4. **Auto-shutdown with next RTC alarm**: N6005 shuts down and sets next wake for 2:50 AM tomorrow
5. **Self-perpetuating cycle**: Wake → Replicate → Sleep → Wake (automatic)

## Configuration

### Script Location
- **Source**: `C:/Users/josep/Documents/dev/sh/zfs-replicate-pbs.sh`
- **Deployed**: `/root/sh/zfs-replicate-pbs.sh` on intel-1250p

### Power Management Settings

```bash
AUTO_SHUTDOWN=true       # Set to false to keep N6005 running
SHUTDOWN_GRACE_TIME=30   # Seconds before shutdown with RTC alarm
```

### Network Configuration

```bash
TARGET_HOST="root@192.168.1.41"
TARGET_IP="192.168.1.41"
TARGET_DATASET="rpool/intel-1250p-proxmox-backup-server"
```

## Usage

### Automatic Usage (Scheduled via Cron)

The script runs automatically at **3:00 AM daily** via cron. N6005 wakes via RTC at 2:50 AM.

**Scheduled cron job:**
```bash
# /etc/cron.d/zfs-pbs-replication on intel-1250p
0 3 * * * root /root/sh/zfs-replicate-pbs.sh >/var/log/zfs-pbs-replication.log 2>&1
```

### Manual Usage

```bash
ssh intel-1250p
/root/sh/zfs-replicate-pbs.sh
```

**Behavior:**
- Expects N6005 to be online (woken by RTC or manually started)
- Performs replication
- Shuts down N6005 with RTC wake alarm set for 2:50 AM next day

### Keep N6005 Running After Replication

Edit the script on intel-1250p:

```bash
ssh intel-1250p
nano /root/sh/zfs-replicate-pbs.sh
# Change: AUTO_SHUTDOWN=false
```

Or run manually without shutdown:

```bash
ssh intel-1250p
AUTO_SHUTDOWN=false /root/sh/zfs-replicate-pbs.sh
```

### Change Replication Schedule

Edit cron file on intel-1250p:

```bash
ssh intel-1250p
nano /etc/cron.d/zfs-pbs-replication

# Example: Change to weekly on Sunday at 3 AM
0 3 * * 0 root /root/sh/zfs-replicate-pbs.sh >/var/log/zfs-pbs-replication.log 2>&1
```

**Important:** If changing schedule, also update RTC wake time in `/root/sh/shutdown-with-rtc-wake.sh` on N6005

## Power Savings

### Estimated Energy Consumption

**N6005 Power Usage:**
- Idle: ~10-15W
- Active (replication): ~20-25W
- Off: <2W

**Typical Replication Time:** 30-60 seconds (incremental)

**Daily Power Savings (assuming daily replication):**
- **Always On**: 10W × 24h = 240 Wh/day (0.24 kWh)
- **WoL Mode**: 2W × 24h + 20W × 0.02h = 48.4 Wh/day (0.048 kWh)
- **Savings**: ~192 Wh/day (0.192 kWh) = **~70 kWh/year**

At $0.15/kWh: **~$10.50/year savings**

## RTC Wake Requirements

### Hardware Requirements
- ✅ N6005 supports RTC wake (hardware clock can trigger power-on)
- ✅ BIOS configured to allow RTC wake
- ✅ Power supply must remain connected (provides standby power)

### Software Requirements (Already Installed)
- ✅ `rtcwake` utility installed on N6005 (part of util-linux)
- ✅ RTC shutdown script: `/root/sh/shutdown-with-rtc-wake.sh` on N6005
- ✅ SSH key authentication configured

### BIOS Requirements (Usually Enabled by Default)

RTC wake is typically enabled by default. If it doesn't work:
1. Boot into BIOS (usually F2 or DEL during startup)
2. Look for: **Advanced > Power Management** or **APM Configuration**
3. Enable: **RTC Alarm Power On** or **Resume by Alarm**
4. Save and reboot

### Testing RTC Wake

Test with short interval (5 minutes):
```bash
ssh intel-n6005
# Set alarm for 5 minutes from now
sudo rtcwake -m off -s 300
# System will power off and wake in 5 minutes
```

## Script Output Examples

### Successful Replication with RTC Shutdown

```
[INFO] Checking N6005 status...
[INFO] N6005 is online
[INFO] Starting PBS datastore replication...
[INFO] Source: rpool/intel-1250p-proxmox-backup-server (intel-1250p)
[INFO] Target: rpool/intel-1250p-proxmox-backup-server (intel-n6005)
[INFO] Creating snapshot: rpool/intel-1250p-proxmox-backup-server@pbs-repl-20251013-030000
[INFO] Performing incremental send from rpool/intel-1250p-proxmox-backup-server@pbs-repl-20251013-020000
[INFO] Incremental size: 1.2M
[INFO] Sending incremental changes...
[INFO] Incremental send completed successfully
[INFO] Cleaning up old snapshots (keeping last 7)...
[INFO] Verifying replication...
[INFO] Source size: 374G
[INFO] Target size: 374G
[INFO] Total replication snapshots: 7
[INFO] PBS datastore replication completed successfully!
[INFO] Latest snapshot: pbs-repl-20251013-030000
[POWER] Auto-shutdown enabled, scheduling RTC wake and shutting down N6005
[POWER] Waiting 30s before shutdown...
[POWER] Setting RTC alarm for 2:50 AM and shutting down N6005...
[POWER] RTC shutdown script executed successfully
```

### Manual Run (No Auto-Shutdown)

If `AUTO_SHUTDOWN=false`:
```
[INFO] Checking N6005 status...
[INFO] N6005 is online
[INFO] Starting PBS datastore replication...
...
[INFO] PBS datastore replication completed successfully!
[INFO] Auto-shutdown disabled, leaving N6005 running
```

## Troubleshooting

### N6005 Doesn't Wake via RTC

1. **Check RTC alarm status:**
   ```bash
   ssh intel-n6005 "cat /proc/driver/rtc"
   # Look for alarm_IRQ and alrm_pending
   ```

2. **Test RTC wake manually:**
   ```bash
   ssh intel-n6005 "sudo rtcwake -m no -s 120"  # Set alarm for 2 min
   ssh intel-n6005 "sudo shutdown -h now"        # Shutdown manually
   # Wait 2 minutes - system should wake automatically
   ```

3. **Check BIOS settings** for RTC wake (see above)

4. **Verify power supply** is plugged in (RTC wake requires standby power)

### Script Fails with "N6005 is not online"

This means N6005 didn't wake via RTC at 2:50 AM:
- Check RTC alarm was set: `ssh intel-n6005 "rtcwake -m show"`
- Verify BIOS RTC wake is enabled
- Check cron log: `ssh intel-1250p "tail /var/log/zfs-pbs-replication.log"`
- Manually start N6005 and check if replication works

### RTC Shutdown Script Fails

- Verify script exists: `ssh intel-n6005 "ls -lh /root/sh/shutdown-with-rtc-wake.sh"`
- Check script is executable: `ssh intel-n6005 "chmod +x /root/sh/shutdown-with-rtc-wake.sh"`
- Test manually: `ssh intel-n6005 "/root/sh/shutdown-with-rtc-wake.sh"`
- Verify SSH key authentication works without password

### Check RTC Shutdown Script

```bash
ssh intel-n6005 "cat /root/sh/shutdown-with-rtc-wake.sh"
```

The script should calculate next 2:50 AM and set RTC alarm.

## Manual Commands

### Check if N6005 is Online

```bash
ping -c 1 192.168.1.41 && echo "Online" || echo "Offline"
```

### Check RTC Status

```bash
ssh intel-n6005 "rtcwake -m show"
ssh intel-n6005 "cat /proc/driver/rtc"
```

### Manually Trigger RTC Shutdown

```bash
ssh intel-n6005 "/root/sh/shutdown-with-rtc-wake.sh"
```

### Clear RTC Alarm

```bash
ssh intel-n6005 "sudo rtcwake -m disable"
```

## Integration with Scheduled Backups

### Current Schedule (Implemented)

**Timeline:**
1. **2:00 AM** - PBS backs up all LXC containers on intel-1250p
2. **2:50 AM** - N6005 wakes via RTC alarm (BIOS-level)
3. **3:00 AM** - ZFS replication runs (cron on intel-1250p)
4. **~3:05 AM** - Replication completes, N6005 shuts down with next RTC alarm set

**Cron Configuration:**
```bash
# /etc/cron.d/zfs-pbs-replication on intel-1250p
0 3 * * * root /root/sh/zfs-replicate-pbs.sh >/var/log/zfs-pbs-replication.log 2>&1
```

**RTC Wake Configuration:**
```bash
# /root/sh/shutdown-with-rtc-wake.sh on intel-n6005
# Calculates next 2:50 AM and sets RTC alarm before shutdown
```

This ensures fresh PBS backups are replicated to N6005 for off-host redundancy.

## Security Considerations

### RTC Wake Security
- **BIOS-level**: RTC wake is hardware-based, no network exposure
- **Physical access required**: Only someone with physical access to N6005 can interfere
- **More secure than WoL**: No network packets, no broadcast vulnerabilities
- **Deterministic**: Wakes at exact scheduled time, predictable behavior

### SSH Security
- N6005 requires SSH key authentication (no password login)
- Auto-shutdown ensures N6005 isn't left running unnecessarily
- Network is behind router firewall
- ZFS replication uses encrypted SSH tunnel

### Physical Security
- Ensure N6005 is in secure location (server room/rack)
- RTC wake requires BIOS access to disable
- Power supply should be on UPS for reliability

## References

- **Replication Script**: `/root/sh/zfs-replicate-pbs.sh` (intel-1250p)
- **RTC Shutdown Script**: `/root/sh/shutdown-with-rtc-wake.sh` (N6005)
- **Cron Schedule**: `/etc/cron.d/zfs-pbs-replication` (intel-1250p)
- **Replication Log**: `/var/log/zfs-pbs-replication.log` (intel-1250p)
- **Network Documentation**: `network-devices.md`
- **PBS Documentation**: `pbs-backup-config.md`
- **iSCSI Investigation**: `iscsi-analysis.md`

## Summary

RTC wake enables **automatic power management** for N6005:
- ✅ Save ~70 kWh/year (~$10.50 in electricity costs)
- ✅ Reduce wear on hardware (powered off 23+ hours/day)
- ✅ **BIOS-level reliability** - more reliable than Wake-on-LAN
- ✅ No network dependency - works even if network is down during wake
- ✅ Self-perpetuating cycle - automatic wake/replicate/sleep
- ✅ Deterministic schedule - wakes at exact time every day
- ✅ Still maintains regular backup replication schedule

**Implemented Schedule:**
- **2:00 AM** - PBS backup
- **2:50 AM** - N6005 RTC wake
- **3:00 AM** - ZFS replication
- **~3:05 AM** - N6005 shutdown with next RTC alarm set
