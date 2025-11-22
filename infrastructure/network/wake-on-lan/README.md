# Wake-on-LAN

Wake-on-LAN scripts and documentation for remote server management.

## Purpose

Scripts and documentation for remotely waking servers in the homelab infrastructure using Wake-on-LAN (WOL) magic packets.

## Use Cases

- Waking Proxmox hosts for maintenance
- Waking NAS for backups
- Remote access to powered-down servers
- Integration with backup automation

## Configuration

Wake-on-LAN functionality is integrated with:
- ZFS replication scripts (using RTC alarm instead)
- Synology auto-backup (auto-detect instead of WOL)
- Manual server management

## Related Documentation

See also:
- `~/Documents/dev/backup/zfs-wol-replication.md` - ZFS replication with wake-on-lan
- `~/Documents/dev/sh/wake-servers.sh` - Server wake script
