#!/usr/bin/env pwsh
<#
.SYNOPSIS
    WiFi Management Menu Launcher

.DESCRIPTION
    Unified interface for WiFi adapter diagnostics and control.
    Consolidates status checking, blocking detection, and adapter control.

.PARAMETER Action
    WiFi action to perform:
    - 'Menu': Interactive menu (default)
    - 'Status': Show adapter status
    - 'Disable': Disable WiFi adapter
    - 'Enable': Enable WiFi adapter
    - 'CheckBlock': Check if WiFi is blocked

.EXAMPLE
    .\manage-wifi.ps1
    Launch interactive menu

.EXAMPLE
    .\manage-wifi.ps1 -Action Status
    Display WiFi and Ethernet adapter status

.EXAMPLE
    .\manage-wifi.ps1 -Action Disable
    Disable WiFi adapter

.NOTES
    Location: infrastructure/network/wifi/manage-wifi.ps1
    Consolidates: check-wifi-status.ps1, check-wifi-block.ps1, disable-wifi.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Menu", "Status", "Disable", "Enable", "CheckBlock")]
    [string]$Action = "Menu"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Point to tools/ subdirectory
$toolsPath = Join-Path $PSScriptRoot "tools"

function Show-WiFiStatus {
    Write-Console "`nWiFi and Ethernet Adapter Status" -ForegroundColor Cyan
    Write-Console "======================================" -ForegroundColor Cyan
    Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet')} |
        Format-Table Name, Status, LinkSpeed, AdminStatus -AutoSize
}

function Disable-WiFiAdapter {
    Write-Console "`nDisabling WiFi adapter..." -ForegroundColor Yellow

    try {
        Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Console "WiFi adapter disabled successfully." -ForegroundColor Green

        Write-Console "`nCurrent adapter status:" -ForegroundColor Cyan
        Show-WiFiStatus
    }
    catch {
        Write-Console "ERROR: Failed to disable WiFi adapter: $_" -ForegroundColor Red
    }
}

function Enable-WiFiAdapter {
    Write-Console "`nEnabling WiFi adapter..." -ForegroundColor Yellow

    try {
        Enable-NetAdapter -Name "Wi-Fi" -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Console "WiFi adapter enabled successfully." -ForegroundColor Green

        Write-Console "`nCurrent adapter status:" -ForegroundColor Cyan
        Show-WiFiStatus
    }
    catch {
        Write-Console "ERROR: Failed to enable WiFi adapter: $_" -ForegroundColor Red
    }
}

function Invoke-WiFiBlockCheck {
    $blockCheckScript = Join-Path $toolsPath "check-wifi-block.ps1"

    if (Test-Path $blockCheckScript) {
        & $blockCheckScript
    }
    else {
        Write-Console "ERROR: WiFi block check script not found" -ForegroundColor Red
    }
}

function Show-Menu {
    while ($true) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  WiFi Management Menu" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""
        Write-Console "  1. Show adapter status" -ForegroundColor White
        Write-Console "  2. Disable WiFi" -ForegroundColor White
        Write-Console "  3. Enable WiFi" -ForegroundColor White
        Write-Console "  4. Check WiFi block status" -ForegroundColor White
        Write-Console ""
        Write-Console "  Q. Quit" -ForegroundColor Yellow
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        $selection = Read-Host "Select action"

        switch ($selection) {
            "1" {
                Show-WiFiStatus
                Read-Host "`nPress Enter to continue"
            }
            "2" {
                Disable-WiFiAdapter
                Read-Host "`nPress Enter to continue"
            }
            "3" {
                Enable-WiFiAdapter
                Read-Host "`nPress Enter to continue"
            }
            "4" {
                Invoke-WiFiBlockCheck
                Read-Host "`nPress Enter to continue"
            }
            {$_ -match "^[Qq]$"} { return }
        }
    }
}

# Entry Point
switch ($Action) {
    "Menu"       { Show-Menu }
    "Status"     { Show-WiFiStatus }
    "Disable"    { Disable-WiFiAdapter }
    "Enable"     { Enable-WiFiAdapter }
    "CheckBlock" { Invoke-WiFiBlockCheck }
}
