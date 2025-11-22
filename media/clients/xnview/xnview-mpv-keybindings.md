# XnView MP Keybindings - MPV.NET Style

**Date:** November 10, 2025
**Purpose:** Configure XnView MP to use similar keybindings as mpv.net for consistent image navigation

## Why XnView MP for HEIC?

- XnView MP has built-in HEIC/HEIF support (with Windows HEIF codec installed)
- Viewing HEIC directly saves disk space (~50% smaller than JPG)
- Can browse Mylio library without converting files
- Full EXIF metadata support

## Installation

1. Install XnView MP (already installed: `C:\Program Files\XnViewMP`)
2. Install HEIF Image Extensions from Microsoft Store (required for HEIC support)

## Current Keybindings Comparison

### mpv.net → XnView MP Mapping

| Action | mpv.net | XnView MP Default | Match? | Notes |
|--------|---------|-------------------|--------|-------|
| **Image Navigation** |
| Next image | `RIGHT` | `RIGHT` | ✅ | Already matches |
| Previous image | `LEFT` | `LEFT` | ✅ | Already matches |
| Jump forward 10 | `PGDN` | Not mapped | ⚠️ | Can browse with grid |
| Jump back 10 | `PGUP` | Not mapped | ⚠️ | Can browse with grid |
| First image | `HOME` | `HOME` | ✅ | Already matches |
| Last image | `END` | `END` | ✅ | Already matches |
| **Playback Control** |
| Pause/Play | `SPACE` | `SPACE` (slideshow) | ✅ | Starts/stops slideshow |
| **View Controls** |
| Zoom in | Mouse wheel up | Mouse wheel up | ✅ | Already matches |
| Zoom out | Mouse wheel down | Mouse wheel down | ✅ | Already matches |
| Best fit | N/A | `*` or `F` | N/A | XnView specific |
| 100% zoom | N/A | `Ctrl+0` | N/A | XnView specific |
| Fullscreen | N/A | `F11` | N/A | Windows standard |

## Configuration Status

### ✅ Already Configured (No Changes Needed)

XnView MP's **default shortcuts already match mpv.net** for the most important actions:

