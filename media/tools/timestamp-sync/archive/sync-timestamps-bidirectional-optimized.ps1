# Sync Timestamps Bidirectionally (File <-> EXIF) - Memory Optimized
# Finds oldest valid timestamp from EXIF or file properties
# Writes to BOTH file timestamps AND EXIF data
# Filters out suspicious times (midnight, exact hours/half-hours)
# OPTIMIZED: Streams changes to file instead of accumulating in memory

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $null
    $previousForeground = $null
    $previousBackground = $null

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        if ($NoNewline -and $Host -and $Host.UI) {
            $Host.UI.Write($Message)
        } else {
            Write-Information -MessageData $Message
        }
    } catch {
        Write-Information -MessageData $Message
        Write-Verbose "Write-Console fallback: $($_.Exception.Message)"
    } finally {
        if ($rawUI -and $null -ne $previousForeground) {
            try {
                $rawUI.ForegroundColor = $previousForeground
            } catch {
                Write-Verbose "Unable to reset foreground color: $($_.Exception.Message)"
            }
        }

        if ($rawUI -and $PSBoundParameters.ContainsKey('BackgroundColor') -and $null -ne $previousBackground) {
            try {
                $rawUI.BackgroundColor = $previousBackground
            } catch {
                Write-Verbose "Unable to reset background color: $($_.Exception.Message)"
            }
        }
    }
}

param(
    [string]$Path = "D:\Mylio",
    [switch]$DryRun,
    [switch]$Verbose
)

if (-not $PSBoundParameters.ContainsKey('DryRun')) {
    $DryRun = $true
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Bidirectional Timestamp Sync" -ForegroundColor Cyan
Write-Console "  (Memory Optimized)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "MODE: DRY RUN (no changes will be made)" -ForegroundColor Yellow
    Write-Console "Run with -DryRun:`$false to apply changes`n" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - Files and EXIF will be modified!" -ForegroundColor Red
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

# Function to check if time is suspicious
function Test-SuspiciousTime {
    param([DateTime]$Date)

    # Check for midnight (00:00:00)
    if ($Date.Hour -eq 0 -and $Date.Minute -eq 0 -and $Date.Second -eq 0) {
        return $true
    }

    # Check for exact hours (HH:00:00)
    if ($Date.Minute -eq 0 -and $Date.Second -eq 0) {
        return $true
    }

    # Check for exact half-hours (HH:30:00)
    if ($Date.Minute -eq 30 -and $Date.Second -eq 0) {
        return $true
    }

    return $false
}

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
    AllSuspicious = 0
    AlreadySynced = 0
}

$startTime = Get-Date

# MEMORY OPTIMIZATION: Keep only last 20 changes for console display
$recentChanges = @()
$maxRecentChanges = 20

# MEMORY OPTIMIZATION: Initialize report file immediately
$reportPath = "$PSScriptRoot\bidirectional-sync-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$reportHeader = @"
Bidirectional Timestamp Sync Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Mode: $(if ($DryRun) { "DRY RUN" } else { "LIVE" })

========================================
SUSPICIOUS TIME DETECTION
========================================

The following times are flagged as suspicious:
- Midnight (00:00:00)
- Exact hours (HH:00:00)
- Exact half-hours (HH:30:00)

These are often default values or manual edits.
Non-suspicious timestamps are preferred when available.

========================================
CHANGES (streaming to file as processed)
========================================

"@

$reportHeader | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "Processing files..." -ForegroundColor Cyan
Write-Console "This may take several minutes...`n" -ForegroundColor Gray
Write-Console "Report file: $reportPath`n" -ForegroundColor Gray

