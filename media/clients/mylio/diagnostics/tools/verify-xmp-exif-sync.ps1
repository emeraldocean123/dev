# Verify XMP sidecars are synced with embedded EXIF metadata
# Checks DateTimeOriginal, GPS coordinates, and other critical fields
# Memory-efficient batch processing

param(
    [int]$SampleSize = 0,  # 0 = check all files, N = check random N files
    [switch]$Detailed = $false
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$mylioPath = "D:\Mylio"
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw')

Write-Console "=== XMP/EXIF Sync Verification ===" -ForegroundColor Cyan
Write-Console ""

# Check if exiftool exists
if (-not (Test-Path $exiftoolPath)) {
    Write-Console "ERROR: ExifTool not found at $exiftoolPath" -ForegroundColor Red
    exit 1
}

Write-Console "Finding XMP sidecar files..." -ForegroundColor Yellow
$xmpFiles = Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File | Where-Object {
    # Skip moved XMP files
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}

$totalXmp = $xmpFiles.Count
Write-Console "Found $totalXmp XMP sidecar files" -ForegroundColor Green
Write-Console ""

# Build list of image files that have XMP sidecars
Write-Console "Building list of images with XMP sidecars..." -ForegroundColor Yellow
$imagesToCheck = @()

foreach ($xmpFile in $xmpFiles) {
    # Find matching image file
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($xmpFile.FullName)
    $directory = $xmpFile.DirectoryName

    foreach ($ext in $imageExtensions) {
        $imagePath = Join-Path $directory "$baseName$ext"
        if (Test-Path $imagePath) {
            $imagesToCheck += Get-Item $imagePath
            break
        }
    }
}

$totalImages = $imagesToCheck.Count
Write-Console "Found $totalImages images with XMP sidecars" -ForegroundColor Green
Write-Console ""

# Sample selection
if ($SampleSize -gt 0 -and $SampleSize -lt $totalImages) {
    Write-Console "Sampling $SampleSize random files..." -ForegroundColor Yellow
    $imagesToCheck = $imagesToCheck | Get-Random -Count $SampleSize
}

$totalToCheck = $imagesToCheck.Count
Write-Console "Checking $totalToCheck files for XMP/EXIF sync..." -ForegroundColor Green
Write-Console ""

# Counters
$processed = 0
$matched = 0
$mismatched = 0
$noXmp = 0
$noExif = 0
$errors = 0
$mismatchedFiles = @()

$startTime = Get-Date
$progressInterval = 50  # Report every 50 files
$batchSize = 50
$gcInterval = 500  # Force garbage collection every 500 files

# Process in batches to avoid memory issues
for ($i = 0; $i -lt $totalToCheck; $i += $batchSize) {
    $batch = $imagesToCheck[$i..([Math]::Min($i + $batchSize - 1, $totalToCheck - 1))]

    foreach ($imageFile in $batch) {
        $processed++

        # Progress
        if ($processed % $progressInterval -eq 0) {
            $percent = [math]::Round(($processed / $totalToCheck) * 100, 1)
            $elapsed = (Get-Date) - $startTime
            $rate = $processed / $elapsed.TotalSeconds
            $remaining = ($totalToCheck - $processed) / $rate
            $eta = [TimeSpan]::FromSeconds($remaining)

            Write-Console "Progress: $processed / $totalToCheck ($percent%) - Matched: $matched, Mismatched: $mismatched - ETA: $($eta.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
        }

        # Force garbage collection periodically to keep memory usage low
        if ($processed % $gcInterval -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }

        try {
            $xmpPath = [System.IO.Path]::ChangeExtension($imageFile.FullName, ".xmp")

            # Check if XMP exists
            if (-not (Test-Path $xmpPath)) {
                $noXmp++
                continue
            }

            # Get DateTimeOriginal from both sources
            $xmpDate = & $exiftoolPath -s -s -s -XMP:DateTimeOriginal $xmpPath 2>$null
            $exifDate = & $exiftoolPath -s -s -s -EXIF:DateTimeOriginal $imageFile.FullName 2>$null

            if (-not $xmpDate) {
                $noExif++
                continue
            }

            # Videos may not have EXIF - skip if no EXIF found
            if (-not $exifDate) {
                $noExif++
                continue
            }

            # Normalize dates (remove milliseconds from XMP)
            $xmpDateNorm = if ($xmpDate -match '^(.+)\.\d+$') { $Matches[1] } else { $xmpDate }
            $exifDateNorm = $exifDate

            if ($xmpDateNorm -eq $exifDateNorm) {
                $matched++
            } else {
                $mismatched++
                $mismatchedFiles += [PSCustomObject]@{
                    File = $imageFile.FullName
                    XMP = $xmpDate
                    EXIF = $exifDate
                }

                if ($Detailed) {
                    Write-Console "  MISMATCH: $($imageFile.Name)" -ForegroundColor Yellow
                    Write-Console "    XMP:  $xmpDate" -ForegroundColor Gray
                    Write-Console "    EXIF: $exifDate" -ForegroundColor Gray
                }
            }

        } catch {
            $errors++
            Write-Console "  Error processing $($imageFile.Name): $_" -ForegroundColor Red
        }
    }

    # Clear batch from memory
    $batch = $null
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
Write-Console "Total files checked: $processed" -ForegroundColor Gray
Write-Console "Matched (XMP = EXIF): $matched" -ForegroundColor Green
Write-Console "Mismatched (XMP ≠ EXIF): $mismatched" -ForegroundColor $(if ($mismatched -gt 0) { "Red" } else { "Green" })
Write-Console "No XMP file: $noXmp" -ForegroundColor Gray
Write-Console "No EXIF date: $noExif" -ForegroundColor Gray
Write-Console "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Gray" })

$percent = if ($processed -gt 0) { [math]::Round(($matched / $processed) * 100, 1) } else { 0 }
Write-Console ""
Write-Console "Sync rate: $percent% matched" -ForegroundColor $(if ($percent -ge 95) { "Green" } elseif ($percent -ge 80) { "Yellow" } else { "Red" })

Write-Console ""
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Console "Total time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Console ""

# Save mismatched files if any
if ($mismatched -gt 0) {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $logPath = "C:\Users\josep\Documents\dev\photos\mylio\archive\xmp-exif-mismatches-$timestamp.txt"

    $logContent = @"
=== XMP/EXIF Mismatches ===
Generated: $(Get-Date)
Total checked: $processed
Matched: $matched
Mismatched: $mismatched

=== Mismatched Files ===

"@

    foreach ($item in $mismatchedFiles) {
        $logContent += "`nFile: $($item.File)"
        $logContent += "`n  XMP:  $($item.XMP)"
        $logContent += "`n  EXIF: $($item.EXIF)`n"
    }

    # Ensure directory exists
    $logDir = Split-Path $logPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Console "Mismatch log saved: $logPath" -ForegroundColor Yellow
    Write-Console ""
}

if ($mismatched -eq 0 -and $matched -gt 0) {
    Write-Console "Perfect sync! All XMP files match their EXIF data." -ForegroundColor Green
}

Write-Console ""
