# Manual ExifTool Update to 13.42

Since you already have 13.42 installed in one location, here's how to copy it to the other two:

## Quick Update (Copy from existing installation)

```powershell
# Copy the updated version you already have to the other two locations

# Update location 1 (Portable)
Copy-Item "<User AppData Local Programs Directory>\ExifTool\ExifTool.exe" `
          "<Portable Programs Drive>\Files\Programs-Portable\ExifTool\exiftool.exe" -Force

# Update location 3 (ExifToolGUI)
Copy-Item "<User AppData Local Programs Directory>\ExifTool\ExifTool.exe" `
          "<User AppData Local Programs Directory>\ExifToolGUI\exiftool.exe" -Force
```

## Verify All Installations

```powershell
# Check version 1
& "<Portable Programs Drive>\Files\Programs-Portable\ExifTool\exiftool.exe" -ver

# Check version 2 (already updated)
& "<User AppData Local Programs Directory>\ExifTool\ExifTool.exe" -ver

# Check version 3
& "<User AppData Local Programs Directory>\ExifToolGUI\exiftool.exe" -ver
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
