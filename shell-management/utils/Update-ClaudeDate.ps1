# Update Claude Code date awareness
# This script updates the "Last Updated" date in CLAUDE.md
# Called automatically by PowerShell profile once per day

param()

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$claudeMdPath = Join-Path $HOME "CLAUDE.md"

if (-not (Test-Path $claudeMdPath)) {
    Write-Warning "CLAUDE.md not found at: $claudeMdPath"
    return
}

try {
    $content = Get-Content $claudeMdPath -Raw
    $todayDate = Get-Date -Format "MMMM d, yyyy"

    # Update the "Last Updated" line if it exists
    if ($content -match '\*\*Last Updated:\*\* .+') {
        $content = $content -replace '\*\*Last Updated:\*\* .+', "**Last Updated:** $todayDate"
        Set-Content -Path $claudeMdPath -Value $content -NoNewline
        Write-Console "Updated CLAUDE.md date to: $todayDate" -ForegroundColor Green
    } else {
        Write-Warning "Could not find 'Last Updated:' line in CLAUDE.md"
    }
} catch {
    Write-Error "Failed to update Claude date: $_"
}
