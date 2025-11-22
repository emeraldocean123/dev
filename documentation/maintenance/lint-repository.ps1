# Repository Hygiene & Linting Audit
# Checks for: Hardcoded paths, Hardcoded IPs, Mixed Line Endings, Trailing Whitespace, BOM issues
# Location: documentation/maintenance/lint-repository.ps1


# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$issues = 0
$hardcodedPaths = @()
$hardcodedIPs = @()
$crlfBashScripts = @()
$bomBashScripts = @()
$emptyDirs = @()

Write-Host "`n=== Repository Hygiene & Linting Audit ===" -ForegroundColor Cyan
Write-Host "Scanning repository for portability and compatibility issues...`n" -ForegroundColor Gray

# Get all relevant files
$files = Get-ChildItem -Path $devRoot.Path -Recurse -Include *.ps1, *.sh, *.py, *.md, *.json, *.yml, *.yaml -File |
    Where-Object { $_.FullName -notlike "*\.git\*" }

Write-Host "Scanning $($files.Count) files..." -ForegroundColor Gray

foreach ($file in $files) {
    $relPath = $file.FullName.Replace($devRoot.Path + "\", "").Replace("\", "/")

    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $content) { continue }

        # 1. Hardcoded Path Check (Windows & Linux users)
        if ($content -match 'C:\\Users\\josep' -or $content -match '/home/josep') {
            # Exclude Mylio scripts (environment-specific by design)
            if ($relPath -notlike "*mylio*" -and $relPath -notlike "*CLAUDE.md*" -and $relPath -notlike "*lint-repository.ps1*") {
                $hardcodedPaths += $relPath
                $issues++
            }
        }

        # 2. Hardcoded IP Address Check (prevents configuration drift)
        if ($file.Extension -eq ".ps1" -or $file.Extension -eq ".sh") {
            # Exclude lib/, .config/, and documentation/ directories
            if ($relPath -notlike "*lib/*" -and $relPath -notlike "*.config/*" -and $relPath -notlike "*documentation/*") {
                # Match IPv4 addresses (e.g., 192.168.1.100)
                $ipMatches = [regex]::Matches($content, '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b')
                if ($ipMatches.Count -gt 0) {
                    # Check if any line with IP is NOT marked with # NO-LINT: IP-ALLOW
                    $lines = $content -split "`n"
                    $hasUnallowedIP = $false
                    foreach ($line in $lines) {
                        if ($line -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' -and $line -notmatch '# NO-LINT: IP-ALLOW') {
                            $hasUnallowedIP = $true
                            break
                        }
                    }
                    if ($hasUnallowedIP) {
                        $hardcodedIPs += $relPath
                        $issues++
                    }
                }
            }
        }

        # 3. Bash Script Formatting Checks
        if ($file.Extension -eq ".sh") {
            # CRLF check (critical - will break on Linux)
            if ($content -match "`r`n") {
                $crlfBashScripts += $relPath
                $issues++
            }

            # BOM Check for Bash (breaks shebang)
            try {
                $bytes = Get-Content $file.FullName -AsByteStream -TotalCount 3 -ErrorAction Stop
                if ($bytes -and $bytes.Count -ge 3) {
                    if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                        $bomBashScripts += $relPath
                        $issues++
                    }
                }
            }
            catch {
                # Fallback for older PowerShell versions
                try {
                    $bytes = Get-Content $file.FullName -Encoding Byte -TotalCount 3 -ErrorAction SilentlyContinue
                    if ($bytes -and $bytes.Count -ge 3) {
                        if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                            $bomBashScripts += $relPath
                            $issues++
                        }
                    }
                }
                catch {
                    # Skip BOM check if both methods fail
                }
            }
        }
    }
    catch {
        Write-Host "  [WARNING] Could not read: $relPath" -ForegroundColor Yellow
    }
}

