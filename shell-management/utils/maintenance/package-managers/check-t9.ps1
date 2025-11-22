# Check Samsung T9 and all USB storage devices

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "=== Samsung T9 Device Status ===" -ForegroundColor Cyan
Get-PnpDevice | Where-Object {($_.FriendlyName -like '*Samsung*') -or ($_.FriendlyName -like '*T9*')} | Format-Table FriendlyName, Status, Class -AutoSize

Write-Console "`n=== All Disks ===" -ForegroundColor Cyan
Get-Disk | Format-Table Number, FriendlyName, BusType, OperationalStatus, HealthStatus, Size -AutoSize

Write-Console "`n=== All Volumes ===" -ForegroundColor Cyan
Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, HealthStatus, SizeRemaining, Size -AutoSize

Write-Console "`n=== USB Devices Connected via CalDigit ===" -ForegroundColor Cyan
Get-PnpDevice -Class USB | Where-Object {$_.Status -eq 'OK'} | Format-Table FriendlyName, Status -AutoSize
