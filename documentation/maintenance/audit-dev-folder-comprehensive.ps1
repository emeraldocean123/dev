# Comprehensive Dev Folder Audit Script
# Analyzes ~/Documents/dev for cleanup opportunities

[CmdletBinding()]
param(
    [switch]$Execute  # If set, will actually perform cleanup operations
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
function Write-Console {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Object,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray
    )

    $message = ($Object -join ' ')
    if ($Host.UI -and $Host.UI.RawUI) {
        $rawUI = $Host.UI.RawUI
        $previous = $rawUI.ForegroundColor
        try {
            $rawUI.ForegroundColor = $ForegroundColor
            Write-Information -MessageData $message -InformationAction Continue
        } finally {
            $rawUI.ForegroundColor = $previous
        }
    } else {
        Write-Information -MessageData $message -InformationAction Continue
    }
}

$devPath = "C:\Users\josep\Documents\dev"
$reportPath = "C:\Users\josep\Documents\dev\documentation\audits\dev-folder-audit-2025-11-13.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Console "=== Dev Folder Comprehensive Audit ===" -ForegroundColor Cyan
Write-Console "Started: $timestamp" -ForegroundColor Gray
Write-Console ""

# Initialize report
$report = @"
# Dev Folder Comprehensive Audit
**Date:** $timestamp
**Location:** $devPath

## Executive Summary

"@

# Get all files
Write-Console "Scanning all files..." -ForegroundColor Yellow
$allFiles = Get-ChildItem -Path $devPath -Recurse -File

$totalFiles = $allFiles.Count
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

$report += @"
- **Total Files:** $totalFiles
- **Total Size:** $totalSizeMB MB

---

## 1. Temporary and Log Files Analysis

"@

Write-Console "Analyzing temporary and log files..." -ForegroundColor Yellow

# Categorize temp/log files
$tempFiles = @()
$tempSize = 0

# Find .txt report files (likely temporary)
$reportFiles = $allFiles | Where-Object {
    $_.Extension -eq '.txt' -and
    ($_.Name -match 'report-\d{4}-\d{2}-\d{2}' -or
     $_.Name -match 'scan-\d{4}-\d{2}-\d{2}' -or
     $_.Name -match 'output\.txt' -or
     $_.Name -match 'dryrun')
}