foreach ($file in $files) {
    $stats.Processed++

    if ($stats.Processed % 100 -eq 0) {
        $percentComplete = [math]::Round(($stats.Processed / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $stats.Processed * $totalFiles
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "`rProgress: $($stats.Processed) / $totalFiles ($percentComplete%) - Updated: $($stats.Updated) - ETA: $($remaining.ToString('hh\:mm\:ss'))" -NoNewline -ForegroundColor Yellow

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        if ($stats.Processed % 1000 -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    try {
        # Get EXIF date fields
        $exifJson = & $exiftoolPath -j -DateTimeOriginal -CreateDate -ModifyDate -MediaCreateDate -DateCreated -DigitalCreationDate $file.FullName 2>$null | ConvertFrom-Json

        if (-not $exifJson) {
            $stats.Errors++
            continue
        }

        $exifData = $exifJson[0]

        # Collect all timestamps (EXIF + File)
        $allTimestamps = @()

        # Add EXIF dates
        $exifFields = @('DateTimeOriginal', 'CreateDate', 'ModifyDate', 'MediaCreateDate', 'DateCreated', 'DigitalCreationDate')
        foreach ($field in $exifFields) {
            $dateString = $exifData.$field
            if ($dateString) {
                try {
                    $parsedDate = [DateTime]::ParseExact($dateString, 'yyyy:MM:dd HH:mm:ss', $null)

                    # Validate date is reasonable
                    if ($parsedDate -lt (Get-Date) -and $parsedDate -gt (Get-Date -Year 1990 -Month 1 -Day 1)) {
                        $isSuspicious = Test-SuspiciousTime -Date $parsedDate
                        $allTimestamps += @{
                            Source = "EXIF:$field"
                            Date = $parsedDate
                            Suspicious = $isSuspicious
                        }
                    }
                } catch {
                    Write-Verbose "Skipping invalid $field timestamp '$dateString' in $($file.FullName): $($_.Exception.Message)"
                }
            }
        }

        # Add file timestamps
        $fileTimestamps = @(
            @{ Source = "File:CreationTime"; Date = $file.CreationTime },
            @{ Source = "File:LastWriteTime"; Date = $file.LastWriteTime },
            @{ Source = "File:LastAccessTime"; Date = $file.LastAccessTime }
        )

        foreach ($ts in $fileTimestamps) {
            $date = $ts.Date
            # Validate date is reasonable
            if ($date -lt (Get-Date) -and $date -gt (Get-Date -Year 1990 -Month 1 -Day 1)) {
                $isSuspicious = Test-SuspiciousTime -Date $date
                $allTimestamps += @{
                    Source = $ts.Source
                    Date = $date
                    Suspicious = $isSuspicious
                }
            }
        }

        if ($allTimestamps.Count -eq 0) {
            # No valid timestamps found
            $stats.Skipped++
            continue
        }

        # Filter out suspicious timestamps first
        $validTimestamps = $allTimestamps | Where-Object { -not $_.Suspicious }

        if ($validTimestamps.Count -eq 0) {
            # All timestamps are suspicious - use them anyway but flag it
            $validTimestamps = $allTimestamps
            $usingSuspicious = $true
            $stats.AllSuspicious++
        } else {
            $usingSuspicious = $false
        }

        # Find oldest timestamp
        $oldestTimestamp = ($validTimestamps | Sort-Object { $_.Date } | Select-Object -First 1)

        # Check if file and EXIF are already in sync with oldest timestamp
        $fileTimestamp = $file.LastWriteTime
        $timeDifference = [Math]::Abs(($oldestTimestamp.Date - $fileTimestamp).TotalSeconds)

        # Get current EXIF DateTimeOriginal for comparison
        $currentExifDate = $null
        if ($exifData.DateTimeOriginal) {
            try {
                $currentExifDate = [DateTime]::ParseExact($exifData.DateTimeOriginal, 'yyyy:MM:dd HH:mm:ss', $null)
            } catch {
                Write-Verbose "Unable to parse DateTimeOriginal for $($file.FullName): $($_.Exception.Message)"
            }
        }

        $exifTimeDifference = if ($currentExifDate) {
            [Math]::Abs(($oldestTimestamp.Date - $currentExifDate).TotalSeconds)
        } else {
            999999  # Large number to indicate missing EXIF
        }

        # Skip if both file and EXIF are already synced (within 1 second)
        if ($timeDifference -le 1 -and $exifTimeDifference -le 1) {
            $stats.AlreadySynced++
            continue
        }

        # Format date for EXIF
        $exifDateString = $oldestTimestamp.Date.ToString('yyyy:MM:dd HH:mm:ss')

        $change = [PSCustomObject]@{
            File = $file.FullName
            OldestTimestamp = $oldestTimestamp.Date
            Source = $oldestTimestamp.Source
            Suspicious = if ($usingSuspicious) { "Yes (all timestamps suspicious)" } else { "No" }
            CurrentFileTime = $fileTimestamp
            CurrentExifTime = if ($currentExifDate) { $currentExifDate.ToString() } else { "None" }
            FileDiffSeconds = [math]::Round($timeDifference, 0)
            ExifDiffSeconds = [math]::Round($exifTimeDifference, 0)
        }

        # MEMORY OPTIMIZATION: Stream to file immediately, don't accumulate
        $change | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
        "" | Out-File -FilePath $reportPath -Append -Encoding UTF8

        # MEMORY OPTIMIZATION: Keep only last 20 for console display
        $recentChanges += $change
        if ($recentChanges.Count -gt $maxRecentChanges) {
            $recentChanges = $recentChanges | Select-Object -Last $maxRecentChanges
        }

        if (-not $DryRun) {
            # Update EXIF data first
            $exifToolArgs = @(
                "-DateTimeOriginal=$exifDateString",
                "-CreateDate=$exifDateString",
                "-ModifyDate=$exifDateString",
                "-overwrite_original",
                $file.FullName
            )

            $result = & $exiftoolPath $exifToolArgs 2>&1

            if ($LASTEXITCODE -ne 0) {
                $stats.Errors++
                if ($Verbose) {
                    Write-Console "`n`nError updating: $($file.Name)" -ForegroundColor Red
                    Write-Console "  $result" -ForegroundColor Gray
                }
                continue
            }

            # Update file timestamps AFTER EXIF write (ExifTool modifies LastWriteTime when writing)
            $file.Refresh()  # Refresh file object to get updated timestamps
            $file.LastWriteTime = $oldestTimestamp.Date
            $file.CreationTime = $oldestTimestamp.Date
            $file.LastAccessTime = $oldestTimestamp.Date
        }

        $stats.Updated++

        if ($Verbose) {
            Write-Console "`n`nFile: $($file.Name)" -ForegroundColor White
            Write-Console "  Oldest timestamp: $($oldestTimestamp.Date) (from $($oldestTimestamp.Source))" -ForegroundColor Green
            if ($usingSuspicious) {
                Write-Console "  WARNING: All timestamps are suspicious!" -ForegroundColor Yellow
            }
            Write-Console "  Current file time: $fileTimestamp" -ForegroundColor Cyan
            Write-Console "  Current EXIF time: $($change.CurrentExifTime)" -ForegroundColor Cyan
        }

    } catch {
        $stats.Errors++
        $errorMessage = $_.Exception.Message
        Write-Console "`nError processing: $($file.FullName) - $errorMessage" -ForegroundColor Red
        if ($Verbose) {
            Write-Console "  $($_.Exception)" -ForegroundColor DarkGray
        }
    }
}

Write-Console "`r`n`n" # Clear progress line

# Generate Summary
$elapsed = (Get-Date) - $startTime

# Write summary to beginning of report file
$summaryReport = @"
========================================
SUMMARY
========================================

Total files processed: $($stats.Processed)
Files synchronized: $($stats.Updated)
Files already in sync: $($stats.AlreadySynced)
Files with all suspicious timestamps: $($stats.AllSuspicious)
Files skipped (no valid timestamps): $($stats.Skipped)
Errors: $($stats.Errors)

Processing time: $($elapsed.ToString('hh\:mm\:ss'))

"@

# Read existing report, prepend summary
$existingReport = Get-Content -Path $reportPath -Raw -Encoding UTF8
$finalReport = $reportHeader + $summaryReport + ($existingReport -replace [regex]::Escape($reportHeader), '')
$finalReport | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Total files processed: $($stats.Processed)" -ForegroundColor White
Write-Console "Files synchronized: $($stats.Updated)" -ForegroundColor $(if ($stats.Updated -gt 0) { "Green" } else { "Gray" })
Write-Console "Files already in sync: $($stats.AlreadySynced)" -ForegroundColor Gray
Write-Console "Files with all suspicious timestamps: $($stats.AllSuspicious)" -ForegroundColor Yellow
Write-Console "Files skipped (no valid timestamps): $($stats.Skipped)" -ForegroundColor Yellow
Write-Console "Errors: $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
Write-Console "`nProcessing time: $($elapsed.ToString('hh\:mm\:ss'))`n" -ForegroundColor White

if ($DryRun -and $stats.Updated -gt 0) {
    Write-Console "This was a DRY RUN - no files were modified." -ForegroundColor Yellow
    Write-Console "Run with -DryRun:`$false to apply these changes.`n" -ForegroundColor Yellow
}

# Show sample changes (last 20 in memory)
if ($recentChanges.Count -gt 0) {
    Write-Console "`n========================================" -ForegroundColor Cyan
    Write-Console "  Recent Changes (last $($recentChanges.Count))" -ForegroundColor Cyan
    Write-Console "========================================`n" -ForegroundColor Cyan

    $recentChanges | Format-Table File, OldestTimestamp, Source, Suspicious, FileDiffSeconds, ExifDiffSeconds -AutoSize
}

Write-Console "`nDetailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green

if (-not $DryRun -and $stats.Updated -gt 0) {
    Write-Console "`nIMPORTANT: Files have been modified!" -ForegroundColor Yellow
    Write-Console "Both file timestamps AND EXIF data are now synchronized." -ForegroundColor White
    Write-Console "All timestamps set to the oldest valid, non-suspicious timestamp.`n" -ForegroundColor White
}


