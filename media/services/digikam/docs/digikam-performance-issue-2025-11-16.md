# DigiKam Performance Issue Investigation

**Date:** November 16, 2025
**Issue:** Extreme slowness when scrolling through photos (10+ second pauses)
**Photo Library:** D:/Immich/library/library/admin/ (82,345 images)
**Database:** MariaDB 11.4 in Docker (localhost:3306)
**Status:** ⚠️ Investigating

## Problem Description

DigiKam exhibits unusable performance when scrolling through photo thumbnails, specifically in the 2024/12 folder. The application pauses for 10+ seconds between scroll actions, making it impossible to browse photos efficiently.

### Symptoms
- 10+ second freezes when scrolling
- No "Loading..." or status messages during freezes
- Issue persists after initial scan completion
- Performance does not improve over time

## Investigation Timeline

### Initial Diagnosis (Nov 16, 13:00)

**Database Performance Check:**
- MariaDB CPU: 1.36%
- MariaDB Memory: 735MB / 31GB (2.31%)
- Slow queries: 0
- Active connections: 9 (all idle/sleeping)
- **Conclusion:** Database is NOT the bottleneck

**Database Configuration:**
- InnoDB buffer pool: 2GB (properly sized)
- Max connections: 200
- All 4 databases exist and healthy:
  - digikam-core
  - digikam-faces (plural - was "digikam-face", fixed)
  - digikam-similarity
  - digikam-thumbs

### Configuration Fixes Applied

#### Fix #1: Database Name Mismatch (13:30)
**Issue:** Config referenced `digikam-face` (singular) but database was `digikam-faces` (plural)

**Fix:**
```bash
sed -i 's/^Database Name Face=digikam-face$/Database Name Face=digikam-faces/' digikamrc
```

**Result:** Database connection errors resolved, but scrolling still slow

#### Fix #2: Lazy Synchronization (13:45)
**Issue:** `Use Lazy Synchronization=false` caused DigiKam to sync all 82k images immediately

**Fix:**
```bash
sed -i 's/^Use Lazy Synchronization=false$/Use Lazy Synchronization=true/' digikamrc
```

**Expected:** Load images on-demand instead of synchronizing all at once
**Result:** No noticeable performance improvement

#### Fix #3: Disable ExifTool Metadata Reading (14:00)
**Issue:** DigiKam was calling ExifTool for EVERY image during scrolling

**Settings Before:**
```ini
Read Metadata From Files With ExifTool=true
Write Metadata To Files With ExifTool=true
Use Fast Scan At Startup=false
```

**Settings After:**
```ini
Read Metadata From Files With ExifTool=false
Write Metadata To Files With ExifTool=false
Use Fast Scan At Startup=true
Use Lazy Synchronization=true
```

**Expected:** Major performance improvement (ExifTool spawns process per image)
**Result:** No noticeable performance improvement

## Current Configuration

### Photo Storage
- **Location:** D:/Immich/library/library/admin/
- **Total Images:** 82,345
- **Drive Type:** NTFS (D: drive - likely HDD based on 7.28 TiB total)
- **Problem Folder:** 2024/12

### DigiKam Settings
```ini
[Database Settings]
Database Type=QMYSQL
Database Hostname=localhost
Database Port=3306
Database Username=digikam
Database Name=digikam-core
Database Name Face=digikam-faces
Database Name Similarity=digikam-similarity
Database Name Thumbnails=digikam-thumbs

[Metadata Settings]
Read Metadata From Files With ExifTool=false
Write Metadata To Files With ExifTool=false
Use Fast Scan At Startup=true
Use Lazy Synchronization=true
Rescan File If Modified=true

[Album Settings]
Default Icon Size=142
Thumbnail Size=60
Preview Load Full Image Size=false
```

### Thumbnail Cache
- **Location:** C:/Users/josep/AppData/Local/digikam/
- **Size:** 932 MB
- **Database:** MariaDB (digikam-thumbs database)

## Remaining Issues to Investigate

### Potential Bottlenecks

1. **Storage Performance**
   - D: drive appears to be HDD (7.28 TiB total, 3.41 TiB used)
   - Reading thumbnails from HDD could be slow
   - Need to verify: Is D: drive an HDD or SSD?

2. **Thumbnail Generation**
   - Thumbnail size: 60px (very small)
   - DigiKam may be regenerating thumbnails
   - Thumbnails stored in database, not local cache files

3. **Image File Size/Format**
   - Unknown: What format are the images? (JPEG, RAW, HEIC?)
   - Unknown: Average file size per image
   - Large RAW files could slow thumbnail loading

4. **Network Latency**
   - Photos in Immich library (typically accessed via network)
   - Need to verify: Is D:/Immich a local directory or network mount?

5. **Face Recognition / AI Features**
   - Face engine enabled: `enableFaceEngine=true`
   - Auto-tags enabled: `enableAutoTags=true`
   - Aesthetic detection enabled: `enableAesthetic=true`
   - These may run on-demand during scrolling

## Questions for User

1. **How many photos are in 2024/12 folder specifically?**
2. **Is D: drive an SSD or HDD?**
3. **What format are most photos? (JPEG, RAW, HEIC, etc.)**
4. **During the 10-second pause:**
   - Does DigiKam show any status message?
   - Does Task Manager show high CPU usage?
   - Do thumbnails eventually appear, or is it completely frozen?

## Next Steps

1. Count files in 2024/12 folder
2. Check D: drive type (SSD vs HDD)
3. Disable AI features (face detection, auto-tags, aesthetic) temporarily
4. Test thumbnail size increase (60px → 256px)
5. Monitor DigiKam process during scroll (CPU, disk I/O)
6. Consider moving thumbnail cache to SSD if D: is HDD

## Related Files

- DigiKam config: `C:/Users/josep/AppData/Local/digikamrc`
- DigiKam system: `C:/Users/josep/AppData/Local/digikam_systemrc`
- Thumbnail cache: `C:/Users/josep/AppData/Local/digikam/`
- Photo library: `D:/Immich/library/library/admin/`
- Docker Compose: `D:/Immich/docker-compose.yml`

## Timeline Summary

| Time  | Action | Result |
|-------|--------|--------|
| 13:30 | Fixed database name mismatch | ✅ Connection errors resolved |
| 13:45 | Enabled lazy synchronization | ❌ No performance improvement |
| 14:00 | Disabled ExifTool metadata reading | ❌ No performance improvement |
| 14:15 | Investigating storage/AI bottlenecks | 🔄 In progress |

## Conclusion

Despite fixing multiple configuration issues (database name, lazy sync, ExifTool), DigiKam performance remains unusably slow. The problem is NOT the database (MariaDB performing perfectly). The bottleneck is likely:

1. **Storage I/O:** HDD read speed for 82k images
2. **AI Processing:** Face detection, auto-tags running on-demand
3. **Thumbnail Storage:** Thumbnails in database instead of local files

Further investigation required to identify actual bottleneck.
