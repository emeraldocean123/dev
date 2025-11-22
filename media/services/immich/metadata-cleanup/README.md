# Metadata Cleanup Tools

Scripts for cleaning and standardizing metadata in the Immich photo library.

## Scripts

### sanitize-xmp-simple.sh
Removes problematic XMP metadata that causes Immich issues.

**Usage:**
```bash
./sanitize-xmp-simple.sh <directory>
```

Scans XMP sidecar files and removes metadata tags known to cause problems with Immich indexing. Backs up original files before modification.

### remove-all-keywords.sh
Strips all keyword tags from photos and XMP files.

**Usage:**
```bash
./remove-all-keywords.sh <directory>
```

Removes all IPTC keywords, subject tags, and related metadata. Useful when keywords are corrupted or need to be rebuilt from scratch.

### fix-extension-errors.sh
Corrects file extension mismatches (e.g., .JPG vs .jpg).

**Usage:**
```bash
./fix-extension-errors.sh <directory>
```

Standardizes file extensions to lowercase and fixes cases where extension doesn't match actual file type. Prevents Immich from skipping files due to extension issues.

### standardize-filenames.sh
Applies consistent filename conventions across the library.

**Usage:**
```bash
./standardize-filenames.sh <directory>
```

Renames files to follow standard naming pattern: `YYYY-MM-DD_HHMMSS_description.ext`. Uses EXIF date for naming when available.

## Requirements

- ExifTool installed and accessible
- Bash environment (or Git Bash on Windows)
- Backup of photo library before running (these modify files)

## Safety

All scripts create backups before modifying files:
- XMP files: `.xmp.bak`
- Photos: Listed in rollback script
- Always test on a small subset first

## Workflow

1. **Before import:** Run metadata cleanup on source files
2. **Extension fixes:** Run `fix-extension-errors.sh` first
3. **Metadata cleanup:** Run `sanitize-xmp-simple.sh`
4. **Optional:** Remove keywords if corrupted
5. **Optional:** Standardize filenames for organization
6. **After cleanup:** Import to Immich

## Related

- See `../mylio-import/` for importing cleaned photos
- See `../orphaned-assets/` for cleanup after failed imports
