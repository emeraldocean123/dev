# Backup Infrastructure

Documentation and automation scripts for the 3-tier backup system.

## Architecture

**Layer 1: Primary Backup (On-Host)**
- Proxmox Backup Server (PBS) on intel-1250p
- Daily backups at 2:00 AM

**Layer 2: Off-Host Replication (RTC Automated)**
- ZFS replication to intel-n6005
- RTC wake at 2:50 AM, auto-shutdown after completion

**Layer 3: Tertiary Backup (Auto on Power-On)**
- Synology DS1520+ NAS
- Rsync via NFS, auto-shutdown when complete

## Key Files

- **backup-infrastructure-overview.md** - Complete 3-tier architecture
- **pbs-backup-config.md** - Proxmox Backup Server configuration
- **synology-auto-backup.md** - Synology automation details
- **zfs-wol-replication.md** - ZFS replication with wake-on-lan
- **services/** - Systemd service files for backup automation
- **wake-on-lan/** - Wake-on-LAN documentation and scripts (moved from root)

## Purpose

Comprehensive backup infrastructure documentation and automation scripts ensuring data redundancy across three independent layers.

## Related Documentation

- Backup scripts: See `../sh/` for synology-auto-backup.sh, zfs-replicate-pbs.sh
- Network infrastructure: See `../network/network-devices.md` for server details
