
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
$testFile = "D:\Mylio\Folder-Follett\2024\(10) October\2024-10-04-21.jpg"

Write-Console "Checking all date/time fields in: $testFile" -ForegroundColor Cyan
Write-Console ""

& $exiftoolPath -time:all -a -G1 -s $testFile
