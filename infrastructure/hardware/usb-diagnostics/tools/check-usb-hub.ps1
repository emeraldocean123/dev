# USB Hub Diagnostic Script
# Quick check for USB4/Thunderbolt devices and network adapter status

# Import shared utilities
$utilsPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n=== USB Hub & Device Status ===" -ForegroundColor Cyan

# Check USB4/Thunderbolt devices
Write-Console "`nUSB4/Thunderbolt Devices:" -ForegroundColor Yellow
Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like '*USB4*') -or
    ($_.FriendlyName -like '*Thunderbolt*') -or
    ($_.FriendlyName -like '*USB-C*')
} | Select-Object FriendlyName, Status, Present | Format-Table -AutoSize

# Check Ethernet adapter (if connected via hub)
Write-Console "`n=== Ethernet Adapter Status ===" -ForegroundColor Cyan
$ethAdapter = Get-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue
if ($ethAdapter) {
    $ethAdapter | Select-Object Name, Status, LinkSpeed | Format-Table -AutoSize

    # Check IP configuration
    Write-Console "`n=== IP Configuration ===" -ForegroundColor Cyan
    $ip = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $gw = (Get-NetIPConfiguration -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue).IPv4DefaultGateway.NextHop

    if ($ip) {
        Write-Console "IP Address: $($ip.IPAddress)" -ForegroundColor White
        Write-Console "Gateway: $gw" -ForegroundColor White

        # Check for APIPA address
        if ($ip.IPAddress -like "169.254.*") {
            Write-Console "`n[WARNING] APIPA address detected! DHCP failed." -ForegroundColor Red
        } else {
            Write-Console "`n[OK] Valid DHCP address" -ForegroundColor Green
        }
    }

    # Test connectivity
    Write-Console "`n=== Connectivity Test ===" -ForegroundColor Cyan
    if ($gw) {
        $ping = Test-Connection -ComputerName $gw -Count 4 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            Write-Console "[OK] Gateway reachable ($gw)" -ForegroundColor Green
        } else {
            Write-Console "[FAIL] Cannot reach gateway ($gw)" -ForegroundColor Red
        }
    } else {
        Write-Console "[WARNING] No gateway configured" -ForegroundColor Yellow
    }
} else {
    Write-Console "No Ethernet adapter found" -ForegroundColor Yellow
}

Write-Console "`n" -ForegroundColor White
