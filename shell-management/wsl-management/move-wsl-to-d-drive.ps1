# Move WSL distribution to D drive
# This saves space on C drive and provides better performance

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$distroName = "Debian"
$exportPath = "D:\WSL\Exports\debian-export.tar"
$importPath = "D:\WSL\Debian"
# Configuration: Set your WSL username here (change if different from Windows user)
$wslUser = "josep"

Write-Console "=== Move WSL Debian to D Drive ===" -ForegroundColor Cyan
Write-Console ""

# Create directories if they don't exist
Write-Console "Creating target directories..." -ForegroundColor Yellow
New-Item -Path "D:\WSL\Exports" -ItemType Directory -Force | Out-Null
New-Item -Path $importPath -ItemType Directory -Force | Out-Null
Write-Console "Directories created" -ForegroundColor Green
Write-Console ""

# Check current WSL status
Write-Console "Current WSL distributions:" -ForegroundColor Yellow
wsl --list --verbose
Write-Console ""

# Export the Debian distribution
Write-Console "Exporting Debian distribution (this may take several minutes)..." -ForegroundColor Yellow
wsl --export $distroName $exportPath

if ($LASTEXITCODE -ne 0) {
    Write-Console "ERROR: Failed to export $distroName" -ForegroundColor Red
    exit 1
}

$exportSize = (Get-Item $exportPath).Length / 1GB
Write-Console "Export complete: $([math]::Round($exportSize, 2)) GB" -ForegroundColor Green
Write-Console ""

# Unregister the old distribution
Write-Console "Unregistering original Debian distribution..." -ForegroundColor Yellow
wsl --unregister $distroName

if ($LASTEXITCODE -ne 0) {
    Write-Console "ERROR: Failed to unregister $distroName" -ForegroundColor Red
    Write-Console "Your export is safe at: $exportPath" -ForegroundColor Yellow
    exit 1
}

Write-Console "Unregistered successfully" -ForegroundColor Green
Write-Console ""

# Import to new location
Write-Console "Importing Debian to D:\WSL\Debian..." -ForegroundColor Yellow
wsl --import $distroName $importPath $exportPath

if ($LASTEXITCODE -ne 0) {
    Write-Console "ERROR: Failed to import $distroName" -ForegroundColor Red
    Write-Console "Your export is safe at: $exportPath" -ForegroundColor Yellow
    Write-Console "You can manually import with: wsl --import $distroName $importPath $exportPath" -ForegroundColor Yellow
    exit 1
}

Write-Console "Import complete" -ForegroundColor Green
Write-Console ""

# Verify new installation
Write-Console "Verifying new installation:" -ForegroundColor Yellow
wsl --list --verbose
Write-Console ""

# Set default user
Write-Console "Setting default user to $wslUser..." -ForegroundColor Yellow
wsl -d $distroName -u root -- bash -c "echo '[user]' > /etc/wsl.conf && echo 'default=$wslUser' >> /etc/wsl.conf"
Write-Console ""

# Cleanup
Write-Console "Cleanup:" -ForegroundColor Cyan
Write-Console "  - Export file kept at: $exportPath" -ForegroundColor Gray
Write-Console "  - Size: $([math]::Round($exportSize, 2)) GB" -ForegroundColor Gray
Write-Console "  - You can delete this after verifying everything works" -ForegroundColor Gray
Write-Console ""

Write-Console "=== Migration Complete ===" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  - Old location: $env:LOCALAPPDATA\Packages\..." -ForegroundColor Gray
Write-Console "  - New location: D:\WSL\Debian" -ForegroundColor Green
Write-Console "  - Backup export: $exportPath" -ForegroundColor Gray
Write-Console ""
Write-Console "Next steps:" -ForegroundColor Yellow
Write-Console "  1. Test WSL: wsl -d Debian" -ForegroundColor Gray
Write-Console "  2. Verify your files are intact" -ForegroundColor Gray
Write-Console "  3. After confirming everything works, delete: $exportPath" -ForegroundColor Gray
Write-Console ""
