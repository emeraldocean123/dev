# Setup Automated DigiKam Database Backup
# This script creates a Windows Task Scheduler task to run nightly backups at 3:00 AM

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$TaskName = "DigiKam Database Backup"
$TaskDescription = "Automated nightly backup of DigiKam MariaDB database"
$ScriptPath = "D:\DigiKam\backup-database-scheduled.bat"
$BackupTime = "3:00AM"  # Run at 3 AM daily

Write-Console "Setting up automated DigiKam database backup..." -ForegroundColor Green
Write-Console ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Console "Task '$TaskName' already exists. Removing old task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the scheduled task
$Action = New-ScheduledTaskAction -Execute $ScriptPath
$Trigger = New-ScheduledTaskTrigger -Daily -At $BackupTime
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -WakeToRun:$false

# Register the task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Description $TaskDescription `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings | Out-Null

Write-Console "✅ Scheduled task created successfully!" -ForegroundColor Green
Write-Console ""
Write-Console "Backup Schedule Details:" -ForegroundColor Cyan
Write-Console "  Task Name: $TaskName"
Write-Console "  Schedule: Daily at $BackupTime"
Write-Console "  Script: $ScriptPath"
Write-Console "  Retention: Last 7 backups kept"
Write-Console "  Backup Location: D:\DigiKam\backups\"
Write-Console ""
Write-Console "To view or manage this task:" -ForegroundColor Yellow
Write-Console "  1. Open Task Scheduler (taskschd.msc)"
Write-Console "  2. Look for '$TaskName' in Task Scheduler Library"
Write-Console ""
Write-Console "To test the backup now:" -ForegroundColor Yellow
Write-Console "  cd D:\DigiKam"
Write-Console "  .\backup-database-scheduled.bat"
Write-Console ""

# Show the task
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State, @{Name='NextRunTime';Expression={(Get-ScheduledTaskInfo $_).NextRunTime}}