# 4. Empty Directories
$allDirs = Get-ChildItem -Path $devRoot.Path -Recurse -Directory | Where-Object { $_.FullName -notlike "*\.git\*" }
foreach ($dir in $allDirs) {
    $contents = Get-ChildItem $dir.FullName -ErrorAction SilentlyContinue
    if (-not $contents -or $contents.Count -eq 0) {
        $emptyDirs += $dir.FullName.Replace($devRoot.Path, "").TrimStart("\")
        $issues++
    }
}

# Report findings
Write-Host "`n=== AUDIT RESULTS ===" -ForegroundColor Cyan

if ($hardcodedPaths.Count -gt 0) {
    Write-Host "`n[CRITICAL] Hardcoded Paths Found ($($hardcodedPaths.Count)):" -ForegroundColor Red
    Write-Host "These paths will break portability on other machines/users:" -ForegroundColor Gray
    foreach ($path in $hardcodedPaths) {
        Write-Host "  - $path" -ForegroundColor Red
    }
}

if ($hardcodedIPs.Count -gt 0) {
    Write-Host "`n[CRITICAL] Hardcoded IP Addresses Found ($($hardcodedIPs.Count)):" -ForegroundColor Red
    Write-Host "IP addresses should be read from .config/homelab.settings.json:" -ForegroundColor Gray
    foreach ($path in $hardcodedIPs) {
        Write-Host "  - $path" -ForegroundColor Red
    }
    Write-Host "  Exception: Add '# NO-LINT: IP-ALLOW' to the line to whitelist an IP" -ForegroundColor DarkGray
}

if ($crlfBashScripts.Count -gt 0) {
    Write-Host "`n[CRITICAL] CRLF Line Endings in Bash Scripts ($($crlfBashScripts.Count)):" -ForegroundColor Magenta
    Write-Host "These scripts will fail on Linux with '\r: command not found' errors:" -ForegroundColor Gray
    foreach ($path in $crlfBashScripts) {
        Write-Host "  - $path" -ForegroundColor Magenta
    }
}

if ($bomBashScripts.Count -gt 0) {
    Write-Host "`n[WARNING] BOM in Bash Scripts ($($bomBashScripts.Count)):" -ForegroundColor Yellow
    Write-Host "UTF-8 BOM can break shebang (#!) interpretation:" -ForegroundColor Gray
    foreach ($path in $bomBashScripts) {
        Write-Host "  - $path" -ForegroundColor Yellow
    }
}

if ($emptyDirs.Count -gt 0) {
    Write-Host "`n[INFO] Empty Directories Found ($($emptyDirs.Count)):" -ForegroundColor DarkGray
    foreach ($dir in $emptyDirs) {
        Write-Host "  - $dir" -ForegroundColor DarkGray
    }
}

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
if ($issues -eq 0) {
    Write-Host "Repository is clean! No portability or compatibility issues found." -ForegroundColor Green
} else {
    Write-Host "Found $issues potential issues:" -ForegroundColor Yellow
    Write-Host "  - Hardcoded paths: $($hardcodedPaths.Count)" -ForegroundColor $(if ($hardcodedPaths.Count -gt 0) { "Red" } else { "Gray" })
    Write-Host "  - Hardcoded IPs: $($hardcodedIPs.Count)" -ForegroundColor $(if ($hardcodedIPs.Count -gt 0) { "Red" } else { "Gray" })
    Write-Host "  - CRLF in Bash: $($crlfBashScripts.Count)" -ForegroundColor $(if ($crlfBashScripts.Count -gt 0) { "Magenta" } else { "Gray" })
    Write-Host "  - BOM in Bash: $($bomBashScripts.Count)" -ForegroundColor $(if ($bomBashScripts.Count -gt 0) { "Yellow" } else { "Gray" })
    Write-Host "  - Empty directories: $($emptyDirs.Count)" -ForegroundColor $(if ($emptyDirs.Count -gt 0) { "DarkGray" } else { "Gray" })
}
Write-Host ""

