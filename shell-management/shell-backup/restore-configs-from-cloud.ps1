# Restore Dotfiles & Configs from Cloud
# Recovers local private configurations from cloud storage using Rclone
# Location: shell-management/shell-backup/restore-configs-from-cloud.ps1
# Usage: ./restore-configs-from-cloud.ps1 [-Force]
#
# DISASTER RECOVERY:
#   This script is the inverse of backup-configs-to-cloud.ps1.
#   Use it to restore configuration after:
#   - Fresh OS installation
#   - Drive failure
#   - Accidental deletion
#   - Migration to new machine

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force,
    [string]$Remote,
    [string]$RemotePath
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Utils not found at $libPath" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Configuration Restoration Tool" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Load Configuration (if exists)
$configPath = Join-Path $devRoot ".config\homelab.settings.json"
$configExists = Test-Path $configPath

if ($configExists -and -not $Force) {
    Write-Console "WARNING: Local configuration already exists!" -ForegroundColor Yellow
    Write-Console "         $configPath" -ForegroundColor Gray
    Write-Console ""
    Write-Console "This will OVERWRITE your existing configuration." -ForegroundColor Yellow
    Write-Console ""
    $response = Read-Host "Continue with restoration? (yes/no)"

    if ($response -notmatch '^(yes|y)$') {
        Write-Console "Restoration cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Attempt to load existing config for cloud settings
if ($configExists) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json

        if (-not $Remote) {
            $Remote = $config.Cloud.RcloneRemote
        }
        if (-not $RemotePath) {
            $RemotePath = $config.Cloud.ConfigBackupPath
        }
    }
    catch {
        Write-Console "WARNING: Could not read existing config: $_" -ForegroundColor Yellow
    }
}

# Fallback to defaults if not specified
if (-not $Remote) {
    $Remote = Read-Host "Enter rclone remote name (default: googlephotos)"
    if (-not $Remote) { $Remote = "googlephotos" }
}

if (-not $RemotePath) {
    $RemotePath = Read-Host "Enter remote path (default: homelab-configs)"
    if (-not $RemotePath) { $RemotePath = "homelab-configs" }
}

# Check if rclone is installed
if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Console "ERROR: rclone is not installed" -ForegroundColor Red
    Write-Console "       Install from: https://rclone.org/" -ForegroundColor Yellow
    exit 1
}

# Verify remote exists
Write-Console "Verifying rclone remote: $Remote" -ForegroundColor Cyan
$remoteCheck = & rclone listremotes 2>&1
if ($LASTEXITCODE -ne 0 -or $remoteCheck -notmatch $Remote) {
    Write-Console "ERROR: Rclone remote '$Remote' not found" -ForegroundColor Red
    Write-Console "       Available remotes:" -ForegroundColor Yellow
    & rclone listremotes
    Write-Console ""
    Write-Console "       Configure with: rclone config" -ForegroundColor Yellow
    exit 1
}

# Construct source and destination paths
$source = "${Remote}:${RemotePath}/"
$destination = Join-Path $devRoot ".config"

Write-Console ""
Write-Console "Restoration Plan:" -ForegroundColor Cyan
Write-Console "  Source:      $source" -ForegroundColor Gray
Write-Console "  Destination: $destination" -ForegroundColor Gray
Write-Console ""

# Create destination directory if needed
if (-not (Test-Path $destination)) {
    Write-Console "Creating directory: $destination" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}

# Execute restoration
Write-Console "Starting restoration from cloud..." -ForegroundColor Yellow
Write-Console ""

try {
    & rclone copy $source $destination --verbose --progress

    if ($LASTEXITCODE -ne 0) {
        Write-Console ""
        Write-Console "ERROR: Restoration failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }

    Write-Console ""
    Write-Console "Cloud restoration completed successfully!" -ForegroundColor Green
}
catch {
    Write-Console "ERROR: Restoration failed: $_" -ForegroundColor Red
    exit 1
}

# CRITICAL: Validate restored configuration
Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Post-Restoration Validation" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

$validatorPath = Join-Path $devRoot "shell-management\utils\_validate-config.ps1"

if (Test-Path $validatorPath) {
    Write-Console "Running configuration validator..." -ForegroundColor Cyan

    $validationResult = & pwsh -NoProfile -File $validatorPath -ConfigPath $configPath -Verbose
    $validationExitCode = $LASTEXITCODE

    if ($validationExitCode -eq 0) {
        Write-Console ""
        Write-Console "========================================" -ForegroundColor Green
        Write-Console "  Restoration Complete" -ForegroundColor Green
        Write-Console "========================================" -ForegroundColor Green
        Write-Console ""
        Write-Console "Configuration restored and validated!" -ForegroundColor Green
        Write-Console ""
        Write-Console "Next steps:" -ForegroundColor Cyan
        Write-Console "  1. Review restored config: $configPath" -ForegroundColor Gray
        Write-Console "  2. Update any machine-specific values (IPs, paths)" -ForegroundColor Gray
        Write-Console "  3. Run: .\homelab.ps1 to verify functionality" -ForegroundColor Gray
        Write-Console ""
    }
    else {
        Write-Console ""
        Write-Console "WARNING: Restored configuration has validation errors" -ForegroundColor Yellow
        Write-Console "         Review the errors above and fix manually" -ForegroundColor Yellow
        Write-Console "         Config location: $configPath" -ForegroundColor Gray
        Write-Console ""
        exit 1
    }
}
else {
    Write-Console "WARNING: Validator not found - skipping validation" -ForegroundColor Yellow
    Write-Console "         Manually verify: $configPath" -ForegroundColor Gray
    Write-Console ""
}

# List restored files
Write-Console "Restored files:" -ForegroundColor Cyan
Get-ChildItem $destination -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Replace($destination, "").TrimStart('\', '/')
    Write-Console "  + .config/$relativePath" -ForegroundColor Gray
}

Write-Console ""
