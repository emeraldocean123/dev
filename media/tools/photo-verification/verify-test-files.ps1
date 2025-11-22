# Verify Test Files Were Updated Correctly

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Verification of Test Files" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Check File 1: EXIF was oldest source (should sync file timestamps to EXIF)
Write-Console "File 1: 2001-06-02-5.jpg (EXIF was oldest source)" -ForegroundColor Yellow
Write-Console "Expected: File timestamps should match 6/2/2001 2:06:14 PM`n" -ForegroundColor Gray

$file1 = Get-Item "D:\Mylio-Test\2001-06-02-5.jpg"
Write-Console "File Timestamps:" -ForegroundColor White
Write-Console "  CreationTime:   $($file1.CreationTime)" -ForegroundColor $(if ($file1.CreationTime.ToString("M/d/yyyy h:mm:ss tt") -eq "6/2/2001 2:06:14 PM") { "Green" } else { "Red" })
Write-Console "  LastWriteTime:  $($file1.LastWriteTime)" -ForegroundColor $(if ($file1.LastWriteTime.ToString("M/d/yyyy h:mm:ss tt") -eq "6/2/2001 2:06:14 PM") { "Green" } else { "Red" })
Write-Console "  LastAccessTime: $($file1.LastAccessTime)" -ForegroundColor $(if ($file1.LastAccessTime.ToString("M/d/yyyy h:mm:ss tt") -eq "6/2/2001 2:06:14 PM") { "Green" } else { "Red" })

$exif1 = & $exiftoolPath -DateTimeOriginal -CreateDate -ModifyDate "D:\Mylio-Test\2001-06-02-5.jpg"
Write-Console "`nEXIF Timestamps:" -ForegroundColor White
$exif1 | ForEach-Object { Write-Console "  $_" -ForegroundColor Cyan }

Write-Console "`n----------------------------------------`n" -ForegroundColor Gray

# Check File 2: File timestamp was oldest (should sync EXIF to file)
Write-Console "File 2: 2004-10-23-1.jpg (File timestamp was oldest)" -ForegroundColor Yellow
Write-Console "Expected: EXIF should match 11/6/2004 11:49:32 AM`n" -ForegroundColor Gray

$file2 = Get-Item "D:\Mylio-Test\2004-10-23-1.jpg"
Write-Console "File Timestamps:" -ForegroundColor White
Write-Console "  CreationTime:   $($file2.CreationTime)" -ForegroundColor Cyan
Write-Console "  LastWriteTime:  $($file2.LastWriteTime)" -ForegroundColor Cyan
Write-Console "  LastAccessTime: $($file2.LastAccessTime)" -ForegroundColor Cyan

$exif2 = & $exiftoolPath -DateTimeOriginal -CreateDate -ModifyDate "D:\Mylio-Test\2004-10-23-1.jpg"
Write-Console "`nEXIF Timestamps:" -ForegroundColor White
$exif2 | ForEach-Object {
    $expectedMatch = $_ -match "2004:11:06 11:49:32"
    Write-Console "  $_" -ForegroundColor $(if ($expectedMatch) { "Green" } else { "Red" })
}

Write-Console "`n----------------------------------------`n" -ForegroundColor Gray

# Check File 3: Already in sync (should not be modified)
Write-Console "File 3: Random file that was already in sync" -ForegroundColor Yellow
$syncedFiles = Get-ChildItem "D:\Mylio-Test" | Where-Object { $_.Name -notmatch "2001-06-02-5|2004-10-23-1" } | Select-Object -First 1
Write-Console "File: $($syncedFiles.Name)" -ForegroundColor Gray
Write-Console "This file should have been skipped (already in sync)`n" -ForegroundColor Gray

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Verification Complete" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan
