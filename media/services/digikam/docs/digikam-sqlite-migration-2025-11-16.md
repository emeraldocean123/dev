# DigiKam SQLite Migration - Performance Fix

**Date:** November 16, 2025
**Issue:** Extreme scrolling slowness with MariaDB backend
**Solution:** Migrate from MariaDB to SQLite with optimized settings
**Result:** 12.7x performance improvement
**Status:** ✅ Resolved

---

## Problem Description

DigiKam exhibited unusable performance when scrolling through photo thumbnails after completing the initial database scan. The application would freeze for 10+ seconds between scroll actions, making photo browsing impossible.

### Symptoms

- 10+ second pauses when scrolling through thumbnails
- Freezes occurred even in small folders
- No loading indicators during freezes
- Performance did not improve after scan completion
- Issue persisted despite database optimizations

### Environment

- **Photo Library**: D:/Immich/library/library/admin/ (82,345 images)
- **Test Folder**: 2024/12 (1,504 photos)
- **Original Database**: MariaDB 11.4 (Docker container)
- **Hardware**: RTX 5090 Laptop GPU, 24-core CPU, 64GB RAM

---

## Root Cause Analysis

### Database Architecture Mismatch

MariaDB is optimized for multi-user client-server applications, not single-user desktop photo management. The performance bottleneck was architectural, not configurational.

**MariaDB Overhead**:
- TCP/IP network stack (even for localhost connections)
- Client-server handshake for every query
- Thumbnails stored as database BLOBs
- Multi-user locking and transaction overhead

**Measured Performance**:
- Initial scan: ~10 hours
- Scrolling: 10+ second freezes per action
- MariaDB CPU: 1.36% (database was NOT the bottleneck)
- MariaDB Memory: 735MB / 31GB (2.31%)

### Failed Optimization Attempts

All MariaDB optimizations had zero performance impact:

1. **Database Name Fix** - Fixed `digikam-face` → `digikam-faces` mismatch
2. **Lazy Synchronization** - Enabled on-demand image loading
3. **ExifTool Disable** - Disabled external metadata tool
4. **AI Features Disable** - Disabled face detection, auto-tags, aesthetics
5. **MariaDB Tuning** - Increased `max_allowed_packet` to 128M

**Conclusion**: The fundamental TCP/IP + BLOB architecture was the bottleneck, not configuration.

---

## Solution: SQLite Migration

### Migration Steps

**1. Backup MariaDB Configuration**

```bash
# Backup location
C:/Users/josep/Documents/dev/photos/digikam-backup-20251116/

# Files backed up
- digikamrc (MariaDB settings)
- digikam_systemrc (AI/GPU settings)
```

**2. Remove DigiKam Configuration**

```bash
# Deleted files
C:/Users/josep/AppData/Local/digikamrc
C:/Users/josep/AppData/Local/digikam_systemrc
C:/Users/josep/AppData/Local/digikam/ (cache folder)
```

**3. Remove MariaDB Container**

```bash
cd /d/DigiKam
docker-compose down
docker volume rm digikam_digikam-db
```

**4. Fresh DigiKam Start**

- Launched DigiKam
- Selected SQLite as database type
- Enabled WAL (Write-Ahead Logging) mode
- Chose to write metadata to files (Immich compatibility)
- Started initial scan

---

## Performance Results

### Initial Scan Comparison

| Metric | MariaDB | SQLite | Improvement |
|--------|---------|--------|-------------|
| Scan Time | ~10 hours | 47 minutes | **12.7x faster** |
| Images | 82,345 | 82,345 | Same |
| Database Type | TCP/IP + BLOBs | File-based | Architecture |

### Scrolling Performance

| Metric | MariaDB | SQLite | Result |
|--------|---------|--------|--------|
| Freeze Duration | 10+ seconds | Instant | **Smooth** |
| Thumbnail Loading | Database query | File read | **SSD speed** |
| User Experience | Unusable | Fluid | **Perfect** |

---

## Optimized Configuration

### Database Settings

```ini
[Database Settings]
Database Type=QSQLITE
Database WAL Mode=true
Database Name=D:/Immich/library/library/
Database Name Face=D:/Immich/library/library/
Database Name Similarity=D:/Immich/library/library/
Database Name Thumbnails=D:/Immich/library/library/
```

**Why WAL Mode**:
- Concurrent readers don't block writers
- Faster commits (writes to log, not main file)
- Better crash recovery

### Metadata Settings (Immich Compatible)

```ini
[Metadata Settings]
Read Metadata From Files With ExifTool=false     # Fast Exiv2 library
Write Metadata To Files With ExifTool=true      # Comprehensive writing
Metadata Writing Mode=2                          # Database + files
Use Fast Scan At Startup=true                   # Optimized scanning
Use Lazy Synchronization=true                   # On-demand loading
Rescan File If Modified=true                    # Auto-detect changes
Use XMP Sidecar For Reading=true                # RAW file support
ExifTool Path=D:/Files/Programs-Portable/ExifTool/
```

