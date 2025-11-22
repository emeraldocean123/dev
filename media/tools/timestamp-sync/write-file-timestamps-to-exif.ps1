# Write File Timestamps to Missing EXIF Data
# For files with no EXIF date, uses oldest file timestamp and writes it to EXIF

param(
    [string]$Path = "D:\Mylio",
    [switch]$DryRun = $true,
    [switch]$Verbose
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
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Write File Timestamps to EXIF" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "MODE: DRY RUN (no changes will be made)" -ForegroundColor Yellow
    Write-Console "Run with -DryRun:`$false to apply changes`n" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - EXIF data will be modified!" -ForegroundColor Red
    Write-Console "Press Ctrl+C within 5 seconds to cancel...`n" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

Write-Console "Scanning: $Path`n" -ForegroundColor White

# Check if exiftool is available
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
if (-not (Test-Path $exiftoolPath)) {
    Write-Console "ERROR: exiftool not found at $exiftoolPath" -ForegroundColor Red
    Write-Console "Please verify ExifTool installation location`n" -ForegroundColor Yellow
    exit 1
}

Write-Console "Using exiftool: $exiftoolPath`n" -ForegroundColor Green

# Get all media files
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.heif', '*.mov', '*.mp4', '*.avi', '*.mkv', '*.m4v')
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

$totalFiles = $files.Count
Write-Console "Found $totalFiles media files to process`n" -ForegroundColor White

# Initialize counters
$stats = @{
    Processed = 0
    Updated = 0
    Skipped = 0
    Errors = 0
    AlreadyHasExif = 0
}

$startTime = Get-Date
$changes = @()

Write-Console "Processing files..." -ForegroundColor Cyan
Write-Console "This may take several minutes...`n" -ForegroundColor Gray

foreach ($file in $files) {
    $stats.Processed++

    if ($stats.Processed % 100 -eq 0) {
        $percentComplete = [math]::Round(($stats.Processed / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $stats.Processed * $totalFiles
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "`rProgress: $($stats.Processed) / $totalFiles ($percentComplete%) - Updated: $($stats.Updated) - ETA: $($remaining.ToString('hh\:mm\:ss'))" -NoNewline -ForegroundColor Yellow
    }

    try {
        # Check if file already has EXIF date data
        $exifJson = & $exiftoolPath -j -DateTimeOriginal -CreateDate -ModifyDate $file.FullName 2>$null | ConvertFrom-Json

        if (-not $exifJson) {
            $stats.Errors++
            continue
        }

        $exifData = $exifJson[0]

        # Check if any date fields exist
        $hasDateTimeOriginal = $exifData.DateTimeOriginal
        $hasCreateDate = $exifData.CreateDate
        $hasModifyDate = $exifData.ModifyDate

        if ($hasDateTimeOriginal -or $hasCreateDate -or $hasModifyDate) {
            # File already has EXIF date data - skip
            $stats.AlreadyHasExif++
            continue
        }

        # File has NO EXIF date data - get file timestamps
        $fileTimestamps = @(
            $file.CreationTime,
            $file.LastWriteTime,
            $file.LastAccessTime
        )

        # Find oldest valid timestamp (not in future, not before 1990)
        $validTimestamps = $fileTimestamps | Where-Object {
            $_ -lt (Get-Date) -and $_ -gt (Get-Date -Year 1990 -Month 1 -Day 1)
        }

        if ($validTimestamps.Count -eq 0) {
            # No valid timestamps - skip
            $stats.Skipped++
            continue
        }

        # Get oldest timestamp
        $oldestTimestamp = $validTimestamps | Sort-Object | Select-Object -First 1

        # Format date for EXIF (YYYY:MM:DD HH:MM:SS)
        $exifDateString = $oldestTimestamp.ToString('yyyy:MM:dd HH:mm:ss')

        $change = [PSCustomObject]@{
            File = $file.FullName
            OldestFileTimestamp = $oldestTimestamp
            ExifDateToWrite = $exifDateString
            CreationTime = $file.CreationTime
            LastWriteTime = $file.LastWriteTime
        }

        $changes += $change

        if (-not $DryRun) {
            # Write EXIF date using exiftool
            # -DateTimeOriginal is the most important field (original capture time)
            # -CreateDate is camera's creation time
            # -ModifyDate is last modification time
            # We set all three to the oldest file timestamp

            $exifToolArgs = @(
                "-DateTimeOriginal=$exifDateString",
                "-CreateDate=$exifDateString",
                "-ModifyDate=$exifDateString",
                "-overwrite_original",  # Don't create backup files
                $file.FullName
            )

            $result = & $exiftoolPath $exifToolArgs 2>&1

            if ($LASTEXITCODE -ne 0) {
                $stats.Errors++
                if ($Verbose) {
                    Write-Console "`n`nError writing EXIF to: $($file.Name)" -ForegroundColor Red
                    Write-Console "  $result" -ForegroundColor Gray
                }
                continue
            }
        }

        $stats.Updated++

        if ($Verbose) {
            Write-Console "`n`nFile: $($file.Name)" -ForegroundColor White
            Write-Console "  No EXIF date found" -ForegroundColor Yellow
            Write-Console "  Oldest file timestamp: $oldestTimestamp" -ForegroundColor Cyan
            Write-Console "  Writing to EXIF: $exifDateString" -ForegroundColor Green
        }

    } catch {
        $stats.Errors++
        if ($Verbose) {
            Write-Console "`nError processing: $($file.Name)" -ForegroundColor Red
            Write-Console "  $_" -ForegroundColor Gray
        }
    }
}

Write-Console "`r`n`n" # Clear progress line

# Generate Report
$elapsed = (Get-Date) - $startTime

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Total files processed: $($stats.Processed)" -ForegroundColor White
Write-Console "Files with no EXIF date (updated): $($stats.Updated)" -ForegroundColor $(if ($stats.Updated -gt 0) { "Green" } else { "Gray" })
Write-Console "Files already have EXIF data: $($stats.AlreadyHasExif)" -ForegroundColor Gray
Write-Console "Files skipped (invalid timestamps): $($stats.Skipped)" -ForegroundColor Yellow
Write-Console "Errors: $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
Write-Console "`nProcessing time: $($elapsed.ToString('hh\:mm\:ss'))`n" -ForegroundColor White

if ($DryRun -and $stats.Updated -gt 0) {
    Write-Console "This was a DRY RUN - no files were modified." -ForegroundColor Yellow
    Write-Console "Run with -DryRun:`$false to apply these changes.`n" -ForegroundColor Yellow
}

# Show sample changes
if ($changes.Count -gt 0) {
    Write-Console "`n========================================" -ForegroundColor Cyan
    Write-Console "  Sample Changes (first 20)" -ForegroundColor Cyan
    Write-Console "========================================`n" -ForegroundColor Cyan

    $changes | Select-Object -First 20 | Format-Table -AutoSize
}

# Save detailed report to file
if ($changes.Count -gt 0) {
    $reportPath = "$PSScriptRoot\write-exif-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    $report = @"
Write File Timestamps to EXIF Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Mode: $(if ($DryRun) { "DRY RUN" } else { "LIVE" })

========================================
SUMMARY
========================================

Total files processed: $($stats.Processed)
Files with no EXIF date (updated): $($stats.Updated)
Files already have EXIF data: $($stats.AlreadyHasExif)
Files skipped (invalid timestamps): $($stats.Skipped)
Errors: $($stats.Errors)

Processing time: $($elapsed.ToString('hh\:mm\:ss'))

========================================
CHANGES ($($changes.Count) files)
========================================

"@

    foreach ($change in $changes) {
        $report += ($change | Format-List | Out-String)
        $report += "`n"
    }

    $report | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Console "`nDetailed report saved to:" -ForegroundColor White
    Write-Console "$reportPath`n" -ForegroundColor Green
}

if (-not $DryRun -and $stats.Updated -gt 0) {
    Write-Console "`nIMPORTANT: EXIF data has been modified!" -ForegroundColor Yellow
    Write-Console "Files now have DateTimeOriginal, CreateDate, and ModifyDate set." -ForegroundColor White
    Write-Console "The timestamps are based on the oldest file timestamp found.`n" -ForegroundColor White
}
