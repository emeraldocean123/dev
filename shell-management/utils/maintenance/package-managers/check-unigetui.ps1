
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}Write-Console "=== Checking if UniGetUI is running ===" -ForegroundColor Cyan
Write-Console ""

$unigetui = Get-Process | Where-Object { $_.ProcessName -like '*UniGetUI*' -or $_.ProcessName -like '*WingetUI*' }

if ($unigetui) {
    Write-Console "UniGetUI is currently running:" -ForegroundColor Yellow
    $unigetui | Select-Object ProcessName, Id, StartTime | Format-Table -AutoSize
    Write-Console ""
    Write-Console "To apply configuration changes, please:" -ForegroundColor Green
    Write-Console "1. Close UniGetUI" -ForegroundColor White
    Write-Console "2. Restart UniGetUI" -ForegroundColor White
} else {
    Write-Console "UniGetUI is not running." -ForegroundColor Green
    Write-Console "Changes will take effect when you start UniGetUI." -ForegroundColor White
}
