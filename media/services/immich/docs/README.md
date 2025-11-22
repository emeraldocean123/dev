# Immich Dev Toolkit

Custom Immich scripts, documentation, and logs live outside the Docker stack
under `~/Documents/dev/applications/immich/`.

**Last Updated:** November 14, 2025

---

## Folder Structure

```text
~/Documents/dev/applications/immich/
├── scripts/          - Custom utility scripts for Immich management
│   └── archive/      - Deprecated/old script versions
├── docs/             - Documentation and guides
└── logs/             - Script execution logs and output files
```

---

## Active Scripts

**Location:** `~/Documents/dev/applications/immich/scripts/`

- **sanitize-xmp-simple.sh** - XMP sidecar sanitization (Immich-compatible metadata only)
  - Optimized single ExifTool command processing
  - Performance: 30+ files/sec (12x faster than original)
  - Creates `.xmp_backup` backups in `D:\Immich\backup\xmp\`

---

## Scripts (`~/Documents/dev/applications/immich/scripts/`)

### Immich Management
- **backup-immich.ps1** - Backup Immich Docker volumes and configuration
- **start-immich.ps1** - Start Immich Docker containers
- **stop-immich.ps1** - Stop Immich Docker containers
- **pause-immich-jobs.ps1** - Pause Immich background jobs
- **resume-immich-jobs.ps1** - Resume Immich background jobs
- **import-mylio-photos.ps1** - Import photos from Mylio to Immich
- **setup-rclone-backup.ps1** - Configure rclone backup for Immich

### Video Processing
- **find-rotated-videos.ps1** - Find videos with incorrect rotation metadata (PowerShell)
- **find-rotated-videos.sh** - Find videos with incorrect rotation metadata (Bash)
- **convert-hdr-to-sdr.ps1** - Detect HDR (BT.2020/PQ/HLG) videos in the library and generate SDR proxies via ffmpeg tone-mapping for manual upload
- **delete-rotated-video-transcodes.ps1** - Clean up incorrectly transcoded rotated videos

### Archive (`~/Documents/dev/applications/immich/scripts/archive/`)
Old XMP sanitization scripts (superseded by `sanitize-xmp-simple.sh`):
- sanitize-xmp-sidecars.ps1 (original)
- sanitize-xmp-sidecars-batch.ps1 (batch processing attempt)
- sanitize-xmp-sidecars-fast.ps1 (stay_open mode attempt - buggy)
- sanitize-xmp-sidecars-parallel.ps1 (PowerShell parallel attempt)
- sanitize-xmp-sidecars-ultra-fast.sh (early bash version)

**Note:** All archive scripts are obsolete. Use `sanitize-xmp-simple.sh` for XMP sanitization.

---

## Documentation (`~/Documents/dev/applications/immich/docs/`)

- **exiftool-optimization-guide.md** - Complete guide for optimizing ExifTool batch operations
  - Three optimization patterns (batch JSON read, recursive processing, argument files)
  - Performance benchmarks
  - Real-world examples
  - Optimization checklist

- **optimization-summary.md** - Summary of all ExifTool optimizations completed
  - Performance comparisons (before/after)
  - Scripts optimized
  - Key takeaways

- **nvenc-display-matrix-issue.md** - NVENC hardware transcoding display matrix bug
  - Issue: Rotated videos transcoded incorrectly
  - Workaround: Delete transcodes, force re-transcode with correct orientation

---

## Logs (`~/Documents/dev/applications/immich/logs/`)

Script execution logs and output files:

### Backup Logs
- `rclone-backup-YYYYMMDD-HHMMSS.log` - rclone backup execution logs

### Video Processing Logs
- `delete-rotated-transcodes.log` - Rotated transcode deletion logs
- `rotated-videos-YYYYMMDD-HHMMSS.txt` - List of videos with rotation issues
- `hdr-to-sdr-YYYYMMDD.log` (console output) - Review tone-mapping conversions when creation issues occur
- `scan-output.log` - Video scan output

## HDR → SDR Workflow

1. **Detect & Convert**
   ```powershell
   cd ~/Documents/dev/applications/immich/scripts
   ./convert-hdr-to-sdr.ps1 `
       -LibraryPath 'D:\Immich\library\library' `
       -OutputRoot 'D:\Immich\exports\hdr-to-sdr'
   ```
   - ffprobe locates HDR assets (BT.2020 primaries, PQ/HLG transfer metadata, etc.).
   - ffmpeg tone-maps to SDR (BT.709) and mirrors the folder tree under `D:\Immich\exports\hdr-to-sdr\...`.
   - File timestamps are copied so Immich’s storage template places SDR clips beside the source HDR asset.
2. **Manual Upload**
   - Copy the SDR files from `D:\Immich\exports\hdr-to-sdr\...` into the Immich uploads inbox.
   - Optional: append a suffix such as `-SDR` before the extension if you want to distinguish versions in the UI.
3. **Storage Template**
   - Run Immich’s “Scan for new assets”. The uploads folder is processed and the SDR clip lands in the same album as the HDR original.
   - Because metadata/timestamps were preserved, digiKam/Mylio can match keywords/rating once you run “Write metadata to files”.

### XMP Sanitization Logs
- `xmp-sanitization-*.log` - XMP sanitization execution logs
  - Multiple versions from different script iterations
  - Most recent: `xmp-sanitization-simple-*.log` (current optimized version)

---

## Immich Application Structure

**Main Immich folder:** `D:\Immich\`

### Immich Core Files/Folders
- `.env` - Immich environment configuration
- `docker-compose.yml` - Docker Compose configuration
- `hwaccel.ml.yml` - Machine learning hardware acceleration config
- `hwaccel.transcoding.yml` - Transcoding hardware acceleration config
- `library/` - Immich photo/video library storage
- `postgres/` - PostgreSQL database files

### Custom Additions
- `backup/` - **Backups and configuration**
  - `config/` - Configuration files (.immich-api-key, immich-config.json)
  - `xmp/` - XMP sidecar backups (.xmp_backup files)
- `~/Documents/dev/applications/immich/` - All custom scripts, docs, and logs

---

## Usage Notes

1. **All scripts** are now in `~/Documents/dev/applications/immich/scripts/` for centralized management
2. **Configuration files** (API keys, Immich config) are in `D:\Immich\backup\config\`
3. **XMP backups** are stored in `D:\Immich\backup\xmp\` (separate from library)
4. **Logs** are automatically created in `~/Documents/dev/applications/immich/logs/` by scripts
5. **Archive scripts** are kept for reference but should not be used

---

## Performance Achievements

**XMP Sanitization Optimization:**
- Original performance: 2.5 files/sec (8-10 hours for 78,123 files)
- Optimized performance: 30+ files/sec (~42 minutes for 78,123 files)
- **Speedup: 12x faster**

**Batch Rename Optimization:**
- Original performance: 3 files/sec
- Optimized performance: 18 files/sec
- **Speedup: 6x faster**

**Key Learning:** Minimize ExifTool process spawns. One process for entire operation is optimal.

---

## Related Documentation

See `~/Documents/dev/photos/` for additional photo management scripts and documentation:
- Mylio photo management scripts
- Video processing scripts (HDR to SDR conversion)
- Photo storage architecture documentation

