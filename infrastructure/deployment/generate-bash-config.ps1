# Generates a Bash-compatible .env file from the secure JSON config
# Used by deploy-to-proxmox.ps1 to inject secrets into remote servers
# Location: infrastructure/deployment/generate-bash-config.ps1

param([string]$OutputPath)

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")

# Load Config
if (-not $Global:HomelabConfig) {
    $configPath = Join-Path $devRoot ".config\homelab.settings.json"
    if (Test-Path $configPath) {
        $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    } else {
        Write-Error "Configuration not found."
        exit 1
    }
}
$C = $Global:HomelabConfig

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Homelab Environment Variables")
[void]$sb.AppendLine("# Generated: $(Get-Date)")
[void]$sb.AppendLine("# DO NOT EDIT - Generated from homelab.settings.json")
[void]$sb.AppendLine("")

# --- HOSTS ---
# Mapping JSON host keys to Standard Bash Variables
if ($C.Network.Hosts.Primary) {
    $h = $C.Network.Hosts.Primary
    [void]$sb.AppendLine("export PRIMARY_HOST='$($h.Name)'")
    [void]$sb.AppendLine("export PRIMARY_IP='$($h.IP)'")
    [void]$sb.AppendLine("export PRIMARY_USER='$($h.User)'")
    if ($h.Mac) {
        [void]$sb.AppendLine("export MAC_1250P='$($h.Mac)'")
    }
}

if ($C.Network.Hosts.Secondary) {
    $h = $C.Network.Hosts.Secondary
    [void]$sb.AppendLine("export SECONDARY_HOST='$($h.Name)'")
    [void]$sb.AppendLine("export SECONDARY_IP='$($h.IP)'")
    [void]$sb.AppendLine("export SECONDARY_USER='$($h.User)'")
    if ($h.Mac) {
        [void]$sb.AppendLine("export MAC_N6005='$($h.Mac)'")
    }
}

if ($C.Network.Hosts.NAS) {
    $h = $C.Network.Hosts.NAS
    [void]$sb.AppendLine("export NAS_HOST='$($h.Name)'")
    [void]$sb.AppendLine("export NAS_IP='$($h.IP)'")
    [void]$sb.AppendLine("export NAS_USER='$($h.User)'")
    if ($h.Mac) {
        [void]$sb.AppendLine("export NAS_MAC='$($h.Mac)'")
        [void]$sb.AppendLine("export MAC_SYNOLOGY='$($h.Mac)'")
    }
    if ($h.BackupPath) {
        [void]$sb.AppendLine("export NAS_BACKUP_PATH='$($h.BackupPath)'")
    }
}

# --- SSH ---
if ($C.SSH.KeyPath) {
    [void]$sb.AppendLine("export SSH_KEY_PATH='$($C.SSH.KeyPath)'")
}

# --- BACKUP ---
if ($C.Backup) {
    if ($C.Backup.SourceDataset) {
        [void]$sb.AppendLine("export BACKUP_SOURCE_DATASET='$($C.Backup.SourceDataset)'")
    }
    if ($C.Backup.TargetDataset) {
        [void]$sb.AppendLine("export BACKUP_TARGET_DATASET='$($C.Backup.TargetDataset)'")
    }
    if ($C.Backup.SnapshotPrefix) {
        [void]$sb.AppendLine("export BACKUP_SNAPSHOT_PREFIX='$($C.Backup.SnapshotPrefix)'")
    }
    if ($C.Backup.KeepSnapshots) {
        [void]$sb.AppendLine("export BACKUP_KEEP_SNAPSHOTS='$($C.Backup.KeepSnapshots)'")
    }
    if ($C.Backup.SourceMount) {
        [void]$sb.AppendLine("export BACKUP_SOURCE_MOUNT='$($C.Backup.SourceMount)'")
    }
}

# Output
$content = $sb.ToString()
if ($OutputPath) {
    $content | Out-File -FilePath $OutputPath -Encoding utf8 -Force
    Write-Host "Generated env file at: $OutputPath" -ForegroundColor DarkGray
} else {
    return $content
}
