# Homelab Menu Integration Example for Media Manager
# ==================================================
# This demonstrates how to integrate media-manager.py into your homelab.ps1 menu system
#
# Copy these menu entries into your main homelab.ps1 file


# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }
function Show-MediaManagerMenu {
    Clear-Host
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   MEDIA MANAGER - Unified Tool" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "1. Rename Files (In-Place)" -ForegroundColor Yellow
    Write-Host "   - Renames files using PowerShell format: YYYY-MM-DD-HHmmss-Make-Model-Hash.ext" -ForegroundColor Gray
    Write-Host "   - Files stay in current folders" -ForegroundColor Gray
    Write-Host "   - Safe operation (use --execute to apply)`n" -ForegroundColor Gray

    Write-Host "2. Organize by Date (Simple YYYY/MM)" -ForegroundColor Yellow
    Write-Host "   - Organizes files into YYYY/MM folder structure" -ForegroundColor Gray
    Write-Host "   - Copies files (originals untouched)" -ForegroundColor Gray
    Write-Host "   - Perfect for chronological browsing`n" -ForegroundColor Gray

    Write-Host "3. Organize by Keywords" -ForegroundColor Yellow
    Write-Host "   - Organizes files into Keywords/[Keyword]/YYYY/MM structure" -ForegroundColor Gray
    Write-Host "   - Groups photos by XMP/IPTC keywords" -ForegroundColor Gray
    Write-Host "   - Great for project-based workflows`n" -ForegroundColor Gray

    Write-Host "4. Full Cleanup (Move + Dedupe + Rename)" -ForegroundColor Yellow
    Write-Host "   - Complete workflow: organize + deduplicate + rename" -ForegroundColor Gray
    Write-Host "   - DESTRUCTIVE: Moves files (deletes originals)" -ForegroundColor Red
    Write-Host "   - Use dry-run first!`n" -ForegroundColor Gray

    Write-Host "5. Deduplicate Only" -ForegroundColor Yellow
    Write-Host "   - Finds and handles duplicate files" -ForegroundColor Gray
    Write-Host "   - Keeps best version (highest resolution/RAW/rated)" -ForegroundColor Gray
    Write-Host "   - Moves duplicates to Duplicates/ subfolder`n" -ForegroundColor Gray

    Write-Host "0. Return to Main Menu`n" -ForegroundColor Gray

    $choice = Read-Host "Select option"

    switch ($choice) {
        "1" { Invoke-MediaRename }
        "2" { Invoke-MediaOrganizeSimple }
        "3" { Invoke-MediaOrganizeKeywords }
        "4" { Invoke-MediaFullCleanup }
        "5" { Invoke-MediaDeduplicate }
        "0" { return }
        default {
            Write-Host "`nInvalid selection!" -ForegroundColor Red
            Start-Sleep -Seconds 2
            Show-MediaManagerMenu
        }
    }
}

# =============================================================================
# MENU OPTION FUNCTIONS
# =============================================================================

