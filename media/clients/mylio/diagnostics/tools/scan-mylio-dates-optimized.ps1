# ============================================================================
# Mylio Folder - Complete Date Anomaly Scan - Memory Optimized
# ============================================================================
# This script scans all photos and videos in the Mylio folder and checks
# for date anomalies including 1907 dates, 1980 dates, very old dates,
# and future dates.
#
# OPTIMIZED: Streams results to file instead of accumulating in memory
# Date: November 11, 2025
# ============================================================================

#Requires -Version 5.1

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$ErrorActionPreference = "Continue"

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

# Configuration
$mylioPath = "D:\Mylio"
$outputPath = "$env:USERPROFILE\Documents\dev\mylio-date-scan-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# File extensions to scan
$imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tiff', '*.tif', '*.heic', '*.heif', '*.webp', '*.raw', '*.cr2', '*.nef', '*.arw', '*.dng')
$videoExtensions = @('*.mp4', '*.mov', '*.avi', '*.mkv', '*.m2ts', '*.mpg', '*.mpeg', '*.mts', '*.3gp', '*.wmv', '*.flv', '*.webm', '*.m4v')

# Color functions
function Write-Success { param($Message) Write-Console $Message -ForegroundColor Green }
function Write-Warning2 { param($Message) Write-Console $Message -ForegroundColor Yellow }
function Write-Error2 { param($Message) Write-Console $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Console $Message -ForegroundColor Cyan }

# Date thresholds
$oldDateThreshold = Get-Date "1990-01-01"
$today = Get-Date
$futureThreshold = $today.AddDays(1)

# MEMORY OPTIMIZATION: Use counters instead of arrays
$totalImages = 0
$totalVideos = 0
$anomalyCount = @{
    Count1907 = 0
    Count1980 = 0
    CountOld = 0
    CountFuture = 0
}

Write-Console "`n============================================================================" -ForegroundColor Cyan
Write-Console "  MYLIO FOLDER - COMPLETE DATE ANOMALY SCAN (Memory Optimized)" -ForegroundColor Cyan
Write-Console "============================================================================`n" -ForegroundColor Cyan

# Check if Mylio path exists
if (-not (Test-Path $mylioPath)) {
    Write-Error2 "✗ Mylio folder not found: $mylioPath"
    exit 1
}

Write-Success "Mylio folder found: $mylioPath`n"

# Start logging
"Mylio Date Anomaly Scan Report (Memory Optimized)" | Out-File $outputPath
"Scan Date: $(Get-Date)" | Out-File $outputPath -Append
"Location: $mylioPath" | Out-File $outputPath -Append
"============================================================================`n" | Out-File $outputPath -Append

$startTime = Get-Date

# ============================================================================
# Scan Images
# ============================================================================

Write-Info "Scanning image files..."
"SCANNING IMAGE FILES" | Out-File $outputPath -Append
"============================================================================`n" | Out-File $outputPath -Append

$imageFiles = Get-ChildItem -Path $mylioPath -Recurse -File -Include $imageExtensions -ErrorAction SilentlyContinue
$totalImages = $imageFiles.Count

Write-Console "Found $totalImages image files to scan`n" -ForegroundColor White

