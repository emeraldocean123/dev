# Automated Backup Verification & Audit Tool
# Checks ZFS snapshots on primary/secondary hosts and Synology status
# Location: infrastructure/backup/audits/verify-backups.ps1

[CmdletBinding()]
param(
    [string]$PrimaryHost = "intel-1250p",
    [string]$SecondaryHost = "intel-n6005",
    [string]$SynologyHost = "synology",
    [string]$Dataset = "rpool/intel-1250p-proxmox-backup-server",
    [string]$SnapshotPrefix = "pbs-repl",
    [switch]$Verbose
)

function Get-RemoteZfsSnapshots {
    param($HostName, $Dataset, $Prefix)

    try {
        Write-Host "  Querying $HostName..." -ForegroundColor Gray
        $output = ssh -o ConnectTimeout=5 root@$HostName "zfs list -H -t snapshot -o name,creation -s creation $Dataset 2>/dev/null" 2>&1

        if ($LASTEXITCODE -eq 0) {
            $snapshots = $output | Where-Object { $_ -like "*@$Prefix*" }
            if ($snapshots) {
                $latest = $snapshots | Select-Object -Last 1
                return @{
                    Success = $true
                    Latest = $latest
                    Count = ($snapshots | Measure-Object).Count
                }
            }
        }
    } catch {
        Write-Verbose "Error connecting to $HostName: $_"
    }

    return @{Success = $false; Latest = $null; Count = 0}
}

function Get-HostStatus {
    param($HostName)

    try {
        $result = ssh -o ConnectTimeout=5 -o BatchMode=yes root@$HostName "echo OK" 2>&1
        if ($LASTEXITCODE -eq 0 -and $result -eq "OK") {
            return $true
        }
    } catch {}

    return $false
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BACKUP INFRASTRUCTURE AUDIT" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
$auditDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Audit Date: $auditDate" -ForegroundColor Gray
Write-Host ""

$allGood = $true

# === Layer 1: Primary PBS (intel-1250p) ===
Write-Host "[Layer 1] Primary Backup Server ($PrimaryHost)" -ForegroundColor Yellow

if (Get-HostStatus $PrimaryHost) {
    $l1 = Get-RemoteZfsSnapshots $PrimaryHost $Dataset $SnapshotPrefix

    if ($l1.Success) {
        Write-Host "  [OK] Host online" -ForegroundColor Green
        Write-Host "  [OK] Snapshots found: $($l1.Count)" -ForegroundColor Green
        Write-Host "       Latest: $($l1.Latest)" -ForegroundColor Gray
    } else {
        Write-Host "  [WARN] No replication snapshots found" -ForegroundColor Red
        $allGood = $false
    }
} else {
    Write-Host "  [ERROR] Host unreachable" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# === Layer 2: Off-Host Replication (intel-n6005) ===
Write-Host "[Layer 2] Off-Host Replication ($SecondaryHost)" -ForegroundColor Yellow

if (Get-HostStatus $SecondaryHost) {
    $l2 = Get-RemoteZfsSnapshots $SecondaryHost $Dataset $SnapshotPrefix

    if ($l2.Success) {
        Write-Host "  [OK] Host online" -ForegroundColor Green
        Write-Host "  [OK] Snapshots found: $($l2.Count)" -ForegroundColor Green
        Write-Host "       Latest: $($l2.Latest)" -ForegroundColor Gray

        # Check sync status
        if ($l1.Success -and $l1.Latest -eq $l2.Latest) {
            Write-Host "  [OK] Replication in sync with primary" -ForegroundColor Green
        } elseif ($l1.Success) {
            Write-Host "  [WARN] Replication may be behind primary" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] No replication snapshots found" -ForegroundColor Red
        $allGood = $false
    }
} else {
    Write-Host "  [INFO] Host offline (Expected: RTC Wake runs at 2:50 AM)" -ForegroundColor DarkGray
}

Write-Host ""

# === Layer 3: Cold Storage (Synology) ===
Write-Host "[Layer 3] Cold Storage ($SynologyHost)" -ForegroundColor Yellow

if (Get-HostStatus $SynologyHost) {
    Write-Host "  [OK] Synology online and accessible" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Synology offline (Expected: On-demand only)" -ForegroundColor DarkGray
}

Write-Host ""

# === Summary ===
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "  AUDIT RESULT: PASS" -ForegroundColor Green
    Write-Host "  All critical backup layers verified" -ForegroundColor Green
} else {
    Write-Host "  AUDIT RESULT: ATTENTION NEEDED" -ForegroundColor Yellow
    Write-Host "  Review warnings above" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
