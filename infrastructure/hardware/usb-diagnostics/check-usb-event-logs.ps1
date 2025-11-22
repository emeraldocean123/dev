# USB Event Log and Device Information Check
# Checks for recent USB/Thunderbolt errors and displays driver/firmware info

# Import shared utilities
$utilsPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n=== Checking Recent System Events (Last 2 Hours) ===" -ForegroundColor Cyan

# Get recent errors and warnings
$recentEvents = Get-EventLog -LogName System -Newest 500 | Where-Object {
    ($_.TimeGenerated -gt (Get-Date).AddHours(-2)) -and
    (($_.Source -like '*USB*') -or
     ($_.Source -like '*Thunderbolt*') -or
     ($_.Source -like '*Disk*') -or
     ($_.Source -like '*PnP*') -or
     ($_.EntryType -eq 'Error') -or
     ($_.EntryType -eq 'Warning'))
}

if ($recentEvents) {
    Write-Console "`nFound $($recentEvents.Count) events:" -ForegroundColor Yellow
    $recentEvents | Select-Object TimeGenerated, EntryType, Source, Message |
        Format-Table -AutoSize -Wrap | Out-String -Width 120
} else {
    Write-Console "`n[OK] No errors or warnings found in last 2 hours" -ForegroundColor Green
}

Write-Console "`n=== USB Ethernet Adapter Information ===" -ForegroundColor Cyan

$ethernetDevices = Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like '*Ethernet*') -and
    ($_.FriendlyName -like '*USB*' -or $_.FriendlyName -like '*Thunderbolt*' -or $_.FriendlyName -like '*10G*')
}

if ($ethernetDevices) {
    foreach ($device in $ethernetDevices) {
        $driverVersion = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName DEVPKEY_Device_DriverVersion -ErrorAction SilentlyContinue
        $driverDate = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName DEVPKEY_Device_DriverDate -ErrorAction SilentlyContinue

        Write-Console "`nDevice: $($device.FriendlyName)" -ForegroundColor White
        Write-Console "Status: $($device.Status)" -ForegroundColor White
        if ($driverVersion) {
            Write-Console "Driver Version: $($driverVersion.Data)" -ForegroundColor White
        }
        if ($driverDate) {
            Write-Console "Driver Date: $($driverDate.Data)" -ForegroundColor White
        }
    }
} else {
    Write-Console "No USB/Thunderbolt Ethernet adapters found" -ForegroundColor Yellow
}

Write-Console "`n=== USB4/Thunderbolt Controller Information ===" -ForegroundColor Cyan

$tbControllers = Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like '*USB4*') -or
    ($_.FriendlyName -like '*Thunderbolt*')
}

foreach ($controller in $tbControllers) {
    Write-Console "`n$($controller.FriendlyName):" -ForegroundColor White
    Write-Console "  Status: $($controller.Status)" -ForegroundColor White

    $driverVer = Get-PnpDeviceProperty -InstanceId $controller.InstanceId -KeyName DEVPKEY_Device_DriverVersion -ErrorAction SilentlyContinue
    if ($driverVer) {
        Write-Console "  Driver Version: $($driverVer.Data)" -ForegroundColor White
    }

    $firmwareVer = Get-PnpDeviceProperty -InstanceId $controller.InstanceId -KeyName DEVPKEY_Device_FirmwareVersion -ErrorAction SilentlyContinue
    if ($firmwareVer) {
        Write-Console "  Firmware Version: $($firmwareVer.Data)" -ForegroundColor White
    }
}

Write-Console "`n" -ForegroundColor White
