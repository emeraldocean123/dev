# NVENC Display Matrix Rotation Issue

**Date:** November 14, 2025
**Issue:** Black screen videos in Edge browser when using NVENC hardware transcoding
**Status:** Root cause identified, workaround implemented

## Summary

NVENC hardware encoding fails to properly handle iPhone videos that use Display Matrix rotation metadata, resulting in black screen playback in web browsers. Software encoding (libx264) correctly handles these videos by physically rotating the pixels during transcoding.

## Root Cause

### The Problem

iPhone records landscape videos using:
- **Pixel dimensions**: 1280×720 (landscape pixels)
- **Display Matrix rotation**: -90° (stored in video stream side_data)
- **Expected display**: Portrait (720×1280) after applying rotation

When NVENC transcodes these videos, it either strips or corrupts the Display Matrix metadata without physically rotating the pixels, resulting in videos that browsers cannot play correctly.

### Technical Details

**Display Matrix Metadata:**
- Stored in video stream `side_data` (not in tags)
- Contains rotation transformation matrix
- Common values: 90°, -90°, 180°
- Used by iPhone for landscape videos to avoid re-encoding

**Detection:**
```bash
# Check for Display Matrix rotation
ffprobe -v error -show_entries stream_side_data -of json video.mov

# Output shows:
{
  "side_data_type": "Display Matrix",
  "rotation": -90
}
```

## Affected Videos

### Videos that WORK with NVENC:
- Portrait videos (720×1280 pixels)
- No Display Matrix metadata
- Already in correct orientation

### Videos that FAIL with NVENC:
- Landscape videos (1280×720 pixels)
- Contains Display Matrix rotation (-90°)
- Common with iPhone landscape recordings

## Evidence

### Test Results (November 14, 2025)

**Good Video (NVENC worked):**
```
File: 2025-11-09-04-23-31-VIDEO-3eb54b89-8cf1-4925-98d0-9b8b677c40f9.mov
Dimensions: 720×1280 (portrait)
Display Matrix: NONE
NVENC Result: ✅ Works perfectly
```

**Bad Video #1 (NVENC failed):**
```
File: 2025-11-09-12-55-46-VIDEO-4c48e66a-b5a1-46cf-8f3d-1f75c6ef927f.mov
Dimensions: 1280×720 (landscape)
Display Matrix: rotation=-90
NVENC Result: ❌ Black screen in Edge browser
```

**Bad Video #2 (NVENC failed, software fixed):**
```
File: 2025-11-09-12-55-46-VIDEO-bac95182-dc5b-43a5-af34-7cf67aa7b90e.mov
Dimensions: 1280×720 (landscape)
Display Matrix: rotation=-90
NVENC Result: ❌ Black screen in Edge browser
Software Result: ✅ Works perfectly after re-transcode
```

## Solution

### Current Implementation

**Software Encoding (Recommended):**
- Disabled hardware transcoding in Immich settings
- All videos transcode with libx264 (software)
- Slower transcoding but 100% browser compatibility
- Properly handles Display Matrix by physically rotating pixels

### Workaround for Existing Bad Transcodes

1. Find video showing black screen in Edge browser
2. Click "Refresh Encoded Video" button (⟳ icon)
3. Wait for transcode to complete (~30-60 seconds)
4. Video plays immediately (no browser cache clearing needed)

### Alternative: Hybrid Approach

If faster transcoding is needed:
1. Enable NVENC hardware transcoding
2. Accept that landscape iPhone videos may show black screens
3. Fix problematic videos individually using refresh transcode
4. Most portrait videos will work correctly with NVENC

## Library Scan Results

**Scan Date:** November 14, 2025
**Total Videos Scanned:** 20,400+
**Videos with Display Matrix Rotation:** Unknown (scan script needs update)

**Note:** Initial scan only checked stream tags, not side_data. Script needs update to detect Display Matrix rotation metadata.

## Technical Comparison

### NVENC (Hardware Encoding)
- **Speed**: Very fast (GPU accelerated)
- **Display Matrix Handling**: ❌ Fails - strips/corrupts metadata
- **Pixel Rotation**: ❌ No - does not physically rotate pixels
- **Browser Compatibility**: ❌ Fails for videos with Display Matrix
- **Result**: Black screen or wrong orientation

