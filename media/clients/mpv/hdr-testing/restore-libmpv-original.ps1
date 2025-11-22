# Restore Original libmpv-2.dll
# Run this if the new DLL causes issues

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$mpvnetPath = "$env:LOCALAPPDATA\Programs\mpv.net"
$currentDll = "$mpvnetPath\libmpv-2.dll"
$backupDll = "$mpvnetPath\libmpv-2.dll.backup-20251110"

Write-Console "Restoring original libmpv-2.dll..." -ForegroundColor Cyan
Write-Console ""

# Check if backup exists
if (-not (Test-Path $backupDll)) {
    Write-Error "Backup not found at: $backupDll"
    Write-Console ""
    Write-Console "Available backups:" -ForegroundColor Yellow
    Get-ChildItem "$mpvnetPath\libmpv-2.dll.backup-*" | ForEach-Object {
        Write-Console "  $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" -ForegroundColor Gray
    }
    exit 1
}

# Show current and backup info
Write-Console "Current DLL:" -ForegroundColor Yellow
$currentInfo = Get-Item $currentDll
Write-Console "  Size: $([math]::Round($currentInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Console "  Date: $($currentInfo.LastWriteTime)" -ForegroundColor Gray

Write-Console ""
Write-Console "Backup DLL:" -ForegroundColor Yellow
$backupInfo = Get-Item $backupDll
Write-Console "  Size: $([math]::Round($backupInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Console "  Date: $($backupInfo.LastWriteTime)" -ForegroundColor Gray

Write-Console ""
$confirm = Read-Host "Restore original DLL? (Y/N)"

if ($confirm -notmatch "^[Yy]") {
    Write-Console "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Perform restore
try {
    Copy-Item $backupDll $currentDll -Force
    Write-Console ""
    Write-Console "======================================================================" -ForegroundColor Green
    Write-Console "Original libmpv-2.dll restored successfully!" -ForegroundColor Green
    Write-Console "======================================================================" -ForegroundColor Green
    Write-Console ""
    Write-Console "Changes:" -ForegroundColor White
    Write-Console "  • Restored 98MB DLL (January 11, 2024)" -ForegroundColor Gray
    Write-Console "  • HDR tone mapping should work again" -ForegroundColor Gray
    Write-Console "  • HEIC support removed (use VLC instead)" -ForegroundColor Gray
    Write-Console ""
    Write-Console "Restart mpv.net to apply changes." -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to restore DLL: $($_.Exception.Message)"
    exit 1
}