function Invoke-MediaRename {
    Write-Host "`n=== RENAME FILES (IN-PLACE) ===`n" -ForegroundColor Cyan

    $source = Read-Host "Enter source directory"
    if (-not (Test-Path $source)) {
        Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "`nRunning DRY-RUN first (preview only)...`n" -ForegroundColor Yellow
    python ~/Documents/git/dev/media/tools/media-manager.py "$source" --mode rename --action move

    $confirm = Read-Host "`nApply these changes? (y/n)"
    if ($confirm -eq 'y') {
        Write-Host "`nExecuting rename operation...`n" -ForegroundColor Green
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --mode rename --action move --execute
    }

    Read-Host "`nPress Enter to continue"
    Show-MediaManagerMenu
}

function Invoke-MediaOrganizeSimple {
    Write-Host "`n=== ORGANIZE BY DATE (YYYY/MM) ===`n" -ForegroundColor Cyan

    $source = Read-Host "Enter source directory"
    $dest = Read-Host "Enter destination directory"

    if (-not (Test-Path $source)) {
        Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    $action = Read-Host "Action type? (copy/move) [default: copy]"
    if ([string]::IsNullOrWhiteSpace($action)) { $action = "copy" }

    Write-Host "`nRunning DRY-RUN first (preview only)...`n" -ForegroundColor Yellow
    python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure simple --action $action

    $confirm = Read-Host "`nApply these changes? (y/n)"
    if ($confirm -eq 'y') {
        Write-Host "`nExecuting organize operation...`n" -ForegroundColor Green
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure simple --action $action --execute
    }

    Read-Host "`nPress Enter to continue"
    Show-MediaManagerMenu
}

function Invoke-MediaOrganizeKeywords {
    Write-Host "`n=== ORGANIZE BY KEYWORDS ===`n" -ForegroundColor Cyan

    $source = Read-Host "Enter source directory"
    $dest = Read-Host "Enter destination directory"

    if (-not (Test-Path $source)) {
        Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    $action = Read-Host "Action type? (copy/move) [default: copy]"
    if ([string]::IsNullOrWhiteSpace($action)) { $action = "copy" }

    Write-Host "`nRunning DRY-RUN first (preview only)...`n" -ForegroundColor Yellow
    python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure keywords --action $action

    $confirm = Read-Host "`nApply these changes? (y/n)"
    if ($confirm -eq 'y') {
        Write-Host "`nExecuting organize operation...`n" -ForegroundColor Green
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure keywords --action $action --execute
    }

    Read-Host "`nPress Enter to continue"
    Show-MediaManagerMenu
}

function Invoke-MediaFullCleanup {
    Write-Host "`n=== FULL CLEANUP (DESTRUCTIVE) ===`n" -ForegroundColor Cyan
    Write-Host "WARNING: This will MOVE files (delete originals)!`n" -ForegroundColor Red

    $source = Read-Host "Enter source directory"
    $dest = Read-Host "Enter destination directory"

    if (-not (Test-Path $source)) {
        Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "`nRunning DRY-RUN first (preview only)...`n" -ForegroundColor Yellow
    python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode all --action move --rename

    Write-Host "`nWARNING: This will permanently move files!" -ForegroundColor Red
    $confirm = Read-Host "Are you SURE you want to proceed? (yes/no)"

    if ($confirm -eq 'yes') {
        Write-Host "`nExecuting full cleanup...`n" -ForegroundColor Green
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode all --action move --rename --execute
    } else {
        Write-Host "`nOperation cancelled.`n" -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue"
    Show-MediaManagerMenu
}

function Invoke-MediaDeduplicate {
    Write-Host "`n=== DEDUPLICATE FILES ===`n" -ForegroundColor Cyan

    $source = Read-Host "Enter source directory"
    $dest = Read-Host "Enter destination directory"

    if (-not (Test-Path $source)) {
        Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "`nDuplicate handling strategies:" -ForegroundColor Gray
    Write-Host "  1. folder     - Move duplicates to Duplicates/ subfolder" -ForegroundColor Gray
    Write-Host "  2. alongside  - Keep duplicates in same folder with -duplicate suffix" -ForegroundColor Gray
    Write-Host "  3. skip       - Ignore duplicates completely`n" -ForegroundColor Gray

    $strategy = Read-Host "Select strategy (1-3) [default: 1]"
    $strategyMap = @{
        "1" = "folder"
        "2" = "alongside"
        "3" = "skip"
        "" = "folder"
    }
    $dupeStrategy = $strategyMap[$strategy]

    $action = Read-Host "Action type? (copy/move) [default: copy]"
    if ([string]::IsNullOrWhiteSpace($action)) { $action = "copy" }

    Write-Host "`nRunning DRY-RUN first (preview only)...`n" -ForegroundColor Yellow
    python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode deduplicate --action $action --dupe-strategy $dupeStrategy

    $confirm = Read-Host "`nApply these changes? (y/n)"
    if ($confirm -eq 'y') {
        Write-Host "`nExecuting deduplication...`n" -ForegroundColor Green
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode deduplicate --action $action --dupe-strategy $dupeStrategy --execute
    }

    Read-Host "`nPress Enter to continue"
    Show-MediaManagerMenu
}

# =============================================================================
# QUICK SHORTCUTS (for main homelab.ps1 menu)
# =============================================================================

<#
Add these to your main homelab.ps1 menu:

"M" {
    # Media Manager Submenu
    Show-MediaManagerMenu
}

"R" {
    # Quick Rename (most common operation)
    $source = Read-Host "Enter source directory"
    if (Test-Path $source) {
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --mode rename --action move
        $confirm = Read-Host "Apply changes? (y/n)"
        if ($confirm -eq 'y') {
            python ~/Documents/git/dev/media/tools/media-manager.py "$source" --mode rename --action move --execute
        }
    }
}

"O" {
    # Quick Organize
    $source = Read-Host "Enter source directory"
    $dest = Read-Host "Enter destination directory"
    if (Test-Path $source) {
        python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure simple --action copy
        $confirm = Read-Host "Apply changes? (y/n)"
        if ($confirm -eq 'y') {
            python ~/Documents/git/dev/media/tools/media-manager.py "$source" --dest "$dest" --mode organize --structure simple --action copy --execute
        }
    }
}
#>

# Launch the menu (for standalone testing)
if ($MyInvocation.InvocationName -ne '.') {
    Show-MediaManagerMenu
}

