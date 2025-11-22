# Run Bidirectional Sync LIVE on Full Mylio Folder
# Uses OPTIMIZED version to prevent memory leaks
# This will process all 75,792 files
# Estimated time: 2-3 hours (much faster than old version)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

& "$PSScriptRoot\sync-timestamps-bidirectional-optimized.ps1" -Path "D:\Mylio" -DryRun:$false
