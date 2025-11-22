# Backup Dotfiles & Configs to Cloud
# Syncs local private configurations to cloud storage using Rclone
# Location: shell-management/shell-backup/backup-configs-to-cloud.ps1
# Usage: ./backup-configs-to-cloud.ps1 [-WhatIf]

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Interactive script requires colored console output')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Global config is shared design pattern across scripts')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '', Justification='UTF-8 without BOM is standard for cross-platform compatibility')]
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")

# Load Configuration
if (-not $Global:HomelabConfig) {
    $configPath = Join-Path $devRoot ".config\homelab.settings.json"
    if (Test-Path $configPath) {
        try {
            $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Failed to load configuration file"
            exit 1
        }
    } else {
        Write-Error "Configuration not found at: $configPath"
        Write-Host "Run: ./shell-management/utils/setup-homelab-config.ps1" -ForegroundColor Yellow
        exit 1
    }
}

# Check if rclone is installed
if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Error "rclone is not installed. Install from https://rclone.org/"
    exit 1
}

# Get cloud configuration
$remote = if ($Global:HomelabConfig.Cloud.RcloneRemote) {
    $Global:HomelabConfig.Cloud.RcloneRemote
} else {
    Write-Warning "Cloud.RcloneRemote not set in configuration, using default 'googlephotos'"
    "googlephotos"
}

$remotePath = if ($Global:HomelabConfig.Cloud.ConfigBackupPath) {
    $Global:HomelabConfig.Cloud.ConfigBackupPath
} else {
    "backups/homelab-configs"
}

Write-Host ""
Write-Host "=== CONFIGURATION CLOUD BACKUP ===" -ForegroundColor Magenta
Write-Host "Remote: $remote`:$remotePath" -ForegroundColor Gray
Write-Host "Using: rclone copy (preserves history)" -ForegroundColor DarkGray
Write-Host ""

# Verify rclone remote exists
try {
    $remotes = rclone listremotes | ForEach-Object { $_.TrimEnd(':') }
    if ($remote -notin $remotes) {
        Write-Error "Rclone remote '$remote' not found. Available remotes: $($remotes -join ', ')"
        Write-Host "Configure rclone with: rclone config" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Error "Failed to list rclone remotes: $_"
    exit 1
}

# Define backup targets (git-ignored files and directories)
$targets = @(
    @{
        Path = ".config"
        Description = "Central configuration (homelab.settings.json)"
    },
    @{
        Path = "infrastructure\network\config\servers.env"
        Description = "Network device MAC addresses"
    }
)

# Track results
$success = 0
$failed = 0
$skipped = 0

foreach ($target in $targets) {
    $localPath = Join-Path $devRoot $target.Path

    if (-not (Test-Path $localPath)) {
        Write-Host "  [SKIP] $($target.Path) (Not found)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Build remote destination preserving directory structure
    $dest = "$($remote):$remotePath/$($target.Path)"
    $itemName = Split-Path $target.Path -Leaf

    if ($PSCmdlet.ShouldProcess("$dest", "Backup $itemName")) {
        Write-Host "  Syncing $itemName... " -NoNewline -ForegroundColor Cyan

        try {
            # Use rclone copy to preserve cloud history
            # --verbose for detailed output if needed (remove for quiet mode)
            if (Test-Path $localPath -PathType Container) {
                # Directory: copy entire directory
                $result = rclone copy $localPath $dest --progress 2>&1
            } else {
                # Single file: copy to parent directory
                $parentDest = Split-Path $dest -Parent
                $result = rclone copy $localPath $parentDest --progress 2>&1
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK]" -ForegroundColor Green
                Write-Host "    → $($target.Description)" -ForegroundColor DarkGray
                $success++
            } else {
                Write-Host "[FAILED]" -ForegroundColor Red
                Write-Host "    Error: $result" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "[FAILED]" -ForegroundColor Red
            Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "=== BACKUP SUMMARY ===" -ForegroundColor Magenta
Write-Host "  Successful: $success" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed:     $failed" -ForegroundColor Red
}
if ($skipped -gt 0) {
    Write-Host "  Skipped:    $skipped" -ForegroundColor Yellow
}
Write-Host ""

if ($failed -eq 0) {
    Write-Host "✓ Cloud backup complete" -ForegroundColor Green
    Write-Host -Object "  Remote: $remote`:$remotePath" -ForegroundColor DarkGray
} else {
    Write-Host "✗ Cloud backup completed with errors" -ForegroundColor Yellow
    exit 1
}
