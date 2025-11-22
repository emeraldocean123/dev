# Process for Grouping Photos with Synced Timestamps

## Overview
This document describes the process for grouping photos taken at the same time so they appear adjacent in Mylio, without other photos scattered between them.

**Date:** November 13, 2025
**Project:** July 2, 2006 Event Consolidation
**Total Photos Grouped:** 98 photos

## Problem
Photos from the same event were scattered in Mylio's timeline because their timestamps were inconsistent across different metadata fields. Mylio reads multiple date fields, and mismatches cause incorrect sorting.

## Solution
Update all date/time metadata fields in both XMP sidecars and EXIF data to match, with photos spaced a few seconds apart to keep them adjacent.

## Key Metadata Fields

### XMP Sidecar (.xmp files)
1. **exif:DateTimeOriginal** - Primary timestamp (format: `2006-07-02T11:00:00.000`)
2. **xmp:CreateDate** - Creation date (format: `2006-07-02T11:00:00.000`)
3. **xmp:ModifyDate** - Modification date (format: `2006-07-02T11:00:00.000`)
4. **photoshop:DateCreated** - Photoshop date (format: `2006-07-02T11:00:00.000`)

### EXIF Data (in .jpg files)
1. **EXIF:DateTimeOriginal** - Primary timestamp (format: `2006:07:02 11:00:00`)
2. **EXIF:CreateDate** - Creation date (format: `2006:07:02 11:00:00`)
3. **EXIF:ModifyDate** - Modification date (format: `2006:07:02 11:00:00`)

**Note:** EXIF does not support milliseconds, so milliseconds are removed when syncing.

## Process Steps

### Step 1: Identify Photos to Group
- Determine which photos belong together (same event, taken within minutes)
- Create a list of filenames
- Decide on target date/time range (e.g., 11:00 AM - 11:06 AM)

### Step 2: Update XMP and EXIF Timestamps
Use ExifTool to update both XMP sidecar and JPG file simultaneously:

```powershell
$xmpDate = "2006:07:02 11:00:00.000"  # With milliseconds for XMP
$exifDate = "2006:07:02 11:00:00"     # Without milliseconds for EXIF

exiftool -overwrite_original `
    "-XMP:DateTimeOriginal=$xmpDate" `
    "-XMP:CreateDate=$xmpDate" `
    "-XMP:ModifyDate=$xmpDate" `
    "-EXIF:DateTimeOriginal=$exifDate" `
    "-EXIF:CreateDate=$exifDate" `
    "-EXIF:ModifyDate=$exifDate" `
    $xmpPath $jpgPath
```

### Step 3: Add photoshop:DateCreated to XMP
ExifTool cannot create the `photoshop:DateCreated` field if it doesn't exist, so we manually edit the XMP file:

```powershell
$psDate = "2006-07-02T11:00:00.000"  # ISO 8601 format with 'T' separator
$content = Get-Content -Path $xmpPath -Raw -Encoding UTF8

# Check if photoshop namespace exists
if ($content -match '<rdf:Description[^>]*xmlns:photoshop=') {
    # Update existing or add to existing block
    if ($content -match '<photoshop:DateCreated>([^<]+)</photoshop:DateCreated>') {
        $content = $content -replace '<photoshop:DateCreated>[^<]+</photoshop:DateCreated>',
            "<photoshop:DateCreated>$psDate</photoshop:DateCreated>"
    } else {
        $content = $content -replace '(<rdf:Description[^>]*xmlns:photoshop=[^>]*>)',
            "`$1`n  <photoshop:DateCreated>$psDate</photoshop:DateCreated>"
    }
} else {
    # Add entire photoshop block
    $photoshopBlock = @"

 <rdf:Description rdf:about=''
  xmlns:photoshop='http://ns.adobe.com/photoshop/1.0/'>
  <photoshop:DateCreated>$psDate</photoshop:DateCreated>
 </rdf:Description>
"@
    $content = $content -replace '</rdf:RDF>', "$photoshopBlock`n</rdf:RDF>"
}

