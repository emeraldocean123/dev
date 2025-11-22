# Fix PowerShell Profile - Add guards for non-interactive environments

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$profilePath = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"

$content = Get-Content $profilePath -Raw

# Fix 1: Add guard for PSReadLine predictions
$oldPrediction = @'
    # Advanced prediction features require PSReadLine 2.1.0+
    if ($psReadLineVersion -and $psReadLineVersion -ge [version]'2.1.0') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
'@

$newPrediction = @'
    # Advanced prediction features require PSReadLine 2.1.0+ and interactive terminal with VT support
    $isInteractive = $Host.UI.SupportsVirtualTerminal -and
                     -not $env:CI -and
                     -not $env:GITHUB_ACTIONS -and
                     -not $env:TF_BUILD -and
                     [Environment]::UserInteractive

    if ($psReadLineVersion -and $psReadLineVersion -ge [version]'2.1.0' -and $isInteractive) {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
'@

$content = $content -replace [regex]::Escape($oldPrediction), $newPrediction

# Fix 2: Add guard for oh-my-posh
$oldOhMyPosh = @'
# --- Oh My Posh Theme ---
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    # Look for theme in the same directory as this profile
    $localTheme = Join-Path $PSScriptRoot "jandedobbeleer.omp.json"

    if (Test-Path $localTheme) {
        oh-my-posh init pwsh --config $localTheme | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config jandedobbeleer | Invoke-Expression
    }
}
'@

$newOhMyPosh = @'
# --- Oh My Posh Theme ---
# Only initialize in interactive terminals (not in CI/automation/non-VT environments)
$isInteractiveTerminal = $Host.UI.SupportsVirtualTerminal -and
                         -not $env:CI -and
                         -not $env:GITHUB_ACTIONS -and
                         -not $env:TF_BUILD -and
                         [Environment]::UserInteractive

$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp -and $isInteractiveTerminal) {
    # Look for theme in the same directory as this profile
    $localTheme = Join-Path $PSScriptRoot "jandedobbeleer.omp.json"

    if (Test-Path $localTheme) {
        oh-my-posh init pwsh --config $localTheme | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config jandedobbeleer | Invoke-Expression
    }
}
'@

$content = $content -replace [regex]::Escape($oldOhMyPosh), $newOhMyPosh

# Write the fixed content
$content | Set-Content $profilePath -NoNewline

Write-Host "✓ PowerShell profile fixed!" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Cyan
Write-Host "  1. Added VT support check for PSReadLine predictions"
Write-Host "  2. Added CI/automation environment detection"
Write-Host "  3. Added guards for oh-my-posh initialization"
Write-Host ""
Write-Host "Backup saved to: Microsoft.PowerShell_profile.ps1.backup"

