# Generate Bash Configuration from Central JSON
# Reads .config/homelab.settings.json and generates .config/homelab.env
# Location: shell-management/utils/generate-bash-config.ps1
# Usage: ./generate-bash-config.ps1 [-OutputPath <path>]

[CmdletBinding()]
param(
    [string]$OutputPath
)

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")

# Default output location
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $devRoot ".config\homelab.env"
}

# Load configuration
if (-not $Global:HomelabConfig) {
    $configPath = Join-Path $devRoot ".config\homelab.settings.json"
    if (-not (Test-Path $configPath)) {
        Write-Error "Configuration not found at: $configPath"
        Write-Host "Run: ./shell-management/utils/setup-homelab-config.ps1" -ForegroundColor Yellow
        exit 1
    }

    try {
        $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Failed to load configuration: $_"
        exit 1
    }
}

$Config = $Global:HomelabConfig

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BASH CONFIGURATION GENERATOR" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Source: .config/homelab.settings.json" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "[Created] $outputDir" -ForegroundColor Green
}

# Build environment file content
$envContent = @"
# Homelab Bash Configuration
# Auto-generated from .config/homelab.settings.json
# DO NOT EDIT MANUALLY - Changes will be overwritten
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# ===== NETWORK CONFIGURATION =====
NETWORK_SUBNET="$($Config.Network.Subnet)"
NETWORK_GATEWAY="$($Config.Network.Gateway)"

"@

# Add host configurations
if ($Config.Network.Hosts) {
    $envContent += "# ===== HOST CONFIGURATION =====`n"

    foreach ($hostProp in $Config.Network.Hosts.PSObject.Properties) {
        $hostInfo = $hostProp.Value
        $hostKey = $hostProp.Name.ToUpper()

        if ($hostInfo.Name) {
            $envContent += "HOST_${hostKey}_NAME=`"$($hostInfo.Name)`"`n"
        }
        if ($hostInfo.IP) {
            $envContent += "HOST_${hostKey}_IP=`"$($hostInfo.IP)`"`n"
        }
        if ($hostInfo.User) {
            $envContent += "HOST_${hostKey}_USER=`"$($hostInfo.User)`"`n"
        }
        if ($hostInfo.Mac) {
            $envContent += "HOST_${hostKey}_MAC=`"$($hostInfo.Mac)`"`n"
        }
        if ($hostInfo.Role) {
            $envContent += "HOST_${hostKey}_ROLE=`"$($hostInfo.Role)`"`n"
        }
        if ($hostInfo.ScriptPath) {
            $envContent += "HOST_${hostKey}_SCRIPT_PATH=`"$($hostInfo.ScriptPath)`"`n"
        }
        if ($hostInfo.Volume) {
            $envContent += "HOST_${hostKey}_VOLUME=`"$($hostInfo.Volume)`"`n"
        }
        $envContent += "`n"
    }
}

# Add container configurations
if ($Config.Network.Containers) {
    $envContent += "# ===== CONTAINER CONFIGURATION =====`n"

    foreach ($containerProp in $Config.Network.Containers.PSObject.Properties) {
        $container = $containerProp.Value
        $containerKey = $containerProp.Name.ToUpper()

        if ($container.ID) {
            $envContent += "CONTAINER_${containerKey}_ID=`"$($container.ID)`"`n"
        }
        if ($container.IP) {
            $envContent += "CONTAINER_${containerKey}_IP=`"$($container.IP)`"`n"
        }
        if ($container.Role) {
            $envContent += "CONTAINER_${containerKey}_ROLE=`"$($container.Role)`"`n"
        }
        $envContent += "`n"
    }
}

# Add SSH configuration
if ($Config.SSH) {
    $envContent += "# ===== SSH CONFIGURATION =====`n"
    if ($Config.SSH.KeyPath) {
        $envContent += "SSH_KEY_PATH=`"$($Config.SSH.KeyPath)`"`n"
    }
    if ($Config.SSH.KeyFile) {
        $envContent += "SSH_KEY_FILE=`"$($Config.SSH.KeyFile)`"`n"
    }
    $envContent += "`n"
}

