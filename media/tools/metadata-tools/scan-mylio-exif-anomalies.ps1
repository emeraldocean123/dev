# Scan Mylio Photos/Videos for EXIF Anomalies - Memory Optimized
# Checks for: midnight times, missing GPS, date mismatches, etc.
# OPTIMIZED: Streams results to file instead of accumulating in memory

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
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
    [switch]$Verbose
)

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  EXIF Anomaly Scanner (Memory Optimized)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

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
Write-Console "Found $totalFiles media files to scan`n" -ForegroundColor White

# MEMORY OPTIMIZATION: Use counters instead of arrays
$anomalyCount = @{
    MidnightTimes = 0
    MissingDateTimeOriginal = 0
    MissingGPS = 0
    DateMismatch = 0
    FutureDates = 0
    VeryOldDates = 0
    ZeroGPS = 0
}

$processed = 0
$startTime = Get-Date

# MEMORY OPTIMIZATION: Initialize report file immediately
$reportPath = "$PSScriptRoot\mylio-exif-anomalies-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$reportHeader = @"
EXIF Anomaly Scan Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path

========================================
ANOMALIES (streaming to file)
========================================

"@

$reportHeader | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "Scanning files..." -ForegroundColor Cyan
Write-Console "This may take several minutes for $totalFiles files...`n" -ForegroundColor Gray

foreach ($file in $files) {
    $processed++

    if ($processed % 100 -eq 0) {
        $percentComplete = [math]::Round(($processed / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $processed * $totalFiles
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "`rProgress: $processed / $totalFiles ($percentComplete%) - ETA: $($remaining.ToString('hh\:mm\:ss'))" -NoNewline -ForegroundColor Yellow

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        if ($processed % 1000 -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    # Get EXIF data using exiftool
    $exifJson = & $exiftoolPath -j -DateTimeOriginal -CreateDate -GPSLatitude -GPSLongitude -GPSPosition -FileModifyDate $file.FullName 2>$null | ConvertFrom-Json

    if (-not $exifJson) { continue }

    $exifData = $exifJson[0]

    # Extract dates
    $dateTimeOriginal = $exifData.DateTimeOriginal
    $createDate = $exifData.CreateDate
    # Check 1: Missing DateTimeOriginal
    if (-not $dateTimeOriginal) {
        $anomalyCount.MissingDateTimeOriginal++

        # MEMORY OPTIMIZATION: Stream to file immediately
        $entry = [PSCustomObject]@{
            Type = "MissingDateTimeOriginal"
            File = $file.FullName
            FileModifyDate = $file.LastWriteTime
            CreateDate = $createDate
        }
        $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
        "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }

    # Check 2: Midnight times (00:00:00)
    if ($dateTimeOriginal -match '\s00:00:00') {
        $anomalyCount.MidnightTimes++

        $entry = [PSCustomObject]@{
            Type = "MidnightTime"
            File = $file.FullName
            DateTimeOriginal = $dateTimeOriginal
            FileModifyDate = $file.LastWriteTime
        }
        $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
        "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }

    # Check 3-5: Date anomalies
    if ($dateTimeOriginal) {
        try {
            $exifDate = [DateTime]::ParseExact($dateTimeOriginal, 'yyyy:MM:dd HH:mm:ss', $null)

            # Check 3: Future dates
            if ($exifDate -gt (Get-Date)) {
                $anomalyCount.FutureDates++

                $entry = [PSCustomObject]@{
                    Type = "FutureDate"
                    File = $file.FullName
                    DateTimeOriginal = $dateTimeOriginal
                    FileModifyDate = $file.LastWriteTime
                }
                $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
                "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            }

            # Check 4: Very old dates (before 2000)
            if ($exifDate -lt (Get-Date -Year 2000 -Month 1 -Day 1)) {
                $anomalyCount.VeryOldDates++

                $entry = [PSCustomObject]@{
                    Type = "VeryOldDate"
                    File = $file.FullName
                    DateTimeOriginal = $dateTimeOriginal
                    FileModifyDate = $file.LastWriteTime
                }
                $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
                "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            }

            # Check 5: Date mismatch (EXIF vs File timestamp > 1 day difference)
            $dateDiff = [Math]::Abs(($exifDate - $file.LastWriteTime).TotalDays)
            if ($dateDiff -gt 1) {
                $anomalyCount.DateMismatch++

                $entry = [PSCustomObject]@{
                    Type = "DateMismatch"
                    File = $file.FullName
                    DateTimeOriginal = $dateTimeOriginal
                    FileModifyDate = $file.LastWriteTime
                    DifferenceInDays = [math]::Round($dateDiff, 1)
                }
                $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
                "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            }
        } catch {
            Write-Verbose "Skipping invalid date comparison for $($file.FullName): $($_.Exception.Message)"
            continue
        }
    }

    # Check 6-7: GPS data (for photos only, not videos)
    if ($file.Extension -match '\.(jpg|jpeg|heic|heif|png)$') {
        $gpsLat = $exifData.GPSLatitude
        $gpsLon = $exifData.GPSLongitude

        if (-not $gpsLat -or -not $gpsLon) {
            $anomalyCount.MissingGPS++

            $entry = [PSCustomObject]@{
                Type = "MissingGPS"
                File = $file.FullName
                DateTimeOriginal = $dateTimeOriginal
            }
            $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
        } elseif ($gpsLat -eq '0' -and $gpsLon -eq '0') {
            # Check 7: Zero GPS coordinates (0,0 is in the Atlantic Ocean)
            $anomalyCount.ZeroGPS++

            $entry = [PSCustomObject]@{
                Type = "ZeroGPS"
                File = $file.FullName
                GPS = "$gpsLat, $gpsLon"
                DateTimeOriginal = $dateTimeOriginal
            }
            $entry | Format-List | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
        }
    }
}

Write-Console "`r`n`n" # Clear progress line

$elapsed = (Get-Date) - $startTime

# Generate Summary Report
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Scan Complete - Results" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Total files scanned: $totalFiles" -ForegroundColor White
Write-Console "Scan duration: $($elapsed.ToString('hh\:mm\:ss'))`n" -ForegroundColor White

Write-Console "Anomalies Found:`n" -ForegroundColor Yellow

# Summary
$totalAnomalies = 0
foreach ($category in $anomalyCount.Keys) {
    $count = $anomalyCount[$category]
    $totalAnomalies += $count

    $color = if ($count -gt 0) { "Yellow" } else { "Green" }
    $status = if ($count -gt 0) { "FOUND" } else { "None" }

    Write-Console "  $category`: " -NoNewline -ForegroundColor White
    Write-Console "$count files $status" -ForegroundColor $color
}

Write-Console "`nTotal anomalies: $totalAnomalies files`n" -ForegroundColor $(if ($totalAnomalies -gt 0) { "Yellow" } else { "Green" })

# Append summary to report
$summary = @"

========================================
SUMMARY
========================================

Total files scanned: $totalFiles
Scan duration: $($elapsed.ToString('hh\:mm\:ss'))

Anomaly Counts:
"@

foreach ($category in $anomalyCount.Keys) {
    $summary += "`n  $category`: $($anomalyCount[$category]) files"
}

$summary += "`n`nTotal anomalies: $totalAnomalies files`n"

$summary | Out-File -FilePath $reportPath -Append -Encoding UTF8

Write-Console "`nDetailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green

