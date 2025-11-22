# DigiKam Dev Toolkit

Utility scripts and documentation for DigiKam database management and photo sharing workflows live under ~/Documents/dev/applications/digikam/.

## Directory Structure

```text
~/Documents/dev/applications/digikam/
├── scripts/              # Utility scripts
│   ├── backup-database.sh
│   ├── backup-database-scheduled.bat
│   ├── monitor-scan.sh
│   ├── upload-to-google-photos.sh
│   └── setup-backup-schedule.ps1
├── docs/                 # Documentation
│   ├── SETUP-AUTOMATED-BACKUP.md
│   └── GOOGLE-PHOTOS-SETUP.md
└── logs/                 # Log files (created automatically)
```

---

## Scripts

### backup-database.sh

**Purpose:** Manual or scheduled database backup with automatic retention management

**Usage:**
```bash
cd /d/DigiKam
bash ~/Documents/dev/applications/digikam/scripts/backup-database.sh
```

**Features:**
- Creates compressed SQL dumps (`.sql.gz`)
- Saves to `D:\DigiKam\backups\`
- Keeps last 7 backups (auto-deletes older)
- Checks if MariaDB container is running
- Displays backup size and location

**Output:** `backups/digikam-backup-YYYYMMDD-HHMMSS.sql.gz`

---

### backup-database-scheduled.bat

**Purpose:** Windows wrapper for Task Scheduler integration

**Usage:**
```bash
cd /d/DigiKam
bash ~/Documents/dev/applications/digikam/scripts/backup-database-scheduled.bat
```

**Features:**
- Calls `backup-database.sh` via Git Bash
- Logs execution time to `backups/backup-schedule.log`
- Designed for Windows Task Scheduler

**Setup:** See `docs/SETUP-AUTOMATED-BACKUP.md`

---

### setup-backup-schedule.ps1

**Purpose:** Automated Windows Task Scheduler setup (PowerShell)

**Usage (requires admin):**
```powershell
cd D:\DigiKam
~/Documents/dev/applications/digikam/scripts\setup-backup-schedule.ps1
```

**Features:**
- Creates scheduled task: "DigiKam Database Backup"
- Schedule: Daily at 3:00 AM
- Removes existing task if present
- Configures task to run on battery/AC power
- Highest privileges execution

**Prerequisites:**
- PowerShell 5.0+
- Administrator privileges

---

### monitor-scan.sh

**Purpose:** Real-time monitoring of DigiKam's initial library scan

**Usage:**
```bash
cd /d/DigiKam
bash ~/Documents/dev/applications/digikam/scripts/monitor-scan.sh
```

**Features:**
- Updates every 5 seconds
- Shows: images scanned / total images / percentage
- Progress updates from MariaDB database
- Press `Ctrl+C` to exit

**Example output:**
```
DigiKam Scan Progress Monitor
==============================
Target: 82,345 total files

Images scanned: 12,500 / 82,345 (15.18%)
```

---

### upload-to-google-photos.sh

**Purpose:** Upload DigiKam exports to Google Photos for sharing

**Usage:**
```bash
cd /d/DigiKam
bash ~/Documents/dev/applications/digikam/scripts/upload-to-google-photos.sh <folder> [album-name]
```

**Examples:**
```bash
# Upload with custom album name
bash ~/Documents/dev/applications/digikam/scripts/upload-to-google-photos.sh /d/DigiKam/export "Family Vacation 2024"

# Upload with default album name
bash ~/Documents/dev/applications/digikam/scripts/upload-to-google-photos.sh /d/DigiKam/export
```

**Features:**
- Uploads photos and videos to Google Photos
- Creates albums automatically
- Shows progress and transfer speed
- Supports: JPG, JPEG, PNG, HEIC, MOV, MP4
- Skips XMP sidecar files

**Prerequisites:**
- rclone installed and configured
- Google Photos remote configured (`googlephotos:`)

**Setup:** See `docs/GOOGLE-PHOTOS-SETUP.md`

---

## Documentation

### SETUP-AUTOMATED-BACKUP.md

Complete guide for setting up automated nightly database backups:
- PowerShell setup (recommended)
- Manual Task Scheduler setup
- Testing the backup
- Verification steps
- Restore procedures
- Troubleshooting

**Location:** `~/Documents/dev/applications/digikam/docs/SETUP-AUTOMATED-BACKUP.md`

---

### GOOGLE-PHOTOS-SETUP.md

Complete workflow for sharing DigiKam photos via Google Photos:
- rclone Google Photos configuration
- DigiKam → Export → Google Photos workflow
- Common use cases (tags, ratings, events)
- Upload optimization tips
- Privacy and sharing settings
- Troubleshooting

**Location:** `~/Documents/dev/applications/digikam/docs/GOOGLE-PHOTOS-SETUP.md`

---

## Common Workflows

### Daily Backup (Automated)

**Setup once:**
```powershell
# Run as Administrator
cd D:\DigiKam
~/Documents/dev/applications/digikam/scripts\setup-backup-schedule.ps1
```

**Result:** Automatic backups every night at 3:00 AM

---

### Share Photos with Family

**Workflow:**
1. **In DigiKam:** Select photos → Export to local folder
2. **Upload:**
   ```bash
   bash ~/Documents/dev/applications/digikam/scripts/upload-to-google-photos.sh /d/DigiKam/export "Album Name"
   ```
3. **Share:** Open Google Photos → Find album → Click Share → Send link

---

### Monitor Initial Scan

**While DigiKam is scanning your library:**
```bash
bash ~/Documents/dev/applications/digikam/scripts/monitor-scan.sh
```

**Watch progress** until complete (~8 hours for 82,345 files)

---

### Manual Backup Before Major Changes

**Before major DigiKam operations:**
```bash
cd /d/DigiKam
bash ~/Documents/dev/applications/digikam/scripts/backup-database.sh
```

**Creates timestamped backup** for easy rollback if needed

---

## Backup Strategy

**Your complete backup strategy:**

1. **Local Backups (DigiKam MariaDB)**
   - Script: `backup-database.sh`
   - Location: `D:\DigiKam\backups\`
   - Retention: 7 days
   - Schedule: Daily at 3:00 AM

2. **Cloud Backup (Google Drive)**
   - Full library backup to `gdrive:` remote
   - Use existing Immich backup scripts
   - Backup entire `D:\Immich\library\` folder

3. **Sharing (Google Photos)**
   - Selected/curated photos only
   - Upload via `upload-to-google-photos.sh`
   - For sharing with family/friends

**Data Flow:**
```
DigiKam Database → Local Backups → Google Drive (full backup)
                                                    ↓
