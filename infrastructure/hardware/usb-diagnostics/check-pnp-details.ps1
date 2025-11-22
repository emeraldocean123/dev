
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}Write-Console "=== CalDigit PnP Device Details ===" -ForegroundColor Cyan
Get-PnpDevice -Class Net | Where-Object {
    $_.FriendlyName -like '*CalDigit*' -or
    $_.FriendlyName -like '*10G*'
} | Select-Object FriendlyName, Status, InstanceId, PNPClass | Format-List

Write-Console "`n=== Device Manager Problem Code ===" -ForegroundColor Yellow
Get-PnpDevice -Class Net | Where-Object {
    $_.FriendlyName -like '*CalDigit*'
} | ForEach-Object {
    $device = Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName "DEVPKEY_Device_ProblemCode"
    Write-Console "Problem Code: $($device.Data)"
}
