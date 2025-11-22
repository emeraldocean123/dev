# Automated Script Deployment to Proxmox Hosts
# Uses Centralized Config (.config/homelab.settings.json)
# Location: infrastructure/deployment/deploy-to-proxmox.ps1
# Usage: ./deploy-to-proxmox.ps1 [-WhatIf] [-Hosts "intel-1250p"]

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string[]]$Hosts = @(),  # Filter by specific host names (empty = deploy to all)
    [switch]$DryRun
)

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")

# Import shared utilities
$libPath = Join-Path $devRoot "lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# --- LOAD CONFIGURATION ---
if (-not $Global:HomelabConfig) {
    $configPath = Join-Path $devRoot ".config\homelab.settings.json"
    if (Test-Path $configPath) {
        try {
            $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Failed to load configuration: $_"
            exit 1
        }
    } else {
        Write-Error "Configuration not found at: $configPath"
        Write-Host "Run: ./shell-management/utils/setup-homelab-config.ps1" -ForegroundColor Yellow
        exit 1
    }
}
$Config = $Global:HomelabConfig

# --- GENERATE BASH CONFIG ---
$envFile = Join-Path $scriptRoot "homelab.env.tmp"
& (Join-Path $scriptRoot "generate-bash-config.ps1") -OutputPath $envFile

if (-not (Test-Path $envFile)) {
    Write-Error "Failed to generate bash config file"
    exit 1
}

# --- DEPLOYMENT MAPPINGS (Code Logic - What Goes Where) ---
# Maps Host Names -> Array of Script Paths (relative to devRoot)
$DeploymentMap = @{
    "intel-1250p" = @(
        "infrastructure/proxmox/lxc-setup.sh",
        "infrastructure/proxmox/lxc-utils.sh",
        "infrastructure/proxmox/upgrade-debian.sh",
        "infrastructure/proxmox/proxmox-setup-repos.sh",
        "infrastructure/backup/scripts/zfs-replicate-pbs.sh",
        "infrastructure/backup/scripts/rsync-pbs-to-synology.sh",
        "infrastructure/backup/scripts/synology-auto-backup.sh",
        "infrastructure/network/wake-on-lan/wake-servers.sh"
    )
    "intel-n6005" = @(
        "infrastructure/backup/rtc-wake/shutdown-with-rtc-wake.sh",
        "infrastructure/backup/rtc-wake/set-rtc-alarm-on-boot.sh",
        "infrastructure/network/wake-on-lan/wake-servers.sh"
    )
}

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  PROXMOX DEPLOYMENT AUTOMATION" -ForegroundColor White
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

$deployedCount = 0
$errorCount = 0

foreach ($hostKey in $DeploymentMap.Keys) {
    # Skip if user filtered by specific hosts
    if ($Hosts.Count -gt 0 -and $hostKey -notin $Hosts) {
        continue
    }

    # Retrieve Host Details from Central Config (Environment Data - Where/Who)
    $hostInfo = $null
    foreach ($hostProp in $Config.Network.Hosts.PSObject.Properties) {
        if ($hostProp.Value.Name -eq $hostKey) {
            $hostInfo = $hostProp.Value
            break
        }
    }

    if (-not $hostInfo) {
        Write-Console "[SKIP] Host '$hostKey' defined in mappings but missing from config" -ForegroundColor Red
        $errorCount++
        continue
    }

    $sshTarget = "$($hostInfo.User)@$($hostInfo.Name)"
    $targetDir = if ($hostInfo.ScriptPath) { $hostInfo.ScriptPath } else { "/root/sh/" }
    $configDir = "${targetDir}config/"

    Write-Console "[Target] $($hostInfo.Name) ($sshTarget -> $targetDir)" -ForegroundColor Yellow
    Write-Console ""

    # 1. Ensure Directories Exist
    if (-not $DryRun -and $PSCmdlet.ShouldProcess($sshTarget, "Create directories")) {
        try {
            ssh $sshTarget "mkdir -p $configDir" 2>&1 | Out-Null
        } catch {
            Write-Console "  [WARN] Could not create config directory" -ForegroundColor Yellow
        }
    }

    # 2. Deploy Config File
    if ($PSCmdlet.ShouldProcess("$sshTarget:${configDir}homelab.env", "Deploy Config")) {
        Write-Host "  [CONFIG] homelab.env... " -NoNewline

        if ($DryRun) {
            Write-Host "[DRYRUN]" -ForegroundColor Yellow
        } else {
            try {
                $scpResult = scp -q $envFile "$($sshTarget):${configDir}homelab.env" 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "SCP failed: $scpResult"
                }

                Write-Host "[OK]" -ForegroundColor Green
                $deployedCount++
            } catch {
                Write-Host "[FAILED]" -ForegroundColor Red
                Write-Host "    Error: $_" -ForegroundColor Red
                $errorCount++
            }
        }
    }

    # 3. Deploy Scripts
    foreach ($relPath in $DeploymentMap[$hostKey]) {
        $localPath = Join-Path $devRoot $relPath

        if (-not (Test-Path $localPath)) {
            Write-Console "  [SKIP] $relPath - file not found locally" -ForegroundColor Red
            $errorCount++
            continue
        }

        $fileName = Split-Path $localPath -Leaf
        $remotePath = "$targetDir$fileName"

        if ($DryRun) {
            Write-Console "  [DRYRUN] Would deploy: $fileName" -ForegroundColor Yellow
            continue
        }

        if ($PSCmdlet.ShouldProcess("$sshTarget:$remotePath", "Deploy $fileName")) {
            Write-Host "  [DEPLOY] $fileName... " -NoNewline

            try {
                # Transfer file via SCP
                $scpResult = scp -q $localPath "$($sshTarget):$targetDir" 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "SCP failed: $scpResult"
                }

                # Set execute permission
                $chmodResult = ssh -o ConnectTimeout=5 $sshTarget "chmod +x $remotePath" 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "chmod failed: $chmodResult"
                }

                Write-Host "[OK]" -ForegroundColor Green
                $deployedCount++
            }
            catch {
                Write-Host "[FAILED]" -ForegroundColor Red
                Write-Host "    Error: $_" -ForegroundColor Red
                $errorCount++
            }
        }
    }

    Write-Console ""
}

# Cleanup temporary env file
if (Test-Path $envFile) {
    Remove-Item $envFile -Force
}

Write-Console "========================================" -ForegroundColor Cyan
Write-Console "Deployment Summary:" -ForegroundColor White
Write-Console "  Deployed: $deployedCount files" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Console "  Errors: $errorCount files" -ForegroundColor Red
}
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""
