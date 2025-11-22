# Comprehensive PATH variable audit and cleanup script

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "PATH Variable Audit & Cleanup" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Function to check if path exists
function Test-PathExists {
    param([string]$Path)
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
    return Test-Path $expandedPath
}

# Function to analyze PATH variable
function Get-PathAnalysis {
    param([string]$Scope)

    if ($Scope -eq "User") {
        $pathValue = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    } else {
        $pathValue = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    }

    if (-not $pathValue) {
        return @{
            Valid = @()
            Invalid = @()
            Duplicates = @()
            Total = 0
        }
    }

    $paths = $pathValue -split ';' | Where-Object { $_ -ne '' }
    $valid = @()
    $invalid = @()
    $seen = @{}
    $duplicates = @()

    foreach ($path in $paths) {
        $trimmedPath = $path.Trim()
        if ($trimmedPath -eq '') { continue }

        $lowerPath = $trimmedPath.ToLower()
        if ($seen.ContainsKey($lowerPath)) {
            $duplicates += $trimmedPath
            continue
        }
        $seen[$lowerPath] = $true

        if (Test-PathExists $trimmedPath) {
            $valid += $trimmedPath
        } else {
            $invalid += $trimmedPath
        }
    }

    return @{
        Valid = $valid
        Invalid = $invalid
        Duplicates = $duplicates
        Total = $paths.Count
    }
}

# Analyze User PATH
Write-Console "Analyzing USER PATH variable..." -ForegroundColor Yellow
$userAnalysis = Get-PathAnalysis -Scope "User"

Write-Console "`n--- USER PATH ANALYSIS ---" -ForegroundColor Cyan
Write-Console "Total entries: $($userAnalysis.Total)" -ForegroundColor White
Write-Console "Valid paths: $($userAnalysis.Valid.Count)" -ForegroundColor Green
Write-Console "Invalid/Orphaned paths: $($userAnalysis.Invalid.Count)" -ForegroundColor Red
Write-Console "Duplicate paths: $($userAnalysis.Duplicates.Count)" -ForegroundColor Yellow

if ($userAnalysis.Valid.Count -gt 0) {
    Write-Console "`nVALID USER PATHS:" -ForegroundColor Green
    $userAnalysis.Valid | ForEach-Object { Write-Console "  ✓ $_" -ForegroundColor Green }
}

if ($userAnalysis.Invalid.Count -gt 0) {
    Write-Console "`nINVALID/ORPHANED USER PATHS (will be removed):" -ForegroundColor Red
    $userAnalysis.Invalid | ForEach-Object { Write-Console "  ✗ $_" -ForegroundColor Red }
}

if ($userAnalysis.Duplicates.Count -gt 0) {
    Write-Console "`nDUPLICATE USER PATHS (will be removed):" -ForegroundColor Yellow
    $userAnalysis.Duplicates | ForEach-Object { Write-Console "  ⚠ $_" -ForegroundColor Yellow }
}

# Analyze System PATH
Write-Console "`n`nAnalyzing SYSTEM PATH variable..." -ForegroundColor Yellow
$systemAnalysis = Get-PathAnalysis -Scope "Machine"

Write-Console "`n--- SYSTEM PATH ANALYSIS ---" -ForegroundColor Cyan
Write-Console "Total entries: $($systemAnalysis.Total)" -ForegroundColor White
Write-Console "Valid paths: $($systemAnalysis.Valid.Count)" -ForegroundColor Green
Write-Console "Invalid/Orphaned paths: $($systemAnalysis.Invalid.Count)" -ForegroundColor Red
Write-Console "Duplicate paths: $($systemAnalysis.Duplicates.Count)" -ForegroundColor Yellow

if ($systemAnalysis.Valid.Count -gt 0) {
    Write-Console "`nVALID SYSTEM PATHS:" -ForegroundColor Green
    $systemAnalysis.Valid | ForEach-Object { Write-Console "  ✓ $_" -ForegroundColor Green }
}

if ($systemAnalysis.Invalid.Count -gt 0) {
    Write-Console "`nINVALID/ORPHANED SYSTEM PATHS (will be removed):" -ForegroundColor Red
    $systemAnalysis.Invalid | ForEach-Object { Write-Console "  ✗ $_" -ForegroundColor Red }
}

if ($systemAnalysis.Duplicates.Count -gt 0) {
    Write-Console "`nDUPLICATE SYSTEM PATHS (will be removed):" -ForegroundColor Yellow
    $systemAnalysis.Duplicates | ForEach-Object { Write-Console "  ⚠ $_" -ForegroundColor Yellow }
}

# Summary
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "CLEANUP SUMMARY" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan

$totalRemoved = $userAnalysis.Invalid.Count + $userAnalysis.Duplicates.Count + $systemAnalysis.Invalid.Count + $systemAnalysis.Duplicates.Count

if ($totalRemoved -eq 0) {
    Write-Console "`n✓ PATH variables are already clean! No changes needed." -ForegroundColor Green
} else {
    Write-Console "`nTotal entries to remove: $totalRemoved" -ForegroundColor Yellow
    Write-Console "  User PATH: $($userAnalysis.Invalid.Count + $userAnalysis.Duplicates.Count)" -ForegroundColor Yellow
    Write-Console "  System PATH: $($systemAnalysis.Invalid.Count + $systemAnalysis.Duplicates.Count)" -ForegroundColor Yellow

    Write-Console "`nProceed with cleanup? (Y/N): " -ForegroundColor Cyan -NoNewline
    $response = Read-Host

    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Console "`nCleaning up PATH variables..." -ForegroundColor Yellow

        # Clean User PATH
        if ($userAnalysis.Valid.Count -gt 0) {
            $cleanUserPath = $userAnalysis.Valid -join ';'
            [System.Environment]::SetEnvironmentVariable("Path", $cleanUserPath, [System.EnvironmentVariableTarget]::User)
            Write-Console "✓ User PATH cleaned" -ForegroundColor Green
        }

        # Clean System PATH
        if ($systemAnalysis.Valid.Count -gt 0) {
            $cleanSystemPath = $systemAnalysis.Valid -join ';'
            [System.Environment]::SetEnvironmentVariable("Path", $cleanSystemPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Console "✓ System PATH cleaned" -ForegroundColor Green
        }

        Write-Console "`n✓ Cleanup complete!" -ForegroundColor Green
        Write-Console "Note: You may need to restart applications or terminal windows to see the changes." -ForegroundColor Yellow
    } else {
        Write-Console "`nCleanup cancelled. No changes made." -ForegroundColor Yellow
    }
}

Read-Host "`nPress Enter to close"
