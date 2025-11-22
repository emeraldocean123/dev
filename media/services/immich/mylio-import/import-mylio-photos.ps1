
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Import Mylio Photos to Immich using immich-go
# This script imports all photos from D:\Mylio into Immich
#
# CONFIGURATION:
#   Source: .config/homelab.settings.json
#   Required Fields:
#     - Secrets.ImmichServerUrl  (Immich server URL)
#     - Secrets.ImmichApiKey     (Immich API key)
#     - Paths.MylioCatalog       (Source photo directory)

Write-Console "Immich-Go Photo Import" -ForegroundColor Cyan
Write-Console "======================" -ForegroundColor Cyan
Write-Console ""

# Load configuration from homelab.settings.json
$configPath = Join-Path $PSScriptRoot "../../../.config/homelab.settings.json"

if (-not (Test-Path $configPath)) {
    Write-Console "ERROR: Config file not found at $configPath" -ForegroundColor Red
    Write-Console "       Please ensure .config/homelab.settings.json exists" -ForegroundColor Yellow
    exit 1
}

try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # Load values from config
    $IMMICH_SERVER  = $config.Secrets.ImmichServerUrl
    $IMMICH_API_KEY = $config.Secrets.ImmichApiKey
    $PHOTO_PATH     = $config.Paths.MylioCatalog

    # Validate that required values were loaded
    if (-not $IMMICH_SERVER -or -not $IMMICH_API_KEY -or -not $PHOTO_PATH) {
        Write-Console "ERROR: Missing required configuration values" -ForegroundColor Red
        Write-Console "       Check Secrets.ImmichServerUrl, Secrets.ImmichApiKey, and Paths.MylioCatalog" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Console "ERROR: Failed to load config: $_" -ForegroundColor Red
    exit 1
}

# Check if Mylio folder exists
if (-not (Test-Path $PHOTO_PATH)) {
    Write-Console "ERROR: Photo path does not exist: $PHOTO_PATH" -ForegroundColor Red
    exit 1
}

# Check if immich-go is available
$immichGo = Get-Command immich-go -ErrorAction SilentlyContinue
if (-not $immichGo) {
    Write-Console "ERROR: immich-go not found in PATH" -ForegroundColor Red
    Write-Console "Please ensure immich-go is installed and in your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Console "Server: $IMMICH_SERVER" -ForegroundColor Green
Write-Console "Source: $PHOTO_PATH" -ForegroundColor Green
Write-Console ""
Write-Console "Starting import..." -ForegroundColor Yellow
Write-Console ""

# Run immich-go upload from-folder
immich-go upload from-folder --server $IMMICH_SERVER --api-key $IMMICH_API_KEY $PHOTO_PATH

if ($LASTEXITCODE -eq 0) {
    Write-Console ""
    Write-Console "Import completed successfully!" -ForegroundColor Green
} else {
    Write-Console ""
    Write-Console "Import failed with error code: $LASTEXITCODE" -ForegroundColor Red
}

