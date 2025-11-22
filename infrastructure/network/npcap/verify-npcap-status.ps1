# Verify Npcap status on CalDigit 10GbE adapter
# This script checks whether Npcap remains disabled after reboots
# Run this script after rebooting to confirm persistence

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

Write-Console ""
Write-Console "=== Npcap Status Verification ===" -ForegroundColor Cyan
Write-Console "Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Console "Adapter: $adapterName" -ForegroundColor Gray
Write-Console ""

# Get Npcap binding status
$npcapBinding = Get-NetAdapterBinding -Name $adapterName | Where-Object {$_.ComponentID -eq "INSECURE_NPCAP"}

if ($npcapBinding) {
    Write-Console "Npcap Binding Status:" -ForegroundColor Yellow
    $npcapBinding | Format-Table Name, DisplayName, Enabled -AutoSize

    if ($npcapBinding.Enabled -eq $false) {
        Write-Console "[OK] Npcap is DISABLED (expected state)" -ForegroundColor Green
        Write-Console "  Network adapter bindings persist correctly across reboots." -ForegroundColor Gray
    } else {
        Write-Console "[WARNING] Npcap is ENABLED (unexpected)" -ForegroundColor Red
        Write-Console "  This should not happen. Please re-run disable-npcap-10gbe.ps1" -ForegroundColor Red
    }
} else {
    Write-Console "[ERROR] Could not find Npcap binding on adapter '$adapterName'" -ForegroundColor Red
    Write-Console "  Verify the adapter name is correct." -ForegroundColor Red
}

# Get last boot time for reference
$bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime
Write-Console ""
Write-Console "System Boot Information:" -ForegroundColor Cyan
Write-Console "Last Boot: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Console "Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Gray

Write-Console ""
Write-Console "=== Verification Complete ===" -ForegroundColor Cyan
Write-Console ""