$processed = 0
foreach ($file in $imageFiles) {
    $processed++

    if ($processed % 1000 -eq 0) {
        $percentComplete = [math]::Round(($processed / $totalImages) * 100, 1)
        Write-Progress -Activity "Scanning images" -Status "Processing $processed of $totalImages ($percentComplete%)" -PercentComplete $percentComplete

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

    try {
        $modifiedDate = $file.LastWriteTime

        # Check for 1907 dates
        if ($modifiedDate.Year -eq 1907) {
            $anomalyCount.Count1907++

            # MEMORY OPTIMIZATION: Stream to file immediately
            $entry = "[$($processed)] [Image] 1907 DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for 1980 dates
        elseif ($modifiedDate.Year -eq 1980 -and $modifiedDate.Month -eq 1 -and $modifiedDate.Day -eq 1) {
            $anomalyCount.Count1980++

            $entry = "[$($processed)] [Image] 1980 DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for other old dates (before 1990, excluding 1907/1980)
        elseif ($modifiedDate -lt $oldDateThreshold -and $modifiedDate.Year -ne 1907 -and -not ($modifiedDate.Year -eq 1980 -and $modifiedDate.Month -eq 1 -and $modifiedDate.Day -eq 1)) {
            $anomalyCount.CountOld++

            $entry = "[$($processed)] [Image] OLD DATE (before 1990)`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for future dates
        elseif ($modifiedDate -gt $futureThreshold) {
            $anomalyCount.CountFuture++

            $entry = "[$($processed)] [Image] FUTURE DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
    }
    catch {
        Write-Verbose "Skipping image file $($file.FullName) due to access error: $($_.Exception.Message)"
    }
}

Write-Progress -Activity "Scanning images" -Completed
Write-Success "Completed scanning $totalImages image files`n"

# ============================================================================
# Scan Videos
# ============================================================================

Write-Info "Scanning video files..."
"SCANNING VIDEO FILES" | Out-File $outputPath -Append
"============================================================================`n" | Out-File $outputPath -Append

$videoFiles = Get-ChildItem -Path $mylioPath -Recurse -File -Include $videoExtensions -ErrorAction SilentlyContinue
$totalVideos = $videoFiles.Count

Write-Console "Found $totalVideos video files to scan`n" -ForegroundColor White

$processed = 0
foreach ($file in $videoFiles) {
    $processed++

    if ($processed % 500 -eq 0) {
        $percentComplete = [math]::Round(($processed / $totalVideos) * 100, 1)
        Write-Progress -Activity "Scanning videos" -Status "Processing $processed of $totalVideos ($percentComplete%)" -PercentComplete $percentComplete

        # MEMORY OPTIMIZATION: Force garbage collection every 500 video files
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

    try {
        $modifiedDate = $file.LastWriteTime

        # Check for 1907 dates
        if ($modifiedDate.Year -eq 1907) {
            $anomalyCount.Count1907++

            $entry = "[$($processed)] [Video] 1907 DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for 1980 dates
        elseif ($modifiedDate.Year -eq 1980 -and $modifiedDate.Month -eq 1 -and $modifiedDate.Day -eq 1) {
            $anomalyCount.Count1980++

            $entry = "[$($processed)] [Video] 1980 DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for other old dates (before 1990, excluding 1907/1980)
        elseif ($modifiedDate -lt $oldDateThreshold -and $modifiedDate.Year -ne 1907 -and -not ($modifiedDate.Year -eq 1980 -and $modifiedDate.Month -eq 1 -and $modifiedDate.Day -eq 1)) {
            $anomalyCount.CountOld++

            $entry = "[$($processed)] [Video] OLD DATE (before 1990)`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
        # Check for future dates
        elseif ($modifiedDate -gt $futureThreshold) {
            $anomalyCount.CountFuture++

            $entry = "[$($processed)] [Video] FUTURE DATE`n  Path: $($file.FullName)`n  Modified: $modifiedDate`n`n"
            $entry | Out-File -FilePath $outputPath -Append -Encoding UTF8
        }
    }
    catch {
        Write-Verbose "Skipping video file $($file.FullName) due to access error: $($_.Exception.Message)"
    }
}

Write-Progress -Activity "Scanning videos" -Completed
Write-Success "Completed scanning $totalVideos video files`n"

# ============================================================================
# Generate Report
# ============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Console "`n============================================================================" -ForegroundColor Cyan
Write-Console "  SCAN RESULTS" -ForegroundColor Cyan
Write-Console "============================================================================`n" -ForegroundColor Cyan

# Summary
$totalFiles = $totalImages + $totalVideos
$totalAnomalies = $anomalyCount.Count1907 + $anomalyCount.Count1980 + $anomalyCount.CountOld + $anomalyCount.CountFuture

Write-Console "Files Scanned:" -ForegroundColor White
Write-Console "  Images:  $totalImages" -ForegroundColor Gray
Write-Console "  Videos:  $totalVideos" -ForegroundColor Gray
Write-Console "  Total:   $totalFiles" -ForegroundColor White
Write-Console ""

# Append summary to report
$summary = @"

SCAN SUMMARY
============================================================================
Total images scanned: $totalImages
Total videos scanned: $totalVideos
Total files scanned: $totalFiles
Total anomalies found: $totalAnomalies

"@
$summary | Out-File -FilePath $outputPath -Append -Encoding UTF8

# Report anomalies
Write-Console "Anomalies Found:" -ForegroundColor White

if ($anomalyCount.Count1907 -gt 0) {
    Write-Error2 "  1907 Dates:   $($anomalyCount.Count1907) files"
} else {
    Write-Success "  1907 Dates:   0 files (none detected)"
}

if ($anomalyCount.Count1980 -gt 0) {
    Write-Error2 "  1980 Dates:   $($anomalyCount.Count1980) files"
} else {
    Write-Success "  1980 Dates:   0 files (none detected)"
}

if ($anomalyCount.CountOld -gt 0) {
    Write-Warning2 "  Old Dates:    $($anomalyCount.CountOld) files (before 1990)"
} else {
    Write-Success "  Old Dates:    0 files (none detected)"
}

if ($anomalyCount.CountFuture -gt 0) {
    Write-Warning2 "  Future Dates: $($anomalyCount.CountFuture) files"
} else {
    Write-Success "  Future Dates: 0 files (none detected)"
}

Write-Console ""
Write-Console "Scan Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Console "Report saved:  $outputPath" -ForegroundColor White

# Append anomaly counts to report
$anomalySummary = @"

Anomaly Breakdown:
  1907 Dates:   $($anomalyCount.Count1907) files
  1980 Dates:   $($anomalyCount.Count1980) files
  Old Dates:    $($anomalyCount.CountOld) files (before 1990)
  Future Dates: $($anomalyCount.CountFuture) files

============================================================================
Scan completed: $endTime
Duration: $($duration.ToString('hh\:mm\:ss'))
"@
$anomalySummary | Out-File -FilePath $outputPath -Append -Encoding UTF8

# Final summary
Write-Console "`n============================================================================" -ForegroundColor Cyan
Write-Console "  CONCLUSION" -ForegroundColor Cyan
Write-Console "============================================================================`n" -ForegroundColor Cyan

if ($totalAnomalies -eq 0) {
    Write-Success "NO DATE ANOMALIES FOUND!"
    Write-Console "`nAll $totalFiles files have valid dates. Your Mylio library is clean!`n" -ForegroundColor Green
} else {
    Write-Warning2 "$totalAnomalies date anomalies detected"
    Write-Console "`nReview the report for details: $outputPath`n" -ForegroundColor Yellow
}

Write-Console "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")









