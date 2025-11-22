# Get all unique file extensions in Mylio folder

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$extensions = Get-ChildItem -Path "D:\Mylio" -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object Extension |
    Where-Object { $_.Extension -ne '' } |
    Group-Object Extension |
    Select-Object -ExpandProperty Name |
    ForEach-Object { $_.ToLower().TrimStart('.') } |
    Sort-Object

Write-Console "`nAll file extensions found in D:\Mylio:`n" -ForegroundColor Cyan
$extensions | ForEach-Object { Write-Console "  $_" -ForegroundColor White }

Write-Console "`nTotal unique extensions: $($extensions.Count)`n" -ForegroundColor Cyan
