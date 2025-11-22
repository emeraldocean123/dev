# Mylio Date Anomaly Scanner - Quick Guide

**Created:** November 6, 2025
**Script:** `scan-mylio-dates.ps1`
**Purpose:** Verify all photos and videos have correct dates after the fix

---

## What This Script Does

Performs a comprehensive scan of your entire Mylio library:
- ✅ Scans all image files (JPG, JPEG, PNG, HEIC, RAW formats, etc.)
- ✅ Scans all video files (MP4, MOV, AVI, etc.)
- ✅ Checks for date anomalies:
  - 1907 dates (corrupted file system dates)
  - 1980 dates (null date corruption)
  - Other old dates (before 1990)
  - Future dates (beyond today)
- ✅ Generates a detailed report

---

## Usage

```powershell
cd ~/Documents/dev
.\scan-mylio-dates.ps1
```

---

## What to Expect

### Scan Time
- **Images:** ~1-2 seconds per 1000 files
- **Videos:** ~2-3 seconds per 1000 files
- **Total time:** ~5-10 minutes for 80,000+ files

### Progress
- Real-time progress bars for images and videos
- Updates every 1000 images / 500 videos
- Shows percentage complete

### Results
The script will report:
- Total files scanned (images + videos)
- Number of anomalies found by type:
  - ✅ **0 anomalies** = Clean library!
  - ⚠️ **Anomalies found** = Details in report

---

## Expected Results (After Fix)

If the date fix was successful, you should see:
```
Anomalies Found:
  1907 Dates:   0 files ✓
  1980 Dates:   0 files ✓
  Old Dates:    0 files ✓ (or minimal legitimate old photos)
  Future Dates: 0 files ✓

✓ NO DATE ANOMALIES FOUND!
All XX,XXX files have valid dates. Your Mylio library is clean!
```

---

## Report File

**Location:** `~/Documents/dev/mylio-date-scan-YYYYMMDD-HHMMSS.txt`

**Contains:**
- Complete summary of files scanned
- Total anomalies by type
- Full list of any problem files with their dates
- Scan duration and timestamp

---

## Interpreting Results

### ✓ Clean Results
- 0 files with 1907 dates
- 0 files with 1980 dates
- 0-10 files with old dates (legitimate old photos)
- 0 files with future dates

### ⚠️ Anomalies Found
If anomalies are detected, the report will show:
- Exact file paths
- Current modified dates
- File type (Image or Video)

---

## File Types Scanned

**Images:**
- Common: JPG, JPEG, PNG, GIF, BMP, HEIC, HEIF
- RAW formats: RAW, CR2, NEF, ARW, DNG
- Other: TIFF, TIF, WEBP

**Videos:**
- Common: MP4, MOV, AVI, MKV, M4V
- Other: M2TS, MPG, MPEG, MTS, 3GP, WMV, FLV, WEBM

---

## Next Steps

### If Clean (0 Anomalies)
1. ✅ Your Mylio library is healthy
2. ✅ All dates are correct
3. ✅ Safe to use Mylio and Eagle

### If Anomalies Found
1. Review the detailed report
2. Check if anomalies are legitimate (actual old photos)
3. If problematic, run the fix script again on specific files
4. Re-scan to verify

---

## Notes

- Script is read-only - no files are modified
- Safe to run multiple times
- Can be run while Mylio is open (just scanning)
- Each run creates a new timestamped report
