# Get system boot time and check for errors around boot

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Console "`n=== System Boot Information ===" -ForegroundColor Cyan
Write-Console "Last Boot Time: $bootTime"
Write-Console "Current Time: $(Get-Date)"
Write-Console "Uptime: $((Get-Date) - $bootTime)"

# Check for errors around boot time (30 minutes before and after)
$startTime = $bootTime.AddMinutes(-30)
$endTime = $bootTime.AddMinutes(30)

Write-Console "`n=== Checking Events Around Boot Time ===" -ForegroundColor Cyan
Write-Console "Searching from: $startTime to $endTime" -ForegroundColor Yellow

$bootEvents = Get-EventLog -LogName System -After $startTime -Before $endTime |
    Where-Object {
        ($_.Source -like '*USB*') -or
        ($_.Source -like '*Thunderbolt*') -or
        ($_.Source -like '*CalDigit*') -or
        ($_.Source -like '*aqnic*') -or
        ($_.Source -like '*WHEA*') -or
        ($_.EntryType -eq 'Error') -or
        ($_.EntryType -eq 'Critical')
    } |
    Sort-Object TimeGenerated

if ($bootEvents) {
    Write-Console "`nFound $($bootEvents.Count) relevant events:" -ForegroundColor Yellow
    $bootEvents | Select-Object TimeGenerated, EntryType, Source, Message |
        Format-Table -AutoSize -Wrap | Out-String -Width 120
} else {
    Write-Console "`n[INFO] No errors or warnings found around boot time" -ForegroundColor Green
}

# Check for shutdown events before the boot
Write-Console "`n=== Checking Shutdown Events Before Boot ===" -ForegroundColor Cyan
$shutdownEvents = Get-EventLog -LogName System -After $startTime -Before $bootTime |
    Where-Object { $_.EventID -eq 1074 -or $_.EventID -eq 6006 -or $_.EventID -eq 6008 } |
    Sort-Object TimeGenerated -Descending |
    Select-Object -First 5

if ($shutdownEvents) {
    $shutdownEvents | Select-Object TimeGenerated, EventID, Source, Message |
        Format-Table -AutoSize -Wrap | Out-String -Width 120
}
