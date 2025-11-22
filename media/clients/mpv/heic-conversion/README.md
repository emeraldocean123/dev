# HEIC Conversion

HEIC to JPG conversion pipeline with sequential and parallel processing options.

## Purpose

Complete workflow for converting HEIC photos to JPG for better compatibility.

## Scripts

### Sequential Processing
- **find-and-stage-heic-files.ps1** - Find and stage HEIC files for conversion
- **convert-staged-heic-files.ps1** - Convert staged files sequentially
- **convert-heic-to-jpg.ps1** - Direct conversion (one file at a time)
- **cleanup-heic-staging.ps1** - Clean up staging area
- **get-staging-stats.ps1** - View staging statistics
- **verify-heic-conversion.ps1** - Verify conversion results

### Parallel Processing (Optimized)
- **convert-heic-to-jpg-parallel.ps1** - **NEW** - Multi-threaded conversion using PowerShell 7
  - **Performance**: 5-10x faster than sequential version
  - **Requirements**: PowerShell 7+, ImageMagick, ExifTool
  - **Features**: Concurrent processing, metadata preservation, progress tracking

## Usage

### Sequential Workflow
```powershell
1. .\find-and-stage-heic-files.ps1
2. .\convert-staged-heic-files.ps1
3. .\verify-heic-conversion.ps1
4. .\cleanup-heic-staging.ps1
```

### Parallel Conversion (Recommended)
```powershell
# Convert all HEIC files in directory (using 8 threads)
.\convert-heic-to-jpg-parallel.ps1 -Path "D:\Photos" -Recursive

# High-performance conversion with 16 threads
.\convert-heic-to-jpg-parallel.ps1 -Path "D:\Photos" -Threads 16 -Quality 95

# Convert and delete originals
.\convert-heic-to-jpg-parallel.ps1 -Path "D:\Photos" -Recursive -DeleteOriginal
```

## Performance Comparison

**Sequential** (convert-heic-to-jpg.ps1):
- 100 files: ~5-10 minutes
- 1000 files: ~50-100 minutes

**Parallel** (convert-heic-to-jpg-parallel.ps1):
- 100 files: ~1-2 minutes (8 threads)
- 1000 files: ~10-15 minutes (8 threads)

## Requirements

- **ImageMagick**: Image conversion engine
- **ExifTool**: Metadata preservation (optional but recommended)
- **PowerShell 7+**: Required for parallel version only

## Location

**Path:** `~/Documents/dev/applications/media-players/mpv/heic-conversion`
**Category:** `mpv`
