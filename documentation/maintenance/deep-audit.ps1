#!/usr/bin/env pwsh
# Deep Consistency Audit
# Run from 'dev' root

$devRoot = Get-Location
$issues = 0

Write-Host "Starting Deep Audit..." -ForegroundColor Cyan

# Define old paths that should effectively be dead in code
$forbiddenPaths = @("photos/", "applications/", "system-scripts/", "server-scripts/")

# Get all code/doc files
$files = Get-ChildItem -Recurse -Include *.ps1, *.sh, *.py, *.md, *.json -Exclude ".git"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if (-not $content) { continue }

    $relPath = $file.FullName.Replace($devRoot.Path + "\", "").Replace("\", "/")

    # --- Check A: Stale Location Headers ---
    # Only match actual location headers (at start of line, not in comments/strings)
    if ($content -match '(?m)^# Location: (.+)$') {
        $claimedLoc = $Matches[1].Trim()
        $normClaim = $claimedLoc.Replace("\", "/")
        $normClaimClean = $normClaim -replace "^~/", "" -replace "^dev/", ""

        if ($relPath -notlike "*$normClaimClean*") {
            Write-Host " [HEADER MISMATCH] $relPath" -ForegroundColor Yellow
            Write-Host "    Says: $claimedLoc" -ForegroundColor Gray
            $issues++
        }
    }

    # --- Check B: References to Dead Folders (excluding documentation files and this script) ---
    if ($file.Extension -ne ".md" -and $file.Name -ne "deep-audit.ps1") {
        foreach ($bad in $forbiddenPaths) {
            if ($content -match $bad) {
                # Look for path-like structures
                if ($content -match "[`"'][\w\-/]*$bad") {
                    Write-Host " [DEAD PATH REF]   $relPath" -ForegroundColor Red
                    Write-Host "    Contains: $bad" -ForegroundColor Gray
                    $issues++
                }
            }
        }
    }
}

# --- Check C: Empty Directories ---
$emptyDirs = Get-ChildItem -Recurse -Directory | Where-Object {
    $items = Get-ChildItem $_.FullName -Force
    $items.Count -eq 0
}
if ($emptyDirs) {
    foreach ($dir in $emptyDirs) {
        $dirPath = $dir.FullName.Replace($devRoot.Path, "")
        Write-Host " [EMPTY DIR]       $dirPath" -ForegroundColor Magenta
        $issues++
    }
}

$color = if ($issues -eq 0) { "Green" } else { "Yellow" }
Write-Host "`nAudit Complete. Found $issues potential issues." -ForegroundColor $color
