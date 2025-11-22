<#
.SYNOPSIS
    Repository Standardization Tool
    1. Updates # Location: headers to match actual file paths.
    2. Injects generic lib/Utils.ps1 imports with correct relative paths.

.NOTES
    Run this from the root 'dev' directory.
#>

$devRoot = Get-Location
$utilsPath = Join-Path $devRoot "lib\Utils.ps1"
$changes = 0

if (-not (Test-Path $utilsPath)) { Write-Error "Run from dev root!"; exit }

Write-Host "Starting Standardization Run..." -ForegroundColor Cyan

# Filter for scripts that should have the library
$scripts = Get-ChildItem -Recurse -Include *.ps1 |
    Where-Object {
        $_.FullName -notlike "*\lib\*" -and
        $_.FullName -notlike "*\ai-configs\*" -and
        $_.Name -ne "Microsoft.PowerShell_profile.ps1" -and
        $_.Name -ne "apply-standards.ps1" -and
        $_.Name -ne "deep-audit.ps1"
    }

foreach ($file in $scripts) {
    $content = Get-Content $file.FullName -Raw
    if (-not $content) { continue }

    $relPath = $file.FullName.Replace($devRoot.Path + "\", "").Replace("\", "/")
    $fileDir = $file.DirectoryName

    # --- 1. Calculate Correct Relative Path to Utils ---
    $depth = ($fileDir.Replace($devRoot.Path, "").Trim("\").Split("\") | Where-Object { $_ }).Count
    $relPrefix = if ($depth -eq 0) { "." } else { (1..$depth | ForEach-Object { ".." }) -join "\" }
    $correctImportStr = '$libPath = Join-Path $PSScriptRoot "' + $relPrefix + '\lib\Utils.ps1"'

    $importBlock = @"
# Import shared utilities
$correctImportStr
if (Test-Path `$libPath) { . `$libPath } else { Write-Host "WARNING: Utils not found at `$libPath" -ForegroundColor Yellow }

"@

    $newContent = $content
    $modified = $false

    # --- 2. Fix Location Header ---
    if ($content -match '# Location: .+' -and $content -notmatch "# Location: $relPath") {
        $newContent = $newContent -replace '# Location: .+', "# Location: $relPath"
        Write-Host "  [HEADER] Fixed: $relPath" -ForegroundColor Yellow
        $modified = $true
    }

    # --- 3. Fix/Inject Import ---
    if ($content -notmatch 'lib\\Utils\.ps1' -and $content -notmatch 'lib/Utils\.ps1') {
        # Skip scripts with [CmdletBinding()] - they need decorator immediately before param()
        if ($content -match '\[CmdletBinding\(\)\]') {
            Write-Host "  [SKIP]   Has [CmdletBinding()]: $relPath" -ForegroundColor DarkGray
        }
        # Only inject if not a simple profile or wrapper
        elseif ($file.Name -ne "homelab.ps1") {
            $lines = $newContent -split "`r?`n"
            $insertIdx = 0

            # Skip shebang and top comments/blank lines
            for ($i=0; $i -lt $lines.Count; $i++) {
                if ($lines[$i].StartsWith("#") -or $lines[$i].Trim() -eq "" -or $lines[$i].StartsWith("<#")) {
                    $insertIdx = $i + 1
                    # Skip multiline comment blocks
                    if ($lines[$i] -match "^<#") {
                        while ($i -lt $lines.Count -and $lines[$i] -notmatch "#>") { $i++; $insertIdx = $i + 1 }
                    }
                } else { break }
            }

            # Reconstruct
            if ($insertIdx -gt 0 -and $insertIdx -lt $lines.Count) {
                $pre = $lines[0..($insertIdx-1)] -join "`r`n"
                $post = $lines[$insertIdx..($lines.Count-1)] -join "`r`n"
                $newContent = "$pre`r`n`r`n$importBlock$post"
            } else {
                $newContent = "$importBlock$newContent"
            }

            Write-Host "  [IMPORT] Injected library: $relPath" -ForegroundColor Green
            $modified = $true
        }
    } elseif ($content -match 'Join-Path \$PSScriptRoot "(.+?)\\lib\\Utils\.ps1"') {
        # Fix broken existing relative paths
        $existingRel = $Matches[1]
        $targetRel = $relPrefix

        if ($existingRel -ne $targetRel) {
            $newContent = $newContent.Replace("`"$existingRel\lib\Utils.ps1`"", "`"$targetRel\lib\Utils.ps1`"")
            Write-Host "  [PATH]   Fixed relative import: $relPath ($existingRel -> $targetRel)" -ForegroundColor Cyan
            $modified = $true
        }
    }

    if ($modified) {
        $newContent | Set-Content -Path $file.FullName -Encoding UTF8
        $changes++
    }
}

$color = if ($changes -gt 0) { "Green" } else { "Gray" }
Write-Host "`nStandardization Complete. Updated $changes files." -ForegroundColor $color
