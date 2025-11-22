# System Health Reports

Automated health monitoring and reporting for your homelab infrastructure.

## Files

- `generate-health-report.ps1` - Daily health report generator
- `health-report-YYYY-MM-DD.md` - Generated reports (not committed to git)

## Usage

### Generate Report

```powershell
cd <Repository Root>/documentation/reports
./generate-health-report.ps1
```

### Open After Generation

```powershell
./generate-health-report.ps1 -OpenAfter
```

### Custom Output Location

```powershell
./generate-health-report.ps1 -OutputFile "C:\Reports\status.md"
```

## Report Sections

The generated report includes:

1. **Local Resources** - Windows disk space with status indicators
   - 🟢 Green: >25% free
   - 🟡 Yellow: 10-25% free
   - 🔴 Red: <10% free

2. **Backup Infrastructure** - Runs `verify-backups.ps1` to check:
   - Layer 1: Primary PBS on intel-1250p
   - Layer 2: Off-host replication on intel-n6005
   - Layer 3: Synology NAS cold storage

3. **Service Status** - Docker container status
   - Local Docker Desktop status
   - Placeholders for Proxmox checks

4. **Notes** - Space for manual observations

## Automation

### Daily Reports (Scheduled Task)

Create a scheduled task to run daily:

```powershell
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-NoProfile -File <Repository Root>/documentation/reports/generate-health-report.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At "8:00AM"

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "HomelabHealthReport" `
    -Description "Generate daily homelab health report"
```

### Weekly Summary

Generate a weekly archive:

```powershell
# Run every Monday to generate weekly report
./generate-health-report.ps1 -OutputFile "weekly-$(Get-Date -Format 'yyyy-MM-dd').md"
```

## Integration

Combine with other monitoring tools:

```powershell
# Morning routine script
cd <Repository Root>

# Generate report
./documentation/reports/generate-health-report.ps1 -OpenAfter

# Optional: Check for updates
git pull

# Optional: Deploy any script changes
./infrastructure/deployment/deploy-to-proxmox.ps1 -WhatIf
```

## Future Enhancements

Possible improvements:

- SSH integration for Proxmox host metrics (CPU, RAM, ZFS status)
- Container health checks (Immich, DigiKam, PBS)
- Network device status (router, switch, PDU)
- Alert thresholds (email/notification on critical issues)
- Historical trending (compare against previous reports)
