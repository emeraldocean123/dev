#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Manage network adapter priorities.

.DESCRIPTION
    Unified wrapper for setting Ethernet or WiFi priority to resolve CalDigit hub issues.
    Consolidates multiple priority management scripts into a single interface.

.PARAMETER Mode
    Operation mode:
    - 'Ethernet': Set Ethernet as primary (workaround for CalDigit TS5+ issues)
    - 'WiFi': Set WiFi as primary
    - 'Status': Show current network metrics and priority

.EXAMPLE
    .\manage-network-priority.ps1 -Mode Ethernet
    Set Ethernet adapter as highest priority.

.EXAMPLE
    .\manage-network-priority.ps1 -Mode Status
    Display current network adapter metrics.

.NOTES
    This script consolidates:
    - set-ethernet-priority.ps1
    - set-wifi-priority.ps1
    - check-network-metrics.ps1
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Ethernet', 'WiFi', 'Status')]
    [string]$Mode
)

# Import shared utilities
$utilsPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Network Priority Management Tool" -ForegroundColor Cyan
Write-Console "=================================" -ForegroundColor Cyan
Write-Console ""

switch ($Mode) {
    'Ethernet' {
        Write-Console "Setting Ethernet as primary adapter..." -ForegroundColor Yellow
        $script = Join-Path $PSScriptRoot "set-ethernet-priority.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "Error: set-ethernet-priority.ps1 not found" -ForegroundColor Red
            exit 1
        }
    }

    'WiFi' {
        Write-Console "Setting WiFi as primary adapter..." -ForegroundColor Yellow
        $script = Join-Path $PSScriptRoot "set-wifi-priority.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "Error: set-wifi-priority.ps1 not found" -ForegroundColor Red
            exit 1
        }
    }

    'Status' {
        Write-Console "Checking network adapter metrics..." -ForegroundColor Yellow
        Write-Console ""

        # Check if check-network-metrics.ps1 exists
        $metricsScript = Join-Path $PSScriptRoot "..\network-diagnostics\check-network-metrics.ps1"
        if (Test-Path $metricsScript) {
            & $metricsScript
        } else {
            # Fallback: show basic metrics using Get-NetIPInterface
            Write-Console "Network Adapter Metrics:" -ForegroundColor Cyan
            Write-Console ""

            Get-NetIPInterface -AddressFamily IPv4 |
                Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
                Sort-Object InterfaceMetric |
                Format-Table InterfaceAlias, InterfaceMetric, ConnectionState, AdminStatus -AutoSize
        }
    }
}

Write-Console ""
Write-Console "Operation complete." -ForegroundColor Green
