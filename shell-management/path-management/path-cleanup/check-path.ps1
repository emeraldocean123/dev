# PATH Analysis Script

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Windows PATH Analysis" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../../../../")

# Get all PATH entries
$paths = $env:Path -split ';'

Write-Console "Total PATH entries: $($paths.Count)`n" -ForegroundColor Yellow

# Display all paths
Write-Console "All PATH entries:" -ForegroundColor White
Write-Console "=================" -ForegroundColor White
$i = 1
foreach ($path in $paths) {
    if ($path) {
        Write-Console "$i. $path"
        $i++
    }
}

# Check for duplicates
Write-Console "`n`nChecking for duplicates..." -ForegroundColor Yellow
$unique = @{}
$duplicates = @()
foreach ($path in $paths) {
    if ($path) {
        $normalized = $path.TrimEnd('\')
        if ($unique.ContainsKey($normalized)) {
            $duplicates += $path
        } else {
            $unique[$normalized] = $true
        }
    }
}

if ($duplicates.Count -gt 0) {
    Write-Console "`nDUPLICATES FOUND:" -ForegroundColor Red
    foreach ($dup in $duplicates) {
        Write-Console "  - $dup" -ForegroundColor Red
    }
} else {
    Write-Console "No duplicates found" -ForegroundColor Green
}

# Check for orphaned paths
Write-Console "`n`nChecking for orphaned paths (folders that don't exist)..." -ForegroundColor Yellow
$orphaned = @()
foreach ($path in $paths) {
    if ($path -and !(Test-Path $path)) {
        $orphaned += $path
    }
}

if ($orphaned.Count -gt 0) {
    Write-Console "`nORPHANED PATHS FOUND:" -ForegroundColor Red
    foreach ($orph in $orphaned) {
        Write-Console "  - $orph" -ForegroundColor Red
    }
} else {
    Write-Console "No orphaned paths found" -ForegroundColor Green
}

# Generate cleaned PATH
if ($duplicates.Count -gt 0 -or $orphaned.Count -gt 0) {
    Write-Console "`n`nGenerating cleaned PATH..." -ForegroundColor Yellow

    $cleanPaths = @()
    $seen = @{}

    foreach ($path in $paths) {
        if ($path) {
            $normalized = $path.TrimEnd('\')
            # Only add if not a duplicate and path exists
            if (!$seen.ContainsKey($normalized) -and (Test-Path $path)) {
                $cleanPaths += $path
                $seen[$normalized] = $true
            }
        }
    }

    $cleanedPath = $cleanPaths -join ';'

    Write-Console "`nCleaned PATH (removed $($duplicates.Count + $orphaned.Count) entries):" -ForegroundColor Green
    Write-Console "Total entries after cleanup: $($cleanPaths.Count)" -ForegroundColor Green

    # Save to file
    $outputFile = Join-Path $devRoot "cleaned-path.txt"
    $cleanedPath | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Console "`nCleaned PATH saved to: $outputFile" -ForegroundColor Cyan

    Write-Console "`n`nTo apply the cleaned PATH, run:" -ForegroundColor Yellow
    Write-Console "  [Environment]::SetEnvironmentVariable('Path', (Get-Content '$outputFile'), 'User')" -ForegroundColor White
    Write-Console "`nWARNING: Back up your current PATH before applying changes!" -ForegroundColor Red
}

Write-Console "`n"
