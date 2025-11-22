# Auto-Rotation Configuration - mpv.net vs XnView MP

**Date:** November 10, 2025
**Status:** Configured for both applications

## TL;DR - Which App to Use

| Image Type | Auto-Rotation Support | Recommended App | Notes |
|------------|----------------------|-----------------|-------|
| **HEIC/HEIF** | ✅ XnView MP | XnView MP | mpv.net cannot open HEIC at all |
| **JPG/JPEG** | ✅ XnView MP | XnView MP | XnView has EXIF auto-rotation |
| **PNG/WebP** | ⚠️ Neither | Either | No EXIF orientation in these formats |
| **Videos** | ✅ mpv.net | mpv.net | Auto-rotation from video metadata |

## Auto-Rotation: How It Works

### EXIF Orientation Tag

Digital cameras and phones often store images rotated incorrectly (e.g., portrait photos saved as landscape). Instead of rotating the actual pixels, they save a **rotation flag in EXIF metadata** that tells viewers how to display the image.

**EXIF Orientation values:**
- `1` = Normal (0° rotation)
- `3` = Upside down (180° rotation)
- `6` = Rotated 90° CW
- `8` = Rotated 90° CCW
- Plus mirror/flip values (2, 4, 5, 7)

**Example:**
- Your iPhone takes a portrait photo
- Image is saved as 4032×3024 (landscape dimensions)
- EXIF Orientation is set to `6` (rotate 90° CW)
- Viewer reads EXIF and displays it as 3024×4032 portrait

## XnView MP - EXIF Auto-Rotation

### ✅ Already Configured

XnView MP **already has auto-rotation enabled** by default. Your configuration shows:

```ini
[Load]
useEXIFRotation=true     # Automatically rotate images based on EXIF
```

### How to Verify

1. Open XnView MP
2. Go to **Tools > Settings** (or `Ctrl+K`)
3. Navigate to **Read/Write > Read**
4. Verify **"Use EXIF orientation"** is checked

### Additional Rotation Settings

Your XnView MP configuration also includes:

```ini
[Browser]
rotationKeepDate=true         # Preserve file timestamps when manually rotating
rotationChangeExif=false      # Don't modify EXIF when manually rotating (read-only)
rotationUseLossless=true      # Use lossless JPEG rotation (no quality loss)
```

**What this means:**
- Images display correctly rotated automatically
- If you manually rotate an image in XnView MP, it uses lossless JPEG rotation
- Original file timestamps are preserved
- EXIF data remains unchanged (read-only mode)

## mpv.net - Video Auto-Rotation (Images: Manual Only)

### ❌ No EXIF Auto-Rotation for Images

