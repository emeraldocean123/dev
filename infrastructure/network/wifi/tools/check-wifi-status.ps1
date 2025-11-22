# Check WiFi and Ethernet status

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet')} | Format-Table Name, Status, LinkSpeed, AdminStatus -AutoSize
