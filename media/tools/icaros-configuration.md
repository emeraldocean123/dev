# Icaros Shell Extensions Configuration

**Date**: November 10, 2025
**Version**: Icaros 3.3.3
**Purpose**: Enable Windows Explorer thumbnails and metadata for video, audio, and image files

## Problem Solved

### Original Issue
- iPhone Camera .mov files showed no thumbnails in Windows Explorer
- Properties > Details tab showed no video metadata (length, bitrate, dimensions)
- Affected 5,958 files in Mylio photo library
- HEIC photos also lacked thumbnails despite Windows HEIF extension being installed

### Root Cause
Windows native shell extensions couldn't parse:
- iPhone Camera MOV files (H.264 codec in QuickTime container)
- Some HEIC image files (despite HEIF Image Extension being installed)
- Various other video and audio formats

### Solution
Installed **Icaros Shell Extensions 3.3.3** - FFmpeg-based thumbnail and property handlers for Windows Explorer

## Installation

### Method 1: WinGet (Recommended)
```powershell
winget install --id Xanashi.Icaros
```

### Method 2: Direct Download
1. Download from: https://github.com/Xanashi/Icaros/releases
2. Run installer as administrator
3. Launch IcarosConfig to configure

## Configuration

### Thumbnail Extensions (Complete List)

**Current Configuration**:
```
3g2;3gp;ape;avi;bmp;cb7;cbr;cbz;divx;epub;flac;flv;gif;heic;jpeg;jpg;m2ts;m4v;mk3d;mka;mkv;mov;mp4;mpc;mpg;myb;ofr;ofs;ogg;ogm;ogv;opus;png;psd;qt;rm;rmvb;spx;tak;tta;wav;webm;webp;wmv;wv;xvid
```

**Breakdown by Category**:

**Video Formats**:
- `3g2, 3gp` - 3GPP mobile video
- `avi` - AVI video
- `divx` - DivX video
- `flv` - Flash video
- `m2ts` - MPEG-2 Transport Stream (Blu-ray)
- `m4v` - iTunes/Apple video
- `mk3d` - Matroska 3D video
- `mkv` - Matroska video
- `mov` - QuickTime/iPhone video (PRIMARY FIX)
- `mp4` - MPEG-4 video
- `mpg` - MPEG video
- `ogm, ogv` - Ogg video
- `qt` - QuickTime video
- `rm, rmvb` - RealMedia video
- `webm` - WebM video
- `wmv` - Windows Media Video
- `xvid` - Xvid video

**Image Formats**:
- `bmp` - Bitmap images
- `gif` - GIF images
- `heic` - HEIF/iPhone photos (SECONDARY FIX)
- `jpeg, jpg` - JPEG images
- `png` - PNG images
- `psd` - Photoshop documents
- `webp` - WebP images

**Audio Formats**:
- `ape` - Monkey's Audio
- `flac` - FLAC lossless
- `mka` - Matroska audio
- `mpc` - Musepack
- `ogg` - Ogg Vorbis
- `ofr, ofs` - OptimFROG
- `opus` - Opus audio
- `spx` - Speex audio
- `tak` - TAK lossless
- `tta` - True Audio
- `wav` - WAV audio
- `wv` - WavPack

**Archive/Document Formats**:
- `cb7, cbr, cbz` - Comic book archives
- `epub` - E-books

**Mylio-Specific**:
- `myb` - Mylio burst photos

### Settings Applied

**Filetypes Tab**:
- ✅ Thumbnailed - Enabled
- ✅ Properties - Enabled (adds metadata to Details tab)
- ✅ Cache (static) - Enabled (caches thumbnails for performance)

**Thumbnail Settings**:
- ✅ Enable white/black frame detection - Enabled (prevents black thumbnails)
- ⬜ Embedded cover art for thumbnails - Disabled (we want actual video frames)

## Results

**Working Features**:
- ✅ Thumbnails display in Windows Explorer for all video files
- ✅ Thumbnails display for HEIC photos
- ✅ Properties > Details shows video metadata:
  - Video Length
  - Bit rate
  - Frame dimensions (when available)
- ✅ No file modification needed
- ✅ All EXIF data preserved (GPS, timestamps, camera info)
- ✅ No Mylio database corruption
- ✅ Systemwide solution for all users

**Files Affected**:
- 5,958 iPhone Camera .mov files - now have thumbnails and metadata
- All HEIC photos - now have thumbnails
- All other video/audio/image formats - enhanced support

## Maintenance

### Updating Thumbnail Extensions

If you need to add new file types:

1. Open IcarosConfig as administrator:
   ```powershell
   Start-Process -FilePath "C:\Program Files\Icaros\IcarosConfig.exe" -Verb RunAs
   ```

2. Go to Filetypes tab

3. Add new extensions to the semicolon-separated list:
   ```
   existing;extensions;newext1;newext2
   ```

4. Click Apply

5. Restart Windows Explorer:
   ```powershell
   Stop-Process -Name explorer -Force; Start-Process explorer.exe
   ```

### Clearing Thumbnail Cache

If thumbnails don't regenerate after changes:

```powershell
Stop-Process -Name explorer -Force
Remove-Item -Path $env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db -Force
Start-Process explorer.exe
```

Or run the provided script:
```powershell
.\restart-explorer.ps1
```

## Utility Scripts

**Location**: `~/Documents/dev/applications/media-players/`

**Available Scripts**:
- `test-icaros-installation.ps1` - Test if Icaros is working correctly
- `get-mylio-extensions.ps1` - List all file extensions in Mylio folder
- `restart-explorer.ps1` - Restart Explorer and clear thumbnail cache
- `diagnose-thumbnails.ps1` - Original diagnostic script (reference)
- `fix-mylio-extensions.ps1` - Fix uppercase extensions to lowercase

## Troubleshooting

### Thumbnails Not Appearing

1. Check if Icaros is installed:
   ```powershell
   Test-Path "C:\Program Files\Icaros\*"
   ```

2. Verify file extension is in thumbnail list:
   ```powershell
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Icaros').'Thumbnail Extensions'
   ```

3. Clear thumbnail cache and restart Explorer (see Maintenance above)

4. Run test script:
   ```powershell
   .\test-icaros-installation.ps1
   ```

### Metadata Not Showing in Details Tab

1. Verify Properties handler is enabled in IcarosConfig
2. Restart Explorer
3. Check specific file with test script

### Performance Issues

If thumbnail generation is slow:

1. Ensure "Cache (static)" is enabled in IcarosConfig
2. Check cache location: `C:\Program Files\Icaros\IcarosCache\`
3. Consider reducing number of thumbnail extensions if not all are needed

## References

- **Icaros GitHub**: https://github.com/Xanashi/Icaros
- **FFmpeg Documentation**: https://ffmpeg.org/documentation.html
- **Installation Date**: November 10, 2025
- **Configuration Date**: November 10, 2025
- **Last Tested**: November 10, 2025

## Notes

- Icaros uses FFmpeg to decode video/audio/image files
- No modifications made to original files
- All metadata preserved (GPS, EXIF, timestamps)
- Safe to use with Mylio photo library
- Works with all Windows versions (Windows 7+)
- Compatible with Windows 11 Pro 25H2
