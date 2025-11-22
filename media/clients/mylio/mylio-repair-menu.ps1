# Mylio Repair & Maintenance Menu
# Centralized controller for all Mylio fix and diagnostic scripts
# Location: media/clients/mylio/mylio-repair-menu.ps1

[CmdletBinding()]
param()

$scriptRoot = $PSScriptRoot
$fixesDir = Join-Path $scriptRoot "fixes"
$diagDir = Join-Path $scriptRoot "diagnostics"

function Show-Header {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   MYLIO REPAIR & MAINTENANCE CONSOLE   " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $mylioProcess = Get-Process Mylio -ErrorAction SilentlyContinue
    if ($mylioProcess) {
        Write-Host "STATUS: Mylio is RUNNING (PID: $($mylioProcess.Id))" -ForegroundColor Red
        Write-Host "WARNING: Most repairs require Mylio to be closed." -ForegroundColor Yellow
    } else {
        Write-Host "STATUS: Mylio is STOPPED (Safe to repair)" -ForegroundColor Green
    }
    Write-Host ""
}

function Get-ScriptSelection {
    param($path, $title)
    Write-Host "--- $title ---" -ForegroundColor Yellow

    if (-not (Test-Path $path)) {
        Write-Host "Directory not found: $path" -ForegroundColor Red
        return @()
    }

    $scripts = Get-ChildItem -Path $path -Filter "*.ps1" -ErrorAction SilentlyContinue
    if ($scripts.Count -eq 0) {
        Write-Host "No scripts found in $path" -ForegroundColor Gray
        return @()
    }

    $i = 1
    foreach ($s in $scripts) {
        Write-Host "[$i] $($s.Name)" -ForegroundColor White
        $i++
    }
    return $scripts
}

do {
    Show-Header

    Write-Host "MAIN MENU:" -ForegroundColor Cyan
    Write-Host "1. Run Diagnostics (Non-destructive)" -ForegroundColor Green
    Write-Host "2. Apply Fixes (Potential data modification)" -ForegroundColor Yellow
    Write-Host "3. Database Tools (Advanced)" -ForegroundColor Magenta
    Write-Host "Q. Quit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select category"

    switch ($choice.ToUpper()) {
        "1" {
            $scripts = Get-ScriptSelection $diagDir "Diagnostic Scripts"
            if ($scripts.Count -gt 0) {
                $sel = Read-Host "Run script number (or press Enter to return)"
                if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $scripts.Count) {
                    Write-Host "`nRunning: $($scripts[$sel-1].Name)`n" -ForegroundColor Cyan
                    & $scripts[$sel-1].FullName
                    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
        }
        "2" {
            $scripts = Get-ScriptSelection $fixesDir "Repair Scripts"
            if ($scripts.Count -gt 0) {
                $sel = Read-Host "Run script number (or press Enter to return)"
                if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $scripts.Count) {
                    Write-Warning "You are about to run: $($scripts[$sel-1].Name)"
                    Write-Warning "This may modify your data. Ensure you have backups."
                    $confirm = Read-Host "Are you sure? (y/n)"
                    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                        Write-Host "`nRunning: $($scripts[$sel-1].Name)`n" -ForegroundColor Cyan
                        & $scripts[$sel-1].FullName
                        Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                }
            }
        }
        "3" {
            $dbDir = Join-Path $scriptRoot "database"
            $scripts = Get-ScriptSelection $dbDir "Database Tools"
            if ($scripts.Count -gt 0) {
                $sel = Read-Host "Run script number (or press Enter to return)"
                if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $scripts.Count) {
                    Write-Host "`nRunning: $($scripts[$sel-1].Name)`n" -ForegroundColor Cyan
                    & $scripts[$sel-1].FullName
                    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
        }
        "Q" {
            Write-Host "Exiting Mylio Repair Console..." -ForegroundColor Cyan
            exit
        }
    }
} while ($true)
