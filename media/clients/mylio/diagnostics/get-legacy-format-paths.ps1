# Get paths to legacy format files for testing

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

Write-Console "=== Legacy Format Test Files ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "3GP files (15 total):" -ForegroundColor Yellow
Write-Console "First 5 samples for testing:" -ForegroundColor Gray
$3gpFiles = Get-ChildItem -Path $mylioPath -Recurse -File -Filter "*.3gp"
$3gpFiles | Select-Object -First 5 | ForEach-Object {
    Write-Console ""
    Write-Console "  $($_.FullName)" -ForegroundColor Green
}
Write-Console ""

Write-Console "3G2 files (1 total - only one to test!):" -ForegroundColor Yellow
Get-ChildItem -Path $mylioPath -Recurse -File -Filter "*.3g2" | ForEach-Object {
    Write-Console ""
    Write-Console "  $($_.FullName)" -ForegroundColor Green
}
Write-Console ""

Write-Console "WebP files (4 total - all listed):" -ForegroundColor Yellow
Get-ChildItem -Path $mylioPath -Recurse -File -Filter "*.webp" | ForEach-Object {
    Write-Console ""
    Write-Console "  $($_.FullName)" -ForegroundColor Green
}
Write-Console ""

Write-Console "=== Summary of Unknown Files ===" -ForegroundColor Cyan
Write-Console ""
Write-Console ".myb files (81): Mylio Burst metadata - DO NOT DELETE" -ForegroundColor Yellow
Write-Console "  These group burst photos together" -ForegroundColor Gray
Write-Console "  Size range: 900 KB - 22 MB" -ForegroundColor Gray
Write-Console ""
Write-Console ".txt file (1): Empty text file" -ForegroundColor Yellow
Write-Console "  D:\Mylio\Folder-Nok\2024\(08) August\2024-08-12-270.txt" -ForegroundColor Gray
Write-Console "  Size: 0 KB - Can be safely deleted" -ForegroundColor Red
Write-Console ""
Write-Console ".pdf file (1): Document file" -ForegroundColor Yellow
Write-Console "  D:\Mylio\Folder-Follett\2020\(04) April\2020-04-03-5.pdf" -ForegroundColor Gray
Write-Console "  Size: 30 MB - Mylio doesn't track PDFs, keep if needed" -ForegroundColor Yellow
Write-Console ""
