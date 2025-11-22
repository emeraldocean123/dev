
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}Write-Console "=== Network Adapter Status ===" -ForegroundColor Cyan
Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like '*CalDigit*' -or
    $_.InterfaceDescription -like '*10G*' -or
    $_.InterfaceDescription -like '*Marvell*'
} | Format-Table Name, Status, LinkSpeed, InterfaceDescription -AutoSize

Write-Console "`n=== All Network Adapters ===" -ForegroundColor Cyan
Get-NetAdapter | Format-Table Name, Status, LinkSpeed, InterfaceDescription -AutoSize
