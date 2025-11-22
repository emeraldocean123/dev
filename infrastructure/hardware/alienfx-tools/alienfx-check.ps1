# Check for alienfx-tools scheduled tasks

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console "=== Checking Scheduled Tasks ===" -ForegroundColor Cyan
Get-ScheduledTask | Where-Object {($_.TaskName -like '*alien*') -or ($_.TaskPath -like '*alien*')} | Format-Table TaskName, TaskPath, State -AutoSize

Write-Console "`n=== Checking Installed Programs ===" -ForegroundColor Cyan
Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object {$_.DisplayName -like '*alien*'} | Select-Object DisplayName, DisplayVersion, InstallLocation | Format-List

Write-Console "`n=== Checking Program Files ===" -ForegroundColor Cyan
if (Test-Path "C:\Program Files\alienfx-tools") {
    Write-Console "Found: C:\Program Files\alienfx-tools"
    Get-ChildItem "C:\Program Files\alienfx-tools" -Recurse -File | Select-Object FullName, LastWriteTime, Length | Format-Table -AutoSize
} else {
    Write-Console "Not found: C:\Program Files\alienfx-tools"
}

if (Test-Path "C:\Program Files (x86)\alienfx-tools") {
    Write-Console "Found: C:\Program Files (x86)\alienfx-tools"
    Get-ChildItem "C:\Program Files (x86)\alienfx-tools" -Recurse -File | Select-Object FullName, LastWriteTime, Length | Format-Table -AutoSize
} else {
    Write-Console "Not found: C:\Program Files (x86)\alienfx-tools"
}
