
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Backup Immich to Google Drive with Encryption
# Uses rclone to sync essential Immich files to encrypted Google Drive storage

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [switch]$StopImmich = $false,

    [Parameter(Mandatory=$false)]
    [string]$Remote = "immich-backup:",

    [Parameter(Mandatory=$false)]
    [string]$ImmichPath = "D:\Immich"
)

Write-Console "Immich Encrypted Backup to Google Drive" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Check if rclone is available
$rclone = Get-Command rclone -ErrorAction SilentlyContinue
if (-not $rclone) {
    Write-Console "ERROR: rclone not found in PATH" -ForegroundColor Red
    Write-Console "Please restart your terminal or run: setup-rclone-backup.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if remote is configured
$remoteCheck = rclone listremotes 2>&1 | Select-String -Pattern "immich-backup:"
if (-not $remoteCheck) {
    Write-Console "ERROR: Remote 'immich-backup' not configured" -ForegroundColor Red
    Write-Console "Please run: .\setup-rclone-backup.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if Immich path exists
if (-not (Test-Path $ImmichPath)) {
    Write-Console "ERROR: Immich path does not exist: $ImmichPath" -ForegroundColor Red
    exit 1
}

$logDirectory = Join-Path $ImmichPath 'logs'
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}
$logTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFilePath = Join-Path $logDirectory "rclone-backup-$logTimestamp.log"

if ($DryRun) {
    Write-Console "DRY RUN MODE - No files will be uploaded" -ForegroundColor Yellow
    Write-Console ""
}

if ($StopImmich) {
    Write-Console "Stopping Immich containers..." -ForegroundColor Yellow
    Push-Location $ImmichPath
    & .\scripts\stop-immich.ps1
    Pop-Location
    Write-Console ""
    Start-Sleep -Seconds 3
}

Write-Console "Backup Configuration:" -ForegroundColor White
Write-Console "  Source: $ImmichPath" -ForegroundColor White
Write-Console "  Destination: $Remote (encrypted)" -ForegroundColor White
Write-Console "  Mode: Essential files only (excludes postgres, thumbs, encoded-video)" -ForegroundColor White
Write-Console ""

Write-Console "Starting backup..." -ForegroundColor Green
Write-Console ""

# Build rclone command with filter rules
$rcloneArgs = @(
    "sync"
    "$ImmichPath\"
    $Remote
    "--filter", "+ /.env"
    "--filter", "+ /docker-compose.yml"
    "--filter", "+ /hwaccel.*.yml"
    "--filter", "+ /immich-config.json"
    "--filter", "+ /*.ps1"
    "--filter", "+ /library/"
    "--filter", "+ /library/library/"
    "--filter", "+ /library/library/**"
    "--filter", "+ /library/upload/"
    "--filter", "+ /library/upload/**"
    "--filter", "+ /library/profile/"
    "--filter", "+ /library/profile/**"
    "--filter", "+ /library/backups/"
    "--filter", "+ /library/backups/**"
    "--filter", "- /library/**"
    "--filter", "- /postgres/"
    "--filter", "- /postgres/**"
    "--filter", "- *"
    "--progress"
    "--transfers", "4"
    "--checkers", "8"
    "--delete-during"
    "--backup-dir", "${Remote}_deleted"
    "--log-file", $logFilePath
    "--log-level", "INFO"
)

if ($DryRun) {
    $rcloneArgs += "--dry-run"
}

# Run rclone
& rclone $rcloneArgs

if ($LASTEXITCODE -eq 0) {
    Write-Console ""
    Write-Console "========================================" -ForegroundColor Cyan
    Write-Console "Backup completed successfully!" -ForegroundColor Green
    Write-Console "========================================" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Log file: $logFilePath" -ForegroundColor White
} else {
    Write-Console ""
    Write-Console "========================================" -ForegroundColor Cyan
    Write-Console "Backup failed with error code: $LASTEXITCODE" -ForegroundColor Red
    Write-Console "========================================" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Check log file: $logFilePath" -ForegroundColor Yellow
}

if ($StopImmich) {
    Write-Console ""
    Write-Console "Starting Immich containers..." -ForegroundColor Yellow
    Push-Location $ImmichPath
    & .\scripts\start-immich.ps1
    Pop-Location
}

Write-Console ""

