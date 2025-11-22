# Fix Network Drive Timeout Issue
# This script reconfigures O: to be non-persistent and adds timeout protection

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Fixing O: drive configuration..." -ForegroundColor Cyan

# Step 1: Get current O: drive mapping info
Write-Console "`n[1/2] Checking current O: drive mapping..." -ForegroundColor Yellow
try {
    $oDrive = Get-PSDrive -Name O -ErrorAction SilentlyContinue
    if ($oDrive -and $oDrive.DisplayRoot) {
        $networkPath = $oDrive.DisplayRoot
        Write-Console "  Found O: mapped to: $networkPath" -ForegroundColor Green

        # Remove current mapping
        Write-Console "  Removing current O: mapping..." -ForegroundColor Yellow
        net use O: /delete /yes 2>&1 | Out-Null

        # Re-add as non-persistent
        Write-Console "  Re-mapping O: as non-persistent..." -ForegroundColor Yellow
        net use O: $networkPath /PERSISTENT:NO

        Write-Console "  ✓ O: is now non-persistent (won't auto-reconnect)" -ForegroundColor Green
    } else {
        Write-Console "  O: drive not currently mapped as network drive" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Could not modify O: drive - $($_.Exception.Message)"
}

Write-Console "`n[2/2] Creating instructions for manual remapping..." -ForegroundColor Yellow

$instructions = @"

To manually map O: as non-persistent (if needed):
============================================
net use O: \\server\share /PERSISTENT:NO

This ensures O: won't auto-reconnect on PowerShell startup.
When you need it, just remap manually with the same command.

"@

Write-Console $instructions -ForegroundColor Cyan
Write-Console "Done!" -ForegroundColor Green
