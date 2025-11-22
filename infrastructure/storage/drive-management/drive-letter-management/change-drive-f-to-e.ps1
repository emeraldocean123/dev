# Change Drive Letter from F: to E:
# This script changes the drive letter assignment for the drive currently assigned to F:

param(
    [switch]$Force
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Console "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Console "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Console "Drive Letter Change: F: -> E:" -ForegroundColor Cyan
Write-Console "=" * 60 -ForegroundColor Cyan

# Check if E: is already in use
$driveE = Get-Partition | Where-Object {$_.DriveLetter -eq 'E'}
if ($driveE -and -not $Force) {
    Write-Console "ERROR: Drive E: is already in use!" -ForegroundColor Red
    Write-Console "Current E: assignment:" -ForegroundColor Yellow
    Get-Volume | Where-Object {$_.DriveLetter -eq 'E'} | Format-Table DriveLetter, FileSystemLabel, Size, SizeRemaining -AutoSize
    Write-Console "`nUse -Force parameter to override if you're sure." -ForegroundColor Yellow
    exit 1
}

# Get the partition currently assigned to F:
$driveF = Get-Partition | Where-Object {$_.DriveLetter -eq 'F'}
if (-not $driveF) {
    Write-Console "ERROR: No drive found with letter F:" -ForegroundColor Red
    Write-Console "`nCurrent drive assignments:" -ForegroundColor Yellow
    Get-Volume | Where-Object {$_.DriveLetter -ne $null} | Select-Object DriveLetter, FileSystemLabel, Size | Sort-Object DriveLetter | Format-Table -AutoSize
    exit 1
}

# Display current F: drive info
Write-Console "`nCurrent F: drive information:" -ForegroundColor Green
Get-Volume | Where-Object {$_.DriveLetter -eq 'F'} | Format-Table DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining -AutoSize

# Confirm the change
if (-not $Force) {
    Write-Console "`nThis will change drive F: to E:" -ForegroundColor Yellow
    $confirmation = Read-Host "Are you sure? (yes/no)"
    if ($confirmation -ne 'yes') {
        Write-Console "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Perform the change
try {
    Write-Console "`nChanging drive letter from F: to E:..." -ForegroundColor Cyan
    Set-Partition -DriveLetter F -NewDriveLetter E
    Write-Console "SUCCESS: Drive letter changed from F: to E:" -ForegroundColor Green

    # Display new configuration
    Write-Console "`nNew E: drive information:" -ForegroundColor Green
    Get-Volume | Where-Object {$_.DriveLetter -eq 'E'} | Format-Table DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining -AutoSize

} catch {
    Write-Console "ERROR: Failed to change drive letter!" -ForegroundColor Red
    Write-Console $_.Exception.Message -ForegroundColor Red
    exit 1
}
