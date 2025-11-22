# Cleanup HEIC Staging Folder
# Removes all converted files since original HEIC in Mylio are correct

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
Write-Console "  HEIC Staging Cleanup" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $stagingPath)) {
    Write-Console "  ✅ Staging folder already deleted or doesn't exist" -ForegroundColor Green
    Write-Console "  Location: $stagingPath" -ForegroundColor Gray
    Write-Console ""
    exit 0
}

# Get folder stats
Write-Console "[1/2] Checking staging folder contents..." -ForegroundColor Yellow
$heicFiles = Get-ChildItem -Path $stagingPath -Filter "*.heic" -File
$jpgFiles = Get-ChildItem -Path $stagingPath -Filter "*.jpg" -File
$allFiles = Get-ChildItem -Path $stagingPath -File

$heicSize = ($heicFiles | Measure-Object -Property Length -Sum).Sum / 1GB
$jpgSize = ($jpgFiles | Measure-Object -Property Length -Sum).Sum / 1GB
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum / 1GB

Write-Console "  Location: $stagingPath" -ForegroundColor Gray
Write-Console ""
Write-Console "  Files to delete:" -ForegroundColor White
Write-Console "    HEIC files: $($heicFiles.Count) ($([math]::Round($heicSize, 2)) GB)" -ForegroundColor Gray
Write-Console "    JPG files:  $($jpgFiles.Count) ($([math]::Round($jpgSize, 2)) GB)" -ForegroundColor Gray
Write-Console "    Total:      $($allFiles.Count) files ($([math]::Round($totalSize, 2)) GB)" -ForegroundColor Gray
Write-Console ""
Write-Console "  Status:" -ForegroundColor White
Write-Console "    Original HEIC in Mylio: ✅ Preserved (D:\Mylio)" -ForegroundColor Green
Write-Console "    Converted JPG:          ❌ Incorrect rotation" -ForegroundColor Red
Write-Console "    Solution:               ✅ Use XnView MP with original HEIC" -ForegroundColor Green

# Confirm deletion
Write-Console "`n[2/2] Ready to delete staging folder" -ForegroundColor Yellow
Write-Console ""
Write-Console "  This will:" -ForegroundColor Cyan
Write-Console "    • Delete all $($allFiles.Count) files in staging" -ForegroundColor Gray
Write-Console "    • Free up $([math]::Round($totalSize, 2)) GB of disk space" -ForegroundColor Gray
Write-Console "    • Remove the staging folder completely" -ForegroundColor Gray
Write-Console ""
Write-Console "  Original HEIC files in D:\Mylio will NOT be touched" -ForegroundColor Green
Write-Console ""

$confirm = Read-Host "  Delete staging folder? (Y/N)"

if ($confirm -notmatch "^[Yy]") {
    Write-Console "`n  ❌ Cancelled - staging folder preserved" -ForegroundColor Yellow
    Write-Console ""
    exit 0
}

# Delete staging folder
Write-Console ""
Write-Console "  Deleting staging folder..." -ForegroundColor Yellow

try {
    Remove-Item -Path $stagingPath -Recurse -Force

    Write-Console ""
    Write-Console "========================================" -ForegroundColor Green
    Write-Console "  ✅ Cleanup Complete!" -ForegroundColor Green
    Write-Console "========================================" -ForegroundColor Green
    Write-Console ""
    Write-Console "  Deleted: $($allFiles.Count) files ($([math]::Round($totalSize, 2)) GB freed)" -ForegroundColor White
    Write-Console "  Folder: $stagingPath (removed)" -ForegroundColor Gray
    Write-Console ""
    Write-Console "  Next steps:" -ForegroundColor Cyan
    Write-Console "    1. Use XnView MP to view HEIC files in D:\Mylio" -ForegroundColor Gray
    Write-Console "    2. Original HEIC files display correctly with auto-rotation" -ForegroundColor Gray
    Write-Console "    3. No conversion needed - saves disk space!" -ForegroundColor Gray
    Write-Console ""
}
catch {
    Write-Console ""
    Write-Console "  ❌ Error deleting staging folder:" -ForegroundColor Red
    Write-Console "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Console ""
    Write-Console "  Try:" -ForegroundColor Yellow
    Write-Console "    1. Close any open programs viewing files in staging" -ForegroundColor Gray
    Write-Console "    2. Run this script again" -ForegroundColor Gray
    Write-Console ""
    exit 1
}
