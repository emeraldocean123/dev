# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$ErrorActionPreference = "Stop"

# Get dev root (2 levels up from script location)
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")

# Save zip in documentation/archives/
$zipPath = Join-Path $devRoot "documentation\archives\dev-repo.zip"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Change to dev root and create zip
Set-Location $devRoot
Compress-Archive -Path * -DestinationPath $zipPath -CompressionLevel Optimal -Force

if (Test-Path $zipPath) {
    $size = (Get-Item $zipPath).Length / 1MB
    Write-Host ""
    Write-Host "✓ Created dev-repo.zip" -ForegroundColor Green
    Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    Write-Host "  Location: $zipPath" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to create zip" -ForegroundColor Red
    exit 1
}