Set-Content -Path $xmpPath -Value $content -Encoding UTF8 -NoNewline
```

### Step 4: Space Photos Apart
To keep photos adjacent without overlap, increment timestamps by 4 seconds:

```powershell
$startTime = [datetime]::new(2006, 7, 2, 11, 0, 0)
$secondsIncrement = 4

for ($i = 0; $i -lt $files.Count; $i++) {
    $photoTime = $startTime.AddSeconds($i * $secondsIncrement)
    # Photo 1: 11:00:00
    # Photo 2: 11:00:04
    # Photo 3: 11:00:08
    # etc.
}
```

## Format Differences

### Date Format Summary
| Field | Format | Example | Notes |
|-------|--------|---------|-------|
| XMP:DateTimeOriginal | `yyyy-MM-ddTHH:mm:ss.fff` | `2006-07-02T11:00:00.000` | ISO 8601 with 'T' |
| XMP:CreateDate | `yyyy-MM-ddTHH:mm:ss.fff` | `2006-07-02T11:00:00.000` | ISO 8601 with 'T' |
| XMP:ModifyDate | `yyyy-MM-ddTHH:mm:ss.fff` | `2006-07-02T11:00:00.000` | ISO 8601 with 'T' |
| photoshop:DateCreated | `yyyy-MM-ddTHH:mm:ss.fff` | `2006-07-02T11:00:00.000` | ISO 8601 with 'T' |
| EXIF:DateTimeOriginal | `yyyy:MM:dd HH:mm:ss` | `2006:07:02 11:00:00` | Colon separators, no milliseconds |
| EXIF:CreateDate | `yyyy:MM:dd HH:mm:ss` | `2006:07:02 11:00:00` | Colon separators, no milliseconds |
| EXIF:ModifyDate | `yyyy:MM:dd HH:mm:ss` | `2006:07:02 11:00:00` | Colon separators, no milliseconds |

**For ExifTool commands:**
- XMP fields use colon format: `"2006:07:02 11:00:00.000"`
- EXIF fields use colon format: `"2006:07:02 11:00:00"`
- ExifTool converts to proper format when writing to file

**For XMP manual editing:**
- Use ISO 8601 format with 'T': `"2006-07-02T11:00:00.000"`

## Complete Script Template

```powershell
# Group photos with synced timestamps
$files = @(
    "photo1.jpg",
    "photo2.jpg"
)

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
$basePath = "D:\Mylio\Folder-Follett"
$startTime = [datetime]::new(2006, 7, 2, 11, 0, 0)
$secondsIncrement = 4

for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $photoTime = $startTime.AddSeconds($i * $secondsIncrement)

    # Format timestamps
    $xmpDate = $photoTime.ToString("yyyy:MM:dd HH:mm:ss.000")
    $exifDate = $photoTime.ToString("yyyy:MM:dd HH:mm:ss")
    $psDate = $photoTime.ToString("yyyy-MM-ddTHH:mm:ss.000")

    # Get file paths
    if ($file -match '^(\d{4})-(\d{2})') {
        $year = $Matches[1]
        $month = $Matches[2]
        $monthName = switch ($month) {
            "07" { "July" }
            # Add other months as needed
        }
        $folderPath = Join-Path $basePath "$year\($month) $monthName"
        $fullPath = Join-Path $folderPath $file
        $xmpPath = $fullPath -replace '\.jpg$', '.xmp'

        # Step 1: Update XMP and EXIF via ExifTool
        & $exiftoolPath -overwrite_original `
            "-XMP:DateTimeOriginal=$xmpDate" `
            "-XMP:CreateDate=$xmpDate" `
            "-XMP:ModifyDate=$xmpDate" `
            "-EXIF:DateTimeOriginal=$exifDate" `
            "-EXIF:CreateDate=$exifDate" `
            "-EXIF:ModifyDate=$exifDate" `
            $xmpPath $fullPath

        # Step 2: Add photoshop:DateCreated to XMP
        if (Test-Path $xmpPath) {
            $content = Get-Content -Path $xmpPath -Raw -Encoding UTF8

            if ($content -match '<rdf:Description[^>]*xmlns:photoshop=') {
                if ($content -match '<photoshop:DateCreated>([^<]+)</photoshop:DateCreated>') {
                    $content = $content -replace '<photoshop:DateCreated>[^<]+</photoshop:DateCreated>',
                        "<photoshop:DateCreated>$psDate</photoshop:DateCreated>"
                } else {
                    $content = $content -replace '(<rdf:Description[^>]*xmlns:photoshop=[^>]*>)',
                        "`$1`n  <photoshop:DateCreated>$psDate</photoshop:DateCreated>"
                }
            } else {
                $photoshopBlock = @"

 <rdf:Description rdf:about=''
  xmlns:photoshop='http://ns.adobe.com/photoshop/1.0/'>
  <photoshop:DateCreated>$psDate</photoshop:DateCreated>
 </rdf:Description>
"@
                $content = $content -replace '</rdf:RDF>', "$photoshopBlock`n</rdf:RDF>"
            }

            Set-Content -Path $xmpPath -Value $content -Encoding UTF8 -NoNewline
        }
    }
}
```

## Verification

### Verify XMP Fields
```bash
# Check XMP sidecar directly (most reliable)
grep "photoshop:DateCreated" file.xmp
```

### Verify EXIF Fields
```bash
exiftool -s -s -s -EXIF:DateTimeOriginal file.jpg
```

### Verify All Fields Match
```powershell
$xmpDate = & exiftool -s -s -s -XMP:DateTimeOriginal file.xmp
$exifDate = & exiftool -s -s -s -EXIF:DateTimeOriginal file.jpg

