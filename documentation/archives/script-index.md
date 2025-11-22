# Dev Folder Script Index

Quick reference guide to all tool folders and their purposes. Every tool folder contains a detailed README.md.

**Last Updated:** November 18, 2025
**Total Tool Folders:** 37
**Total Scripts:** 129

---

## Applications (25 tool folders)

### DigiKam (4 folders)
- **database-backup** - DigiKam database backup and scheduling
- **exiftool-updater** - Updates ExifTool for DigiKam
- **scan-monitor** - Monitors DigiKam library scanning progress
- **google-photos-upload** - Uploads DigiKam photos to Google Photos

### Immich (7 folders)
- **control** - Start/stop/pause/resume Immich services
- **backup** - Backup and file management
- **video-rotation** - Find and fix rotated videos
- **orphaned-assets** - Find and delete orphaned files
- **metadata-cleanup** - Clean and standardize metadata
- **rclone-backup** - Cloud backup setup
- **mylio-import** - Import Mylio photos

### Media Players - MPV (3 folders)
- **mpv/heic-conversion** - HEIC to JPG conversion pipeline
- **mpv/mpv-setup** - MPV installation and configuration
- **mpv/hdr-testing** - HDR tone mapping tests

### Media Players - XnView (1 folder)
- **xnview/xnview-config** - XnViewMP configuration and testing

### Media Players - General (8 folders)
- **file-association-tools** - Windows file association management
- **codec-tools** - Video codec and thumbnail diagnostics
- **mylio-tools** - Mylio file extension tools
- **metadata-tools** - Metadata scanning and analysis
- **timestamp-sync** - File timestamp and EXIF synchronization
- **mylio-sync** - Mylio library synchronization
- **photo-verification** - Photo integrity verification
- **photo-utilities** - Miscellaneous photo utilities

### Utilities (2 folders)
- **package-managers** - Package manager health checks
- **cleanup-tools** - System cleanup utilities

---

## Hardware (7 tool folders)

- **caldigit-diagnostics** - CalDigit TS5+ dock diagnostics
- **network-priority** - Network adapter priority management
- **usb-diagnostics** - USB4 and PnP diagnostics
- **network-diagnostics** - Network adapter diagnostics
- **npcap-management** - Npcap packet capture management
- **alienfx-tools** - AlienFX lighting diagnostics
- **system-diagnostics** - General system diagnostics

---

## Network (2 tool folders)

- **scripts/ethernet-tools** - Ethernet diagnostics and fixes
- **scripts/wifi-management** - WiFi management tools

---

## Storage (2 tool folders)

- **drive-management/drive-letter-management** - Drive letter assignment tools
- **drive-management/drive-diagnostics** - Drive health and network drive tools

---

## Photos (4 tool folders)

- **exiftool-management** - ExifTool update utility
- **filename-tools** - Photo filename correction
- **scripts/digikam-tools/xmp-keyword-import** - XMP to DigiKam keyword importer
- **scripts/video-processing/xmp-consolidation** - XMP sidecar consolidation
- **scripts/video-processing/video-toolkit** - Video processing utilities

---

## Backup (3 tool folders)

- **rtc-wake** - RTC alarm management for automated backups
- **synology-tools** - Synology NAS configuration
- **wake-on-lan/wake-servers** - Wake-on-LAN for backup servers

---

## Shell Management (4 tool folders)

- **shell-backup** - Shell configuration backup/restore
- **path-auditing** - PATH environment variable auditor
- **wsl-management** - WSL disk management
- **path-management/path-cleanup** - PATH cleanup and optimization

---

## Documentation (2 tool folders)

- **scripts/dev-folder-audits** - Dev folder organization audits
- **scripts/lint-checker** - PowerShell script linter

---

## Folders NOT Reorganized (Preserved)

- **sh/** - Proxmox/LXC management scripts (already has README)
- **media-players/mylio-management/** - 70+ specialized Mylio scripts
- **archive/** folders - Historical data
- **configs/** folders - Configuration backups
- **vpn/** - Contains hamachi-nat.sh (router deployment script)

---

## Quick Navigation

### By Task

**Backup Management:**
- C:\Users\josep\Documents\dev\backup\rtc-wake
- C:\Users\josep\Documents\dev\backup\synology-tools
- C:\Users\josep\Documents\dev\backup\wake-on-lan\wake-servers
- C:\Users\josep\Documents\dev\applications\immich\backup

**Photo Management:**
- C:\Users\josep\Documents\dev\applications\immich\control
- C:\Users\josep\Documents\dev\applications\immich\mylio-import
- C:\Users\josep\Documents\dev\applications\digikam
- C:\Users\josep\Documents\dev\photos

**System Diagnostics:**
- C:\Users\josep\Documents\dev\hardware\caldigit-diagnostics
- C:\Users\josep\Documents\dev\hardware\network-priority
- C:\Users\josep\Documents\dev\hardware\system-diagnostics
- C:\Users\josep\Documents\dev\network\scripts\ethernet-tools

**Media Playback:**
- C:\Users\josep\Documents\dev\applications\media-players\mpv
- C:\Users\josep\Documents\dev\applications\media-players\xnview
- C:\Users\josep\Documents\dev\applications\media-players\codec-tools

**Shell & Environment:**
- C:\Users\josep\Documents\dev\shell-management\shell-backup
- C:\Users\josep\Documents\dev\shell-management\path-management\path-cleanup
- C:\Users\josep\Documents\dev\shell-management\wsl-management

---

## Usage

To use any tool:
1. Navigate to the tool folder
2. Read the README.md for details
3. Run the appropriate script

Example:
```powershell
cd ~/Documents/dev/applications/immich/control
cat README.md
./start-immich.ps1
```

---

## Documentation

- **Full reorganization details:** ~/Documents/dev/documentation/audits/script-reorganization-2025-11-18.md
- **Naming conventions:** All tool folders use kebab-case
- **Maximum depth:** 3 levels (dev > category > tool)
- **README format:** Every tool folder has comprehensive README.md

---

## Statistics

- **Tool Folders:** 37
- **README Files:** 67
- **Scripts by Category:**
  - Applications: 79 scripts
  - Hardware: 18 scripts
  - Network: 6 scripts
  - Storage: 4 scripts
  - Photos: 5 scripts
  - Backup: 5 scripts
  - Shell Management: 9 scripts
  - Documentation: 3 scripts

**Total Scripts Organized:** 129+
