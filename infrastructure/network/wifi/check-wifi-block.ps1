# Check what might be preventing WiFi from being disabled

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "=== Checking WiFi Connections ===" -ForegroundColor Cyan
Get-NetConnectionProfile | Format-Table Name, InterfaceAlias, NetworkCategory -AutoSize

Write-Console "`n=== Checking WiFi Radio State ===" -ForegroundColor Cyan
netsh wlan show interfaces

Write-Console "`n=== Checking if any process has exclusive WiFi access ===" -ForegroundColor Cyan
$wifi = Get-NetAdapter -Name "Wi-Fi"
Write-Console "WiFi Adapter Details:" -ForegroundColor Yellow
$wifi | Format-List Name, Status, MediaConnectionState, AdminStatus
