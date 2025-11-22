# Add ExifTool to User PATH
# Automatically detects ExifTool installation and adds to PATH if missing

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$ExifToolPath = $null
$KnownLocations = @(
    "D:\Files\Programs-Portable\ExifTool",
    "$env:LOCALAPPDATA\Programs\ExifTool",
    "$env:LOCALAPPDATA\Programs\ExifToolGUI",
    "C:\Program Files\ExifTool"
)

Write-Console "Checking for ExifTool..." -ForegroundColor Cyan

# 1. Check if already in PATH
if (Get-Command exiftool -ErrorAction SilentlyContinue) {
    $currentPath = (Get-Command exiftool).Source
    Write-Console "✅ ExifTool is already in PATH: $currentPath" -ForegroundColor Green
    # Verify version
    $ver = & exiftool -ver
    Write-Console "   Version: $ver" -ForegroundColor Gray
    exit 0
}

# 2. Find installation
foreach ($loc in $KnownLocations) {
    if (Test-Path "$loc\exiftool.exe") {
        $ExifToolPath = $loc
        Write-Console "Found ExifTool at: $loc" -ForegroundColor Yellow
        break
    }
}

if (-not $ExifToolPath) {
    Write-Console "❌ ExifTool not found in common locations." -ForegroundColor Red
    Write-Console "`nSearched locations:" -ForegroundColor Gray
    foreach ($loc in $KnownLocations) {
        Write-Console "  - $loc" -ForegroundColor DarkGray
    }
    Write-Console "`nDownload from: https://exiftool.org/" -ForegroundColor Cyan
    exit 1
}

# 3. Add to User PATH
try {
    $currentPathEnv = [Environment]::GetEnvironmentVariable("Path", "User")

    # Double check it's not already there (string check)
    if ($currentPathEnv -like "*$ExifToolPath*") {
        Write-Console "Path entry already exists in User environment." -ForegroundColor Green
    } else {
        Write-Console "Adding to User PATH..." -ForegroundColor Cyan
        $newPathEnv = "$currentPathEnv;$ExifToolPath"
        [Environment]::SetEnvironmentVariable("Path", $newPathEnv, "User")

        # Update current session
        $env:Path += ";$ExifToolPath"

        Write-Console "✅ Successfully added to PATH." -ForegroundColor Green
        Write-Console "   Run 'exiftool -ver' to verify." -ForegroundColor Gray
    }
} catch {
    Write-Console "❌ Failed to modify environment variable: $_" -ForegroundColor Red
}
