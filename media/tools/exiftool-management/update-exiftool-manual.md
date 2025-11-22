# Manual ExifTool Update to 13.42

Since you already have 13.42 installed in one location, here's how to copy it to the other two:

## Quick Update (Copy from existing installation)

```powershell
# Copy the updated version you already have to the other two locations

# Update location 1 (Portable)
Copy-Item "C:\Users\josep\AppData\Local\Programs\ExifTool\ExifTool.exe" `
          "D:\Files\Programs-Portable\ExifTool\exiftool.exe" -Force

# Update location 3 (ExifToolGUI)
Copy-Item "C:\Users\josep\AppData\Local\Programs\ExifTool\ExifTool.exe" `
          "C:\Users\josep\AppData\Local\Programs\ExifToolGUI\exiftool.exe" -Force
```

## Verify All Installations

```powershell
# Check version 1
& "D:\Files\Programs-Portable\ExifTool\exiftool.exe" -ver

# Check version 2 (already updated)
& "C:\Users\josep\AppData\Local\Programs\ExifTool\ExifTool.exe" -ver

# Check version 3
& "C:\Users\josep\AppData\Local\Programs\ExifToolGUI\exiftool.exe" -ver
```

All three should show **13.42**.

## Alternative: Download Fresh Copy

If you prefer to download fresh:

1. Go to https://exiftool.org/
2. Download **Version 13.42 for Windows**
3. Extract the zip file
4. Rename `exiftool(-k).exe` to `exiftool.exe`
5. Copy to all three locations above

---

**Note:** Once updated, close and reopen your terminal for the PATH changes to take effect.
