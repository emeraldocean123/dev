# Find orphaned XMP files and search for their matching images anywhere in Mylio

param(
    [string]$ReportPath = "C:\Users\josep\Documents\dev\photos\mylio\xmp-scan-2025-11-12-173639.txt"
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
Write-Console "=== Orphaned XMP Image Finder ===" -ForegroundColor Cyan
Write-Console ""

# Read the report to get orphaned XMP files
$content = Get-Content $ReportPath -Raw
$orphanedSection = $content -split "=== Orphaned XMP Files ===" | Select-Object -Last 1

# Extract XMP file paths
$xmpFiles = @()
$orphanedSection -split "`n" | ForEach-Object {
    if ($_ -match '^(D:\\Mylio\\.+\.xmp)$') {
        $xmpFiles += $Matches[1]
    }
}

Write-Console "Found $($xmpFiles.Count) orphaned XMP files to check" -ForegroundColor Yellow
Write-Console ""

$found = @()
$notFound = @()
$counter = 0

foreach ($xmpPath in $xmpFiles) {
    $counter++
    if ($counter % 50 -eq 0) {
        Write-Console "Checked $counter / $($xmpFiles.Count)..." -ForegroundColor Gray
    }

    $xmpFile = Get-Item $xmpPath
    $baseName = $xmpFile.BaseName

    # Search for matching image file anywhere in Mylio
    $extensions = @('jpg', 'jpeg', 'png', 'gif', 'bmp', 'mp4', 'mov', 'avi', 'heic')
    $imageFound = $false

    foreach ($ext in $extensions) {
        $searchPattern = "$baseName.$ext"
        $matches = Get-ChildItem -Path "D:\Mylio" -Filter $searchPattern -Recurse -File -ErrorAction SilentlyContinue

        if ($matches) {
            $imageFound = $true
            foreach ($match in $matches) {
                $found += [PSCustomObject]@{
                    XMP = $xmpPath
                    Image = $match.FullName
                    XMPFolder = $xmpFile.Directory.FullName
                    ImageFolder = $match.Directory.FullName
                    Movable = ($xmpFile.Directory.FullName -ne $match.Directory.FullName)
                }
            }
            break
        }
    }

    if (-not $imageFound) {
        $notFound += $xmpPath
    }
}

Write-Console ""
Write-Console "=== Results ===" -ForegroundColor Green
Write-Console "Orphaned XMP files with matching images found elsewhere: $($found.Count)" -ForegroundColor Cyan
Write-Console "Truly orphaned (no image exists): $($notFound.Count)" -ForegroundColor Yellow
Write-Console ""

if ($found.Count -gt 0) {
    Write-Console "Files that can be reunited:" -ForegroundColor Green
    foreach ($item in $found) {
        Write-Console "  XMP: $($item.XMP)" -ForegroundColor Gray
        Write-Console "  Image: $($item.Image)" -ForegroundColor Gray
        if ($item.Movable) {
            Write-Console "  -> Can move XMP to: $($item.ImageFolder)" -ForegroundColor Yellow
        } else {
            Write-Console "  -> Already in same folder" -ForegroundColor Green
        }
        Write-Console ""
    }
}

Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  Reunitable: $($found.Count)" -ForegroundColor Green
Write-Console "  Truly orphaned: $($notFound.Count)" -ForegroundColor Yellow

# Save results
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$outputPath = "C:\Users\josep\Documents\dev\photos\mylio\orphaned-xmp-analysis-$timestamp.txt"

$report = @"
=== Orphaned XMP Analysis ===
Generated: $(Get-Date)

Total orphaned XMP files checked: $($xmpFiles.Count)
Files with matching images found: $($found.Count)
Truly orphaned (no image): $($notFound.Count)

=== Reunitable Files ===

"@

foreach ($item in $found) {
    $report += "`nXMP: $($item.XMP)"
    $report += "`nImage: $($item.Image)"
    $report += "`nXMP Folder: $($item.XMPFolder)"
    $report += "`nImage Folder: $($item.ImageFolder)"
    if ($item.Movable) {
        $report += "`nAction: Move XMP to image folder"
    } else {
        $report += "`nAction: Already in same folder (different issue)"
    }
    $report += "`n"
}

$report += "`n`n=== Truly Orphaned Files (No Image Exists) ===`n`n"
foreach ($path in $notFound) {
    $report += "$path`n"
}

$report | Out-File -FilePath $outputPath -Encoding UTF8
Write-Console ""
Write-Console "Report saved: $outputPath" -ForegroundColor Cyan

return [PSCustomObject]@{
    Reunitable = $found
    TrulyOrphaned = $notFound
}
