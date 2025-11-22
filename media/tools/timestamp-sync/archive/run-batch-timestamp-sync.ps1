# Batch Timestamp Sync - Process folders sequentially
# Prevents memory exhaustion by processing one folder at a time

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $null
    $previousForeground = $null
    $previousBackground = $null

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        if ($NoNewline -and $Host -and $Host.UI) {
            $Host.UI.Write($Message)
        } else {
            Write-Information -MessageData $Message
        }
    } catch {
        Write-Information -MessageData $Message
        Write-Verbose "Write-Console fallback: $($_.Exception.Message)"
    } finally {
        if ($rawUI -and $null -ne $previousForeground) {
            try {
                $rawUI.ForegroundColor = $previousForeground
            } catch {
                Write-Verbose "Unable to reset foreground color: $($_.Exception.Message)"
            }
        }

        if ($rawUI -and $PSBoundParameters.ContainsKey('BackgroundColor') -and $null -ne $previousBackground) {
            try {
                $rawUI.BackgroundColor = $previousBackground
            } catch {
                Write-Verbose "Unable to reset background color: $($_.Exception.Message)"
            }
        }
    }
}

param(
    [switch]$DryRun
)

if (-not $PSBoundParameters.ContainsKey('DryRun')) {
    $DryRun = $false
}

$mylioPath = "D:\Mylio"
$scriptPath = "$PSScriptRoot\sync-timestamps-bidirectional-optimized.ps1"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Batch Timestamp Sync" -ForegroundColor Cyan
Write-Console "  Processing folders sequentially" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "MODE: DRY RUN - No changes will be made" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - Files will be modified!" -ForegroundColor Red
    Write-Console "Press Ctrl+C within 10 seconds to cancel...`n" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Get all top-level folders
$folders = Get-ChildItem -Path $mylioPath -Directory | Sort-Object Name

Write-Console "Found $($folders.Count) folders to process:`n" -ForegroundColor White
foreach ($folder in $folders) {
    Write-Console "  - $($folder.Name)" -ForegroundColor Gray
}

Write-Console ""

$totalFolders = $folders.Count
$processedFolders = 0
$overallStart = Get-Date

$overallStats = @{
    TotalProcessed = 0
    TotalUpdated = 0
    TotalAlreadySynced = 0
    TotalAllSuspicious = 0
    TotalSkipped = 0
    TotalErrors = 0
}

foreach ($folder in $folders) {
    $processedFolders++
    $folderStart = Get-Date

    Write-Console "`n========================================" -ForegroundColor Cyan
    Write-Console "  Folder $processedFolders / $totalFolders" -ForegroundColor Cyan
    Write-Console "  Processing: $($folder.Name)" -ForegroundColor Cyan
    Write-Console "========================================`n" -ForegroundColor Cyan

    # Run optimized sync script on this folder
    try {
        if ($DryRun) {
            & $scriptPath -Path $folder.FullName -DryRun
        } else {
            & $scriptPath -Path $folder.FullName -DryRun:$false
        }

        # Parse the report to extract stats
        $latestReport = Get-ChildItem -Path $PSScriptRoot -Filter "bidirectional-sync-report-*.txt" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestReport) {
            $reportContent = Get-Content -Path $latestReport.FullName -Raw

            # Extract stats using regex
            if ($reportContent -match 'Total files processed:\s+(\d+)') {
                $overallStats.TotalProcessed += [int]$matches[1]
            }
            if ($reportContent -match 'Files synchronized:\s+(\d+)') {
                $overallStats.TotalUpdated += [int]$matches[1]
            }
            if ($reportContent -match 'Files already in sync:\s+(\d+)') {
                $overallStats.TotalAlreadySynced += [int]$matches[1]
            }
            if ($reportContent -match 'Files with all suspicious timestamps:\s+(\d+)') {
                $overallStats.TotalAllSuspicious += [int]$matches[1]
            }
            if ($reportContent -match 'Files skipped.*:\s+(\d+)') {
                $overallStats.TotalSkipped += [int]$matches[1]
            }
            if ($reportContent -match 'Errors:\s+(\d+)') {
                $overallStats.TotalErrors += [int]$matches[1]
            }
        }

        $folderElapsed = (Get-Date) - $folderStart
        Write-Console "`nFolder completed in: $($folderElapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green

    } catch {
        Write-Console "`nERROR processing folder: $($folder.Name)" -ForegroundColor Red
        Write-Console "  $_" -ForegroundColor Gray
        $overallStats.TotalErrors++
    }

    # Force garbage collection between folders
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    Write-Console "`nMemory cleaned between folders" -ForegroundColor Gray
}

$overallElapsed = (Get-Date) - $overallStart

# Final Summary
Write-Console "`n`n========================================" -ForegroundColor Cyan
Write-Console "  OVERALL SUMMARY" -ForegroundColor Cyan
Write-Console "  All Folders Complete" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Folders processed: $processedFolders / $totalFolders" -ForegroundColor White
Write-Console "`nCumulative Statistics:" -ForegroundColor White
Write-Console "  Total files processed: $($overallStats.TotalProcessed)" -ForegroundColor White
Write-Console "  Files synchronized: $($overallStats.TotalUpdated)" -ForegroundColor $(if ($overallStats.TotalUpdated -gt 0) { "Green" } else { "Gray" })
Write-Console "  Files already in sync: $($overallStats.TotalAlreadySynced)" -ForegroundColor Gray
Write-Console "  Files with all suspicious timestamps: $($overallStats.TotalAllSuspicious)" -ForegroundColor Yellow
Write-Console "  Files skipped (no valid timestamps): $($overallStats.TotalSkipped)" -ForegroundColor Yellow
Write-Console "  Errors: $($overallStats.TotalErrors)" -ForegroundColor $(if ($overallStats.TotalErrors -gt 0) { "Red" } else { "Gray" })

Write-Console "`nTotal processing time: $($overallElapsed.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Console "Average per folder: $([math]::Round($overallElapsed.TotalMinutes / $processedFolders, 1)) minutes`n" -ForegroundColor Gray

# Save overall summary
$summaryPath = "$PSScriptRoot\batch-sync-summary-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$summary = @"
Batch Timestamp Sync Summary
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Base Path: $mylioPath
Mode: $(if ($DryRun) { "DRY RUN" } else { "LIVE" })

========================================
OVERALL SUMMARY
========================================

Folders processed: $processedFolders / $totalFolders

Total files processed: $($overallStats.TotalProcessed)
Files synchronized: $($overallStats.TotalUpdated)
Files already in sync: $($overallStats.TotalAlreadySynced)
Files with all suspicious timestamps: $($overallStats.TotalAllSuspicious)
Files skipped (no valid timestamps): $($overallStats.TotalSkipped)
Errors: $($overallStats.TotalErrors)

Total processing time: $($overallElapsed.ToString('hh\:mm\:ss'))
Average per folder: $([math]::Round($overallElapsed.TotalMinutes / $processedFolders, 1)) minutes

========================================
FOLDERS PROCESSED
========================================

"@

foreach ($folder in $folders) {
    $summary += "  - $($folder.Name)`n"
}

$summary | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Console "Summary saved to:" -ForegroundColor White
Write-Console "$summaryPath`n" -ForegroundColor Green

if ($DryRun) {
    Write-Console "This was a DRY RUN - no files were modified." -ForegroundColor Yellow
    Write-Console "Run without -DryRun to apply changes.`n" -ForegroundColor Yellow
} else {
    Write-Console "All folders have been processed!" -ForegroundColor Green
    Write-Console "Check individual folder reports for detailed changes.`n" -ForegroundColor White
}

