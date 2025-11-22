# final-privacy-audit.ps1
# Comprehensive Privacy & Personal Data Audit
# Scans the entire repository for potential privacy leaks before going public

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoPath = Get-Location
$findings = @()
$fileCount = 0

# Patterns to search for
$patterns = @{
    "IPv4 Addresses" = '192\.168\.\d{1,3}\.\d{1,3}'
    "MAC Addresses" = '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})'
    "Email Addresses" = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    "SSH Keys (Private)" = '-----BEGIN.*PRIVATE KEY-----'
    "Usernames (root)" = '\broot@'
    "Usernames (follett)" = '\bfollett'
    "Usernames (josep)" = '\bjosep'
    "Device Names (intel-1250p)" = 'intel-1250p'
    "Device Names (intel-n6005)" = 'intel-n6005'
    "Device Names (synology)" = 'synology-1520'
    "Device Names (alienware)" = 'alienware-18-area51'
    "Proxmox Hostnames" = 'proxmox-host'
    "UCG Router" = 'unifi-ucg-fiber'
    "USW Switch" = 'unifi-usw-pro-xg'
    "Linksys Mesh" = 'linksys-mx4200'
    "GL.iNet KVM" = 'glkvm-comet'
}

# Files/folders to exclude from scan
$excludePaths = @(
    '.git',
    '.config',
    'node_modules',
    'sanitize-history.ps1',
    'final-privacy-audit.ps1'
)

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Final Privacy & Personal Data Audit" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scanning repository for potential privacy leaks..." -ForegroundColor Yellow
Write-Host ""

# Get all files, excluding ignored paths
$files = Get-ChildItem -Path $repoPath -Recurse -File | Where-Object {
    $file = $_
    $shouldExclude = $false
    foreach ($exclude in $excludePaths) {
        if ($file.FullName -like "*\$exclude\*" -or $file.Name -eq $exclude) {
            $shouldExclude = $true
            break
        }
    }
    -not $shouldExclude
}

$totalFiles = $files.Count
Write-Host "Files to scan: $totalFiles" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    $fileCount++
    $relativePath = $file.FullName.Replace($repoPath.Path + '\', '')

    Write-Progress -Activity "Scanning files" -Status "$fileCount of $totalFiles" -PercentComplete (($fileCount / $totalFiles) * 100)

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content) {
            foreach ($patternName in $patterns.Keys) {
                $pattern = $patterns[$patternName]
                $matches = [regex]::Matches($content, $pattern)

                if ($matches.Count -gt 0) {
                    foreach ($match in $matches) {
                        # Get line number
                        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count

                        $findings += [PSCustomObject]@{
                            File = $relativePath
                            Line = $lineNumber
                            Type = $patternName
                            Match = $match.Value
                        }
                    }
                }
            }
        }
    } catch {
        # Skip binary files or files we can't read
    }
}

Write-Progress -Activity "Scanning files" -Completed

# Generate Report
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AUDIT RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($findings.Count -eq 0) {
    Write-Host "[OK] NO PRIVACY LEAKS DETECTED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository is clean and ready for public sharing." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "WARNING: FOUND $($findings.Count) POTENTIAL PRIVACY LEAKS" -ForegroundColor Yellow
    Write-Host ""

    # Group by file
    $byFile = $findings | Group-Object File

    foreach ($group in $byFile | Sort-Object Name) {
        Write-Host "[FILE] $($group.Name)" -ForegroundColor Cyan

        $byType = $group.Group | Group-Object Type
        foreach ($typeGroup in $byType) {
            Write-Host "   ├─ $($typeGroup.Name): $($typeGroup.Count) occurrence(s)" -ForegroundColor Yellow

            # Show first 3 examples
            $examples = $typeGroup.Group | Select-Object -First 3
            foreach ($example in $examples) {
                Write-Host "   │  Line $($example.Line): $($example.Match)" -ForegroundColor Gray
            }

            if ($typeGroup.Count -gt 3) {
                Write-Host "   │  ... and $($typeGroup.Count - 3) more" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }

    # Summary by type
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Summary by Type:" -ForegroundColor Cyan
    Write-Host ""

    $byType = $findings | Group-Object Type | Sort-Object Count -Descending
    foreach ($typeGroup in $byType) {
        Write-Host "  $($typeGroup.Name): $($typeGroup.Count) occurrences" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Save detailed report
$reportPath = Join-Path $repoPath "privacy-audit-report.txt"
$findings | Format-Table -AutoSize | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Detailed report saved to: privacy-audit-report.txt" -ForegroundColor Cyan
Write-Host ""

# Return status
if ($findings.Count -eq 0) {
    Write-Host "[OK] Repository is SAFE for public sharing" -ForegroundColor Green
    exit 0
} else {
    Write-Host "WARNING: Review findings before proceeding" -ForegroundColor Yellow
    exit 1
}
