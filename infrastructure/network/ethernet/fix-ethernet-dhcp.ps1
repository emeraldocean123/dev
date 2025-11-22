# Fix Ethernet DHCP

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console "Resetting Ethernet DHCP..." -ForegroundColor Yellow

# Disable and re-enable Ethernet adapter to force DHCP renew
Disable-NetAdapter -Name "Ethernet" -Confirm:$false
Start-Sleep -Seconds 3
Enable-NetAdapter -Name "Ethernet" -Confirm:$false

Write-Console "Waiting for DHCP..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Console "`n=== Ethernet Status ===" -ForegroundColor Green
Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4 | Format-Table IPAddress, PrefixLength -AutoSize

Write-Console "`n=== Network Adapters ===" -ForegroundColor Green
Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet')} | Format-Table Name, Status, LinkSpeed -AutoSize
