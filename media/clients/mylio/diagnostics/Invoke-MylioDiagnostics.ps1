# Mylio Diagnostics Menu Launcher
# Organized menu system for all Mylio diagnostic tools
# Location: media/clients/mylio/diagnostics/Invoke-MylioDiagnostics.ps1

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Menu", "Database", "FileSystem", "Metadata", "SmartTags", "Monitoring")]
    [string]$Category = "Menu"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Point to tools/ subdirectory where actual diagnostic scripts live
$diagnosticsPath = Join-Path $PSScriptRoot "tools"

# Script categories with descriptions
$categories = @{
    "Database" = @(
        @{ Name = "check-missing-files.ps1"; Desc = "Find files in database but missing on disk" },
        @{ Name = "check-mylio-sync-errors.ps1"; Desc = "Check for sync errors in Mylio database" },
        @{ Name = "investigate-missing-files.ps1"; Desc = "Deep analysis of missing file causes" }
    )
    "FileSystem" = @(
        @{ Name = "count-all-files.ps1"; Desc = "Count all files in Mylio catalog" },
        @{ Name = "count-all-file-types.ps1"; Desc = "Count files by type" },
        @{ Name = "find-orphaned-images.ps1"; Desc = "Find images without XMP sidecars" },
        @{ Name = "find-orphaned-xmp-v2.ps1"; Desc = "Find XMP files without corresponding media" },
        @{ Name = "get-legacy-format-paths.ps1"; Desc = "Find files using legacy XMP format" },
        @{ Name = "scan-mylio-videos.ps1"; Desc = "Scan and analyze video files" }
    )
    "Metadata" = @(
        @{ Name = "analyze-media-by-device.ps1"; Desc = "Group media by capture device" },
        @{ Name = "analyze-unknown-files.ps1"; Desc = "Analyze files with unknown metadata" },
        @{ Name = "check-xmp-file-types.ps1"; Desc = "Verify XMP file type consistency" },
        @{ Name = "check-moved-xmp-formats.ps1"; Desc = "Check for XMP format changes after moves" },
        @{ Name = "parse-media-files-column.ps1"; Desc = "Parse media files database column" },
        @{ Name = "scan-mylio-dates-optimized.ps1"; Desc = "Scan date metadata (optimized)" },
        @{ Name = "scan-xmp-dates.ps1"; Desc = "Extract and analyze XMP date fields" },
        @{ Name = "verify-xmp-exif-match.ps1"; Desc = "Verify XMP matches EXIF data" },
        @{ Name = "verify-xmp-exif-sync.ps1"; Desc = "Check XMP-EXIF synchronization" },
        @{ Name = "analyze-2006-july-timestamps.ps1"; Desc = "Analyze specific date anomaly" }
    )
    "SmartTags" = @(
        @{ Name = "check-smarttag-status.ps1"; Desc = "Check SmartTag configuration status" },
        @{ Name = "check-smarttag-settings.ps1"; Desc = "Verify SmartTag settings" },
        @{ Name = "find-smarttag-setting.ps1"; Desc = "Find specific SmartTag setting" },
        @{ Name = "search-enable-settings.ps1"; Desc = "Search for enable/disable settings" }
    )
    "Monitoring" = @(
        @{ Name = "check-mylio-running.ps1"; Desc = "Check if Mylio process is running" },
        @{ Name = "monitor-google-drive-sync.ps1"; Desc = "Monitor Google Drive sync status" },
        @{ Name = "analyze-crash-dump.ps1"; Desc = "Analyze Mylio crash dumps" }
    )
}

function Show-CategoryMenu {
    param($CategoryName)

    $scripts = $categories[$CategoryName]

    if (-not $scripts) {
        Write-Console "ERROR: Unknown category: $CategoryName" -ForegroundColor Red
        return
    }

    while ($true) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  Mylio Diagnostics - $CategoryName" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            Write-Console "  $($i + 1). $($script.Name)" -ForegroundColor White
            Write-Console "      $($script.Desc)" -ForegroundColor Gray
            Write-Console ""
        }

        Write-Console "  B. Back to main menu" -ForegroundColor Yellow
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        $selection = Read-Host "Select diagnostic tool (number or 'B' to back)"

        if ($selection -match "^[Bb]$") { return }

        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $scripts.Count) {
            $scriptToRun = $scripts[[int]$selection - 1]
            $scriptPath = Join-Path $diagnosticsPath $scriptToRun.Name

            if (Test-Path $scriptPath) {
                Write-Console "`nRunning: $($scriptToRun.Name)" -ForegroundColor Yellow
                Write-Console "======================================================" -ForegroundColor DarkGray
                Write-Console ""

                & $scriptPath

                Write-Console ""
                Write-Console "======================================================" -ForegroundColor DarkGray
                Write-Console "Execution Complete." -ForegroundColor Green
                Read-Host "Press Enter to continue"
            }
            else {
                Write-Console "ERROR: Script not found: $scriptPath" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  Mylio Diagnostics - Main Menu" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""
        Write-Console "  1. Database Checks (3 tools)" -ForegroundColor White
        Write-Console "      Verify database integrity and find missing files" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  2. File System Scans (6 tools)" -ForegroundColor White
        Write-Console "      Count files, find orphans, scan catalog" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  3. Metadata Analysis (10 tools)" -ForegroundColor White
        Write-Console "      XMP verification, date analysis, device grouping" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  4. SmartTag Management (4 tools)" -ForegroundColor White
        Write-Console "      Check and configure SmartTag settings" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  5. Monitoring (3 tools)" -ForegroundColor White
        Write-Console "      Process monitoring, crash analysis, sync status" -ForegroundColor Gray
        Write-Console ""
        Write-Console "  Q. Quit" -ForegroundColor Yellow
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""

        $selection = Read-Host "Select category"

        switch ($selection) {
            "1" { Show-CategoryMenu -CategoryName "Database" }
            "2" { Show-CategoryMenu -CategoryName "FileSystem" }
            "3" { Show-CategoryMenu -CategoryName "Metadata" }
            "4" { Show-CategoryMenu -CategoryName "SmartTags" }
            "5" { Show-CategoryMenu -CategoryName "Monitoring" }
            {$_ -match "^[Qq]$"} { return }
        }
    }
}

# Entry Point
if ($Category -eq "Menu") {
    Show-MainMenu
}
else {
    Show-CategoryMenu -CategoryName $Category
}
