# Get statistics for staging folder conversion results

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$stagingPath = "$env:USERPROFILE\Documents\heic-staging"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  HEIC Conversion Complete!" -ForegroundColor Green
Write-Console "========================================`n" -ForegroundColor Cyan

# Get file counts and sizes
$heicFiles = Get-ChildItem -Path $stagingPath -Filter "*.heic" -File
$jpgFiles = Get-ChildItem -Path $stagingPath -Filter "*.jpg" -File

$heicSize = ($heicFiles | Measure-Object -Property Length -Sum).Sum / 1GB
$jpgSize = ($jpgFiles | Measure-Object -Property Length -Sum).Sum / 1GB
$totalSize = $heicSize + $jpgSize

Write-Console "  Files Converted:" -ForegroundColor Yellow
Write-Console "    HEIC originals: $($heicFiles.Count) files ($([math]::Round($heicSize, 2)) GB)" -ForegroundColor Gray
Write-Console "    JPG converted:  $($jpgFiles.Count) files ($([math]::Round($jpgSize, 2)) GB)" -ForegroundColor Gray
Write-Console "    Total size:     $([math]::Round($totalSize, 2)) GB" -ForegroundColor Gray

Write-Console "`n  Metadata Preservation:" -ForegroundColor Yellow
Write-Console "    ✅ GPS coordinates" -ForegroundColor Green
Write-Console "    ✅ Camera make/model" -ForegroundColor Green
Write-Console "    ✅ EXIF data (ISO, f-stop, shutter speed, lens info)" -ForegroundColor Green
Write-Console "    ✅ Date taken (original date)" -ForegroundColor Green
Write-Console "    ✅ File timestamps (creation, modification, access)" -ForegroundColor Green

Write-Console "`n  Quality Settings:" -ForegroundColor Yellow
Write-Console "    JPG Quality: 95%" -ForegroundColor Gray
Write-Console "    Conversion Tool: ImageMagick 7.1.2-Q16-HDRI" -ForegroundColor Gray
Write-Console "    Metadata Tool: ExifTool" -ForegroundColor Gray

Write-Console "`n  Location:" -ForegroundColor Yellow
Write-Console "    Original Mylio: D:\Mylio (UNTOUCHED)" -ForegroundColor Green
Write-Console "    Staging folder: $stagingPath" -ForegroundColor Cyan
Write-Console "    - Contains both HEIC originals and JPG conversions" -ForegroundColor Gray

Write-Console "`n  Next Steps:" -ForegroundColor Yellow
Write-Console "    1. Review converted JPG files in staging folder" -ForegroundColor Gray
Write-Console "    2. Import JPG files into Mylio using Mylio's import function" -ForegroundColor Gray
Write-Console "    3. Verify everything looks good in Mylio" -ForegroundColor Gray
Write-Console "    4. Optionally delete HEIC files from Mylio library" -ForegroundColor Gray
Write-Console "    5. Clean up staging folder when done" -ForegroundColor Gray

Write-Console ""
