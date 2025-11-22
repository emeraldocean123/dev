# Deploy PowerShell Profile
# Links the Windows PowerShell profile to this repository location

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$RepoProfile = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"
$TargetProfile = $PROFILE

Write-Console "=== Deploying PowerShell Profile ===" -ForegroundColor Cyan
Write-Console "Source: $RepoProfile" -ForegroundColor Gray
Write-Console "Target: $TargetProfile" -ForegroundColor Gray
Write-Console ""

if (-not (Test-Path $RepoProfile)) {
    Write-Console "ERROR: Repository profile not found!" -ForegroundColor Red
    exit 1
}

# Ensure target directory exists
$TargetDir = Split-Path $TargetProfile
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Console "Created directory: $TargetDir" -ForegroundColor Yellow
}

# Backup existing profile
if (Test-Path $TargetProfile) {
    $BackupPath = "$TargetProfile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $TargetProfile $BackupPath -Force
    Write-Console "Backed up existing profile to: $BackupPath" -ForegroundColor Yellow
}

# Create loader script
# We use dot-sourcing so variables/functions are loaded into the current scope
$LoaderContent = ". `"$RepoProfile`""
Set-Content -Path $TargetProfile -Value $LoaderContent -Encoding UTF8

Write-Console "Successfully deployed profile loader!" -ForegroundColor Green
Write-Console "Your profile now loads directly from the dev repository." -ForegroundColor Green
Write-Console "Run 'Reload-Profile' or restart PowerShell to apply." -ForegroundColor Cyan
