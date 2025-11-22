param(
    [string]$Path = "D:\Mylio",
    [switch]$DryRun
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Fix EXIF Using Oldest Date Strategy" -ForegroundColor Cyan
Write-Console "  (Optimized - Memory Efficient)" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

if ($DryRun) {
    Write-Console "MODE: DRY RUN - No files will be modified!" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - Files will be modified!" -ForegroundColor Red
    Write-Console "Press Ctrl+C within 10 seconds to cancel..." -ForegroundColor Yellow
    Write-Console ""
    Start-Sleep -Seconds 10
}

Write-Console ""
Write-Console "Scanning: $Path" -ForegroundColor Gray
Write-Console ""

# Find exiftool
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
if (-not (Test-Path $exiftoolPath)) {
    $exiftoolPath = (Get-Command exiftool -ErrorAction SilentlyContinue).Source
    if (-not $exiftoolPath) {
        Write-Console "ERROR: ExifTool not found!" -ForegroundColor Red
        exit 1
    }
}

Write-Console "Using exiftool: $exiftoolPath" -ForegroundColor Gray
Write-Console ""

# Pattern to match Mylio date-based filenames: YYYY-MM-DD-*.ext
$datePattern = '^(\d{4})-(\d{2})-(\d{2})-'

# Get all media files
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.mov', '*.mp4', '*.avi', '*.m4v', '*.3gp')
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

$total = $files.Count
$processed = 0
$fixed = 0
$alreadyCorrect = 0
$errors = 0
$skipped = 0

Write-Console "Found $total media files to check" -ForegroundColor Yellow
Write-Console ""

# Report file
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$reportPath = "C:\Users\josep\Documents\dev\applications\media-players\mylio\fix-exif-oldest-report-$timestamp.txt"

"Fix EXIF Using Oldest Date Strategy Report (Optimized)" | Out-File -FilePath $reportPath -Encoding UTF8
"Generated: $(Get-Date)" | Out-File -FilePath $reportPath -Append
"Path: $Path" | Out-File -FilePath $reportPath -Append
"Mode: $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })" | Out-File -FilePath $reportPath -Append
"Strategy: Find oldest date from ALL sources (filename, EXIF, file timestamps)" | Out-File -FilePath $reportPath -Append
"" | Out-File -FilePath $reportPath -Append

foreach ($file in $files) {
    $processed++

    # Progress indicator
    if ($processed % 100 -eq 0) {
        $percent = [math]::Round(($processed / $total) * 100, 1)
        Write-Console "`rProgress: $processed / $total ($percent%)" -NoNewline -ForegroundColor Gray
    }

    # Check if filename matches date pattern
    if ($file.Name -notmatch $datePattern) {
        # Filename doesn't match Mylio pattern - skip
        $skipped++
        continue
    }

    try {
        # Extract filename date
        $filenameYear = [int]$matches[1]
        $filenameMonth = [int]$matches[2]
        $filenameDay = [int]$matches[3]

        # Validate filename date
        $filenameDate = $null
        try {
            $filenameDate = [datetime]::new($filenameYear, $filenameMonth, $filenameDay, 12, 0, 0)
        }
        catch {
            $errors++
            "ERROR: Invalid date in filename: $($file.Name)" | Out-File -FilePath $reportPath -Append
            "" | Out-File -FilePath $reportPath -Append
            continue
        }

        # Get ALL EXIF dates in a single exiftool call (much faster!)
        $exifData = & $exiftoolPath -s -s -s -DateTimeOriginal -CreateDate -ModifyDate "$($file.FullName)" 2>$null

        # Parse EXIF output (3 lines expected: DTO, CreateDate, ModifyDate)
        $exifLines = $exifData -split "`r?`n" | Where-Object { $_ -match '\S' }

        $exifDTO = if ($exifLines.Count -ge 1) { $exifLines[0] } else { $null }
        $exifCreate = if ($exifLines.Count -ge 2) { $exifLines[1] } else { $null }
        $exifModify = if ($exifLines.Count -ge 3) { $exifLines[2] } else { $null }

        # Collect all valid dates (use ArrayList for better performance)
        $dateSources = [System.Collections.ArrayList]::new()

        # Add filename date
        [void]$dateSources.Add([PSCustomObject]@{
            Source = "Filename"
            Date = $filenameDate
        })

        # Parse and add EXIF dates
        if ($exifDTO -and $exifDTO -match '(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})') {
            try {
                $exifDTODate = [datetime]::ParseExact($exifDTO, "yyyy:MM:dd HH:mm:ss", $null)
                [void]$dateSources.Add([PSCustomObject]@{
                    Source = "EXIF:DateTimeOriginal"
                    Date = $exifDTODate
                })
            }
            catch { }
        }

        if ($exifCreate -and $exifCreate -match '(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})') {
            try {
                $exifCreateDate = [datetime]::ParseExact($exifCreate, "yyyy:MM:dd HH:mm:ss", $null)
                [void]$dateSources.Add([PSCustomObject]@{
                    Source = "EXIF:CreateDate"
                    Date = $exifCreateDate
                })
            }
            catch { }
        }

        if ($exifModify -and $exifModify -match '(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})') {
            try {
                $exifModifyDate = [datetime]::ParseExact($exifModify, "yyyy:MM:dd HH:mm:ss", $null)
                [void]$dateSources.Add([PSCustomObject]@{
                    Source = "EXIF:ModifyDate"
                    Date = $exifModifyDate
                })
            }
            catch { }
        }

        # Add file system timestamps
        if ($file.CreationTime) {
            [void]$dateSources.Add([PSCustomObject]@{
                Source = "FileSystem:CreationTime"
                Date = $file.CreationTime
            })
        }

        if ($file.LastWriteTime) {
            [void]$dateSources.Add([PSCustomObject]@{
                Source = "FileSystem:LastWriteTime"
                Date = $file.LastWriteTime
            })
        }

        # Must have at least the filename date
        if ($dateSources.Count -eq 0) {
            $errors++
            "ERROR: No dates found: $($file.Name)" | Out-File -FilePath $reportPath -Append
            "" | Out-File -FilePath $reportPath -Append
            continue
        }

        # Find the OLDEST date from all sources
        $oldestSource = $dateSources | Sort-Object { $_.Date } | Select-Object -First 1
        $oldestDate = $oldestSource.Date

        # Determine the time component to use
        # If oldest source has a time component (not noon), preserve it
        # Otherwise use the time from EXIF DateTimeOriginal if available, else noon
        $timeComponent = "12:00:00"

        if ($oldestDate.Hour -ne 12 -or $oldestDate.Minute -ne 0 -or $oldestDate.Second -ne 0) {
            # Oldest source has a specific time - use it
            $timeComponent = $oldestDate.ToString("HH:mm:ss")
        }
        elseif ($exifDTO -and $exifDTO -match '\d{4}:\d{2}:\d{2}\s+(\d{2}:\d{2}:\d{2})') {
            # Use time from EXIF DateTimeOriginal
            $timeComponent = $matches[1]
        }

        # Create the target date string for EXIF (using oldest date + preserved/chosen time)
        $targetDateString = $oldestDate.ToString("yyyy:MM:dd") + " " + $timeComponent
        $targetDateTime = [datetime]::ParseExact($targetDateString, "yyyy:MM:dd HH:mm:ss", $null)

        # Check if all dates match the oldest date (only comparing date portion, not time)
        $allMatch = $true
        $mismatchDetails = [System.Collections.ArrayList]::new()
        $oldestDateOnly = $oldestDate.Date

        foreach ($source in $dateSources) {
            if ($source.Date.Date -ne $oldestDateOnly) {
                $allMatch = $false
                [void]$mismatchDetails.Add("  $($source.Source): $($source.Date.ToString('yyyy-MM-dd HH:mm:ss'))")
            }
        }

        if ($allMatch) {
            # All dates already match the oldest - no fix needed
            $alreadyCorrect++
        }
        else {
            # Dates don't match - need to fix!
            $fixed++

            "MISMATCH: $($file.Name)" | Out-File -FilePath $reportPath -Append
            "  Oldest date: $($oldestSource.Date.ToString('yyyy-MM-dd HH:mm:ss')) (from $($oldestSource.Source))" | Out-File -FilePath $reportPath -Append
            "  Will write: $targetDateString to all fields" | Out-File -FilePath $reportPath -Append
            "  Mismatched sources:" | Out-File -FilePath $reportPath -Append
            $mismatchDetails | ForEach-Object { $_ | Out-File -FilePath $reportPath -Append }
            "  Full path: $($file.FullName)" | Out-File -FilePath $reportPath -Append

            if (-not $DryRun) {
                # Write oldest date to ALL EXIF fields
                & $exiftoolPath -overwrite_original `
                    "-DateTimeOriginal=$targetDateString" `
                    "-CreateDate=$targetDateString" `
                    "-ModifyDate=$targetDateString" `
                    "$($file.FullName)" 2>$null | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    # Also update file timestamps to match
                    $file.CreationTime = $targetDateTime
                    $file.LastWriteTime = $targetDateTime

                    "  FIXED (wrote oldest date to all fields)" | Out-File -FilePath $reportPath -Append
                }
                else {
                    "  ERROR during fix" | Out-File -FilePath $reportPath -Append
                    $errors++
                }
            }
            else {
                "  WOULD FIX (dry run)" | Out-File -FilePath $reportPath -Append
            }

            "" | Out-File -FilePath $reportPath -Append
        }

        # Clear date sources for next iteration (prevent memory accumulation)
        $dateSources.Clear()
        $mismatchDetails.Clear()
    }
    catch {
        $errors++
        "ERROR processing: $($file.Name)" | Out-File -FilePath $reportPath -Append
        "  Error: $_" | Out-File -FilePath $reportPath -Append
        "" | Out-File -FilePath $reportPath -Append
    }
}

Write-Console "`n"
Write-Console ""
Write-Console "Complete!" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  Total files scanned: $total" -ForegroundColor White
Write-Console "  Already correct: $alreadyCorrect" -ForegroundColor Green
Write-Console "  Fixed/Would fix: $fixed" -ForegroundColor Yellow
Write-Console "  Errors: $errors" -ForegroundColor Red
Write-Console "  Skipped (no date in filename): $skipped" -ForegroundColor Gray
Write-Console ""
Write-Console "Report saved to: $reportPath" -ForegroundColor Green
Write-Console ""

# Summary in report
"" | Out-File -FilePath $reportPath -Append
"========================================" | Out-File -FilePath $reportPath -Append
"SUMMARY" | Out-File -FilePath $reportPath -Append
"========================================" | Out-File -FilePath $reportPath -Append
"Total files scanned: $total" | Out-File -FilePath $reportPath -Append
"Already correct: $alreadyCorrect" | Out-File -FilePath $reportPath -Append
"Fixed/Would fix: $fixed" | Out-File -FilePath $reportPath -Append
"Errors: $errors" | Out-File -FilePath $reportPath -Append
"Skipped (no date in filename): $skipped" | Out-File -FilePath $reportPath -Append
