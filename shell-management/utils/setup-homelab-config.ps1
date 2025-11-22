# Homelab Configuration Setup
# Generates the central .config/homelab.settings.json file
# Location: shell-management/utils/setup-homelab-config.ps1
# Usage: ./setup-homelab-config.ps1

param(
    [switch]$Force
)

$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$configDir = Join-Path $devRoot ".config"
$configFile = Join-Path $configDir "homelab.settings.json"
$exampleFile = Join-Path $configDir "homelab.settings.example.json"

Write-Host "`n=== HOMELAB CONFIGURATION SETUP ===" -ForegroundColor Cyan
Write-Host ""

# Ensure .config directory exists
if (-not (Test-Path $configDir)) {
    Write-Host "Creating .config directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Check if real config already exists
if ((Test-Path $configFile) -and -not $Force) {
    Write-Host "✓ Configuration already exists: $configFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "To regenerate, use: ./setup-homelab-config.ps1 -Force" -ForegroundColor Gray
    Write-Host "WARNING: This will overwrite your existing configuration!" -ForegroundColor Yellow
    exit 0
}

# Copy example template to real config
if (Test-Path $exampleFile) {
    Write-Host "Copying example template to homelab.settings.json..." -ForegroundColor Yellow
    Copy-Item $exampleFile $configFile -Force
    Write-Host "✓ Configuration file created: $configFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Edit .config/homelab.settings.json with your real infrastructure values" -ForegroundColor White
    Write-Host "2. Replace placeholder IPs, MAC addresses, and paths" -ForegroundColor White
    Write-Host "3. Save the file - it's git-ignored so your secrets stay private" -ForegroundColor White
    Write-Host ""
    Write-Host "To open in editor:" -ForegroundColor Gray
    Write-Host "  notepad '$configFile'" -ForegroundColor DarkGray
} else {
    Write-Host "✗ ERROR: Example template not found at: $exampleFile" -ForegroundColor Red
    Write-Host "This file should exist in the repository. Please check your git clone." -ForegroundColor Yellow
    exit 1
}
