# Enable Bluetooth Radio
# Fixes grey/stuck Bluetooth icon after CalDigit crash

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Enabling Bluetooth radio..." -ForegroundColor Cyan

Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null

# Request access
$accessLevel = [Windows.Devices.Radios.Radio]::RequestAccessAsync().AsTask().GetAwaiter().GetResult()
Write-Console "Access Level: $accessLevel"

# Get all radios
$radios = [Windows.Devices.Radios.Radio]::GetRadiosAsync().AsTask().GetAwaiter().GetResult()

# Find Bluetooth radio
$btRadio = $radios | Where-Object { $_.Kind -eq 'Bluetooth' }

if ($btRadio) {
    Write-Console "Found Bluetooth Radio: $($btRadio.Name)"
    Write-Console "Current State: $($btRadio.State)" -ForegroundColor Yellow

    if ($btRadio.State -ne 'On') {
        Write-Console "Turning Bluetooth ON..." -ForegroundColor Yellow
        $result = $btRadio.SetStateAsync('On').AsTask().GetAwaiter().GetResult()
        Write-Console "Result: $result" -ForegroundColor Green

        Start-Sleep -Seconds 2

        $newState = $btRadio.State
        Write-Console "New State: $newState" -ForegroundColor Green

        if ($newState -eq 'On') {
            Write-Console "Bluetooth radio successfully enabled!" -ForegroundColor Green
        } else {
            Write-Console "Warning: Bluetooth radio may not be fully enabled" -ForegroundColor Yellow
        }
    } else {
        Write-Console "Bluetooth radio is already ON" -ForegroundColor Green
    }
} else {
    Write-Console "ERROR: No Bluetooth radio found" -ForegroundColor Red
}

Write-Console ""
