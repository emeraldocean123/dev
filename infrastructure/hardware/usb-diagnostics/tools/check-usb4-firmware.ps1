
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}Write-Console "=== USB4/Thunderbolt Controller Information ===" -ForegroundColor Cyan

# Get USB4 Root Router device
$usb4Root = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like '*USB4*Root*' -or
    $_.FriendlyName -like '*Thunderbolt*Root*' -or
    $_.FriendlyName -like '*USB4 Host Router*'
}

if ($usb4Root) {
    Write-Console "`nUSB4 Root Router Device:" -ForegroundColor Yellow
    $usb4Root | Format-List FriendlyName, Status, InstanceId

    # Get driver version
    $driver = Get-PnpDeviceProperty -InstanceId $usb4Root.InstanceId -KeyName "DEVPKEY_Device_DriverVersion"
    Write-Console "Driver Version: $($driver.Data)" -ForegroundColor Green

    # Get driver date
    $driverDate = Get-PnpDeviceProperty -InstanceId $usb4Root.InstanceId -KeyName "DEVPKEY_Device_DriverDate"
    Write-Console "Driver Date: $($driverDate.Data)" -ForegroundColor Green

    # Get firmware version if available
    $firmware = Get-PnpDeviceProperty -InstanceId $usb4Root.InstanceId -KeyName "DEVPKEY_Device_FirmwareVersion"
    if ($firmware.Data) {
        Write-Console "Firmware Version: $($firmware.Data)" -ForegroundColor Green
    }
}

# Get all Thunderbolt/USB4 related devices
Write-Console "`n=== All USB4/Thunderbolt Devices ===" -ForegroundColor Cyan
Get-PnpDevice | Where-Object {
    $_.FriendlyName -like '*USB4*' -or
    $_.FriendlyName -like '*Thunderbolt*'
} | Select-Object FriendlyName, Status, InstanceId | Format-Table -AutoSize

# Check BIOS version
Write-Console "`n=== BIOS Information ===" -ForegroundColor Cyan
Get-CimInstance -ClassName Win32_BIOS | Select-Object Manufacturer, Name, Version, ReleaseDate | Format-List
