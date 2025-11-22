# HEIC/HEIF Support in mpv.net

**Issue:** mpv.net cannot open HEIC (High Efficiency Image Container) files
**Status:** ⚠️ Workaround available
**Created:** November 9, 2025

## The Problem

HEIC files (Apple's image format) require:
1. libheif library for HEIF container support
2. HEVC/H.265 decoder for the image data

mpv.net's bundled `libmpv-2.dll` may not have been compiled with libheif support, meaning it can't decode HEIC files even though it can handle HEVC video.

## Configuration Applied

Added to `~/AppData/Roaming/mpv.net/mpv.conf`:

```ini
# Enable image demuxer for additional formats
demuxer-lavf-format=+heif,+heic,+avif
demuxer-lavf-o=format_whitelist=heif,heic,avif,jpg,jpeg,png,webp,bmp,gif

# Image file extensions to recognize
image-exts=jpg,jpeg,png,webp,bmp,gif,heic,heif,avif

# Use FFmpeg's image2 demuxer for image sequences
demuxer=lavf
```

## Testing

Try opening a HEIC file with mpv.net now:
```powershell
& "C:\Users\josep\AppData\Local\Programs\mpv.net\mpvnet.exe" "path\to\file.heic"
```

## Confirmed: mpv.net Cannot Open HEIC Files

Based on official mpv GitHub issue #6834 and **verified by testing** (November 10, 2025):

**mpv (and mpv.net) do not support HEIC/HEIF.** The maintainer stated "that's up to ffmpeg" and closed the issue. FFmpeg has HEIF *container* support but lacks the libheif *decoder* library.

**Tested:** Replaced mpv.net's libmpv-2.dll with latest shinchiro build (Nov 2025) - HEIC still doesn't work.

**Confirmed:** Even the latest mpv builds don't include libheif decoder due to licensing/build complexity.

**Bottom line:** mpv.net cannot and will not open HEIC files. Use VLC instead.

## Solution: Convert HEIC to JPEG

### Why Convert?

If you have many HEIC files you want to view in mpv.net, convert them.

**IMPORTANT:** ImageMagick alone does NOT preserve EXIF metadata (GPS, dates, camera info)!

**Proper conversion with metadata preservation:**

The script `convert-heic-to-jpg.ps1` handles this correctly:
1. Converts with ImageMagick (image quality)
2. Copies ALL metadata with ExifTool (GPS, EXIF, dates)
3. Preserves file timestamps

```powershell
# Use the conversion script (preserves ALL metadata)
cd ~/Documents/dev/applications/media-players/mpv
.\convert-heic-to-jpg.ps1

# Or for a specific folder:
.\convert-heic-to-jpg.ps1 -Path "D:\Mylio\Photos" -Recursive
```

**What gets preserved:**
- ✅ GPS coordinates (latitude/longitude)
- ✅ Camera make/model
- ✅ Date taken (original date)
- ✅ Exposure settings (ISO, aperture, shutter speed)
- ✅ File timestamps (creation, modification dates)
- ✅ All other EXIF tags

**Manual conversion (if needed):**
```powershell
# Install ImageMagick
winget install ImageMagick.ImageMagick

# Convert with metadata preservation (requires ExifTool in PATH)
magick convert input.heic output.jpg
exiftool -TagsFromFile input.heic -All:All -overwrite_original output.jpg
```

**Using Windows Photos:**
Windows 11 can convert HEIC, but this does NOT preserve GPS or all EXIF data:
1. Open HEIC in Windows Photos
2. Click "..." → "Save as"
3. Save as JPG
⚠️ Warning: This loses GPS coordinates and some metadata!

### Benefits of Converting to JPEG
- Modern JPEGs with quality 95+ are visually identical
- Better compatibility across all software
- Smaller file sizes (HEIC advantage is mostly for mobile devices)

**For batch conversion script:**
```powershell
# Convert all HEIC files in D:\Mylio to JPEG
Get-ChildItem -Path "D:\Mylio" -Recurse -Filter "*.heic" | ForEach-Object {
    $outputPath = $_.FullName -replace '\.heic$', '.jpg'
    if (-not (Test-Path $outputPath)) {
        Write-Host "Converting: $($_.Name)"
        magick convert $_.FullName -quality 95 $outputPath
    }
}
```

## Why HEIC Exists

HEIC (High Efficiency Image Format) is Apple's default format because:
- 50% smaller than JPEG at same quality
- Supports transparency (like PNG)
- Supports HDR
- Supports image sequences (live photos)

However, support outside Apple ecosystem is limited, which is why conversion is often the best solution.

## Windows HEIC Codec (Optional)

If you want HEIC support in Windows Photos and File Explorer:

1. Open Microsoft Store
2. Search for "HEIF Image Extensions"
3. Install (free)

**Note:** This doesn't help mpv.net (it needs libheif in FFmpeg), but enables system-wide HEIC viewing.

## Summary

**Current Status:**
- ✅ HDR videos work perfectly in mpv.net
- ❌ mpv.net cannot open HEIC (confirmed: libheif not available in any mpv build)
- ✅ Conversion script preserves all metadata (GPS, EXIF, timestamps)

**Recommended Solution:**
- Convert HEIC to JPEG using `convert-heic-to-jpg.ps1`
- All metadata preserved (GPS coordinates, camera info, dates)
- File timestamps preserved (creation/modification dates)
- Use mpv.net for all images and videos after conversion

## Related Files

- **MPV Config:** `~/AppData/Roaming/mpv.net/mpv.conf`
- **mpv.net Location:** `~/AppData/Local/Programs/mpv.net/`
- **HDR Guide:** `~/Documents/dev/applications/media-players/mpv/mpv-hdr-configuration.md`
