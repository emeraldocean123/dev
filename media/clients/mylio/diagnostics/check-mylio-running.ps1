# Check if Mylio is running

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$mylioProc = Get-Process -Name "*mylio*" -ErrorAction SilentlyContinue

if ($mylioProc) {
    Write-Console "Mylio is running:" -ForegroundColor Red
    $mylioProc | Select-Object Id, ProcessName, Path | Format-Table
} else {
    Write-Console "Mylio is not running" -ForegroundColor Green
}
