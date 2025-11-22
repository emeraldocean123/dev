
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Start Immich Photo Management
# Quick start script for Immich on Windows 11 with Docker Desktop

Write-Console "Starting Immich..." -ForegroundColor Green

# Change to Immich directory
Set-Location "$PSScriptRoot"

# Start containers
docker compose up -d

# Wait for containers to be healthy
Write-Console "`nWaiting for containers to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check status
Write-Console "`nContainer Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}`t{{.Status}}" | Select-String -Pattern "immich|NAMES"

Write-Console "`nImmich is ready!" -ForegroundColor Green
Write-Console "`nAccess Immich at: http://localhost:2283" -ForegroundColor Cyan
Write-Console "`nTo view logs:" -ForegroundColor Yellow
Write-Console "  docker compose logs -f" -ForegroundColor Gray
Write-Console "`nTo stop Immich:" -ForegroundColor Yellow
Write-Console "  docker compose down" -ForegroundColor Gray

