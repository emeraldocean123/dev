# Final Verification Before Full Mylio Sync

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
Write-Console "  Final Verification Check" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Check 10 random files from test folder
$testFiles = Get-ChildItem 'D:\Mylio-Test' -File | Get-Random -Count 10
$passed = 0
$failed = 0

foreach ($file in $testFiles) {
    $exif = & $exiftoolPath -DateTimeOriginal $file.FullName -s3
    if ($exif) {
        try {
            $exifDate = [DateTime]::ParseExact($exif, 'yyyy:MM:dd HH:mm:ss', $null)
            $timeDiff = [Math]::Abs(($file.LastWriteTime - $exifDate).TotalSeconds)

            if ($timeDiff -le 1) {
                $passed++
            } else {
                $failed++
                Write-Console "FAIL: $($file.Name) - diff: $timeDiff seconds" -ForegroundColor Red
            }
        } catch {
            Write-Console "ERROR: $($file.Name) - unable to parse EXIF" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Console "Checked 10 random files:" -ForegroundColor White
Write-Console "  Passed: $passed" -ForegroundColor Green
if ($failed -eq 0) {
    Write-Console "  Failed: $failed" -ForegroundColor Green
} else {
    Write-Console "  Failed: $failed" -ForegroundColor Red
}
Write-Console ""

if ($failed -eq 0) {
    Write-Console "SUCCESS: All files verified - ready for full Mylio sync" -ForegroundColor Green
    Write-Console ""
    Write-Console "Full Mylio sync will process 75,792 files" -ForegroundColor Yellow
    Write-Console "Estimated time: 10-11 hours" -ForegroundColor Yellow
} else {
    Write-Console "FAILURE: Verification failed - DO NOT proceed" -ForegroundColor Red
}
Write-Console ""
