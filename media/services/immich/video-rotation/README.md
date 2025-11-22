# Video Rotation Management

Scripts for finding and managing rotated videos in the Immich library.

## Scripts

### find-rotated-videos.ps1 (PowerShell)
Scans the Immich library for videos with rotation metadata.

**Usage:**
```powershell
.\find-rotated-videos.ps1 [-Path <directory>]
```

Searches for videos that have rotation tags in their EXIF metadata. Creates a report of all rotated videos for review.

### find-rotated-videos.sh (Bash)
Shell script version of the rotated video finder.

**Usage:**
```bash
./find-rotated-videos.sh [directory]
```

Bash alternative that can run directly on the Immich LXC container for faster local scanning.

### delete-rotated-video-transcodes.ps1
Deletes Immich transcoded files for rotated videos.

**Usage:**
```powershell
.\delete-rotated-video-transcodes.ps1 [-VideoList <file>]
```

Removes transcoded versions of rotated videos, forcing Immich to regenerate them with correct orientation. Use after identifying rotated videos with the find scripts.

## Workflow

1. Run `find-rotated-videos.ps1` to identify problematic videos
2. Review the generated report
3. Run `delete-rotated-video-transcodes.ps1` to remove bad transcodes
4. Immich will automatically regenerate transcodes with correct rotation

## Requirements

- ExifTool installed and in PATH
- SSH access to Immich container for shell script version
- Write access to Immich transcoded-video directory

## Related

- Immich upload directory: `/mnt/immich/upload/` on LXC 1001
- Transcoded video directory: `/mnt/immich/upload/encoded-video/`