# Add backup configuration
if ($Config.Backup) {
    $envContent += "# ===== BACKUP CONFIGURATION =====`n"
    if ($Config.Backup.SourceDataset) {
        $envContent += "BACKUP_SOURCE_DATASET=`"$($Config.Backup.SourceDataset)`"`n"
    }
    if ($Config.Backup.TargetDataset) {
        $envContent += "BACKUP_TARGET_DATASET=`"$($Config.Backup.TargetDataset)`"`n"
    }
    if ($Config.Backup.SnapshotPrefix) {
        $envContent += "BACKUP_SNAPSHOT_PREFIX=`"$($Config.Backup.SnapshotPrefix)`"`n"
    }
    if ($Config.Backup.KeepSnapshots) {
        $envContent += "BACKUP_KEEP_SNAPSHOTS=`"$($Config.Backup.KeepSnapshots)`"`n"
    }
    if ($Config.Backup.SourceMount) {
        $envContent += "BACKUP_SOURCE_MOUNT=`"$($Config.Backup.SourceMount)`"`n"
    }
    if ($Config.Backup.TargetPath) {
        $envContent += "BACKUP_TARGET_PATH=`"$($Config.Backup.TargetPath)`"`n"
    }
    $envContent += "`n"
}

# Add convenience aliases for common hosts
$envContent += "# ===== CONVENIENCE ALIASES =====`n"
$envContent += "# These provide backward compatibility with existing scripts`n`n"

# Primary/Secondary Proxmox hosts
if ($Config.Network.Hosts.Primary) {
    $primary = $Config.Network.Hosts.Primary
    $envContent += "# Primary Proxmox Host`n"
    $envContent += "PRIMARY_HOST=`"$($primary.Name)`"`n"
    $envContent += "PRIMARY_IP=`"$($primary.IP)`"`n"
    $envContent += "PRIMARY_USER=`"$($primary.User)`"`n"
    $envContent += "PRIMARY_MAC=`"$($primary.Mac)`"`n"
    $envContent += "`n"
}

if ($Config.Network.Hosts.Secondary) {
    $secondary = $Config.Network.Hosts.Secondary
    $envContent += "# Secondary Proxmox Host`n"
    $envContent += "SECONDARY_HOST=`"$($secondary.Name)`"`n"
    $envContent += "SECONDARY_IP=`"$($secondary.IP)`"`n"
    $envContent += "SECONDARY_USER=`"$($secondary.User)`"`n"
    $envContent += "SECONDARY_MAC=`"$($secondary.Mac)`"`n"
    $envContent += "`n"
}

# NAS
if ($Config.Network.Hosts.NAS) {
    $nas = $Config.Network.Hosts.NAS
    $envContent += "# Synology NAS`n"
    $envContent += "NAS_HOST=`"$($nas.Name)`"`n"
    $envContent += "NAS_IP=`"$($nas.IP)`"`n"
    $envContent += "NAS_USER=`"$($nas.User)`"`n"
    $envContent += "NAS_MAC=`"$($nas.Mac)`"`n"
    if ($nas.Volume) {
        $envContent += "NAS_VOLUME=`"$($nas.Volume)`"`n"
    }
    # Computed convenience variables for rsync
    if ($Config.Backup -and $Config.Backup.TargetPath) {
        $envContent += "NAS_BACKUP_TARGET=`"$($nas.User)@$($nas.IP):$($Config.Backup.TargetPath)`"`n"
    }
    $envContent += "`n"
}

# Compatibility aliases for wake-servers.sh
$envContent += "# ===== WAKE-ON-LAN COMPATIBILITY =====`n"
if ($Config.Network.Hosts.Primary -and $Config.Network.Hosts.Primary.Mac) {
    $envContent += "MAC_1250P=`"$($Config.Network.Hosts.Primary.Mac)`"`n"
}
if ($Config.Network.Hosts.Secondary -and $Config.Network.Hosts.Secondary.Mac) {
    $envContent += "MAC_N6005=`"$($Config.Network.Hosts.Secondary.Mac)`"`n"
}
if ($Config.Network.Hosts.NAS -and $Config.Network.Hosts.NAS.Mac) {
    $envContent += "MAC_SYNOLOGY=`"$($Config.Network.Hosts.NAS.Mac)`"`n"
}
$envContent += "`n"

$envContent += "# End of generated configuration`n"

# Write to file
$envContent | Out-File -FilePath $OutputPath -Encoding utf8 -NoNewline

Write-Host "[Generated] $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration file generated successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Show sample variables
Write-Host "Sample variables available in scripts:" -ForegroundColor Yellow
Write-Host "  \$PRIMARY_IP      = $($Config.Network.Hosts.Primary.IP)" -ForegroundColor Gray
Write-Host "  \$SECONDARY_IP    = $($Config.Network.Hosts.Secondary.IP)" -ForegroundColor Gray
Write-Host "  \$NAS_IP          = $($Config.Network.Hosts.NAS.IP)" -ForegroundColor Gray
Write-Host ""
