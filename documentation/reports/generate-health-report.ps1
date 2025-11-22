# Daily System Health Report Generator v2.0
# Aggregates status from local system, centralized config, and backup audits
# Location: documentation/reports/generate-health-report.ps1
# Usage: ./generate-health-report.ps1 [-OpenAfter]

[CmdletBinding()]
param(
    [string]$OutputFile,
    [switch]$OpenAfter
)

$scriptRoot = $PSScriptRoot
$devRoot = Resolve-Path (Join-Path $scriptRoot "../..")
$dateStr = Get-Date -Format "yyyy-MM-dd"

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $scriptRoot "health-report-$dateStr.md"
}

# --- LOAD CONFIGURATION ---
if (-not $Global:HomelabConfig) {
    $configPath = Join-Path $devRoot ".config\homelab.settings.json"
    if (Test-Path $configPath) {
        try {
            $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to load configuration: $_"
        }
    }
}
$Config = $Global:HomelabConfig

$verifyBackupsScript = Join-Path $devRoot "infrastructure\backup\audits\verify-backups.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SYSTEM HEALTH REPORT GENERATOR" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating report: $OutputFile" -ForegroundColor Gray
Write-Host ""

# === Helper Functions ===

function Get-DiskSpaceTable {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }

    $table = "| Drive | Used (GB) | Free (GB) | Total (GB) | % Free |`n"
    $table += "|-------|-----------|-----------|------------|--------|`n"

    foreach ($drive in $drives) {
        $used = [math]::Round($drive.Used / 1GB, 2)
        $free = [math]::Round($drive.Free / 1GB, 2)
        $total = $used + $free
        $pctFree = [math]::Round(($free / $total) * 100, 1)

        $statusIcon = if ($pctFree -lt 10) { "🔴" } elseif ($pctFree -lt 25) { "🟡" } else { "🟢" }

        $table += "| $statusIcon $($drive.Name): | $used | $free | $total | $pctFree% |`n"
    }

    return $table
}

function Get-DockerStatus {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            $running = @(docker ps -q 2>$null).Count
            $total = @(docker ps -a -q 2>$null).Count
            return "Running: **$running** / $total containers"
        } catch {
            return "Docker installed but not running"
        }
    }
    return "Docker not found on local system"
}

function Get-BackupStatus {
    param([string]$ScriptPath)

    if (-not (Test-Path $ScriptPath)) {
        return "_Backup verification script not found._"
    }

    Write-Host "  Running backup verification..." -ForegroundColor Yellow

    try {
        $output = & $ScriptPath *>&1 | Out-String
        return "``````text`n$($output.Trim())`n``````"
    } catch {
        return "_Error running backup verification: $_"
    }
}

# === Build Report ===

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# 📊 Homelab Health Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Date:** $dateStr")
[void]$sb.AppendLine("**Generated:** $(Get-Date -Format 'HH:mm:ss')")

# Add config-based metadata
if ($Config) {
    [void]$sb.AppendLine("**Owner:** $($Config.Owner)")
    [void]$sb.AppendLine("**Network:** $($Config.Network.Subnet) (Gateway: $($Config.Network.Gateway))")
} else {
    [void]$sb.AppendLine("**Owner:** _Configuration not loaded_")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")

# Section 1: Local Resources
Write-Host "[1/4] Gathering local disk space..." -ForegroundColor Cyan
[void]$sb.AppendLine("## 🖥️ Local Resources (Windows)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine((Get-DiskSpaceTable))
[void]$sb.AppendLine("")

# Section 2: Backup Infrastructure
Write-Host "[2/4] Verifying backup infrastructure..." -ForegroundColor Cyan
[void]$sb.AppendLine("## 🛡️ Backup Infrastructure")
[void]$sb.AppendLine("")
[void]$sb.AppendLine((Get-BackupStatus $verifyBackupsScript))
[void]$sb.AppendLine("")

# Section 3: Services
Write-Host "[3/4] Checking service status..." -ForegroundColor Cyan
[void]$sb.AppendLine("## 🐳 Service Status")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### Local Docker")
[void]$sb.AppendLine("- Status: $(Get-DockerStatus)")
[void]$sb.AppendLine("")

# Section 4: Infrastructure Hosts (from config)
Write-Host "[4/4] Listing infrastructure hosts..." -ForegroundColor Cyan
[void]$sb.AppendLine("### Infrastructure Hosts")
[void]$sb.AppendLine("")

if ($Config -and $Config.Network.Hosts) {
    $Config.Network.Hosts.PSObject.Properties | ForEach-Object {
        $hostInfo = $_.Value
        [void]$sb.AppendLine("- **$($hostInfo.Name):** $($hostInfo.IP) ($($hostInfo.Role))")
    }
} else {
    [void]$sb.AppendLine("_Configuration not loaded - unable to list infrastructure hosts_")
}

[void]$sb.AppendLine("")

# Section 5: Containers (from config)
if ($Config -and $Config.Network.Containers) {
    [void]$sb.AppendLine("### LXC Containers")
    [void]$sb.AppendLine("")
    $Config.Network.Containers.PSObject.Properties | ForEach-Object {
        $containerInfo = $_.Value
        [void]$sb.AppendLine("- **$($_.Name):** LXC $($containerInfo.ID) @ $($containerInfo.IP) - $($containerInfo.Role)")
    }
    [void]$sb.AppendLine("")
}

# Section 6: Notes
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 📝 Notes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("_Add manual observations here..._")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("*Report generated by `generate-health-report.ps1` using centralized configuration*")

# Save Report
$sb.ToString() | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Report generated successfully!" -ForegroundColor Green
Write-Host "Location: $OutputFile" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($OpenAfter) {
    Invoke-Item $OutputFile
}
