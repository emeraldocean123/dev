# Immich Backup Scripts

Scripts for backing up the Immich photo library and managing backup file naming.

## Scripts

### backup-immich.ps1
Creates a complete backup of Immich library to external storage.

**Usage:**
```powershell
.\backup-immich.ps1
```

Performs a full backup of the Immich photo library from LXC 1001 to external backup location. Includes database, uploads, and configuration.

### rename-backups-optimized.sh
Renames Immich backup files with standardized naming convention.

**Usage:**
```bash
./rename-backups-optimized.sh [backup-directory]
```

Processes backup files and applies consistent naming: `immich-backup-YYYY-MM-DD-HHMMSS.tar.gz`

### wait-and-rename-backups.sh
Waits for backup completion then automatically renames files.

**Usage:**
```bash
./wait-and-rename-backups.sh [backup-directory]
```

Monitors backup directory for new files, waits for writes to complete, then applies standardized naming. Useful for automated backup workflows.

## Requirements

- SSH access to Immich LXC container (192.168.1.51)
- Sufficient disk space for backup files (library is ~370GB)
- External backup storage mounted and accessible

## Backup Schedule

- Primary backup: Immich's built-in backup to `/mnt/backup/immich/`
- These scripts handle post-processing and external copying
- Coordinate with main Proxmox backup schedule (2:00 AM daily)

## Related

- Immich backup storage: `/mnt/backup/immich/` on LXC 1001
- External backup location: Configured in backup-immich.ps1
