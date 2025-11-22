
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Stop Immich Photo Management
# Quick stop script for Immich on Windows 11 with Docker Desktop

Write-Console "Stopping Immich..." -ForegroundColor Yellow

# Change to Immich directory
Set-Location "$PSScriptRoot"

# Stop containers
docker compose down

Write-Console "`nImmich stopped successfully" -ForegroundColor Green

