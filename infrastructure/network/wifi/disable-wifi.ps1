# Disable WiFi adapter

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console "Disabling WiFi adapter..." -ForegroundColor Yellow
Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false
Start-Sleep -Seconds 2
Write-Console "WiFi adapter disabled." -ForegroundColor Green

# Check status
Write-Console "`nCurrent adapter status:" -ForegroundColor Cyan
Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet')} | Format-Table Name, Status, LinkSpeed -AutoSize
