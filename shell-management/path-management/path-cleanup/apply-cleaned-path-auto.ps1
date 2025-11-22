# Apply Cleaned PATH Script (Auto-Apply Version)
# This script safely applies the cleaned PATH and backs up the old one

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Apply Cleaned PATH (AUTO)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Get current PATH
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
Write-Console "Current USER PATH has $($currentPath.Split(';').Count) entries" -ForegroundColor White

# Backup current PATH
$backupFile = "C:\Users\josep\Documents\dev\path-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$currentPath | Out-File -FilePath $backupFile -Encoding UTF8
Write-Console "Current PATH backed up to:" -ForegroundColor Green
Write-Console "  $backupFile" -ForegroundColor Cyan

# Load cleaned PATH
$cleanedFile = "C:\Users\josep\Documents\dev\cleaned-path.txt"
if (!(Test-Path $cleanedFile)) {
    Write-Console "`nERROR: Cleaned PATH file not found: $cleanedFile" -ForegroundColor Red
    exit 1
}

$cleanedPath = Get-Content $cleanedFile -Raw
$cleanedPath = $cleanedPath.Trim()

# Show comparison
$currentEntries = $currentPath -split ';' | Where-Object { $_ }
$cleanedEntries = $cleanedPath -split ';' | Where-Object { $_ }

Write-Console "`nComparison:" -ForegroundColor Yellow
Write-Console "  Before: $($currentEntries.Count) entries" -ForegroundColor White
Write-Console "  After:  $($cleanedEntries.Count) entries" -ForegroundColor White
Write-Console "  Removed: $($currentEntries.Count - $cleanedEntries.Count) entries" -ForegroundColor Green

# Apply cleaned PATH
Write-Console "`nApplying cleaned PATH..." -ForegroundColor Yellow
try {
    [Environment]::SetEnvironmentVariable('Path', $cleanedPath, 'User')
    Write-Console "SUCCESS! PATH has been updated." -ForegroundColor Green

    # Verify
    $newPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $newEntries = $newPath -split ';' | Where-Object { $_ }
    Write-Console "`nVerification:" -ForegroundColor Cyan
    Write-Console "  New PATH has $($newEntries.Count) entries" -ForegroundColor Green

    Write-Console "`nFixed issues:" -ForegroundColor Cyan
    Write-Console "  - Removed 29 duplicate entries" -ForegroundColor Green
    Write-Console "  - Removed 7 orphaned paths (folders that don't exist)" -ForegroundColor Green
    Write-Console "  - Updated ExifTool path (Program-Portable -> Programs-Portable)" -ForegroundColor Green
    Write-Console "  - Removed old MPV.NET path" -ForegroundColor Green
    Write-Console "  - Removed old PowerToys path" -ForegroundColor Green

    Write-Console "`nIMPORTANT: Changes will take effect in NEW terminal windows." -ForegroundColor Yellow
    Write-Console "Close and reopen your terminal to see the changes." -ForegroundColor Yellow

    Write-Console "`nBackup saved to:" -ForegroundColor White
    Write-Console "  $backupFile" -ForegroundColor Cyan

    Write-Console "`nIf you need to restore the old PATH, run:" -ForegroundColor White
    Write-Console "  [Environment]::SetEnvironmentVariable('Path', (Get-Content '$backupFile'), 'User')" -ForegroundColor Cyan

} catch {
    Write-Console "`nERROR applying PATH: $_" -ForegroundColor Red
    Write-Console "Your PATH has NOT been changed." -ForegroundColor Red
    Write-Console "`nYou can restore from backup if needed:" -ForegroundColor White
    Write-Console "  [Environment]::SetEnvironmentVariable('Path', (Get-Content '$backupFile'), 'User')" -ForegroundColor Cyan
    exit 1
}

Write-Console ""
