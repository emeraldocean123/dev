# Fix Unicode box drawing characters in homelab.ps1


# Import shared utilities
$libPath = Join-Path $PSScriptRoot ".\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$file = Join-Path $PSScriptRoot "homelab.ps1"
$content = Get-Content $file -Raw -Encoding UTF8

# Replace Unicode box drawing character with equals signs
$content = $content -replace 'â•', '='

# Save back
$content | Set-Content $file -Encoding UTF8 -NoNewline

Write-Host "Fixed Unicode characters in homelab.ps1" -ForegroundColor Green

