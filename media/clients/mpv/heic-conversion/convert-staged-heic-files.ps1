# Convert staged HEIC files to JPEG with full metadata preservation
# This script uses full paths to avoid PATH issues

param(
    [Parameter(Mandatory=$false)]
    [string]$StagingPath = "$env:USERPROFILE\Documents\heic-staging",

    [Parameter(Mandatory=$false)]
    [int]$Quality = 95,

    [Parameter(Mandatory=$false)]
    [switch]$DeleteOriginal = $false
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
# Tool paths
$magickPath = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  HEIC to JPEG Conversion" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Check if ImageMagick exists
if (-not (Test-Path $magickPath)) {
    Write-Console "Error: ImageMagick not found at: $magickPath" -ForegroundColor Red
    exit 1
}

# Check if ExifTool exists
if (-not (Test-Path $exiftoolPath)) {
    Write-Console "Error: ExifTool not found at: $exiftoolPath" -ForegroundColor Red
    Write-Console "Conversion will proceed but metadata will NOT be preserved!" -ForegroundColor Yellow
    $exiftoolPath = $null
}

# Check if staging folder exists
if (-not (Test-Path $StagingPath)) {
    Write-Console "Error: Staging folder not found: $StagingPath" -ForegroundColor Red
    exit 1
}

# Find HEIC files
Write-Console "[1/3] Searching for HEIC files in staging folder..." -ForegroundColor Yellow
$heicFiles = Get-ChildItem -Path $StagingPath -Filter "*.heic" -File

if ($heicFiles.Count -eq 0) {
    Write-Console "  No HEIC files found in staging folder." -ForegroundColor Yellow
    exit 0
}

$totalSize = ($heicFiles | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Console "  Found $($heicFiles.Count) HEIC files" -ForegroundColor Green
Write-Console "  Total size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Green
Write-Console "  Quality: $Quality%" -ForegroundColor Gray
Write-Console "  Metadata preservation: $(if ($exiftoolPath) { 'YES (ExifTool)' } else { 'NO' })" -ForegroundColor Gray

# Check for existing JPG files
$existingJpgs = Get-ChildItem -Path $StagingPath -Filter "*.jpg" -File
if ($existingJpgs.Count -gt 0) {
    Write-Console "`n  Warning: $($existingJpgs.Count) JPG files already exist in staging." -ForegroundColor Yellow
    Write-Console "  These files will be skipped." -ForegroundColor Gray
}

# Confirm
Write-Console "`n[2/3] Ready to convert $($heicFiles.Count) HEIC files to JPEG" -ForegroundColor Cyan
$confirm = Read-Host "  Proceed? (Y/N)"

if ($confirm -notmatch "^[Yy]") {
    Write-Console "`n  Cancelled by user.`n" -ForegroundColor Yellow
    exit 0
}

# Convert files
Write-Console "`n[3/3] Converting files..." -ForegroundColor Yellow
Write-Console ""

$converted = 0
$skipped = 0
$failed = 0
$startTime = Get-Date

foreach ($file in $heicFiles) {
    $outputPath = $file.FullName -replace '\.heic$', '.jpg'

    # Skip if JPG already exists
    if (Test-Path $outputPath) {
        $skipped++
        continue
    }

    $fileName = $file.Name
    Write-Console "  [$($converted + 1)/$($heicFiles.Count)] $fileName" -ForegroundColor Cyan -NoNewline

    try {
        # Step 1: Convert using ImageMagick
        $convertResult = & $magickPath convert $file.FullName -quality $Quality $outputPath 2>&1

        if (-not (Test-Path $outputPath)) {
            Write-Console " - FAILED (no output)" -ForegroundColor Red
            $failed++
            continue
        }

        # Step 2: Copy EXIF metadata using ExifTool (if available)
        if ($exiftoolPath) {
            $exifResult = & $exiftoolPath -TagsFromFile $file.FullName -All:All -overwrite_original $outputPath 2>&1 | Out-Null
        }

        # Step 3: Preserve file timestamps
        $jpgFile = Get-Item $outputPath
        $jpgFile.CreationTime = $file.CreationTime
        $jpgFile.LastWriteTime = $file.LastWriteTime
        $jpgFile.LastAccessTime = $file.LastAccessTime

        # Calculate sizes
        $heicSize = $file.Length / 1MB
        $jpgSize = $jpgFile.Length / 1MB
        $savings = if ($heicSize -gt 0) { [math]::Round((1 - ($jpgSize / $heicSize)) * 100, 1) } else { 0 }

        Write-Console " - OK" -ForegroundColor Green
        Write-Console "      HEIC: $([math]::Round($heicSize, 2)) MB → JPG: $([math]::Round($jpgSize, 2)) MB ($(if ($savings -lt 0) { '+' } else { '' })$savings%)" -ForegroundColor Gray

        # Delete original if requested
        if ($DeleteOriginal) {
            Remove-Item $file.FullName -Force
            Write-Console "      Deleted original HEIC file" -ForegroundColor DarkGray
        }

        $converted++
    }
    catch {
        Write-Console " - FAILED" -ForegroundColor Red
        Write-Console "      Error: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }

    # Progress update every 100 files
    if ($converted % 100 -eq 0) {
        $elapsed = (Get-Date) - $startTime
        $rate = $converted / $elapsed.TotalSeconds
        $remaining = ($heicFiles.Count - $converted) / $rate
        Write-Console ""
        Write-Console "  Progress: $converted/$($heicFiles.Count) files ($([math]::Round($rate, 1)) files/sec, ~$([math]::Round($remaining / 60, 1)) min remaining)" -ForegroundColor DarkCyan
        Write-Console ""
    }
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

# Summary
Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Conversion Complete!" -ForegroundColor Green
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "  Converted: $converted files" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Console "  Skipped: $skipped files (already existed)" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Console "  Failed: $failed files" -ForegroundColor Red
}

Write-Console ""
Write-Console "  Time taken: $([math]::Round($totalTime / 60, 1)) minutes" -ForegroundColor Gray
Write-Console "  Average: $([math]::Round($converted / $totalTime, 1)) files/second" -ForegroundColor Gray

if ($exiftoolPath) {
    Write-Console ""
    Write-Console "  Metadata Preserved:" -ForegroundColor Cyan
    Write-Console "    GPS coordinates, EXIF data, dates, camera info" -ForegroundColor Gray
}

Write-Console ""
Write-Console "  Staging folder: $StagingPath" -ForegroundColor Cyan
Write-Console ""

if ($converted -gt 0) {
    Write-Console "  Next steps:" -ForegroundColor Yellow
    Write-Console "    1. Review converted JPG files in staging folder" -ForegroundColor Gray
    Write-Console "    2. Import JPG files into Mylio using Mylio's import function" -ForegroundColor Gray
    Write-Console "    3. Verify everything looks good in Mylio" -ForegroundColor Gray
    Write-Console "    4. Optionally delete HEIC files from Mylio library" -ForegroundColor Gray
    Write-Console "    5. Clean up staging folder when done" -ForegroundColor Gray
    Write-Console ""
}
