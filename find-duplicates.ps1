# Find Duplicate Files in Repository


# Import shared utilities
$libPath = Join-Path $PSScriptRoot ".\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$repoRoot = $PSScriptRoot

Write-Host "Scanning for duplicate files in: $repoRoot" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

$duplicates = Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -notlike '.*' -and $_.DirectoryName -notlike '*\node_modules\*' -and $_.DirectoryName -notlike '*\.git\*' } |
  Group-Object Name |
  Where-Object { $_.Count -gt 1 }

if ($duplicates.Count -eq 0) {
    Write-Host "No duplicate files found!" -ForegroundColor Green
} else {
    Write-Host "Found $($duplicates.Count) sets of duplicate filenames:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($dup in $duplicates) {
        Write-Host "Duplicate: $($dup.Name)" -ForegroundColor Yellow
        $dup.Group | ForEach-Object {
            $relPath = $_.FullName.Replace($repoRoot + "\", "")
            $size = [math]::Round($_.Length / 1KB, 2)
            $modified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Write-Host "  - $relPath ($size KB, Modified: $modified)"
        }
        Write-Host ""
    }
}

