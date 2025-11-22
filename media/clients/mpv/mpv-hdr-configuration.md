# MPV.NET HDR Configuration Guide

**Created:** November 9, 2025
**Issue:** HDR videos showing color distortion in mpv.net
**Status:** ✅ FIXED

## Problem

When playing HDR videos in mpv.net, colors appeared distorted/oversaturated because mpv.net wasn't properly tone-mapping HDR content to SDR displays.

## Solution

Updated `~/AppData/Roaming/mpv.net/mpv.conf` with proper HDR tone mapping and color management.

## Configuration Location

**File:** `C:\Users\josep\AppData\Roaming\mpv.net\mpv.conf`

## Key HDR Settings Explained

### Tone Mapping Algorithm

```ini
tone-mapping=hable
```

**Options:**
- `hable` - Filmic tone mapping (Uncharted 2 algorithm) - **RECOMMENDED**
  - Natural film-like appearance
  - Good detail preservation
  - Works well for most content

- `mobius` - Mobius tone mapping
  - Excellent for very bright scenes
  - Preserves fine detail in highlights
  - Try this if hable looks too dark

- `bt.2446a` - ITU-R BT.2446 Method A
  - Industry standard
  - Very accurate color reproduction
  - More clinical/accurate look

- `reinhard` - Reinhard tone mapping
  - Classic algorithm
  - Softer, more gentle look
  - Good for anime/animation

### HDR Metadata Processing

```ini
hdr-compute-peak=yes
hdr-peak-percentile=99.995
target-peak=auto
```

- Analyzes each video's HDR metadata dynamically
- Calculates peak brightness from top 99.995% of pixels
- Automatically adjusts tone mapping per-video

### Color Space Management

```ini
target-trc=auto
target-prim=auto
target-contrast=auto
gamut-mapping-mode=auto
```

- Automatically detects source and target color spaces
- Properly maps wide color gamut (BT.2020) to your display (BT.709)
- Prevents color clipping and oversaturation

## Hardware Acceleration

```ini
hwdec=auto-copy
vo=gpu-next
gpu-api=vulkan
gpu-context=winvk
```

- Uses NVIDIA RTX 5090 for GPU-accelerated decoding
- Vulkan API for best performance on Windows
- `gpu-next` is mpv's modern high-quality renderer

## Quality Enhancements

### Debanding
```ini
deband=yes
deband-iterations=4
deband-threshold=35
deband-range=16
deband-grain=48
```

Reduces color banding (common in HDR content due to compression).

### Scaling
```ini
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
dscale=mitchell
```

High-quality scaling algorithms for upscaling/downscaling.

## Testing HDR Videos

1. **Open an HDR video** with mpv.net
2. **Look for natural colors** - no oversaturation or weird tints
3. **Check bright scenes** - highlights should have detail, not blown out
4. **Check dark scenes** - shadows should have detail, not crushed

## Troubleshooting

### Colors Still Look Wrong

**Try different tone mapping:**
1. Open `mpv.conf`
2. Change `tone-mapping=hable` to:
   - `tone-mapping=mobius` (for brighter look)
   - `tone-mapping=bt.2446a` (for accurate look)
   - `tone-mapping=reinhard` (for softer look)
3. Restart mpv.net and test

### Video Stuttering/Performance Issues

If playback is stuttering with the new config:

1. **Disable interpolation:**
   ```ini
   #interpolation=yes  # Comment out this line
   ```

2. **Reduce deband quality:**
   ```ini
   deband-iterations=2  # Change from 4 to 2
   ```

3. **Use D3D11 instead of Vulkan:**
   ```ini
   gpu-api=d3d11  # Change from vulkan
   gpu-context=d3d11  # Change from winvk
   ```

### Comparing to VLC

**mpv.net advantages:**
- Better tone mapping algorithms
- More customizable
- Better quality scaling
- Lower resource usage

**VLC advantages:**
- Works out-of-box (no config needed)
- More format support
- Built-in subtitle styling

With this config, mpv.net should now match or exceed VLC's HDR playback quality.

## Configuration Backup

Original config backed up to: `mpv.conf.backup` (if you need to revert)

## Advanced: Per-Video Adjustments

**While playing a video, press these keys:**

- `9` / `0` - Decrease/increase contrast
- `Ctrl+1` / `Ctrl+2` - Cycle tone mapping algorithms
- `Ctrl+h` - Toggle HDR metadata display
- `i` - Show video codec info (check if HDR is detected)

## Test Videos

Good HDR test sources:
- Your converted HDR videos in `D:\Mylio`
- YouTube HDR content (if using yt-dlp)
- 4K HDR movie trailers

## Related Files

- **Config file:** `~/AppData/Roaming/mpv.net/mpv.conf`
- **Input bindings:** `~/AppData/Roaming/mpv.net/input.conf`
- **Installation script:** `~/Documents/dev/applications/media-players/mpv/install-mpv.ps1`

## References

- [mpv Manual - Tone Mapping](https://mpv.io/manual/master/#options-tone-mapping)
- [mpv Wiki - HDR](https://github.com/mpv-player/mpv/wiki/HDR)
- [GPU-Next Renderer](https://github.com/mpv-player/mpv/wiki/GPU-Next-vs-GPU)

## Changelog

**November 9, 2025:**
- Fixed HDR color distortion by adding tone mapping configuration
- Switched to `gpu-next` renderer with Vulkan
- Added HDR metadata processing
- Added color space management
- Enabled debanding for better quality
- Added high-quality scaling algorithms
