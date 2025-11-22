# Adobe Lightroom and Creative Cloud Cleanup Script
# This script removes all orphaned Adobe files, folders, and registry entries

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Adobe Lightroom and Creative Cloud Cleanup Script" -ForegroundColor Cyan
Write-Console "=================================================" -ForegroundColor Cyan
Write-Console ""

# Require administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Console "ERROR: This script requires administrator privileges!" -ForegroundColor Red
    Write-Console "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$removedItems = @()
$failedItems = @()

# Function to safely remove folder
function Remove-FolderSafely {
    param([string]$Path)

    if (Test-Path $Path) {
        try {
            Write-Console "Removing folder: $Path" -ForegroundColor Yellow
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            $removedItems += $Path
            Write-Console "  SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Console "  FAILED: $_" -ForegroundColor Red
            $failedItems += $Path
        }
    }
}

# Function to safely remove registry key
function Remove-RegistryKeySafely {
    param([string]$Path)

    if (Test-Path $Path) {
        try {
            Write-Console "Removing registry key: $Path" -ForegroundColor Yellow
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            $removedItems += $Path
            Write-Console "  SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Console "  FAILED: $_" -ForegroundColor Red
            $failedItems += $Path
        }
    }
}

Write-Console "Step 1: Removing Program Files..." -ForegroundColor Cyan
Write-Console ""

# Program Files locations
Remove-FolderSafely "C:\Program Files\Adobe"
Remove-FolderSafely "C:\Program Files (x86)\Adobe"
Remove-FolderSafely "C:\Program Files\Common Files\Adobe"
Remove-FolderSafely "C:\Program Files (x86)\Common Files\Adobe"

Write-Console ""
Write-Console "Step 2: Removing AppData folders..." -ForegroundColor Cyan
Write-Console ""

# User AppData locations
Remove-FolderSafely "$env:APPDATA\Adobe"
Remove-FolderSafely "$env:LOCALAPPDATA\Adobe"
Remove-FolderSafely "$env:LOCALAPPDATA\Packages\*.Adobe.*"

Write-Console ""
Write-Console "Step 3: Removing ProgramData folders..." -ForegroundColor Cyan
Write-Console ""

# ProgramData locations
Remove-FolderSafely "C:\ProgramData\Adobe"
Remove-FolderSafely "C:\ProgramData\Packages\*.Adobe.*"

Write-Console ""
Write-Console "Step 4: Removing temp files..." -ForegroundColor Cyan
Write-Console ""

# Temp folders
$tempAdobe = Get-ChildItem -Path $env:TEMP -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Adobe*' -or $_.Name -like '*Lightroom*' }
foreach ($folder in $tempAdobe) {
    Remove-FolderSafely $folder.FullName
}

Write-Console ""
Write-Console "Step 5: Removing user-specific folders..." -ForegroundColor Cyan
Write-Console ""

# Check common user locations
$possibleLocations = @(
    "$env:USERPROFILE\Adobe",
    "$env:USERPROFILE\Documents\Adobe",
    "$env:USERPROFILE\Pictures\Lightroom"
)

foreach ($loc in $possibleLocations) {
    Remove-FolderSafely $loc
}

Write-Console ""
Write-Console "Step 6: Cleaning up registry entries..." -ForegroundColor Cyan
Write-Console ""

# Registry keys to check and remove
$registryPaths = @(
    "HKCU:\Software\Adobe",
    "HKLM:\Software\Adobe",
    "HKLM:\Software\WOW6432Node\Adobe",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Adobe*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Adobe*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Adobe*"
)

foreach ($regPath in $registryPaths) {
    if ($regPath -like "*\*Adobe*") {
        # Wildcard path - get matching keys
        $parentPath = $regPath.Substring(0, $regPath.LastIndexOf('\'))
        if (Test-Path $parentPath) {
            $keys = Get-ChildItem -Path $parentPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Adobe*' -or $_.Name -like '*Lightroom*' }
            foreach ($key in $keys) {
                Remove-RegistryKeySafely $key.PSPath
            }
        }
    }
    else {
        # Direct path
        Remove-RegistryKeySafely $regPath
    }
}

Write-Console ""
Write-Console "Step 7: Checking for Start Menu shortcuts..." -ForegroundColor Cyan
Write-Console ""

# Start Menu shortcuts
$startMenuPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Adobe*",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe*"
)

foreach ($path in $startMenuPaths) {
    $shortcuts = Get-Item -Path $path -ErrorAction SilentlyContinue
    foreach ($shortcut in $shortcuts) {
        Remove-FolderSafely $shortcut.FullName
    }
}

Write-Console ""
Write-Console "=================================================" -ForegroundColor Cyan
Write-Console "Cleanup Summary" -ForegroundColor Cyan
Write-Console "=================================================" -ForegroundColor Cyan
Write-Console ""
Write-Console "Successfully removed: $($removedItems.Count) items" -ForegroundColor Green

if ($removedItems.Count -gt 0) {
    Write-Console ""
    Write-Console "Removed items:" -ForegroundColor Green
    $removedItems | ForEach-Object { Write-Console "  - $_" -ForegroundColor Gray }
}

if ($failedItems.Count -gt 0) {
    Write-Console ""
    Write-Console "Failed to remove: $($failedItems.Count) items" -ForegroundColor Red
    $failedItems | ForEach-Object { Write-Console "  - $_" -ForegroundColor Gray }
    Write-Console ""
    Write-Console "TIP: Some files may be in use. Try closing all programs and run again." -ForegroundColor Yellow
}

if ($removedItems.Count -eq 0 -and $failedItems.Count -eq 0) {
    Write-Console "No Adobe remnants found - system is clean!" -ForegroundColor Green
}

Write-Console ""
Write-Console "Cleanup complete! You may want to restart your computer." -ForegroundColor Cyan
Write-Console ""
