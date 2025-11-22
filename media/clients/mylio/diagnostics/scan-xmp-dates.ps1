# Simple XMP Date Scanner for Mylio
# Finds XMP files with dates that don't match the filename

param(
    [string]$MylioPath = "D:\Mylio"
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
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "=== Mylio XMP Date Scanner ===" -ForegroundColor Cyan
Write-Console "Scanning: $MylioPath" -ForegroundColor White
Write-Console ""

Write-Console "Finding all XMP files..." -ForegroundColor Yellow
$xmpFiles = Get-ChildItem -Path $MylioPath -Filter "*.xmp" -Recurse -File
Write-Console "Found $($xmpFiles.Count) XMP files" -ForegroundColor Cyan
Write-Console ""

$incorrectDates = @()
$orphaned = @()
$counter = 0

Write-Console "Scanning for date mismatches..." -ForegroundColor Yellow

foreach ($xmp in $xmpFiles) {
    $counter++
    if ($counter % 500 -eq 0) {
        Write-Console "  Processed $counter / $($xmpFiles.Count)..." -ForegroundColor Gray
    }

    $baseName = $xmp.BaseName
    $dir = $xmp.Directory

    # Check for matching image file
    $imageFile = $null
    $extensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.mp4', '.mov', '.avi', '.heic')

    foreach ($ext in $extensions) {
        $testPath = Join-Path $dir "$baseName$ext"
        if (Test-Path $testPath) {
            $imageFile = $testPath
            break
        }
    }

    if (-not $imageFile) {
        $orphaned += $xmp.FullName
        continue
    }

    # Check if filename matches YYYY-MM-DD pattern
    if ($baseName -match '^(\d{4})-(\d{2})-(\d{2})-\d+$') {
        $fileDate = "$($Matches[1])-$($Matches[2])-$($Matches[3])"

        # Read XMP date
        $xmpDate = & $exiftoolPath -s -s -s -XMP:DateTimeOriginal $xmp.FullName 2>$null

        if ($xmpDate -and $xmpDate -match '^(\d{4})-(\d{2})-(\d{2})') {
            $xmpDatePart = "$($Matches[1])-$($Matches[2])-$($Matches[3])"

            if ($fileDate -ne $xmpDatePart) {
                $incorrectDates += [PSCustomObject]@{
                    XMPFile = $xmp.FullName
                    ImageFile = $imageFile
                    BaseName = $baseName
                    FileDate = $fileDate
                    XMPDate = $xmpDatePart
                    FullXMPDate = $xmpDate
                }
            }
        }
    }
}

Write-Console ""
Write-Console "=== Results ===" -ForegroundColor Green
Write-Console "Total XMP files: $($xmpFiles.Count)" -ForegroundColor White
Write-Console "Incorrect dates: $($incorrectDates.Count)" -ForegroundColor Yellow
Write-Console "Orphaned XMP files: $($orphaned.Count)" -ForegroundColor Yellow
Write-Console ""

if ($incorrectDates.Count -gt 0) {
    Write-Console "Files with incorrect dates:" -ForegroundColor Yellow
    foreach ($item in $incorrectDates) {
        Write-Console "  $($item.BaseName)" -ForegroundColor Gray
        Write-Console "    Filename: $($item.FileDate) | XMP: $($item.XMPDate)" -ForegroundColor DarkGray
    }
}

if ($orphaned.Count -gt 0) {
    Write-Console ""
    Write-Console "Orphaned XMP files (first 20):" -ForegroundColor Yellow
    $orphaned | Select-Object -First 20 | ForEach-Object {
        Write-Console "  $_" -ForegroundColor Gray
    }
    if ($orphaned.Count -gt 20) {
        Write-Console "  ... and $($orphaned.Count - 20) more" -ForegroundColor DarkGray
    }
}

# Save results
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$reportPath = "C:\Users\josep\Documents\dev\photos\mylio\xmp-scan-$timestamp.txt"

$report = @"
=== Mylio XMP Date Scan Report ===
Generated: $(Get-Date)
Path: $MylioPath

Total XMP files: $($xmpFiles.Count)
Incorrect dates: $($incorrectDates.Count)
Orphaned XMP files: $($orphaned.Count)

=== Files with Incorrect Dates ===

"@

foreach ($item in $incorrectDates) {
    $report += "`n$($item.BaseName)"
    $report += "`n  XMP: $($item.XMPFile)"
    $report += "`n  Image: $($item.ImageFile)"
    $report += "`n  Filename Date: $($item.FileDate)"
    $report += "`n  XMP Date: $($item.XMPDate)"
    $report += "`n  Full XMP Date: $($item.FullXMPDate)"
    $report += "`n"
}

if ($orphaned.Count -gt 0) {
    $report += "`n`n=== Orphaned XMP Files ===`n`n"
    foreach ($orphan in $orphaned) {
        $report += "$orphan`n"
    }
}

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Console ""
Write-Console "Report saved: $reportPath" -ForegroundColor Cyan

# Return objects for further processing
return [PSCustomObject]@{
    IncorrectDates = $incorrectDates
    Orphaned = $orphaned
}
