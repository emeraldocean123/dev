# Photo Utilities

Miscellaneous photo utilities for media organization and system management.

## Purpose

Lightweight PowerShell tools for media file organization and system utilities.

## Scripts

### organize-media.ps1
Unified media organizer that renames and organizes photos/videos with SHA256 hashing.
Matches the naming convention of `media-manager.py` for interoperability.

**Features:**
- SHA256-based file naming (compatible with media-manager.py)
- YYYY/MM folder organization
- Config-aware (reads from `.config/homelab.settings.json`)
- XMP sidecar preservation
- Safety modes (copy, dry-run)

**Usage:**
```powershell
# Rename in place
.\organize-media.ps1 C:\Photos

# Organize into YYYY/MM structure
.\organize-media.ps1 C:\Photos D:\Archive -Organize

# Preview changes
.\organize-media.ps1 C:\Photos -DryRun
```

### create-test-folder.ps1
Creates test folder structure for development and testing.

### restart-explorer.ps1
Restarts Windows Explorer process to resolve UI freezes.

## Location

**Path:** `media/tools/photo-utilities/`
**Category:** Media Tools

## See Also

- **media-manager.py** - Full-featured Python tool with deduplication
- **metadata-scrubber.py** - Remove metadata from media files
- **xmp-sidecar.py** - Extract metadata to XMP sidecar files