DigiKam Export → Google Photos (sharing only)
```

---

## Logs

### Backup Logs

**Location:** `D:\DigiKam\backups\backup-schedule.log`

**View recent backups:**
```bash
tail -20 /d/DigiKam/backups/backup-schedule.log
```

**Example:**
```
Backup completed at 11/16/2025 03:00:12
Backup completed at 11/17/2025 03:00:08
```

---

## Troubleshooting

### Backup Script Fails

**Check:**
1. MariaDB container is running: `docker ps | grep digikam`
2. Backups folder exists: `ls /d/DigiKam/backups`
3. Container logs: `docker logs digikam-mariadb`

### Upload to Google Photos Fails

**Common issues:**
1. **"googlephotos: not found"** → Run `rclone config` to set up Google Photos
2. **"Failed to create file system"** → Reconnect: `rclone config reconnect googlephotos:`
3. **Authentication expired** → Reconfigure: `rclone config` → edit `googlephotos` → re-authenticate

### Monitor Script Shows Wrong Count

**Cause:** Database query returns different count than DigiKam shows

**Fix:** DigiKam may be scanning videos or other file types not yet in Images table. Wait for scan to complete.

---

## Integration with Immich

**Your complete photo management ecosystem:**

```
┌─────────────────────────────────────────────────────────┐
│                    Photo Library                         │
│              D:\Immich\library\library\                  │
│                  (82,345 files)                          │
└──────────┬──────────────────────┬────────────────────────┘
           │                      │
           ↓                      ↓
    ┌─────────────┐        ┌─────────────┐
    │   DigiKam   │        │   Immich    │
    │  (Desktop)  │        │  (Web/App)  │
    └──────┬──────┘        └─────────────┘
           │
           ├─ Organize/tag/rate
           ├─ Face recognition
           ├─ Batch editing
           └─ Export selections
                     │
                     ↓
              ┌─────────────┐
              │   Export    │
              │   Folder    │
              └──────┬──────┘
                     │
          ┌──────────┴──────────┐
          ↓                     ↓
    ┌──────────┐         ┌──────────────┐
    │  Google  │         │ Google Drive │
    │  Photos  │         │ (Full Backup)│
    │(Sharing) │         │              │
    └──────────┘         └──────────────┘
```

**Storage layout**
- Active DigiKam SQLite files live under `D:\Immich\library\library\` (`digikam4.db`, `recognition.db`, `similarity.db`).
- Timestamped user backups live in `D:\Immich\backup\db\` (created automatically before imports or major changes).

**Key points:**
- ✅ DigiKam and Immich share the same library
- ✅ XMP sidecars keep metadata in sync
- ✅ Google Drive: Full backup (all files)
- ✅ Google Photos: Selective sharing only

---

## Requirements

**System:**
- Windows 11 (or Windows 10)
- Git Bash (for shell scripts)
- PowerShell 5.0+ (for automation)
- Docker Desktop (for MariaDB container)

**Tools:**
- DigiKam 8.x
- rclone (for Google Photos uploads)
- MariaDB 11.4 (via Docker)

**Disk Space:**
- DigiKam database: ~500MB - 2GB (grows with library size)
- Local backups: ~10-50MB (7 days × compressed SQL dumps)
- Export folder: Variable (temporary storage for sharing)

---

## Quick Reference

**Most Common Commands:**

```bash
# Start DigiKam MariaDB
cd /d/DigiKam && docker-compose up -d

# Backup database
bash ~/Documents/dev/applications/digikam/scripts/backup-database.sh

# Monitor scan
bash ~/Documents/dev/applications/digikam/scripts/monitor-scan.sh

# Upload to Google Photos
bash ~/Documents/dev/applications/digikam/scripts/upload-to-google-photos.sh /d/DigiKam/export "Album Name"

# Check container status
docker ps | grep digikam

# View logs
docker logs digikam-mariadb
```

---

For more information, see the main README: `D:\DigiKam\README.md`


