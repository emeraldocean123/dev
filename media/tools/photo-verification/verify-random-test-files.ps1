# Verify Random Test Files

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

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Verifying Random Test Files" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Get the first 5 files from the test folder
$testFiles = Get-ChildItem 'D:\Mylio-Test' -File | Select-Object -First 5

foreach ($file in $testFiles) {
    Write-Console "File: $($file.Name)" -ForegroundColor Yellow

    Write-Console ""
    Write-Console "File Timestamps:" -ForegroundColor White
    Write-Console "  CreationTime:   $($file.CreationTime)" -ForegroundColor Cyan
    Write-Console "  LastWriteTime:  $($file.LastWriteTime)" -ForegroundColor Cyan
    Write-Console "  LastAccessTime: $($file.LastAccessTime)" -ForegroundColor Cyan

    Write-Console ""
    Write-Console "EXIF Timestamps:" -ForegroundColor White
    $exif = & $exiftoolPath -DateTimeOriginal -CreateDate -ModifyDate $file.FullName
    $exif | ForEach-Object { Write-Console "  $_" -ForegroundColor Cyan }

    # Check if timestamps match (within 1 second)
    $exifDateString = ($exif | Where-Object { $_ -match "Date/Time Original" }) -replace ".*: ", ""
    if ($exifDateString) {
        try {
            $exifDate = [DateTime]::ParseExact($exifDateString, 'yyyy:MM:dd HH:mm:ss', $null)
            $timeDiff = [Math]::Abs(($file.LastWriteTime - $exifDate).TotalSeconds)

            if ($timeDiff -le 1) {
                Write-Console ""
                Write-Console "  PASS: File timestamps match EXIF (diff: $timeDiff seconds)" -ForegroundColor Green
            } else {
                Write-Console ""
                Write-Console "  FAIL: File timestamps do not match EXIF (diff: $timeDiff seconds)" -ForegroundColor Red
            }
        } catch {
            Write-Console ""
            Write-Console "  Unable to parse EXIF date for comparison" -ForegroundColor Yellow
        }
    }

    Write-Console ""
    Write-Console "----------------------------------------" -ForegroundColor Gray
    Write-Console ""
}

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Verification Complete" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""
