# Get detailed info about alienfx scheduled tasks

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$tasks = Get-ScheduledTask | Where-Object {($_.TaskName -like '*alien*') -or ($_.TaskPath -like '*alien*')}

foreach ($task in $tasks) {
    Write-Console "`n========================================" -ForegroundColor Cyan
    Write-Console "Task Name: $($task.TaskName)" -ForegroundColor Yellow
    Write-Console "Task Path: $($task.TaskPath)" -ForegroundColor Yellow
    Write-Console "State: $($task.State)" -ForegroundColor Yellow

    $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
    if ($taskInfo) {
        Write-Console "Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
        Write-Console "Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    }

    # Get action details
    $actions = (Get-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath).Actions
    Write-Console "Actions:" -ForegroundColor Green
    foreach ($action in $actions) {
        if ($action.Execute) {
            Write-Console "  Execute: $($action.Execute)" -ForegroundColor White
            Write-Console "  Arguments: $($action.Arguments)" -ForegroundColor White
            Write-Console "  WorkingDirectory: $($action.WorkingDirectory)" -ForegroundColor White
        }
    }
}
