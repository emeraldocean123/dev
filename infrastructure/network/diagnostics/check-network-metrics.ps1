
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}Get-NetIPInterface -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -in @('Ethernet', 'Wi-Fi') } |
    Select-Object InterfaceAlias, InterfaceMetric, ConnectionState |
    Sort-Object InterfaceMetric |
    Format-Table -AutoSize
