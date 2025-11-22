# Check Current Drive Configuration

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Current Disk Configuration:" -ForegroundColor Cyan
Write-Console "=" * 80 -ForegroundColor Cyan
Get-Disk | Select-Object Number, FriendlyName, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, PartitionStyle | Format-Table -AutoSize

Write-Console "`nCurrent Partition Assignments:" -ForegroundColor Cyan
Write-Console "=" * 80 -ForegroundColor Cyan
Get-Partition | Where-Object {$_.DriveLetter -ne $null} | Select-Object DiskNumber, PartitionNumber, DriveLetter, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, Type | Sort-Object DriveLetter | Format-Table -AutoSize

Write-Console "`nCurrent Volume Labels:" -ForegroundColor Cyan
Write-Console "=" * 80 -ForegroundColor Cyan
Get-Volume | Where-Object {$_.DriveLetter -ne $null} | Select-Object DriveLetter, FileSystemLabel, FileSystem, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}} | Sort-Object DriveLetter | Format-Table -AutoSize
