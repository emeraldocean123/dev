# Convert HEIC files to JPEG with full metadata preservation
# Requires:
#   - ImageMagick: winget install ImageMagick.ImageMagick
#   - ExifTool: Already in your PATH (for metadata preservation)

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "",

    [Parameter(Mandatory=$false)]
    [int]$Quality = 95,

    [Parameter(Mandatory=$false)]
    [switch]$Recursive,

    [Parameter(Mandatory=$false)]
    [switch]$DeleteOriginal,

    [Parameter(Mandatory=$false)]
    [switch]$PreserveTimestamps = $true
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
# Check if ImageMagick is installed
$magick = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magick) {
    Write-Console "ImageMagick is not installed!" -ForegroundColor Red
    Write-Console ""
    Write-Console "Install it with:" -ForegroundColor Yellow
    Write-Console "  winget install ImageMagick.ImageMagick" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Then restart PowerShell and run this script again." -ForegroundColor Yellow
    exit 1
}

# Check if ExifTool is installed (for metadata preservation)
$exiftool = Get-Command exiftool -ErrorAction SilentlyContinue
if (-not $exiftool) {
    Write-Console "Warning: ExifTool not found!" -ForegroundColor Yellow
    Write-Console "EXIF metadata (GPS, dates, camera info) will NOT be preserved." -ForegroundColor Yellow
    Write-Console ""
    $continue = Read-Host "Continue without metadata preservation? (Y/N)"
    if ($continue -notmatch "^[Yy]") {
        Write-Console "Install ExifTool from: https://exiftool.org/" -ForegroundColor Cyan
        exit 1
    }
    $PreserveTimestamps = $false
}

# If no path specified, prompt user
if (-not $Path) {
    Write-Console "HEIC to JPEG Converter" -ForegroundColor Cyan
    Write-Console "=====================" -ForegroundColor Cyan
    Write-Console ""

    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing HEIC files"
    $folderBrowser.RootFolder = "MyComputer"

    if ($folderBrowser.ShowDialog() -eq "OK") {
        $Path = $folderBrowser.SelectedPath
    } else {
        Write-Console "No folder selected. Exiting." -ForegroundColor Yellow
        exit 0
    }
}

# Check if path exists
if (-not (Test-Path $Path)) {
    Write-Console "Error: Path not found: $Path" -ForegroundColor Red
    exit 1
}

# Find HEIC files
Write-Console "`nSearching for HEIC files..." -ForegroundColor Yellow

$searchParams = @{
    Path = $Path
    Filter = "*.heic"
}

if ($Recursive) {
    $searchParams.Recurse = $true
}

$heicFiles = Get-ChildItem @searchParams

if ($heicFiles.Count -eq 0) {
    Write-Console "No HEIC files found in: $Path" -ForegroundColor Yellow
    exit 0
}

Write-Console "Found $($heicFiles.Count) HEIC file(s)" -ForegroundColor Green
Write-Console ""

# Confirm before proceeding
Write-Console "Settings:" -ForegroundColor Cyan
Write-Console "  Quality: $Quality" -ForegroundColor White
Write-Console "  Recursive: $Recursive" -ForegroundColor White
Write-Console "  Delete originals: $DeleteOriginal" -ForegroundColor White
Write-Console ""

$confirm = Read-Host "Proceed with conversion? (Y/N)"
if ($confirm -notmatch "^[Yy]") {
    Write-Console "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Console ""

# Convert files
$converted = 0
$skipped = 0
$failed = 0

foreach ($file in $heicFiles) {
    $outputPath = $file.FullName -replace '\.heic$', '.jpg'

    # Skip if JPG already exists
    if (Test-Path $outputPath) {
        Write-Console "[SKIP] $($file.Name) - JPG already exists" -ForegroundColor Yellow
        $skipped++
        continue
    }

    Write-Console "[CONV] $($file.Name)" -ForegroundColor Cyan -NoNewline

    try {
        # Step 1: Convert using ImageMagick
        & magick convert $file.FullName -quality $Quality $outputPath 2>&1 | Out-Null

        if (Test-Path $outputPath) {
            # Step 2: Copy EXIF metadata using ExifTool
            if ($exiftool) {
                & exiftool -TagsFromFile $file.FullName -All:All -overwrite_original $outputPath 2>&1 | Out-Null

                # Step 3: Preserve file timestamps if requested
                if ($PreserveTimestamps) {
                    $fileItem = Get-Item $outputPath
                    $fileItem.CreationTime = $file.CreationTime
                    $fileItem.LastWriteTime = $file.LastWriteTime
                    $fileItem.LastAccessTime = $file.LastAccessTime
                }
            }

            $jpgSize = (Get-Item $outputPath).Length / 1MB
            $heicSize = $file.Length / 1MB
            $savings = [math]::Round((1 - ($jpgSize / $heicSize)) * 100, 1)

            Write-Console " → OK (JPG: $([math]::Round($jpgSize, 2)) MB, Savings: $savings%)" -ForegroundColor Green
            if ($exiftool) {
                Write-Console "       Metadata preserved (EXIF, GPS, dates)" -ForegroundColor Gray
            }

            # Delete original if requested
            if ($DeleteOriginal) {
                Remove-Item $file.FullName -Force
                Write-Console "       Deleted original" -ForegroundColor Gray
            }

            $converted++
        } else {
            Write-Console " → FAILED (no output file)" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Console " → FAILED ($($_.Exception.Message))" -ForegroundColor Red
        $failed++
    }
}

# Summary
Write-Console ""
Write-Console "=" * 60 -ForegroundColor Cyan
Write-Console "Conversion Complete!" -ForegroundColor Green
Write-Console "=" * 60 -ForegroundColor Cyan
Write-Console "  Converted: $converted" -ForegroundColor Green
Write-Console "  Skipped: $skipped" -ForegroundColor Yellow
Write-Console "  Failed: $failed" -ForegroundColor Red
Write-Console ""

if ($converted -gt 0) {
    Write-Console "JPG files saved to same location as HEIC files" -ForegroundColor Cyan
}