- `LEFT` / `RIGHT` - Previous/Next image (same as mpv.net)
- `SPACE` - Start/Stop slideshow (equivalent to mpv.net's pause/play)
- `HOME` / `END` - First/Last image (same as mpv.net)
- Mouse wheel - Zoom in/out (same as mpv.net)

### ⚠️ Minor Differences

**Page Up/Down:**
- mpv.net: Jump 10 images forward/back
- XnView MP: Not mapped by default (use thumbnail grid instead)

**Solution:** XnView MP uses Browser mode with thumbnail grid for bulk navigation, which is actually more efficient than jumping 10 items.

### 🔧 Optional Customizations

If you want to customize keyboard shortcuts:

1. Open XnView MP
2. Go to **Tools > Settings** (or press `Ctrl+K`)
3. Navigate to **Interface > Keyboard**
4. Customize shortcuts as needed
5. Click **Save** to create a custom `.keys` file

## XnView MP-Specific Features

### Viewer Mode Additional Shortcuts

| Key | Action | Notes |
|-----|--------|-------|
| `F` | Fit to window | Useful for large images |
| `1` | 100% zoom | View actual size |
| `+` / `-` | Zoom in/out | Alternative to mouse wheel |
| `F11` | Toggle fullscreen | Windows standard |
| `I` | Show EXIF info | View metadata |
| `H` | Show histogram | Photo analysis |
| `Del` | Delete file | Move to recycle bin |
| `Ctrl+C` | Copy file | File management |

### Browser Mode Shortcuts

| Key | Action | Notes |
|-----|--------|-------|
| `Up` / `Down` | Navigate thumbnail grid | Vertical navigation |
| `Enter` | Open in viewer | From grid |
| `Backspace` | Go up one folder | Folder navigation |
| `Ctrl+F` | Search | Find files |

## Recommended Settings

### For HEIC Viewing Workflow

1. **Tools > Settings > File List**
   - Enable "Show hidden files" if needed
   - Set thumbnail size to 128x96 or larger

2. **Tools > Settings > Viewer**
   - Enable "Loop when reaching last file" for continuous browsing
   - Enable "Use EXIF rotation" to auto-rotate images
   - Set "Mouse wheel" to Zoom (default)
   - Set "Left/Right arrow keys" to Previous/Next image (default)

3. **Tools > Settings > Metadata**
   - Enable "Read EXIF data" for proper metadata display
   - Enable "Use EXIF date for file timestamp" if desired

## HEIC Support Verification

### Test HEIC File Opening

Try opening a HEIC file from Mylio:

```powershell
& "C:\Program Files\XnViewMP\xnviewmp.exe" "D:\Mylio\path\to\file.heic"
```

**Expected results:**
- Image opens immediately
- EXIF data visible (press `I`)
- GPS coordinates shown (if present)
- Can navigate with LEFT/RIGHT arrows
- Original file timestamps preserved

### Troubleshooting HEIC

If HEIC files won't open:

1. **Install HEIF Image Extensions:**
   - Open Microsoft Store
   - Search "HEIF Image Extensions"
   - Install (free from Microsoft)

2. **Verify XnView MP version:**
   - Help > About XnView MP
   - Should be version 1.0 or newer for HEIC support

3. **Check file association:**
   - Right-click HEIC file
   - Open With > Choose another app
   - Select XnView MP
   - Enable "Always use this app"

## Workflow with Mylio

### Option 1: Browse HEIC Files Directly

**Advantages:**
- No conversion needed
- Save disk space (HEIC is ~50% smaller)
- Full metadata preserved
- Faster workflow (no import/export)

**How to:**
1. Open XnView MP
2. Navigate to `D:\Mylio` in Browser mode
3. Browse thumbnails or open individual images
4. Use LEFT/RIGHT arrows to navigate
5. Files remain in Mylio untouched

### Option 2: Convert HEIC to JPG (Already Done)

**Advantages:**
- Universal compatibility
- Can use any image viewer (including mpv.net)
- Slightly faster loading (no codec overhead)

**Disadvantages:**
- 2x disk space usage
- Extra import step into Mylio

**Status:**
- ✅ Already converted 4,617 HEIC files to JPG
- ✅ All metadata preserved
- ✅ Staging folder: `C:\Users\josep\Documents\heic-staging`

### Recommendation

**Use XnView MP for browsing HEIC files directly** - this is the most efficient workflow:

- No conversion needed
- No duplicate storage
- Same keybindings as mpv.net
- Full metadata support
- Can still use mpv.net for JPG/PNG/other formats

## File Association

### Set XnView MP as Default for HEIC

```powershell
# PowerShell command to set file association
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.heic\UserChoice" -Name "ProgId" -Value "XnView.heic"
```

Or manually:
1. Right-click any .heic file
2. Open With > Choose another app
3. Select XnView MP
4. Check "Always use this app to open .heic files"
5. Click OK

## Summary

### Current Configuration Status

- ✅ XnView MP installed
- ✅ Default keybindings match mpv.net (LEFT/RIGHT, SPACE, HOME/END)
- ⚠️ HEIF Image Extensions may need to be installed
- ✅ No custom keyboard configuration needed

### Next Steps

1. Install HEIF Image Extensions from Microsoft Store (if not already installed)
2. Test opening a HEIC file from Mylio
3. Set XnView MP as default for .heic files (optional)
4. Start browsing HEIC files directly - no conversion needed!

### Keybindings Summary

For consistent image viewing experience between mpv.net and XnView MP:

| Action | Keybinding | Works in both |
|--------|------------|---------------|
| Next image | `RIGHT` | ✅ |
| Previous image | `LEFT` | ✅ |
| First image | `HOME` | ✅ |
| Last image | `END` | ✅ |
| Slideshow/Pause | `SPACE` | ✅ |
| Zoom | Mouse wheel | ✅ |

**Result:** No configuration changes needed. XnView MP and mpv.net share the same core navigation keybindings out of the box.

## Related Files

- **mpv.net config:** `~/AppData/Roaming/mpv.net/input.conf`
- **mpv.net location:** `~/AppData/Local/Programs/mpv.net/`
- **XnView MP config:** `~/AppData/Roaming/XnViewMP/xnview.ini`
- **XnView MP location:** `C:\Program Files\XnViewMP\`
- **Mylio library:** `D:\Mylio\` (4,617 HEIC files)
- **Converted JPGs:** `~/Documents/heic-staging/` (4,617 files, optional to import)
