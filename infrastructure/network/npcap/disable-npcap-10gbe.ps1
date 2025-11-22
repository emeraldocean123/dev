# Disable Npcap on CalDigit 10GbE adapter to prevent system freezes during hub crashes
# Run as Administrator
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$adapterName = "Ethernet"  # CalDigit 10GbE adapter

Write-Console "Disabling Npcap on $adapterName..." -ForegroundColor Yellow

# Disable Npcap binding
Disable-NetAdapterBinding -Name $adapterName -ComponentID "INSECURE_NPCAP" -Confirm:$false

Write-Console "`nVerifying bindings..." -ForegroundColor Cyan
Get-NetAdapterBinding -Name $adapterName | Where-Object {$_.ComponentID -eq "INSECURE_NPCAP"} | Format-Table Name,DisplayName,Enabled -AutoSize

Write-Console "`nNpcap has been disabled on $adapterName" -ForegroundColor Green
Write-Console "This should prevent Windows lock-ups during CalDigit hub crashes." -ForegroundColor Green
