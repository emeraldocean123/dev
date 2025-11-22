# DigiKam Management Console
# Unifies backup, scanning, upload, and migration workflows
# Location: media/services/digikam/manage-digikam.ps1

[CmdletBinding()]
param()

# Paths to sub-tools (relative to script location)
$scriptRoot = $PSScriptRoot
$monitorScript = Join-Path $scriptRoot "scan-monitor\monitor-scan.sh"
$uploadScript = Join-Path $scriptRoot "google-photos-upload\upload-to-google-photos.sh"
$backupScript = Join-Path $scriptRoot "database-backup\backup-database.sh"
$keywordImportScript = Join-Path $scriptRoot "tools\xmp-keyword-import\import-xmp-keywords-to-digikam.ps1"

function Show-Header {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      DIGIKAM MANAGEMENT CONSOLE        " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-BashScript {
    param([string]$ScriptPath, [string]$Args)

    if (-not (Test-Path $ScriptPath)) {
        Write-Host "ERROR: Script not found: $ScriptPath" -ForegroundColor Red
        Pause
        return
    }

    Write-Host "Executing: $ScriptPath" -ForegroundColor Gray

    # Use bash from Git Bash or WSL
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        if ($Args) {
            bash "$ScriptPath" $Args
        } else {
            bash "$ScriptPath"
        }
    } else {
        Write-Host "ERROR: bash not found in PATH" -ForegroundColor Red
        Write-Host "Install Git Bash or enable WSL" -ForegroundColor Yellow
    }

    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MigrationAssistant {
    Clear-Host
    Write-Host "--- DigiKam Migration Assistant ---" -ForegroundColor Magenta
    Write-Host "1. Scan XMP Sidecar Compatibility"
    Write-Host "2. Import Keywords from XMP (Dry Run)"
    Write-Host "3. Import Keywords from XMP (Live)"
    Write-Host "B. Back to Main Menu"
    Write-Host ""

    $migChoice = Read-Host "Select task"

    switch ($migChoice.ToUpper()) {
        "1" {
            Write-Host "Scanning for XMP files..." -ForegroundColor Yellow
            $scanTool = Join-Path $scriptRoot "..\..\tools\metadata-tools\scan-xmp-sidecars.ps1"
            if (Test-Path $scanTool) {
                & $scanTool
            } else {
                Write-Warning "Tool not found: $scanTool"
            }
            Pause
        }
        "2" {
            Write-Host "Running keyword import (Dry Run)..." -ForegroundColor Yellow
            if (Test-Path $keywordImportScript) {
                & $keywordImportScript -DryRun
            } else {
                Write-Warning "Import script not found: $keywordImportScript"
            }
            Pause
        }
        "3" {
            Write-Warning "This will modify your DigiKam database!"
            $confirm = Read-Host "Are you sure? (y/n)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                if (Test-Path $keywordImportScript) {
                    & $keywordImportScript
                } else {
                    Write-Warning "Import script not found: $keywordImportScript"
                }
            }
            Pause
        }
    }
}

do {
    Show-Header

    Write-Host "SERVICE OPERATIONS" -ForegroundColor Green
    Write-Host "1. Monitor Scan Progress (Live DB Stats)"
    Write-Host "2. Backup MariaDB Database"

    Write-Host "`nCLOUD OPERATIONS" -ForegroundColor Yellow
    Write-Host "3. Upload Export to Google Photos"

    Write-Host "`nMIGRATION & METADATA" -ForegroundColor Magenta
    Write-Host "4. Migration Assistant"

    Write-Host "`nQ. Quit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select action"

    switch ($choice.ToUpper()) {
        "1" {
            Invoke-BashScript -ScriptPath $monitorScript
        }
        "2" {
            Invoke-BashScript -ScriptPath $backupScript
        }
        "3" {
            $folder = Read-Host "Enter source folder path"
            $album = Read-Host "Enter album name (optional)"

            if ($folder) {
                if ($album) {
                    Invoke-BashScript -ScriptPath $uploadScript -Args "`"$folder`" `"$album`""
                } else {
                    Invoke-BashScript -ScriptPath $uploadScript -Args "`"$folder`""
                }
            }
        }
        "4" {
            Show-MigrationAssistant
        }
        "Q" {
            Write-Host "Exiting DigiKam Management Console..." -ForegroundColor Cyan
            exit
        }
    }
} while ($true)
