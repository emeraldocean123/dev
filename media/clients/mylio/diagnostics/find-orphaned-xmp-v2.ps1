# Find orphaned XMP files (XMP files without matching image files)
# Memory-efficient version for large photo libraries

param(
    [switch]$DeleteOrphans = $false,
    [string]$LogPath = "C:\Users\josep\Documents\dev\photos\mylio\archive\orphaned-xmp-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
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
$imageExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.heic', '.heif', '.mp4', '.mov', '.avi', '.mpg', '.mpeg', '.m4v', '.mkv', '.webp', '.cr2', '.nef', '.arw', '.dng', '.raw')

Write-Console "=== Orphaned XMP Finder v2 ===" -ForegroundColor Cyan
Write-Console ""

if ($DeleteOrphans) {
    Write-Console "DELETE MODE - Will delete orphaned XMP files" -ForegroundColor Red
    Write-Console ""
    $confirm = Read-Host "Are you sure? Type 'DELETE' to confirm"
    if ($confirm -ne "DELETE") {
        Write-Console "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Console ""
} else {
    Write-Console "SCAN MODE - Finding orphaned XMP files..." -ForegroundColor Yellow
    Write-Console ""
}

# Get all XMP files
Write-Console "Scanning for XMP files..." -ForegroundColor Gray
$xmpFiles = Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File
$totalXmp = $xmpFiles.Count

Write-Console "Found $totalXmp XMP files" -ForegroundColor Green
Write-Console ""

# Counters
$orphaned = 0
$matched = 0
$processed = 0
$deleted = 0
$orphanedFiles = @()

$startTime = Get-Date
$progressInterval = 1000

Write-Console "Checking for orphaned XMP files..." -ForegroundColor Green
Write-Console ""

foreach ($xmpFile in $xmpFiles) {
    $processed++

    # Progress
    if ($processed % $progressInterval -eq 0) {
        $percent = [math]::Round(($processed / $totalXmp) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $rate = $processed / $elapsed.TotalSeconds
        $remaining = ($totalXmp - $processed) / $rate
        $eta = [TimeSpan]::FromSeconds($remaining)

        Write-Console "Progress: $processed / $totalXmp ($percent%) - Orphaned: $orphaned - ETA: $($eta.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    }

    $baseName = $xmpFile.BaseName
    $directory = $xmpFile.DirectoryName
    $foundMatch = $false

    # Check for matching image in the same directory
    foreach ($ext in $imageExtensions) {
        $imagePath = Join-Path $directory "$baseName$ext"
        if (Test-Path $imagePath) {
            $foundMatch = $true
            $matched++
            break
        }
    }

    if (-not $foundMatch) {
        $orphaned++
        $orphanedFiles += $xmpFile.FullName

        if ($DeleteOrphans) {
            try {
                Remove-Item $xmpFile.FullName -Force
                $deleted++
            } catch {
                Write-Console "  Error deleting: $($xmpFile.FullName)" -ForegroundColor Red
            }
        }
    }
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
Write-Console "Total XMP files: $totalXmp" -ForegroundColor Gray
Write-Console "Matched (has image): $matched" -ForegroundColor Green
Write-Console "Orphaned (no image): $orphaned" -ForegroundColor $(if ($orphaned -gt 0) { "Yellow" } else { "Green" })

if ($DeleteOrphans) {
    Write-Console "Deleted: $deleted" -ForegroundColor $(if ($deleted -gt 0) { "Green" } else { "Gray" })
}

Write-Console ""
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Console "Total time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Console ""

# Save log
if ($orphaned -gt 0 -and -not $DeleteOrphans) {
    Write-Console "Saving orphaned XMP list to log..." -ForegroundColor Gray

    $logContent = @"
=== Orphaned XMP Files ===
Generated: $(Get-Date)
Total XMP files: $totalXmp
Matched: $matched
Orphaned: $orphaned

=== Orphaned Files ===

"@

    foreach ($file in $orphanedFiles) {
        $logContent += "$file`n"
    }

    # Ensure directory exists
    $logDir = Split-Path $LogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logContent | Out-File -FilePath $LogPath -Encoding UTF8
    Write-Console "Log saved: $LogPath" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "To delete orphaned XMP files, run:" -ForegroundColor Yellow
    Write-Console "  .\find-orphaned-xmp-v2.ps1 -DeleteOrphans" -ForegroundColor Gray
} elseif ($orphaned -eq 0) {
    Write-Console "No orphaned XMP files found! All XMP files have matching images." -ForegroundColor Green
}

Write-Console ""
