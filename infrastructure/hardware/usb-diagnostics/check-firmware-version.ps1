# Check CalDigit TS5+ Current Firmware Version
# Latest available: 64.1 (October 17, 2025)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n=== CalDigit TS5+ Firmware & Driver Versions ===" -ForegroundColor Cyan

# Ethernet Driver
Write-Console "`n10GbE Ethernet Driver:" -ForegroundColor Yellow
$eth = Get-PnpDevice | Where-Object {$_.FriendlyName -like '*CalDigit Thunderbolt 10G*'}
if ($eth) {
    $ethDriver = Get-PnpDeviceProperty -InstanceId $eth.InstanceId -KeyName DEVPKEY_Device_DriverVersion
    $ethDate = Get-PnpDeviceProperty -InstanceId $eth.InstanceId -KeyName DEVPKEY_Device_DriverDate
    Write-Console "  Version: $($ethDriver.Data)"
    Write-Console "  Date: $($ethDate.Data)"
}

# Thunderbolt Controllers
Write-Console "`nThunderbolt/USB4 Controllers:" -ForegroundColor Yellow
$tbDevices = Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like '*USB4*Router*') -or
    ($_.FriendlyName -like '*Thunderbolt*') -and
    ($_.Status -eq 'OK')
}

foreach ($device in $tbDevices) {
    Write-Console "`n  $($device.FriendlyName):"
    Write-Console "    Status: $($device.Status)"

    # Try to get firmware version
    $fwVer = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName DEVPKEY_Device_FirmwareVersion -ErrorAction SilentlyContinue
    if ($fwVer -and $fwVer.Data) {
        Write-Console "    Firmware: $($fwVer.Data)"
    }

    # Get driver version
    $drvVer = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName DEVPKEY_Device_DriverVersion -ErrorAction SilentlyContinue
    if ($drvVer -and $drvVer.Data) {
        Write-Console "    Driver: $($drvVer.Data)"
    }
}

Write-Console "`n=== Latest Available Firmware ===" -ForegroundColor Cyan
Write-Console "  CalDigit TS5+ Firmware: v64.1 (Released: October 17, 2025)" -ForegroundColor Green
Write-Console "  Download: https://downloads.caldigit.com/" -ForegroundColor Green

Write-Console "`n"
