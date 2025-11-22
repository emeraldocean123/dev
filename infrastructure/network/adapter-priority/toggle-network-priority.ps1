# Toggle Network Priority Script
# Switches between WiFi and Ethernet as primary network adapter
# Run as Administrator

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("wifi", "ethernet", "status")]
    [string]$Mode = "status"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
function Show-NetworkStatus {
    Write-Console "`n=== Current Network Priority ===" -ForegroundColor Cyan

    $adapters = Get-NetIPInterface -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -in @("Ethernet", "Wi-Fi") } |
        Select-Object InterfaceAlias, InterfaceMetric, ConnectionState |
        Sort-Object InterfaceMetric

    foreach ($adapter in $adapters) {
        $color = if ($adapter.InterfaceMetric -eq 5) { "Green" } else { "Yellow" }
        Write-Console "`n$($adapter.InterfaceAlias):" -ForegroundColor $color
        Write-Console "  Metric: $($adapter.InterfaceMetric)" -ForegroundColor $color
        Write-Console "  Status: $($adapter.ConnectionState)" -ForegroundColor $color

        if ($adapter.InterfaceMetric -eq 5) {
            Write-Console "  [PRIMARY - All traffic routes here]" -ForegroundColor Green
        }
    }

    # Show current default route
    $defaultRoute = Get-NetRoute -AddressFamily IPv4 |
        Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } |
        Select-Object -First 1

    if ($defaultRoute) {
        $routeInterface = (Get-NetAdapter -InterfaceIndex $defaultRoute.InterfaceIndex).Name
        Write-Console "`nDefault Route: via $routeInterface" -ForegroundColor Cyan
    }

    Write-Console ""
}

function Set-WiFiPriority {
    Write-Console "`n=== Switching to WiFi Priority ===" -ForegroundColor Yellow

    try {
        Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 25
        Set-NetIPInterface -InterfaceAlias "Wi-Fi" -InterfaceMetric 5

        Write-Console "[SUCCESS] WiFi is now primary network adapter" -ForegroundColor Green
        Write-Console "Ethernet metric: 25 (lower priority)" -ForegroundColor Yellow
        Write-Console "WiFi metric: 5 (higher priority)" -ForegroundColor Green

        Show-NetworkStatus
    }
    catch {
        Write-Console "[ERROR] Failed to change network priority: $_" -ForegroundColor Red
    }
}

function Set-EthernetPriority {
    Write-Console "`n=== Switching to Ethernet Priority ===" -ForegroundColor Yellow

    try {
        Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 5
        Set-NetIPInterface -InterfaceAlias "Wi-Fi" -InterfaceMetric 20

        Write-Console "[SUCCESS] Ethernet is now primary network adapter" -ForegroundColor Green
        Write-Console "Ethernet metric: 5 (higher priority)" -ForegroundColor Green
        Write-Console "WiFi metric: 20 (lower priority)" -ForegroundColor Yellow

        Show-NetworkStatus
    }
    catch {
        Write-Console "[ERROR] Failed to change network priority: $_" -ForegroundColor Red
    }
}

# Main script logic
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Console "[ERROR] This script must be run as Administrator" -ForegroundColor Red
    Write-Console "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

switch ($Mode.ToLower()) {
    "wifi" {
        Set-WiFiPriority
    }
    "ethernet" {
        Set-EthernetPriority
    }
    "status" {
        Show-NetworkStatus
        Write-Console "Usage:" -ForegroundColor Cyan
        Write-Console "  .\toggle-network-priority.ps1 wifi      - Set WiFi as primary" -ForegroundColor White
        Write-Console "  .\toggle-network-priority.ps1 ethernet  - Set Ethernet as primary" -ForegroundColor White
        Write-Console "  .\toggle-network-priority.ps1 status    - Show current status" -ForegroundColor White
    }
}
