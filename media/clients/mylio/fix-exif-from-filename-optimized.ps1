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
Write-Console "  Fix EXIF from Mylio Filename Dates" -ForegroundColor Cyan
Write-Console "  (Memory Optimized)" -ForegroundColor Cyan
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
$olderExifFound = 0

Write-Console "Found $total media files to check" -ForegroundColor Yellow
Write-Console ""

# Report file
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$reportPath = "C:\Users\josep\Documents\dev\applications\media-players\mylio\fix-exif-report-$timestamp.txt"

"Fix EXIF from Filename Report (Memory Optimized)" | Out-File -FilePath $reportPath -Encoding UTF8
"Generated: $(Get-Date)" | Out-File -FilePath $reportPath -Append
"Path: $Path" | Out-File -FilePath $reportPath -Append
"Mode: $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })" | Out-File -FilePath $reportPath -Append
"Strategy: Use filename date as source of truth" | Out-File -FilePath $reportPath -Append
"" | Out-File -FilePath $reportPath -Append

# Pre-allocate StringBuilder for report (more memory efficient than repeated Out-File)
$reportBuilder = [System.Text.StringBuilder]::new()

foreach ($file in $files) {
    $processed++

    # Progress indicator
    if ($processed % 100 -eq 0) {
        $percent = [math]::Round(($processed / $total) * 100, 1)
        Write-Console "`rProgress: $processed / $total ($percent%)" -NoNewline -ForegroundColor Gray

        # Flush report builder to file every 100 files to prevent memory buildup
        if ($reportBuilder.Length -gt 0) {
            $reportBuilder.ToString() | Out-File -FilePath $reportPath -Append
            $reportBuilder.Clear()
        }
    }

    # Check if filename matches date pattern
    if ($file.Name -notmatch $datePattern) {
        # Filename doesn't match Mylio pattern - skip
        $skipped++
        continue
    }

    $filenameYear = [int]$matches[1]
    $filenameMonth = [int]$matches[2]
    $filenameDay = [int]$matches[3]

    # Validate filename date
    try {
        $filenameDate = [datetime]::new($filenameYear, $filenameMonth, $filenameDay)
    }
    catch {
        $errors++
        [void]$reportBuilder.AppendLine("ERROR: Invalid date in filename: $($file.Name)")
        [void]$reportBuilder.AppendLine("")
        continue
    }

    # Create expected date string for EXIF
    $expectedDate = "$($filenameYear):$($filenameMonth.ToString('00')):$($filenameDay.ToString('00'))"

    # Get current EXIF DateTimeOriginal only (single call)
    try {
        $exifOutput = & $exiftoolPath -s -s -s -DateTimeOriginal "$($file.FullName)" 2>$null

        if ($exifOutput -and $exifOutput -match '^(\d{4}):(\d{2}):(\d{2})') {
            $exifYear = [int]$matches[1]
            $exifMonth = [int]$matches[2]
            $exifDay = [int]$matches[3]

            # Create datetime for comparison
            $exifDateTime = [datetime]::new($exifYear, $exifMonth, $exifDay)

            # Check if EXIF date is older than filename
            if ($exifDateTime -lt $filenameDate) {
                $olderExifFound++
                [void]$reportBuilder.AppendLine("OLDER EXIF FOUND: $($file.Name)")
                [void]$reportBuilder.AppendLine("  Filename date: $filenameYear-$filenameMonth-$filenameDay")
                [void]$reportBuilder.AppendLine("  EXIF date:     $exifYear-$exifMonth-$exifDay (OLDER)")
                [void]$reportBuilder.AppendLine("  Full path: $($file.FullName)")
                [void]$reportBuilder.AppendLine("  ACTION: Will overwrite with filename date")
                [void]$reportBuilder.AppendLine("")
            }

            # Check if dates match
            if ($filenameYear -eq $exifYear -and $filenameMonth -eq $exifMonth -and $filenameDay -eq $exifDay) {
                $alreadyCorrect++
            }
            else {
                # Dates don't match - need to fix!
                $fixed++

                [void]$reportBuilder.AppendLine("MISMATCH: $($file.Name)")
                [void]$reportBuilder.AppendLine("  Filename date: $filenameYear-$filenameMonth-$filenameDay")
                [void]$reportBuilder.AppendLine("  EXIF date:     $exifYear-$exifMonth-$exifDay")
                [void]$reportBuilder.AppendLine("  Full path: $($file.FullName)")

                if (-not $DryRun) {
                    # Fix EXIF to match filename
                    # Preserve original time if it exists, otherwise use noon
                    $timeComponent = "12:00:00"
                    if ($exifOutput -match '^\d{4}:\d{2}:\d{2}\s+(\d{2}:\d{2}:\d{2})') {
                        $timeComponent = $matches[1]
                    }

                    $newDateTime = "$expectedDate $timeComponent"

                    # Write to all date fields
                    & $exiftoolPath -overwrite_original `
                        "-DateTimeOriginal=$newDateTime" `
                        "-CreateDate=$newDateTime" `
                        "-ModifyDate=$newDateTime" `
                        "$($file.FullName)" 2>$null | Out-Null

                    if ($LASTEXITCODE -eq 0) {
                        # Also update file timestamps to match
                        $newDate = [datetime]::ParseExact($newDateTime, "yyyy:MM:dd HH:mm:ss", $null)
                        $file.CreationTime = $newDate
                        $file.LastWriteTime = $newDate

                        [void]$reportBuilder.AppendLine("  FIXED")
                    }
                    else {
                        [void]$reportBuilder.AppendLine("  ERROR during fix")
                        $errors++
                    }
                }
                else {
                    [void]$reportBuilder.AppendLine("  WOULD FIX (dry run)")
                }

                [void]$reportBuilder.AppendLine("")
            }
        }
        elseif (-not $exifOutput) {
            # No EXIF DateTimeOriginal - need to add it
            $fixed++

            [void]$reportBuilder.AppendLine("MISSING EXIF: $($file.Name)")
            [void]$reportBuilder.AppendLine("  Filename date: $filenameYear-$filenameMonth-$filenameDay")

            if (-not $DryRun) {
                $newDateTime = "$expectedDate 12:00:00"

                & $exiftoolPath -overwrite_original `
                    "-DateTimeOriginal=$newDateTime" `
                    "-CreateDate=$newDateTime" `
                    "-ModifyDate=$newDateTime" `
                    "$($file.FullName)" 2>$null | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    $newDate = [datetime]::ParseExact($newDateTime, "yyyy:MM:dd HH:mm:ss", $null)
                    $file.CreationTime = $newDate
                    $file.LastWriteTime = $newDate

                    [void]$reportBuilder.AppendLine("  ADDED EXIF")
                }
                else {
                    [void]$reportBuilder.AppendLine("  ERROR adding EXIF")
                    $errors++
                }
            }
            else {
                [void]$reportBuilder.AppendLine("  WOULD ADD EXIF (dry run)")
            }

            [void]$reportBuilder.AppendLine("")
        }
        else {
            # EXIF date doesn't parse correctly
            $errors++
            [void]$reportBuilder.AppendLine("ERROR: Unable to parse EXIF date: $($file.Name)")
            [void]$reportBuilder.AppendLine("  EXIF output: $exifOutput")
            [void]$reportBuilder.AppendLine("")
        }
    }
    catch {
        $errors++
        [void]$reportBuilder.AppendLine("ERROR processing: $($file.Name)")
        [void]$reportBuilder.AppendLine("  Error: $_")
        [void]$reportBuilder.AppendLine("")
    }
}

# Flush remaining report content
if ($reportBuilder.Length -gt 0) {
    $reportBuilder.ToString() | Out-File -FilePath $reportPath -Append
    $reportBuilder.Clear()
}

Write-Console "`n"
Write-Console ""
Write-Console "Complete!" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  Total files scanned: $total" -ForegroundColor White
Write-Console "  Already correct: $alreadyCorrect" -ForegroundColor Green
Write-Console "  Fixed/Would fix: $fixed" -ForegroundColor Yellow
Write-Console "  Files with EXIF older than filename: $olderExifFound" -ForegroundColor Magenta
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
"Files with EXIF older than filename: $olderExifFound" | Out-File -FilePath $reportPath -Append
"Errors: $errors" | Out-File -FilePath $reportPath -Append
"Skipped (no date in filename): $skipped" | Out-File -FilePath $reportPath -Append
