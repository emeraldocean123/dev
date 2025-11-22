# Restart Windows Explorer
# Required after installing Icaros shell extensions

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nRestarting Windows Explorer..." -ForegroundColor Cyan
Write-Console "This will close all Explorer windows temporarily.`n" -ForegroundColor Yellow

# Kill Explorer
Stop-Process -Name explorer -Force

# Wait a moment
Start-Sleep -Seconds 2

# Restart Explorer
Start-Process explorer.exe

Write-Console "Windows Explorer has been restarted." -ForegroundColor Green
Write-Console "Icaros shell extensions should now be loaded.`n" -ForegroundColor White
