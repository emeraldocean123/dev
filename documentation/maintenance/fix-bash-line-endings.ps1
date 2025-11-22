# Fix CRLF Line Endings in Bash Scripts
# Converts all .sh files from CRLF to LF for Linux compatibility
# Location: documentation/maintenance/fix-bash-line-endings.ps1

$devRoot = Get-Location
$fixed = 0
$skipped = 0

Write-Host "`n=== Fixing Bash Script Line Endings ===" -ForegroundColor Cyan
Write-Host "Converting CRLF -> LF for Linux compatibility`n" -ForegroundColor Gray

# Get all bash scripts
$bashScripts = Get-ChildItem -Recurse -Filter "*.sh" -File |
    Where-Object { $_.FullName -notlike "*\.git\*" }

Write-Host "Found $($bashScripts.Count) bash scripts to check...`n" -ForegroundColor Gray

foreach ($file in $bashScripts) {
    $relPath = $file.FullName.Replace($devRoot.Path + "\", "").Replace("\", "/")

    try {
        # Read file content
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop

        if ($content -match "`r`n") {
            # Convert CRLF to LF
            $lfContent = $content -replace "`r`n", "`n"

            # Write back without BOM (use UTF8 without BOM)
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $lfContent, $utf8NoBom)

            Write-Host "  [FIXED] $relPath" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "  [OK]    $relPath (already LF)" -ForegroundColor DarkGray
            $skipped++
        }
    }
    catch {
        Write-Host "  [ERROR] $relPath - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Fixed: $fixed files" -ForegroundColor Green
Write-Host "Already OK: $skipped files" -ForegroundColor Gray
Write-Host "`nAll bash scripts are now Linux-compatible!" -ForegroundColor Green
Write-Host ""