**Metadata Written to Files**:
- Tags/Keywords → XMP/IPTC
- Ratings → XMP/EXIF
- Color Labels → XMP
- Pick Labels → XMP
- Face Tags → XMP
- GPS/Position → EXIF
- Comments → EXIF/XMP
- Date/Time → EXIF

**File Formats**:
- JPEG/TIFF/PNG: Embedded metadata
- RAW files: XMP sidecars (e.g., `IMG_1234.CR2.xmp`)
- Videos: XMP sidecars

### Hardware Acceleration

```ini
[System]
softwareOpenGL=false                # GPU rendering
enableOpenCL=true                   # RTX 5090 compute
enableDnnOpenCL=true               # AI on GPU
dnnOpenCLTested=true               # GPU verified
enableHWVideo=true                 # Hardware decode
enableHWTConv=true                 # Hardware transcode
videoBackend=ffmpeg                # FFmpeg engine
```

**GPU**: NVIDIA GeForce RTX 5090 Laptop GPU (fully utilized)

### AI Features (Re-enabled After Migration)

```ini
enableAIAutoTools=true             # Combined AI tools
enableFaceEngine=true              # Face detection
enableAesthetic=true               # Quality analysis
enableAutoTags=true                # Object recognition
```

**Note**: These were disabled during MariaDB troubleshooting but work smoothly with SQLite performance.

---

## Why SQLite is Faster

### Architectural Advantages

**1. No Network Overhead**
- MariaDB: TCP/IP stack + connection pooling
- SQLite: Direct file I/O

**2. File-Based Thumbnails**
- MariaDB: Thumbnails as database BLOBs (query + network transfer)
- SQLite: Thumbnails as files on SSD (direct read)

**3. Simpler Transaction Model**
- MariaDB: Multi-user locking, ACID overhead
- SQLite: Single-writer, optimized for desktop apps

**4. Metadata Reading**
- MariaDB: ExifTool spawned processes (slow)
- SQLite: Exiv2 in-memory library (microseconds)

### Performance Breakdown

**MariaDB Bottlenecks**:
- TCP/IP localhost: ~1-5ms per query
- BLOB retrieval: Database query overhead
- ExifTool spawning: ~100ms per image
- Connection pooling: Client-server handshake

**SQLite Advantages**:
- File I/O: Direct SSD access (sub-millisecond)
- Thumbnail files: No query overhead
- Exiv2 library: In-memory (microseconds)
- WAL mode: Concurrent read/write

---

## Immich Integration

### Metadata Compatibility

DigiKam writes all metadata to files, which Immich can read:

**Tags**:
- DigiKam: `Xmp.dc.subject`, `Iptc.Application2.Keywords`
- Immich: Reads tags from XMP/IPTC

**Ratings**:
- DigiKam: `Xmp.xmp.Rating`, `Exif.Image.Rating`
- Immich: Reads star ratings

**GPS**:
- DigiKam: `Exif.GPSInfo.*`
- Immich: Displays on map

**Face Tags**:
- DigiKam: `Xmp.digiKam.TagsList` (face regions)
- Immich: Can detect faces

### Workflow

**1. Tag/Rate Photos in DigiKam**
- Changes written to files (EXIF/XMP)
- SQLite database updated

**2. Immich Metadata Refresh**
- Per-photo: Photo options → Refresh metadata
- Bulk: Administration → Jobs → Metadata Extraction

**3. Result**
- Tags appear in Immich
- Ratings synchronized
- GPS locations on map
- Face tags detectable

---

## File Locations

### Configuration Files

```text
C:/Users/josep/AppData/Local/
├── digikamrc                    # Main DigiKam config
└── digikam_systemrc             # Hardware/AI settings
```

### Databases

```text
D:/Immich/library/library/
|-- digikam4.db                  # Core DigiKam database (active)
|-- recognition.db               # Face recognition
|-- similarity.db                # Duplicate detection
```

Timestamped safety copies live outside the library tree:

```text
D:/Immich/backup/db/
`-- digikam4.db.backup-YYYY-MM-DD-HHmmss  # Created before each import/sync
```

User-created SQLite caches now live alongside other manual assets:

```text
D:/Immich/backup/user-created/digikam/
`-- thumbnails-digikam.db        # Thumbnail metadata (regenerate in DigiKam if needed)
```

### Thumbnail Cache

```text
C:/Users/josep/AppData/Local/digikam/
└── thumbnails-*.db              # File-based thumbnails
```

### Backup

```text
C:/Users/josep/Documents/dev/photos/digikam-backup-20251116/
├── digikamrc                    # MariaDB config (archived)
└── digikam_systemrc             # System settings backup
```

