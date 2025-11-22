# Mylio Folder - Date/Time Anomalies

**Analysis Date:** November 3, 2025
**Location:** D:\Mylio\

## Warning
**DO NOT modify files in the Mylio folder outside of the Mylio application.**
File system changes can corrupt the Mylio database. All corrections must be made within Mylio.

---

## Anomaly #1: Corrupted Modified Dates (1907)

### Summary
32 files have corrupted file system Modified Date showing **June 8, 1907 at 3:42:46 AM**.

### Impact
- **Mylio**: Correctly displays files using EXIF DateTimeOriginal metadata
- **Eagle**: Shows incorrect 1907 date (relies on file system Modified Date)

### Root Cause
File system metadata corruption. EXIF data is intact and correct.

### Files Affected (32 total)

#### 2010 (1 file)
- `D:\Mylio\Folder-Follett\2010\(05) May\2010-05-01-34.jpg`

#### 2013 (1 file)
- `D:\Mylio\Folder-Follett\2013\(12) December\2013-12-01-29.jpg`

#### 2014 (22 files)
- `D:\Mylio\Folder-Follett\2014\(01) January\2014-01-02-11.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-383.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-388.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-392.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-395.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-437.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-439.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-441.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-446.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-449.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-451.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-456.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-458.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-463.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-466.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-27-467.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-28-635.jpg`
- `D:\Mylio\Folder-Follett\2014\(06) June\2014-06-28-637.jpg`
- `D:\Mylio\Folder-Follett\2014\(09) September\2014-09-26-146.jpg`
- `D:\Mylio\Folder-Follett\2014\(10) October\2014-10-24-269.jpg`
- `D:\Mylio\Folder-Follett\2014\(10) October\2014-10-24-271.jpg`

#### 2015 (5 files)
- `D:\Mylio\Folder-Follett\2015\(01) January\2015-01-22-93.jpg`
- `D:\Mylio\Folder-Follett\2015\(01) January\2015-01-22-94.jpg`
- `D:\Mylio\Folder-Follett\2015\(01) January\2015-01-22-95.jpg`
- `D:\Mylio\Folder-Follett\2015\(01) January\2015-01-22-96.jpg`
- `D:\Mylio\Folder-Follett\2015\(01) January\2015-01-22-97.jpg`

#### 2016 (1 file)
- `D:\Mylio\Folder-Follett\2016\(09) September\2016-09-29-227.jpg`

#### 2017 (2 files)
- `D:\Mylio\Folder-Follett\2017\(06) June\2017-06-10-191.jpg`
- `D:\Mylio\Folder-Follett\2017\(06) June\2017-06-24-230.jpg`
- `D:\Mylio\Folder-Follett\2017\(06) June\2017-06-24-231.jpg`

### File Timestamps

**Corrupted Modified Date (all files):** June 8, 1907, 3:42:46 AM
**Created Date (all files):** August 2, 2025, ~8:32 PM (import time)

### Example EXIF Data (2014-06-27-451.jpg)

**File System:**
- Modified Date: Jun 8, 1907, 2:42:46 AM ❌
- Created Date: Aug 2, 2025, 8:32:52 PM

**EXIF Metadata (Correct):**
- DateTimeOriginal: 2014-06-27T17:44:43 ✓
- CreateDate: 2014-06-27T17:44:43 ✓
- ModifyDate: 2014-06-27T17:44:43 ✓
- Camera: SONY DSC-HX20V

**Verification:**
Filename `2014-06-27-451.jpg` matches EXIF DateTimeOriginal `2014-06-27`.

---

## Anomaly #2: Corrupted Modified Dates (1980)

### Summary
**343 files** have corrupted file system Modified Date showing **January 1, 1980 at 00:00:00** (midnight).

### Pattern
This is a common "null date" corruption - January 1, 1980 is often used as a default date when file system metadata is lost or corrupted. This is similar to Unix epoch (Jan 1, 1970) but with an offset.

### Impact
Same as Anomaly #1:
- **Mylio**: Correctly displays files using EXIF DateTimeOriginal metadata
- **Eagle**: Would show incorrect 1980 date (relies on file system Modified Date)

### Distribution
Files span from 1980-2024 based on folder organization, but all show the same corrupted timestamp.

### Files Affected
**Full list of all 343 files available in:** `C:\Users\josep\Documents\dev\mylio-analysis-results.txt`

**Sample files (first 50):**
- D:\Mylio\Folder-Follett\1980\(01) January\1980-01-01-1-1.jpg
- D:\Mylio\Folder-Follett\2000\(01) January\2000-01-01-2.jpg
- D:\Mylio\Folder-Follett\2000\(06) June\2000-06-23-9.jpg
- D:\Mylio\Folder-Follett\2001\(02) February\2001-02-16-8.jpg
- D:\Mylio\Folder-Follett\2002\(02) February\2002-02-09-2.jpg
- (and 338 more - see analysis results file for complete list)

### Timestamps
**All files have:**
- Modified Date: January 1, 1980, 00:00:00
- Created Date: August 2, 2025, ~8:32 PM (import time)

---

## Additional Anomalies

### No Other Issues Found
The comprehensive analysis of 60,743 image files found:
- ✓ No future dates
- ✓ No filename/folder date mismatches
- ✓ No files missing EXIF markers
- ✓ No other date corruption patterns

### Total Files with Corrupted Dates
- **32 files** with 1907 dates
- **343 files** with 1980 dates
- **375 total** files with corrupted file system metadata (0.62% of 60,743 files)

## Video Files Analysis

### Summary
**20,900 video files** analyzed - **NO ANOMALIES FOUND** ✓

All video files in the Mylio folder have correct timestamps. No corrupted dates detected.

**File formats scanned:**
- MP4, MOV, AVI, MKV, M2TS, MPG, MPEG, MTS, 3GP, WMV, FLV, WEBM

**Results:**
- ✓ No 1907 dates
- ✓ No 1980 dates
- ✓ No other old dates (before 1990)
- ✓ No future dates
- ✓ No filename/folder mismatches

**Analysis Report:** `C:\Users\josep\Documents\dev\mylio-video-analysis-results.txt`

---

## Recommendations

1. **Do not attempt to fix file system dates manually** - this could corrupt Mylio's database
2. **Mylio handles these files correctly** - it uses EXIF metadata as the primary date source
3. **Eagle requires EXIF support** - or use applications that read EXIF data for date information
4. If corrections are needed, use Mylio's built-in metadata tools to synchronize file dates with EXIF data
