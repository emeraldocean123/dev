# Set Samsung and Ventoy Drive Letters (Working Version)
# This script must be run as Administrator
#
# Target configuration:
# - E: = Samsung T9 4TB
# - F: = VTOYEFI_GPT (Ventoy EFI)
# - G: = VentoyGPT (Ventoy data)

# Check for admin privileges

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires Administrator privileges. Please run PowerShell as Administrator and try again."
    exit 1
}

Write-Console "Setting Samsung and Ventoy drive letters..." -ForegroundColor Cyan

# Step 1: Assign temporary letter Z: to Samsung T9
Write-Console "`n[1/6] Assigning temporary Z: to Samsung T9..." -ForegroundColor Yellow
Get-Partition -DiskNumber 4 -PartitionNumber 1 | Set-Partition -NewDriveLetter Z
Write-Console "  ✓ Samsung T9 temporarily assigned to Z:" -ForegroundColor Green

# Step 2: Remove E: from Ventoy EFI
Write-Console "`n[2/6] Removing E: from Ventoy EFI..." -ForegroundColor Yellow
Get-Partition -DiskNumber 3 -PartitionNumber 2 | Remove-PartitionAccessPath -AccessPath "E:"
Write-Console "  ✓ E: removed from Ventoy EFI" -ForegroundColor Green

# Step 3: Remove H: from Ventoy data
Write-Console "`n[3/6] Removing H: from Ventoy data..." -ForegroundColor Yellow
Get-Partition -DiskNumber 3 -PartitionNumber 1 | Remove-PartitionAccessPath -AccessPath "H:"
Write-Console "  ✓ H: removed from Ventoy data" -ForegroundColor Green

# Step 4: Assign E: to Samsung T9
Write-Console "`n[4/6] Assigning E: to Samsung T9..." -ForegroundColor Yellow
Get-Partition -DiskNumber 4 -PartitionNumber 1 | Set-Partition -NewDriveLetter E
Write-Console "  ✓ Samsung T9 is now E:" -ForegroundColor Green

# Step 5: Assign F: to Ventoy EFI
Write-Console "`n[5/6] Assigning F: to Ventoy EFI..." -ForegroundColor Yellow
Get-Partition -DiskNumber 3 -PartitionNumber 2 | Set-Partition -NewDriveLetter F
Write-Console "  ✓ Ventoy EFI is now F:" -ForegroundColor Green

# Step 6: Assign G: to Ventoy data
Write-Console "`n[6/6] Assigning G: to Ventoy data..." -ForegroundColor Yellow
Get-Partition -DiskNumber 3 -PartitionNumber 1 | Set-Partition -NewDriveLetter G
Write-Console "  ✓ Ventoy data is now G:" -ForegroundColor Green

# Display final configuration
Write-Console "`n" -NoNewline
Write-Console "="*80 -ForegroundColor Cyan
Write-Console "Drive Letter Configuration Complete!" -ForegroundColor Green
Write-Console "="*80 -ForegroundColor Cyan
Write-Console "`nFinal configuration:" -ForegroundColor Cyan
Get-Volume | Where-Object {$_.DriveLetter -ne $null} |
    Select-Object DriveLetter, FileSystemLabel, FileSystem,
    @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}} |
    Sort-Object DriveLetter |
    Format-Table -AutoSize

Write-Console "`nSummary:" -ForegroundColor Cyan
Write-Console "  E: = Samsung T9 4TB (Backup - Samsung 4TB)" -ForegroundColor White
Write-Console "  F: = Ventoy EFI partition (VTOYEFI_GPT, 32MB)" -ForegroundColor White
Write-Console "  G: = Ventoy data partition (VentoyGPT, 239GB)" -ForegroundColor White
