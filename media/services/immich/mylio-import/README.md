# Mylio to Immich Import

Script for importing photos from Mylio library into Immich.

## Script

### import-mylio-photos.ps1
Imports curated photo collection from Mylio into Immich.

**Usage:**
```powershell
.\import-mylio-photos.ps1 [-Source <path>] [-Filter <pattern>]
```

**Parameters:**
- `-Source`: Mylio library path (default: configured in script)
- `-Filter`: Optional file pattern filter (e.g., "*.jpg", "2024-*")

## What This Script Does

1. **Pre-import cleanup:**
   - Runs metadata sanitization on source files
   - Fixes file extensions and EXIF data
   - Removes problematic XMP tags

2. **Import process:**
   - Copies files to Immich import directory
   - Preserves folder structure and metadata
   - Skips duplicates (checks hash)
   - Logs all operations

3. **Post-import:**
   - Triggers Immich library scan
   - Monitors import progress
   - Reports statistics

## Mylio to Immich Considerations

**What transfers:**
- Photos and videos
- EXIF metadata (dates, camera info, GPS)
- File organization/folder structure
- XMP sidecar files (cleaned)

**What doesn't transfer:**
- Mylio keywords (requires cleanup first)
- Mylio albums/collections (manual recreation)
- Mylio edits (export edited versions first)
- Mylio sync status and metadata

## Pre-Import Checklist

1. **Backup Mylio library** (in case of issues)
2. **Run metadata cleanup** scripts from `../metadata-cleanup/`
3. **Verify EXIF dates** are correct (Mylio sometimes corrupts)
4. **Clean keywords** if using Mylio smart tags
5. **Export edited versions** if you want Mylio edits preserved

## Requirements

- Mylio library accessible (local or network drive)
- SSH access to Immich LXC container
- Sufficient disk space on Immich (Mylio library size + 20%)
- ExifTool installed for metadata processing

## Workflow

```powershell
# 1. Clean metadata on Mylio exports
cd ..\metadata-cleanup
.\sanitize-xmp-simple.sh "D:\Mylio\Photos"

# 2. Return to import folder and run import
cd ..\mylio-import
.\import-mylio-photos.ps1 -Source "D:\Mylio\Photos"

# 3. Monitor Immich job queue
cd ..\control
.\pause-immich-jobs.ps1  # Pause if import is too intense
.\resume-immich-jobs.ps1 # Resume when ready
```

## Related

- Metadata cleanup: `../metadata-cleanup/`
- Immich control: `../control/` for managing jobs during import
- See `~/Documents/dev/photos/` for additional photo management tools
