# Run Bidirectional Sync LIVE on Test Folder

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

&"$PSScriptRoot\sync-timestamps-bidirectional.ps1" -Path "D:\Mylio-Test" -DryRun:$false
