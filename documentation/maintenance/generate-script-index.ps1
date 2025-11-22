# Generate Script Index
# Automatically generates documentation/script-index.md by scanning directory structure
# Location: documentation/maintenance/generate-script-index.ps1

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found" -ForegroundColor Yellow }

# Get dev root (2 levels up from script location)
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$outputPath = Join-Path $devRoot "documentation\script-index.md"

# Directories to skip
$skipDirs = @('.git', '.config', 'archive', 'archives', 'lib', 'tools', 'node_modules', '.vscode')

Write-Host ""
Write-Host "Generating Script Index..." -ForegroundColor Cyan
Write-Host "Scanning: $devRoot" -ForegroundColor Gray
Write-Host ""

# Scan for all scripts
$allScripts = Get-ChildItem -Path $devRoot -Recurse -Include *.ps1, *.py, *.sh -File |
    Where-Object {
        $skip = $false
        foreach ($dir in $skipDirs) {
            if ($_.FullName -match "\\$dir(\\|$)") {
                $skip = $true
                break
            }
        }
        -not $skip -and $_.Name -notlike "_*" -and $_.Name -notlike "common.ps1"
    }

# Group scripts by directory
$grouped = $allScripts | Group-Object -Property DirectoryName | Sort-Object Name

# Build markdown content
$markdown = @"
# Dev Folder Script Index

Automatically generated script inventory. Last updated: $(Get-Date -Format "MMMM d, yyyy")

**Total Scripts:** $($allScripts.Count)
**Total Categories:** $($grouped.Count)

---

"@

# Process each directory
foreach ($group in $grouped) {
    $dirName = $group.Name.Replace($devRoot, "").TrimStart('\').Replace('\', '/')
    $scriptCount = $group.Count

    $markdown += "`n## $dirName ($scriptCount scripts)`n`n"

    foreach ($script in $group.Group | Sort-Object Name) {
        $scriptName = $script.Name

        # Try to extract description from script header
        $description = ""
        try {
            $firstLines = Get-Content $script.FullName -TotalCount 20 -ErrorAction SilentlyContinue

            # Look for .SYNOPSIS (PowerShell)
            $synopsisIndex = $firstLines | Select-String -Pattern "^\.SYNOPSIS" | Select-Object -First 1
            if ($synopsisIndex) {
                $lineNum = $synopsisIndex.LineNumber
                if ($lineNum -lt $firstLines.Count) {
                    $description = $firstLines[$lineNum].Trim()
                }
            }

            # Fall back to first comment line
            if (-not $description) {
                $commentLine = $firstLines | Where-Object { $_ -match "^#\s+(.+)" -and $_ -notmatch "^#!/" } | Select-Object -First 1
                if ($commentLine) {
                    $description = ($commentLine -replace "^#\s*", "").Trim()
                }
            }

            # Default if no description found
            if (-not $description) {
                $description = "(No description available)"
            }
        }
        catch {
            $description = "(Error reading description)"
        }

        $markdown += "- **$scriptName** - $description`n"
    }
}

# Write to file
$markdown | Out-File -FilePath $outputPath -Encoding UTF8 -Force

# Summary
if (Test-Path $outputPath) {
    $sizeKB = [math]::Round((Get-Item $outputPath).Length / 1KB, 2)
    Write-Host "✓ Generated script-index.md" -ForegroundColor Green
    Write-Host "  Location: $outputPath" -ForegroundColor Gray
    Write-Host "  Size: $sizeKB KB" -ForegroundColor Gray
    Write-Host "  Scripts indexed: $($allScripts.Count)" -ForegroundColor Gray
    Write-Host "  Categories: $($grouped.Count)" -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "✗ Failed to generate script-index.md" -ForegroundColor Red
    exit 1
}
