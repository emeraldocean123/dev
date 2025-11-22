# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$ErrorActionPreference = "Stop"
Set-Location C:\Users\josep\Documents\git

if (Test-Path dev-repo.zip) {
    Remove-Item dev-repo.zip -Force
}

Compress-Archive -Path dev\* -DestinationPath dev-repo.zip -CompressionLevel Optimal -Force

if (Test-Path dev-repo.zip) {
    $size = (Get-Item dev-repo.zip).Length / 1MB
    Write-Host ""
    Write-Host "✓ Created dev-repo.zip" -ForegroundColor Green
    Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    Write-Host "  Location: C:\Users\josep\Documents\git\dev-repo.zip" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to create zip" -ForegroundColor Red
    exit 1
}

