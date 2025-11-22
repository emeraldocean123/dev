# Expand WSL VHDX disk size
# This increases the maximum size limit of the virtual disk

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$distroName = "Debian-CasaOS"
$newSizeGB = 2048  # 2 TB - adjust as needed

Write-Console "=== Expand WSL Disk Size ===" -ForegroundColor Cyan
Write-Console ""

# Shutdown WSL
Write-Console "Shutting down WSL..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 3

# Find the VHDX file
$vhdxPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\TheDebianProject*" -Recurse -Filter "ext4.vhdx" |
    Where-Object { $_.Directory.Name -like "*$distroName*" } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $vhdxPath) {
    Write-Console "ERROR: Could not find VHDX for $distroName" -ForegroundColor Red
    exit 1
}

Write-Console "Found VHDX: $vhdxPath" -ForegroundColor Green
$currentSize = (Get-Item $vhdxPath).Length / 1GB
Write-Console "Current size: $([math]::Round($currentSize, 2)) GB" -ForegroundColor Gray
Write-Console ""

# Expand using diskpart
Write-Console "Expanding disk to $newSizeGB GB..." -ForegroundColor Yellow
$diskpartScript = @"
select vdisk file="$vhdxPath"
expand vdisk maximum=$($newSizeGB * 1024)
exit
"@

$diskpartScript | diskpart

if ($LASTEXITCODE -eq 0) {
    Write-Console "Disk expanded successfully!" -ForegroundColor Green
    Write-Console ""

    # Now resize the partition inside WSL
    Write-Console "Resizing partition inside WSL..." -ForegroundColor Yellow
    wsl -d $distroName -u root -- bash -c "resize2fs /dev/sdb"

    Write-Console ""
    Write-Console "=== Complete ===" -ForegroundColor Green
    Write-Console "New maximum size: $newSizeGB GB" -ForegroundColor Gray
} else {
    Write-Console "ERROR: Failed to expand disk" -ForegroundColor Red
    exit 1
}
