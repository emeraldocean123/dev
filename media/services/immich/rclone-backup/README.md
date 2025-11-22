# Rclone Backup Configuration

Script for setting up automated Immich backups to cloud storage using rclone.

## Script

### setup-rclone-backup.ps1
Configures rclone for automated Immich backups to cloud storage (Google Drive, etc.).

**Usage:**
```powershell
.\setup-rclone-backup.ps1
```

Interactive script that:
1. Checks for rclone installation
2. Configures cloud storage remote (Google Drive, OneDrive, S3, etc.)
3. Sets up backup schedule
4. Tests backup configuration
5. Creates monitoring script

## What This Script Configures

- **Rclone remote:** Cloud storage destination for backups
- **Backup schedule:** Automated backup timing (default: weekly)
- **Retention policy:** How long to keep old backups
- **Bandwidth limits:** Optional upload speed throttling
- **Encryption:** Optional rclone crypt for secure cloud storage

## Requirements

- Rclone installed (script will check and offer to install)
- Cloud storage account (Google Drive, OneDrive, S3, etc.)
- Sufficient cloud storage space (~370GB for full Immich library)
- Internet connection for cloud uploads

## Recommended Setup

**For primary backups:**
- Use local Proxmox Backup Server (already configured)
- Use this for offsite/cloud backup tier

**Backup tiers:**
1. Local: Proxmox Backup Server (LXC 1002)
2. Offsite: ZFS replication to intel-n6005
3. Cloud: Rclone to Google Drive (this script)

## Cloud Storage Options

- **Google Drive:** 2TB with Google One, good integration
- **OneDrive:** Included with Microsoft 365
- **Backblaze B2:** Pay-per-GB, very affordable
- **AWS S3:** Enterprise option, glacier for long-term
- **Wasabi:** S3-compatible, flat pricing

## After Setup

- Test backup: `rclone sync /path/to/immich remote:immich-backup --dry-run`
- Monitor logs: `rclone ls remote:immich-backup`
- Verify integrity: `rclone check /path/to/immich remote:immich-backup`

## Related

- Primary backup: `../backup/` folder
- Immich control: `../control/` for starting/stopping before backup