# Remove milliseconds from XMP for comparison
$xmpDateNoMs = if ($xmpDate -match '^(.+)\.\d+$') { $Matches[1] } else { $xmpDate }

if ($xmpDateNoMs -eq $exifDate) {
    Write-Host "Timestamps match" -ForegroundColor Green
}
```

## Scripts Created

### July 2006 Event Scripts
1. **fix-group-to-11am.ps1** - Initial 79 photos (11:00:00 - 11:05:12)
2. **add-photoshop-datecreated.ps1** - Added photoshop:DateCreated to 79 photos
3. **add-14-more-to-group.ps1** - Added 14 photos (11:05:16 - 11:06:08)
4. **add-5-more-to-group.ps1** - Added 5 photos (11:06:12 - 11:06:28)
5. **verify-11am-group.ps1** - Verification script for all fields

**Total:** 98 photos grouped from 11:00:00 AM to 11:06:28 AM

## Important Notes

1. **Always update XMP sidecar AND JPG file** - Mylio reads both
2. **photoshop:DateCreated must be added manually** - ExifTool can't create it
3. **Use UTF8 encoding** when editing XMP files
4. **No newline at end** - Use `-NoNewline` when writing XMP files
5. **4-second spacing** - Keeps photos adjacent without overlap
6. **Restart Mylio** after changes to pick up updated XMP files

## File Organization

### Mylio Folder Structure
```
D:\Mylio\Folder-Follett\
├── 2006\
│   └── (07) July\
│       ├── 2006-07-02-50.jpg
│       ├── 2006-07-02-50.xmp
│       ├── 2006-07-03-301.jpg
│       └── 2006-07-03-301.xmp
```

### Scripts Location
```
C:\Users\josep\Documents\dev\photos\mylio\
├── group-photos-process.md (this document)
├── fix-group-to-11am.ps1
├── add-photoshop-datecreated.ps1
├── add-14-more-to-group.ps1
├── add-5-more-to-group.ps1
└── verify-11am-group.ps1
```

## Success Criteria
- ✅ All XMP fields match target timestamps
- ✅ All EXIF fields match target timestamps (without milliseconds)
- ✅ photoshop:DateCreated field exists and matches
- ✅ Photos appear adjacent in Mylio timeline
- ✅ No other photos scattered between grouped photos

## Next Groups
For future photo groups, use the template script above and:
1. Update the `$files` array with new filenames
2. Update `$startTime` to desired group start time
3. Adjust `$secondsIncrement` if needed (4 seconds works well)
4. Run script and verify results in Mylio
