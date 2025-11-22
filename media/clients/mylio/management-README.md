# Mylio Date Corruption Fix - Quick Guide

**Created:** November 6, 2025
**Script:** `fix-mylio-dates.ps1`
**Files to fix:** 375 (32 with 1907 dates, 343 with 1980 dates)

---

## Prerequisites

### 1. Install ExifTool

**Option A: Using winget (recommended)**
```powershell
winget install exiftool
```

**Option B: Manual download**
1. Download from: https://exiftool.org/
2. Extract `exiftool.exe` to a folder in your PATH (or to `C:\Windows\`)

**Verify installation:**
```powershell
exiftool -ver
```

---

## Usage Instructions

### Step 1: Close Mylio
**IMPORTANT:** Exit Mylio completely before running the script.

### Step 2: Run the Script
```powershell
cd ~/Documents/dev
.\fix-mylio-dates.ps1
```

### Step 3: Follow Prompts
- The script will check for ExifTool
- Verify the file count (should be 375)
- Confirm to proceed
- Watch the progress bar

### Step 4: Review Results
- Check the summary at the end
- Review the log file if needed

### Step 5: Restart Mylio
- Open Mylio
- Let it re-scan the library
- Verify dates are correct
- Check Calendar view - files should no longer appear in 1907/1980

---

## What the Script Does

1. ✅ Checks if ExifTool is installed
2. ✅ Loads the list of 375 corrupted files
3. ✅ Warns if Mylio is running
4. ✅ For each file:
   - Reads EXIF `DateTimeOriginal` (the correct date)
   - Updates file system `Modified Date` to match
   - Keeps original file (no backup copies)
5. ✅ Creates a detailed log file
6. ✅ Shows progress and summary

---

## Files

- **Script:** `~/Documents/dev/fix-mylio-dates.ps1`
- **File list:** `~/Documents/dev/mylio-corrupted-files-list.txt` (375 files)
- **Analysis:** `~/Documents/dev/mylio-date-anomalies.md`
- **Log:** `~/Documents/dev/mylio-date-fix-log-YYYYMMDD-HHMMSS.txt` (created when run)

---

## Troubleshooting

### "ExifTool not found"
Install ExifTool using the instructions above.

### "File not found" errors
Some files may have been moved or deleted. The script will skip them and continue.

### Permission denied
Run PowerShell as Administrator if you get permission errors.

### Script won't run (Execution Policy)
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## Safety Notes

✅ **Safe:** The script only updates file system timestamps
✅ **Safe:** EXIF metadata is not modified
✅ **Safe:** Original files are preserved (no copies made)
✅ **Safe:** Operation is logged for review

⚠️ **Important:** Always close Mylio before running
⚠️ **Recommended:** Verify a few files in Mylio after completion

---

## Expected Results

After running successfully:
- **Succeeded:** 375/375 files
- **Failed:** 0 files
- **Duration:** ~2-5 minutes (depending on disk speed)

All files should now have correct Modified Dates matching their EXIF DateTimeOriginal.
