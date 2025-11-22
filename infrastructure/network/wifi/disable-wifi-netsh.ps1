# Disable WiFi using netsh (alternative method)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console "Disabling WiFi using netsh..." -ForegroundColor Yellow

# Get the WiFi interface name
$wifi = Get-NetAdapter -Name "Wi-Fi"
$interfaceName = $wifi.InterfaceDescription

Write-Console "WiFi Interface: $interfaceName" -ForegroundColor Cyan

# Disable using netsh
netsh interface set interface "Wi-Fi" admin=disable

Start-Sleep -Seconds 2

Write-Console "`nCurrent status:" -ForegroundColor Cyan
Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet')} | Format-Table Name, Status, LinkSpeed -AutoSize
