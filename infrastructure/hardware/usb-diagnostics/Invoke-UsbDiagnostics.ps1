# USB Diagnostics Menu Launcher
# Organized menu system for all USB diagnostic tools
# Location: infrastructure/hardware/usb-diagnostics/Invoke-UsbDiagnostics.ps1

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Menu", "Firmware", "PNP", "Events", "Hub", "USB4")]
    [string]$Category = "Menu"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Point to tools/ subdirectory where actual diagnostic scripts live
$diagnosticsPath = Join-Path $PSScriptRoot "tools"

# Script categories with descriptions
$categories = @{
    "Firmware" = @(
        @{ Name = "check-firmware-version.ps1"; Desc = "Check USB device firmware versions" },
        @{ Name = "check-usb4-firmware.ps1"; Desc = "Check USB4 controller firmware" }
    )
    "PNP" = @(
        @{ Name = "check-pnp-devices.ps1"; Desc = "List all PnP USB devices" },
        @{ Name = "check-pnp-details.ps1"; Desc = "Detailed PnP device information" }
    )
    "Events" = @(
        @{ Name = "check-usb-event-logs.ps1"; Desc = "Scan Windows Event Log for USB errors" }
    )
    "Hub" = @(
        @{ Name = "check-usb-hub.ps1"; Desc = "Diagnose USB hub connectivity" }
    )
}

function Show-CategoryMenu {
    param($CategoryName)

    $scripts = $categories[$CategoryName]

    if (-not $scripts) {
        Write-Console "ERROR: Unknown category: $CategoryName" -ForegroundColor Red
        return
    }

    while ($true) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  USB Diagnostics - $CategoryName" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            Write-Console "  $($i + 1). $($script.Name)" -ForegroundColor White
            Write-Console "      $($script.Desc)" -ForegroundColor Gray
            Write-Console ""
        }

        Write-Console "  B. Back to main menu" -ForegroundColor Yellow
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        $selection = Read-Host "Select diagnostic tool (number or 'B' to back)"

        if ($selection -match "^[Bb]$") { return }

        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $scripts.Count) {
            $scriptToRun = $scripts[[int]$selection - 1]
            $scriptPath = Join-Path $diagnosticsPath $scriptToRun.Name

            if (Test-Path $scriptPath) {
                Write-Console "`nRunning: $($scriptToRun.Name)" -ForegroundColor Yellow
                Write-Console "======================================================" -ForegroundColor DarkGray
                Write-Console ""

                & $scriptPath

                Write-Console ""
                Write-Console "======================================================" -ForegroundColor DarkGray
                Write-Console "Execution Complete." -ForegroundColor Green
                Read-Host "Press Enter to continue"
            }
            else {
                Write-Console "ERROR: Script not found: $scriptPath" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  USB Diagnostics - Main Menu" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""
        Write-Console "  1. Firmware Checks (2 tools)" -ForegroundColor White
        Write-Console "      Check device and controller firmware versions" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  2. PnP Device Info (2 tools)" -ForegroundColor White
        Write-Console "      Enumerate and analyze PnP USB devices" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  3. Event Log Diagnostics (1 tool)" -ForegroundColor White
        Write-Console "      Scan Windows Event Log for USB issues" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  4. USB Hub Diagnostics (1 tool)" -ForegroundColor White
        Write-Console "      Analyze USB hub connectivity and power" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  Q. Quit" -ForegroundColor Yellow
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        $selection = Read-Host "Select category"

        switch ($selection) {
            "1" { Show-CategoryMenu -CategoryName "Firmware" }
            "2" { Show-CategoryMenu -CategoryName "PNP" }
            "3" { Show-CategoryMenu -CategoryName "Events" }
            "4" { Show-CategoryMenu -CategoryName "Hub" }
            {$_ -match "^[Qq]$"} { return }
        }
    }
}

# Entry Point
if ($Category -eq "Menu") {
    Show-MainMenu
}
else {
    Show-CategoryMenu -CategoryName $Category
}
