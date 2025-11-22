# Check for OpenCodec installation

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nChecking for OpenCodec installation...`n" -ForegroundColor Cyan

# Check Program Files directories
$locations = @(
    "C:\Program Files\OpenCodec",
    "C:\Program Files (x86)\OpenCodec",
    "C:\OpenCodec"
)

$found = $false

foreach ($location in $locations) {
    if (Test-Path $location) {
        Write-Console "Found: $location" -ForegroundColor Green
        $found = $true
        Get-ChildItem $location | Select-Object Name, Length, LastWriteTime | Format-Table
    }
}

# Check installed programs
$uninstall = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -like '*OpenCodec*' } |
    Select-Object DisplayName, Publisher, InstallLocation, DisplayVersion

if ($uninstall) {
    Write-Console "OpenCodec found in installed programs:" -ForegroundColor Green
    $uninstall | Format-List
    $found = $true
}

# Check WinGet
$winget = winget list --name OpenCodec 2>&1 | Out-String
if ($winget -notlike '*No installed package found*') {
    Write-Console "OpenCodec found via WinGet" -ForegroundColor Green
    $found = $true
}

if (-not $found) {
    Write-Console "OpenCodec is NOT installed" -ForegroundColor Yellow
    Write-Console "`nOpenCodec was likely removed when you uninstalled PotPlayer.`n" -ForegroundColor Gray
} else {
    Write-Console "`nOpenCodec IS installed`n" -ForegroundColor Green
}