$reportFileCount = $reportFiles.Count
$reportFileSize = [math]::Round(($reportFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

$report += @"
### Report/Log Files (Dated .txt files)
- **Count:** $reportFileCount files
- **Size:** $reportFileSize MB
- **Recommendation:** Move to archive subfolder or delete if older than 30 days

#### Files Found:
"@

foreach ($file in $reportFiles | Sort-Object DirectoryName, Name) {
    $relPath = $file.FullName.Replace($devPath, '~\Documents\dev')
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    $age = ((Get-Date) - $file.LastWriteTime).Days
    $report += "`n- ``$relPath`` ($sizeMB MB, $age days old)"
    $tempFiles += $file
    $tempSize += $file.Length
}

# Find files without extensions
$noExtFiles = $allFiles | Where-Object { $_.Extension -eq '' }
if ($noExtFiles) {
    $report += @"

### Files Without Extensions
- **Count:** $($noExtFiles.Count) files

"@
    foreach ($file in $noExtFiles) {
        $relPath = $file.FullName.Replace($devPath, '~\Documents\dev')
        $report += "`n- ``$relPath``"
        $tempFiles += $file
        $tempSize += $file.Length
    }
}

$report += @"


---

## 2. Duplicate and Similar Scripts Analysis

"@

Write-Console "Analyzing for duplicates..." -ForegroundColor Yellow

# Find scripts with similar names (potential duplicates)
$scripts = $allFiles | Where-Object { $_.Extension -eq '.ps1' }
$scriptGroups = $scripts | Group-Object {
    $name = $_.BaseName -replace '-optimized$', '' -replace '-v\d+$', ''
    $name
} | Where-Object { $_.Count -gt 1 }

$report += @"
### Potential Duplicate Scripts
Found $($scriptGroups.Count) groups of similar scripts:

"@

foreach ($group in $scriptGroups) {
    $report += "`n#### $($group.Name)"
    foreach ($file in $group.Group | Sort-Object LastWriteTime -Descending) {
        $relPath = $file.FullName.Replace($devPath, '~\Documents\dev')
        $lastMod = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        $sizeMB = [math]::Round($file.Length / 1KB, 1)
        $report += "`n- ``$($file.Name)`` ($sizeMB KB, modified: $lastMod)"
    }
    $report += ""
}

$report += @"

---

## 3. Documentation Link Validation

"@

Write-Console "Validating markdown links..." -ForegroundColor Yellow

# Find all markdown files
$mdFiles = $allFiles | Where-Object { $_.Extension -eq '.md' }
$brokenLinks = @()
$totalLinks = 0

foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName -Raw

    # Find all markdown links [text](path)
    $links = [regex]::Matches($content, '\[([^\]]+)\]\(([^\)]+)\)')

    foreach ($link in $links) {
        $totalLinks++
        $linkPath = $link.Groups[2].Value

        # Skip URLs
        if ($linkPath -match '^https?://') { continue }
        if ($linkPath -match '^#') { continue }  # Skip anchor links

        # Resolve relative path
        $fullPath = Join-Path (Split-Path $mdFile.FullName) $linkPath

        if (-not (Test-Path $fullPath)) {
            $brokenLinks += @{
                File = $mdFile.FullName.Replace($devPath, '~\Documents\dev')
                Link = $linkPath
            }
        }
    }
}

$report += @"
- **Total Links Checked:** $totalLinks
- **Broken Links:** $($brokenLinks.Count)

"@

if ($brokenLinks.Count -gt 0) {
    $report += "`n### Broken Links Found:`n"
    foreach ($broken in $brokenLinks) {
        $report += "`n- In ``$($broken.File)``"
        $report += "`n  - Link: ``$($broken.Link)``"
    }
}

$report += @"


---

## 4. File Organization Issues

"@

Write-Console "Checking file organization..." -ForegroundColor Yellow

# Find files that might be in wrong location
$misplacedFiles = @()

# Check for .sh files outside of sh/ folder
$shFiles = $allFiles | Where-Object { $_.Extension -eq '.sh' -and $_.DirectoryName -notmatch '\\sh($|\\)' }
if ($shFiles) {
    foreach ($file in $shFiles) {
        $misplacedFiles += @{
            File = $file.FullName.Replace($devPath, '~\Documents\dev')
            Reason = "Bash script outside of sh/ folder"
            Suggestion = "Move to ~/Documents/dev/sh/"
        }
    }
}

# Check for service files outside backup/services or vpn folders
$serviceFiles = $allFiles | Where-Object {
    $_.Extension -eq '.service' -and
    $_.DirectoryName -notmatch '\\(backup\\services|vpn)($|\\)'
}
if ($serviceFiles) {
    foreach ($file in $serviceFiles) {
        $misplacedFiles += @{
            File = $file.FullName.Replace($devPath, '~\Documents\dev')
            Reason = "Service file in unexpected location"
            Suggestion = "Move to ~/Documents/dev/backup/services/ or ~/Documents/dev/vpn/"
        }
    }
}

$report += @"
### Potentially Misplaced Files
Found $($misplacedFiles.Count) files that may be in the wrong location:

"@

foreach ($item in $misplacedFiles) {
    $report += "`n- ``$($item.File)``"
    $report += "`n  - **Issue:** $($item.Reason)"
    $report += "`n  - **Suggestion:** $($item.Suggestion)"
    $report += ""
}

$report += @"


---

## 5. Naming Convention Violations

"@

Write-Console "Checking naming conventions..." -ForegroundColor Yellow

# Check for files not following kebab-case
$namingViolations = @()

foreach ($file in $allFiles) {
    $name = $file.BaseName

    # Skip README files and system files
    if ($name -eq 'README' -or $name -match '^Microsoft\.') { continue }

    # Check if kebab-case (all lowercase, hyphens only)
    if ($name -match '[A-Z]' -or $name -match '_') {
        $namingViolations += @{
            File = $file.FullName.Replace($devPath, '~\Documents\dev')
            CurrentName = $file.Name
            Issue = if ($name -match '[A-Z]') { "Contains uppercase letters" } else { "Contains underscores" }
            Suggestion = $name -replace '_', '-' | ForEach-Object { $_.ToLower() }
        }
    }
}

$report += @"
### Files Not Following kebab-case Convention
Found $($namingViolations.Count) files with naming issues:

"@

foreach ($violation in $namingViolations | Select-Object -First 20) {
    $report += "`n- ``$($violation.CurrentName)``"
    $report += "`n  - **Issue:** $($violation.Issue)"
    $report += "`n  - **Suggested:** ``$($violation.Suggestion)$($allFiles | Where-Object { $_.Name -eq $violation.CurrentName } | Select-Object -First 1 -ExpandProperty Extension)``"
    $report += ""
}

if ($namingViolations.Count -gt 20) {
    $report += "`n*... and $($namingViolations.Count - 20) more*"
}

$report += @"


---

## 6. Consolidation Opportunities

"@

Write-Console "Identifying consolidation opportunities..." -ForegroundColor Yellow

# Find folders with only 1-2 files
$sparseFolders = Get-ChildItem -Path $devPath -Recurse -Directory | Where-Object {
    $fileCount = (Get-ChildItem $_.FullName -File).Count
    $fileCount -le 2 -and $fileCount -gt 0
} | ForEach-Object {
    @{
        Folder = $_.FullName.Replace($devPath, '~\Documents\dev')
        FileCount = (Get-ChildItem $_.FullName -File).Count
        Files = (Get-ChildItem $_.FullName -File | Select-Object -ExpandProperty Name) -join ', '
    }
}

$report += @"
### Sparse Folders (1-2 files)
Found $($sparseFolders.Count) folders with very few files (consider consolidating):

"@

foreach ($folder in $sparseFolders) {
    $report += "`n- ``$($folder.Folder)`` ($($folder.FileCount) file(s))"
    $report += "`n  - Files: $($folder.Files)"
    $report += ""
}

$report += @"


---

## 7. Cleanup Recommendations Summary

"@

$totalTempSizeMB = [math]::Round($tempSize / 1MB, 2)

$report += @"

### High Priority
1. **Archive or delete dated report files** - $reportFileCount files ($reportFileSize MB)
   - Older than 30 days should be deleted
   - Recent files should be moved to archive subfolders

2. **Remove files without extensions** - $($noExtFiles.Count) files
   - These appear to be temp/test files

3. **Fix broken documentation links** - $($brokenLinks.Count) broken links found

### Medium Priority
4. **Consolidate duplicate scripts** - $($scriptGroups.Count) script groups with potential duplicates
   - Keep only the latest/optimized version
   - Archive or delete older versions

5. **Fix naming convention violations** - $($namingViolations.Count) files not following kebab-case

### Low Priority
6. **Consolidate sparse folders** - $($sparseFolders.Count) folders with 1-2 files
   - Consider merging into parent folder

### Total Potential Cleanup
- **Space to be freed:** ~$totalTempSizeMB MB
- **Files to be reviewed:** $($tempFiles.Count + $namingViolations.Count) files

---

## Execution Plan

"@

if (-not $Execute) {
    $report += @"

**DRY RUN MODE** - No changes were made.

To execute cleanup operations, run:
``````powershell
.\audit-dev-folder-comprehensive.ps1 -Execute
``````

"@
} else {
    $report += "`n**EXECUTION MODE** - Changes will be applied.`n"

    # Archive old report files
    Write-Console "Archiving old report files..." -ForegroundColor Yellow
    $archiveCount = 0
    foreach ($file in $reportFiles) {
        $age = ((Get-Date) - $file.LastWriteTime).Days
        if ($age -gt 30) {
            # Move to archive or delete
            Remove-Item $file.FullName -Force
            $archiveCount++
            Write-Console "  Deleted: $($file.Name)" -ForegroundColor Green
        }
    }
    $report += "`n- Deleted $archiveCount old report files (>30 days)`n"
}

# Write report
New-Item -Path (Split-Path $reportPath) -ItemType Directory -Force | Out-Null
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console ""
Write-Console "=== Audit Complete ===" -ForegroundColor Green
Write-Console "Report saved to: $reportPath" -ForegroundColor Cyan
Write-Console ""
Write-Console "Summary:" -ForegroundColor Yellow
Write-Console "  Total files: $totalFiles ($totalSizeMB MB)" -ForegroundColor Gray
Write-Console "  Temp/log files: $($tempFiles.Count) ($totalTempSizeMB MB)" -ForegroundColor Gray
Write-Console "  Potential duplicates: $($scriptGroups.Count) groups" -ForegroundColor Gray
Write-Console "  Broken links: $($brokenLinks.Count)" -ForegroundColor Gray
Write-Console "  Naming violations: $($namingViolations.Count)" -ForegroundColor Gray
Write-Console ""
