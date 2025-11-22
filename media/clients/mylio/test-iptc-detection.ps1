# Test IPTC:Keywords Detection

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
$testPath = "D:\Mylio\Folder-Follett\2004\(11) November"

Write-Console "Testing IPTC:Keywords detection..." -ForegroundColor Cyan

$iptcCount = & $exiftoolPath -IPTC:Keywords -r -csv $testPath 2>$null |
    ConvertFrom-Csv |
    Where-Object { $_.Keywords -and $_.Keywords.Trim() -ne '' } |
    Measure-Object |
    Select-Object -ExpandProperty Count

Write-Console "Found $iptcCount files with IPTC:Keywords in test folder" -ForegroundColor Yellow

# Show all files with keywords
Write-Console "`nFiles with embedded IPTC:Keywords:" -ForegroundColor Cyan
& $exiftoolPath -IPTC:Keywords -r -csv $testPath 2>$null |
    ConvertFrom-Csv |
    Where-Object { $_.Keywords -and $_.Keywords.Trim() -ne '' } |
    ForEach-Object {
        $filename = Split-Path -Leaf $_.SourceFile
        Write-Console "  $filename : $($_.Keywords)" -ForegroundColor White
    }