### libx264 (Software Encoding)
- **Speed**: Slower (CPU only)
- **Display Matrix Handling**: ✅ Correct - reads and applies rotation
- **Pixel Rotation**: ✅ Yes - physically rotates pixels during encoding
- **Browser Compatibility**: ✅ Works for all videos
- **Result**: Proper orientation, no metadata needed

## Recommendations

### For New Installations
- Use **software encoding** (disable hardware transcoding)
- Ensures all videos play correctly in browsers
- Accept slower transcoding for reliability

### For Existing Installations
- Keep software encoding enabled
- Re-transcode any videos showing black screens
- No need to batch re-transcode entire library

### Future Considerations
- Monitor NVENC driver updates for Display Matrix support
- Consider hybrid approach if transcoding speed becomes critical
- Most portrait videos work fine with NVENC

## Related Files

- Test video script: `~/Documents/dev/applications/immich/scripts/find-rotated-videos.sh`
- Results log: `~/Documents/dev/applications/immich/logs/rotated-videos-YYYYMMDD-HHMMSS.txt`
- Scan output: `~/Documents/dev/applications/immich/logs/scan-output.log`
- HDR → SDR helper: `~/Documents/dev/applications/immich/scripts/convert-hdr-to-sdr.ps1` (writes SDR proxies to `D:\Immich\exports\hdr-to-sdr\...` so they can be uploaded and placed beside the HDR originals)

## References

**Camera Used:**
- Device: iPhone 17 Pro Max
- App: ProCamera 26.0.2
- Format: HEVC (H.265) in QuickTime container

**System Details:**
- Immich Version: Latest (as of Nov 2025)
- Docker Desktop: Windows
- GPU: NVIDIA GeForce RTX 5090 Laptop
- OS: Windows 11 Pro

## Known Issues & Community Reports

Our findings align with known issues in the FFmpeg and media server communities:

### Jellyfin Issue #6305 (2021)
**Title:** "Videos Recorded in Portrait Mode are Rotated -90 Degrees When Transcoded using (h264_nvenc)"
- **Platform:** Jellyfin Media Server
- **Issue:** Portrait mode videos display rotated when transcoded with NVENC
- **Root Cause:** NVENC encoder does not properly handle Display Matrix rotation metadata
- **Workaround:** Use software encoding (libx264) for videos with rotation metadata

**Key Quote:** "This issue is believed to be related to the 'displaymatrix: rotation of -90.00 degrees' parameter added to the end of the nvenc ffmpeg command."

### FFmpeg NVENC Rotation Limitations
**General Limitation:** FFmpeg cannot perform rotation when using a full NVENC pipeline because:
- NVENC works with GPU frames
- The `transpose` filter (used for rotation) operates on CPU frames
- Creating an incompatibility between filter formats

**Common Error:** When attempting hardware-accelerated rotation:
```
Impossible to convert between the formats supported by the filter 'transpose' and the filter 'auto_scaler_0'
```

### Documented Workarounds
1. **Disable Autorotation:** Use `-autorotate 0` to prevent FFmpeg from attempting rotation
   - **Limitation:** Video output will have wrong orientation
   - **Use Case:** When you'll manually correct orientation later

2. **Software Encoding:** Use libx264 instead of NVENC
   - **Benefit:** Properly handles Display Matrix and physically rotates pixels
   - **Trade-off:** Slower encoding, but 100% compatibility

3. **Manual Rotation with GPU:** Rotate video outside transcoding pipeline
   - **Complexity:** Requires multi-step process
   - **Benefit:** Can still use NVENC for final encode

### Status in 2025
As of November 2025, the NVENC Display Matrix rotation issue remains unresolved in:
- NVIDIA NVENC encoder
- FFmpeg NVENC integration
- Applications using FFmpeg with NVENC (Immich, Jellyfin, Plex, etc.)

**Recommendation:** Use software encoding for videos with rotation metadata until NVIDIA addresses this limitation in future driver or SDK updates.
