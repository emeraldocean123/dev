# Sync File Timestamps to Oldest EXIF Date
# Finds the oldest valid date in EXIF data and sets file timestamp to match

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
Write-Console "  Sync File Timestamps to EXIF" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "MODE: DRY RUN (no changes will be made)" -ForegroundColor Yellow
    Write-Console "Run with -DryRun:`$false to apply changes`n" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - Files will be modified!" -ForegroundColor Red
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
    NoExifDate = 0
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
        # Get all date fields from EXIF
        $exifJson = & $exiftoolPath -j -DateTimeOriginal -CreateDate -ModifyDate -FileModifyDate -DateCreated -DigitalCreationDate -MediaCreateDate $file.FullName 2>$null | ConvertFrom-Json

        if (-not $exifJson) {
            $stats.NoExifDate++
            continue
        }

        $exifData = $exifJson[0]

        # Collect all valid dates
        $dates = @()

        # Extract dates from EXIF fields
        $dateFields = @('DateTimeOriginal', 'CreateDate', 'ModifyDate', 'DateCreated', 'DigitalCreationDate', 'MediaCreateDate')

        foreach ($field in $dateFields) {
            $dateString = $exifData.$field
            if ($dateString) {
                try {
                    # Parse EXIF date format: "YYYY:MM:DD HH:MM:SS"
                    $parsedDate = [DateTime]::ParseExact($dateString, 'yyyy:MM:dd HH:mm:ss', $null)

                    # Validate date is reasonable (not in future, not before 1990)
                    if ($parsedDate -lt (Get-Date) -and $parsedDate -gt (Get-Date -Year 1990 -Month 1 -Day 1)) {
                        $dates += @{
                            Field = $field
                            Date = $parsedDate
                        }
                    }
                } catch {
                    # Invalid date format - skip
                }
            }
        }

        # If no valid dates found, skip
        if ($dates.Count -eq 0) {
            $stats.NoExifDate++
            continue
        }

        # Find the oldest date
        $oldestDate = ($dates | Sort-Object { $_.Date } | Select-Object -First 1)

        # Compare with current file timestamp
        $currentTimestamp = $file.LastWriteTime
        $timeDifference = [Math]::Abs(($oldestDate.Date - $currentTimestamp).TotalSeconds)

        # Only update if difference is more than 1 second (avoid unnecessary writes)
        if ($timeDifference -gt 1) {
            $change = [PSCustomObject]@{
                File = $file.FullName
                CurrentTimestamp = $currentTimestamp
                NewTimestamp = $oldestDate.Date
                SourceField = $oldestDate.Field
                DifferenceInDays = [math]::Round(($currentTimestamp - $oldestDate.Date).TotalDays, 1)
            }

            $changes += $change

            if (-not $DryRun) {
                # Update file timestamp
                $file.LastWriteTime = $oldestDate.Date
                $file.CreationTime = $oldestDate.Date
                $file.LastAccessTime = $oldestDate.Date
            }

            $stats.Updated++

            if ($Verbose) {
                Write-Console "`n`nFile: $($file.Name)" -ForegroundColor White
                Write-Console "  Current:  $currentTimestamp" -ForegroundColor Yellow
                Write-Console "  EXIF:     $($oldestDate.Date) (from $($oldestDate.Field))" -ForegroundColor Green
                Write-Console "  Diff:     $($change.DifferenceInDays) days" -ForegroundColor Cyan
            }
        } else {
            $stats.Skipped++
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
Write-Console "Files updated: $($stats.Updated)" -ForegroundColor $(if ($stats.Updated -gt 0) { "Green" } else { "Gray" })
Write-Console "Files skipped (already correct): $($stats.Skipped)" -ForegroundColor Gray
Write-Console "Files with no EXIF date: $($stats.NoExifDate)" -ForegroundColor Yellow
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
    $reportPath = "$PSScriptRoot\timestamp-sync-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    $report = @"
File Timestamp Sync Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Mode: $(if ($DryRun) { "DRY RUN" } else { "LIVE" })

========================================
SUMMARY
========================================

Total files processed: $($stats.Processed)
Files updated: $($stats.Updated)
Files skipped (already correct): $($stats.Skipped)
Files with no EXIF date: $($stats.NoExifDate)
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