**Known limitation:** mpv and mpv.net **do NOT read EXIF orientation** from image files. This is an open issue in the mpv project (GitHub #5350).

**Impact:**
- Portrait photos from phones may display sideways
- You must manually rotate them using keybindings

### ✅ Video Auto-Rotation Configured

I've added this to your `mpv.conf`:

```ini
# Auto-rotate videos based on metadata (does NOT work for EXIF in images)
# Note: mpv does not read EXIF orientation from images - use XnView MP for images
video-rotate=0
```

**What this does:**
- Videos shot in portrait mode (phones/cameras) will auto-rotate correctly
- The `video-rotate=0` setting tells mpv to use rotation from video metadata
- This only works for **videos**, not images

### Manual Rotation Keybindings

I've added manual rotation controls to `input.conf`:

```ini
# Manual rotation controls (for images/videos)
r     cycle-values video-rotate "0" "90" "180" "270"  # Rotate clockwise
R     cycle-values video-rotate "0" "270" "180" "90"  # Rotate counter-clockwise
Alt+r set video-rotate 0                               # Reset rotation
```

**Usage:**
- Press `r` repeatedly to rotate clockwise (0° → 90° → 180° → 270° → 0°)
- Press `Shift+r` to rotate counter-clockwise
- Press `Alt+r` to reset to 0° rotation

**Note:** This rotation is **temporary** and only affects the current viewing session. It does not modify the file.

## Configuration Files Modified

### mpv.net Configuration

**mpv.conf location:** `~/AppData/Roaming/mpv.net/mpv.conf`

Added lines 78-80:
```ini
# Auto-rotate videos based on metadata (does NOT work for EXIF in images)
# Note: mpv does not read EXIF orientation from images - use XnView MP for images
video-rotate=0
```

**input.conf location:** `~/AppData/Roaming/mpv.net/input.conf`

Added lines 31-36:
```ini
# Manual rotation controls (for images/videos)
# Note: mpv does NOT auto-rotate images based on EXIF
# These allow manual rotation if image displays incorrectly
r     cycle-values video-rotate "0" "90" "180" "270"  # Rotate clockwise
R     cycle-values video-rotate "0" "270" "180" "90"  # Rotate counter-clockwise
Alt+r set video-rotate 0                               # Reset rotation
```

### XnView MP Configuration

**xnview.ini location:** `~/AppData/Roaming/XnViewMP/xnview.ini`

Existing configuration (no changes needed):
```ini
[Load]
useEXIFRotation=true

[Browser]
rotationKeepDate=true
rotationChangeExif=false
rotationUseLossless=true
```

## Recommended Workflow

### For HEIC Images (iPhone/Apple Photos)

**Use XnView MP exclusively:**
1. XnView MP can open HEIC files natively
2. Auto-rotation works perfectly
3. All EXIF data displayed correctly
4. No conversion needed

**Command:**
```powershell
& "C:\Program Files\XnViewMP\xnviewmp.exe" "D:\Mylio\path\to\photo.heic"
```

### For JPG Images

**Prefer XnView MP for auto-rotation:**
- XnView MP: ✅ Auto-rotates based on EXIF
- mpv.net: ❌ Displays raw pixels, may appear sideways

**If using mpv.net:**
- Press `r` to manually rotate clockwise
- Press `Shift+r` to rotate counter-clockwise
- Rotation is temporary (not saved to file)

### For Videos

**Use mpv.net:**
- ✅ Auto-rotation from video metadata works
- ✅ HDR tone mapping configured
- ✅ Better video playback performance

### For PNG/WebP/BMP

**Either app works:**
- These formats don't have EXIF orientation
- Images are stored with correct pixel orientation
- No rotation needed

## Testing Auto-Rotation

### Test XnView MP EXIF Rotation

1. Find a portrait photo from your phone (HEIC or JPG)
2. Open in XnView MP
3. Press `I` to view EXIF data
4. Look for "Orientation" field
5. Image should display correctly rotated

### Test mpv.net Manual Rotation

1. Open same portrait photo in mpv.net
2. If displayed sideways, press `r` to rotate
3. Press `r` multiple times to cycle through rotations
4. Press `Alt+r` to reset

## Permanently Fixing Rotation in Images

If you have many images with incorrect EXIF orientation and want to **permanently fix them**:

### Option 1: Lossless JPEG Rotation (XnView MP)

1. Open image in XnView MP
2. Press `Ctrl+J` (lossless rotation clockwise)
3. Or: `Ctrl+Shift+J` (lossless rotation counter-clockwise)
4. Save (XnView uses jpegtran for lossless rotation)

**Advantages:**
- No quality loss (lossless)
- Updates EXIF orientation to normal (1)
- Preserves all metadata

### Option 2: Batch Rotation (XnView MP)

1. Select multiple images in Browser mode
2. Right-click > **Batch Convert/Rename**
3. **Transformations** tab > Add "Rotate based on EXIF"
4. This physically rotates the pixels and sets EXIF to normal

### Option 3: ExifTool (Command Line)

```powershell
# Auto-rotate all JPG files in a folder based on EXIF orientation
exiftool -all= -tagsfromfile @ -all:all -unsafe -icc_profile -Orientation=1 -n "path\to\folder\*.jpg"
```

**Warning:** This modifies files. Always backup first!

## Summary Table

| Feature | mpv.net | XnView MP | Winner |
|---------|---------|-----------|--------|
| **HEIC Support** | ❌ No | ✅ Yes | XnView MP |
| **EXIF Auto-Rotation (Images)** | ❌ No | ✅ Yes | XnView MP |
| **Video Auto-Rotation** | ✅ Yes | ⚠️ Limited | mpv.net |
| **Manual Rotation Keybinds** | ✅ Yes (r/R) | ✅ Yes (L/R) | Tie |
| **HDR Video** | ✅ Yes | ❌ No | mpv.net |
| **Lossless JPEG Rotation** | ❌ No | ✅ Yes | XnView MP |
| **Batch Processing** | ❌ No | ✅ Yes | XnView MP |

## Final Recommendation

**Use the right tool for the job:**

1. **Photos from phone/camera (HEIC/JPG with EXIF):** XnView MP
   - Auto-rotation works perfectly
   - No manual adjustment needed
   - Can view HEIC files natively

2. **Videos:** mpv.net
   - Better video playback
   - HDR support
   - Auto-rotation from video metadata

3. **Web images (PNG/WebP/downloaded JPGs):** Either
   - No EXIF orientation issues
   - Both work equally well

## Related Files

- **mpv.net config:** `~/AppData/Roaming/mpv.net/mpv.conf`
- **mpv.net keybinds:** `~/AppData/Roaming/mpv.net/input.conf`
- **XnView MP config:** `~/AppData/Roaming/XnViewMP/xnview.ini`
- **XnView MP keybindings:** `~/Documents/dev/applications/media-players/xnview/xnview-mpv-keybindings.md`
- **mpv HDR config:** `~/Documents/dev/applications/media-players/mpv/mpv-hdr-configuration.md`
