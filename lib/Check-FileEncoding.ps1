<#
.SYNOPSIS
    Checks file encodings for compliance (PowerShell version).
.DESCRIPTION
    Replaces the bash-based check-file-encoding.sh to avoid 'file' command dependency.
#>

$scriptDir = $PSScriptRoot
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

$issues = 0

Write-Host "Checking file encodings in dev repository..." -ForegroundColor Cyan

# 1. Check Critical Files (BOM required for legacy PS compatibility)
$bomRequired = @(
    "shell-management\utils\winfetch.ps1"
)

Write-Host "`n=== Critical: Files Requiring UTF-8 with BOM ===" -ForegroundColor White

foreach ($relPath in $bomRequired) {
    $fullPath = Join-Path $repoRoot $relPath
    
    if (-not (Test-Path $fullPath)) {
        Write-Host "[FAIL] MISSING: $relPath" -ForegroundColor Red
        $issues++
        continue
    }

    # Read first 3 bytes
    try {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "[OK] $relPath" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] $relPath (Missing BOM)" -ForegroundColor Red
            Write-Host "   Fix: Must be UTF-8 with BOM for PowerShell 5 compatibility" -ForegroundColor Gray
            $issues++
        }
    } catch {
        Write-Host "[FAIL] ERROR reading ${relPath}: $_" -ForegroundColor Red
        $issues++
    }
}

# 2. Check for UTF-16 (Basic check)
Write-Host "`n=== Checking for Problematic Encodings ===" -ForegroundColor White
$psFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notmatch "\\.git\\" }

foreach ($file in $psFiles) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($bytes.Length -ge 2) {
            # Check for UTF-16 LE (FF FE) or BE (FE FF)
            if (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)) {
                Write-Host "[FAIL] $($file.Name): UTF-16 encoding detected (should be UTF-8)" -ForegroundColor Red
                $issues++
            }
        }
    } catch {
        # Ignore read errors on locked files etc
    }
}

if ($issues -eq 0) {
    Write-Host "`n[OK] All encoding checks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAIL] Found $issues encoding issue(s)" -ForegroundColor Red
    exit 1
}