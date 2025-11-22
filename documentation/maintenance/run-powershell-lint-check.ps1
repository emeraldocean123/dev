# PowerShell Script Lint Checker
# Uses PSScriptAnalyzer to check for common issues
# Focuses on critical scripts in dev folder

[CmdletBinding()]
param(
    [switch]$All  # Check all 82 scripts (takes longer)
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

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  PowerShell Script Lint Checker" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Check if PSScriptAnalyzer is installed
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Console "PSScriptAnalyzer not installed. Installing..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
    Write-Console "[OK] PSScriptAnalyzer installed`n" -ForegroundColor Green
}

Import-Module PSScriptAnalyzer

$devPath = "$env:USERPROFILE\Documents\git\dev"

# Critical scripts to always check
$criticalScripts = @(
    # Homelab menu
    "homelab.ps1"

    # Infrastructure scripts
    "infrastructure\hardware\check-caldigit.ps1"
    "infrastructure\network\wake-on-lan.ps1"
    "infrastructure\storage\drive-management\set-drive-letters.ps1"

    # Shell management
    "shell-management\shell-backup\backup-configs-to-cloud.ps1"

    # Documentation maintenance
    "documentation\maintenance\audit-dev-folder-comprehensive.ps1"
    "documentation\maintenance\cleanup-dev-folder.ps1"
)

if ($All) {
    # Get all PowerShell scripts
    $scripts = Get-ChildItem -Path $devPath -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue
    Write-Console "Checking ALL $($scripts.Count) PowerShell scripts..." -ForegroundColor Yellow
    Write-Console "This may take several minutes...`n" -ForegroundColor Gray
} else {
    # Check only critical scripts
    $scripts = $criticalScripts | ForEach-Object {
        $path = Join-Path $devPath $_
        if (Test-Path $path) {
            Get-Item $path
        } else {
            Write-Console "Warning: Script not found: $_" -ForegroundColor Yellow
        }
    }
    Write-Console "Checking $($scripts.Count) critical scripts...`n" -ForegroundColor Yellow
}

$totalScripts = $scripts.Count
$scriptsWithIssues = 0
$totalIssues = 0
$issuesBySeverity = @{
    Error = 0
    Warning = 0
    Information = 0
}

# Create reports directory if it doesn't exist
$reportDir = Join-Path $devPath "documentation\reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportPath = Join-Path $reportDir "powershell-lint-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').md"

"# PowerShell Script Lint Report`n" | Out-File -FilePath $reportPath -Encoding UTF8
"**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"**Scope:** $(if ($All) { 'All scripts' } else { 'Critical scripts only' })`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"**Total Scripts:** $totalScripts`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"---`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8

$processedCount = 0

foreach ($script in $scripts) {
    $processedCount++
    $relativePath = $script.FullName.Replace("$devPath\", "")

    Write-Console "[$processedCount/$totalScripts] Checking: $relativePath" -ForegroundColor Cyan

    # Run PSScriptAnalyzer
    $results = Invoke-ScriptAnalyzer -Path $script.FullName -Severity Error,Warning,Information

    if ($results.Count -gt 0) {
        $scriptsWithIssues++
        $totalIssues += $results.Count

        Write-Console "  [WARN] Found $($results.Count) issue(s)" -ForegroundColor Yellow

        # Write to report
        "## $relativePath`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
        "**Issues Found:** $($results.Count)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8

        foreach ($result in $results) {
            $issuesBySeverity[$result.Severity.ToString()]++

            $icon = switch ($result.Severity) {
                'Error' { '[ERR]' }
                'Warning' { '[WARN]' }
                'Information' { '[INFO]' }
            }

            Write-Console "    $icon [$($result.Severity)] $($result.RuleName)" -ForegroundColor Gray
            Write-Console "      Line $($result.Line): $($result.Message)" -ForegroundColor Gray

            # Write to report
            "### $icon $($result.Severity): $($result.RuleName)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "- **Line:** $($result.Line)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "- **Message:** $($result.Message)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "- **Suggested Correction:** $($result.SuggestedCorrections)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
        }

        "`n---`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    } else {
        Write-Console "  [OK] No issues found" -ForegroundColor Green
    }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Lint Check Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Scripts checked: $totalScripts" -ForegroundColor White
Write-Console "Scripts with issues: $scriptsWithIssues" -ForegroundColor $(if ($scriptsWithIssues -gt 0) { "Yellow" } else { "Green" })
Write-Console "Total issues: $totalIssues`n" -ForegroundColor $(if ($totalIssues -gt 0) { "Yellow" } else { "Green" })

Write-Console "Issues by Severity:" -ForegroundColor White
Write-Console "  Errors: $($issuesBySeverity.Error)" -ForegroundColor $(if ($issuesBySeverity.Error -gt 0) { "Red" } else { "Gray" })
Write-Console "  Warnings: $($issuesBySeverity.Warning)" -ForegroundColor $(if ($issuesBySeverity.Warning -gt 0) { "Yellow" } else { "Gray" })
Write-Console "  Information: $($issuesBySeverity.Information)" -ForegroundColor $(if ($issuesBySeverity.Information -gt 0) { "Cyan" } else { "Gray" })

# Append summary to report
"`n## Summary`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"`n**Scripts checked:** $totalScripts" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"**Scripts with issues:** $scriptsWithIssues" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"**Total issues:** $totalIssues`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"`n**Issues by Severity:**" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"- Errors: $($issuesBySeverity.Error)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"- Warnings: $($issuesBySeverity.Warning)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"- Information: $($issuesBySeverity.Information)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"`n---`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
"**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $reportPath -Append -Encoding UTF8

Write-Console "`nDetailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green

if ($scriptsWithIssues -eq 0) {
    Write-Console "[OK] All scripts passed lint checks!" -ForegroundColor Green
} else {
    Write-Console "[WARN] Review the report for detailed findings" -ForegroundColor Yellow
}

Write-Console "" -ForegroundColor White

