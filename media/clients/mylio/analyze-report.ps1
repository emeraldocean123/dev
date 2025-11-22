
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}$content = Get-Content "C:\Users\josep\Documents\dev\applications\media-players\mylio\fix-exif-report-2025-11-12-012057.txt"

$mismatch = ($content | Select-String 'MISMATCH:').Count
$missing = ($content | Select-String 'MISSING EXIF:').Count
$older = ($content | Select-String 'OLDER EXIF FOUND:').Count
$fixed = ($content | Select-String '  FIXED$').Count
$errorDuringFix = ($content | Select-String '  ERROR during fix').Count
$errorAdding = ($content | Select-String '  ERROR adding EXIF').Count

Write-Console "Report Analysis:"
Write-Console "MISMATCH entries: $mismatch"
Write-Console "MISSING EXIF entries: $missing"
Write-Console "OLDER EXIF FOUND: $older"
Write-Console "FIXED successfully: $fixed"
Write-Console "ERROR during fix: $errorDuringFix"
Write-Console "ERROR adding EXIF: $errorAdding"
Write-Console ""
Write-Console "Total fixes attempted: $($mismatch + $missing)"
Write-Console "Total errors: $($errorDuringFix + $errorAdding)"