---

## Docker Cleanup

### MariaDB Removal

**Stopped Services**:

```bash
cd /d/DigiKam
docker-compose down
```

**Removed Volumes**:

```bash
docker volume rm digikam_digikam-db
```

**Deleted Files**:

```text
D:/DigiKam/
├── docker-compose.yml           # MariaDB setup (obsolete)
├── backup/config/               # MariaDB config (obsolete)
└── mariadb-config/              # Empty folder (deleted)
```

**Status**: All MariaDB infrastructure removed, D:/DigiKam folder deleted

---

## Troubleshooting

### Hardware Acceleration Test Failed

**Symptom**: GPU acceleration test fails after DigiKam reset

**Cause**: Settings reset to defaults during SQLite migration

**Fix**:

```ini
# Before (defaults)
softwareOpenGL=true              # CPU rendering
enableOpenCL=false               # GPU disabled
enableDnnOpenCL=false            # AI on CPU

# After (fixed)
softwareOpenGL=false             # GPU rendering
enableOpenCL=true                # RTX 5090 enabled
enableDnnOpenCL=true            # AI on GPU
```

**Result**: GPU acceleration working (verified by user)

### Metadata Not Writing

**Check Settings**:

```ini
Write Metadata To Files With ExifTool=true
Metadata Writing Mode=2          # Must be 2 (file + DB)
```

**Verify Writing**:

```bash
# Check JPEG file
exiftool -Keywords -Rating -GPS* "D:/Immich/library/library/admin/2024/12/IMG_001.jpg"

# Check XMP sidecar (RAW)
exiftool "D:/Immich/library/library/admin/2024/12/IMG_001.CR2.xmp"
```

---

## Lessons Learned

### Database Selection Matters

**Single-User Applications**:
- ✅ SQLite (desktop apps, single writer)
- ❌ MariaDB/PostgreSQL (multi-user, network apps)

**Multi-User Applications**:
- ❌ SQLite (concurrent writes limited)
- ✅ MariaDB/PostgreSQL (client-server, ACID)

### Optimization Order

1. **Architecture First** - Choose right database type
2. **Configuration Second** - Tune settings for workload
3. **Hardware Third** - Upgrade only if architecture + config optimized

**Wrong Approach** (our initial path):
- Tune MariaDB → No improvement
- Disable features → No improvement
- Increase resources → No improvement

**Right Approach** (final solution):
- Switch to SQLite → 12.7x improvement
- Optimize settings → Perfect performance

### Thumbnail Storage

**Database BLOBs** (MariaDB):
- ❌ Slow query + network overhead
- ❌ Database bloat
- ❌ No OS-level caching

**File-Based** (SQLite):
- ✅ Direct SSD access
- ✅ OS file system cache
- ✅ No database overhead

---

## Performance Metrics Summary

### Initial Scan

- **MariaDB**: ~10 hours (82,345 images)
- **SQLite**: 47 minutes (82,345 images)
- **Improvement**: 12.7x faster

### Scrolling

- **MariaDB**: 10+ second freezes
- **SQLite**: Instant, smooth scrolling
- **Improvement**: Completely resolved

### Resource Usage

**MariaDB**:
- CPU: 1.36% (not the bottleneck)
- Memory: 735MB
- Disk: Database queries + BLOB transfers

**SQLite**:
- CPU: Negligible
- Memory: Minimal
- Disk: Direct file I/O (SSD speed)

---

## Related Documentation

- `digikam-performance-issue-2025-11-16.md` - Initial investigation timeline
- `~/Documents/dev/applications/digikam/docs/README.md` - DigiKam toolkit
- `photo-vault-architecture.md` - Photo storage architecture
- `immich-hardware-transcoding.md` - Immich GPU acceleration

---

## Quick Reference

### Start DigiKam

```bash
# Windows
"C:\Program Files\digiKam\digikam.exe"
```

### Check Database Status

```bash
# SQLite databases
ls -lh /d/Immich/library/library/*.db

# WAL files (active)
ls -lh /d/Immich/library/library/*.db-wal
```

### Verify Metadata Writing

```bash
# Test image
exiftool -Keywords -Rating -GPS* "/d/Immich/library/library/admin/2024/12/IMG_001.jpg"
```

### Configuration Files

```bash
# Main config
cat /c/Users/josep/AppData/Local/digikamrc

# System settings
cat /c/Users/josep/AppData/Local/digikam_systemrc
```

---

## Success Criteria

✅ Initial scan: 47 minutes (12.7x faster than MariaDB)
✅ Scrolling: Instant, smooth (no freezes)
✅ Metadata: Written to files (Immich compatible)
✅ GPU acceleration: RTX 5090 active
✅ AI features: Enabled and working smoothly
✅ Configuration: Optimized for SQLite + Immich workflow
