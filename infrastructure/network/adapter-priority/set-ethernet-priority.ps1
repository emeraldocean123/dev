# Set Ethernet as Primary Network Adapter
# Run as Administrator

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Console "[ERROR] This script must be run as Administrator" -ForegroundColor Red
    Write-Console "Right-click PowerShell and select 'Run as Administrator', then run this script again" -ForegroundColor Yellow
    exit 1
}

Write-Console "`n=== Setting Ethernet as Primary Network ===" -ForegroundColor Cyan

# Set Ethernet to higher priority (lower metric = higher priority)
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 5
Write-Console "[OK] Ethernet metric set to 5 (higher priority)" -ForegroundColor Green

# Set WiFi to lower priority (higher metric = lower priority)
Set-NetIPInterface -InterfaceAlias "Wi-Fi" -InterfaceMetric 20
Write-Console "[OK] WiFi metric set to 20 (lower priority)" -ForegroundColor Yellow

Write-Console "`n=== Verification ===" -ForegroundColor Cyan
Get-NetIPInterface -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -in @('Ethernet', 'Wi-Fi') } |
    Select-Object InterfaceAlias, InterfaceMetric, ConnectionState |
    Sort-Object InterfaceMetric |
    Format-Table -AutoSize

Write-Console "[SUCCESS] Ethernet is now the primary network adapter" -ForegroundColor Green
Write-Console "All internet traffic will route through Ethernet (10GbE)" -ForegroundColor Green
Write-Console "`nTo switch back to WiFi, run: set-wifi-priority.ps1" -ForegroundColor Yellow
Write-Console ""
