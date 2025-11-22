# Find Orphaned Program Files and Folders
# This script identifies folders that don't have corresponding installed programs

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "Orphaned Program Files Scanner" -ForegroundColor Cyan
Write-Console "===============================" -ForegroundColor Cyan
Write-Console ""

# Get all installed programs from registry
Write-Console "Step 1: Getting list of installed programs..." -ForegroundColor Yellow
$installed64 = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -ne $null } |
    Select-Object DisplayName, Publisher, InstallLocation

$installed32 = Get-ItemProperty 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -ne $null } |
    Select-Object DisplayName, Publisher, InstallLocation

$installedUser = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -ne $null } |
    Select-Object DisplayName, Publisher, InstallLocation

$allInstalled = $installed64 + $installed32 + $installedUser
$installedNames = $allInstalled | ForEach-Object { $_.DisplayName.ToLower() }
$installedPublishers = $allInstalled | ForEach-Object { if ($_.Publisher) { $_.Publisher.ToLower() } }

Write-Console "Found $($allInstalled.Count) installed programs" -ForegroundColor Green
Write-Console ""

# Get all folders from key locations
Write-Console "Step 2: Scanning Program Files folders..." -ForegroundColor Yellow
$programFiles64 = Get-ChildItem -Path 'C:\Program Files' -Directory -ErrorAction SilentlyContinue
$programFiles32 = Get-ChildItem -Path 'C:\Program Files (x86)' -Directory -ErrorAction SilentlyContinue
$programData = Get-ChildItem -Path 'C:\ProgramData' -Directory -Force -ErrorAction SilentlyContinue
$appDataRoaming = Get-ChildItem -Path "$env:APPDATA" -Directory -ErrorAction SilentlyContinue
$appDataLocal = Get-ChildItem -Path "$env:LOCALAPPDATA" -Directory -ErrorAction SilentlyContinue

Write-Console ""
Write-Console "Step 3: Analyzing folders for orphans..." -ForegroundColor Yellow
Write-Console ""

$orphans = @()

# System folders to always skip
$skipFolders = @(
    'Common Files', 'Internet Explorer', 'Windows Defender', 'Windows Mail', 'Windows NT',
    'Windows Photo Viewer', 'WindowsPowerShell', 'Microsoft OneDrive', 'ModifiableWindowsApps',
    'MSBuild', 'Reference Assemblies', 'PackageManagement', 'dotnet', 'Microsoft.NET',
    'Windows Kits', 'Application Data', 'Desktop', 'Documents', 'Templates', 'Start Menu',
    'Microsoft', 'Packages', 'Package Cache', 'SoftwareDistribution', 'USOPrivate', 'USOShared',
    'ssh', 'regid.1991-06.com.microsoft', 'Intel', 'NVIDIA', 'NVIDIA Corporation', 'Realtek',
    'Dell', 'Alienware', 'Dolby', 'ENE', 'Killer Networking'
)

function Test-IsOrphan {
    param([string]$FolderName, [string]$Location)

    $folderLower = $FolderName.ToLower()

    # Skip system folders
    if ($skipFolders -contains $FolderName) { return $false }

    # Check if folder name matches any installed program name
    foreach ($prog in $installedNames) {
        if ($prog -and ($prog -like "*$folderLower*" -or $folderLower -like "*$prog*")) {
            return $false
        }
    }

    # Check if folder name matches any publisher
    foreach ($pub in $installedPublishers) {
        if ($pub -and ($pub -like "*$folderLower*" -or $folderLower -like "*$pub*")) {
            return $false
        }
    }

    return $true
}

# Check Program Files (x64)
Write-Console "Checking C:\Program Files..." -ForegroundColor Cyan
foreach ($folder in $programFiles64) {
    if (Test-IsOrphan -FolderName $folder.Name -Location "Program Files (x64)") {
        $orphans += [PSCustomObject]@{
            Location = "Program Files (x64)"
            Name = $folder.Name
            Path = $folder.FullName
            LastModified = $folder.LastWriteTime
        }
    }
}

# Check Program Files (x86)
Write-Console "Checking C:\Program Files (x86)..." -ForegroundColor Cyan
foreach ($folder in $programFiles32) {
    if (Test-IsOrphan -FolderName $folder.Name -Location "Program Files (x86)") {
        $orphans += [PSCustomObject]@{
            Location = "Program Files (x86)"
            Name = $folder.Name
            Path = $folder.FullName
            LastModified = $folder.LastWriteTime
        }
    }
}

# Check ProgramData
Write-Console "Checking C:\ProgramData..." -ForegroundColor Cyan
foreach ($folder in $programData) {
    if (Test-IsOrphan -FolderName $folder.Name -Location "ProgramData") {
        $orphans += [PSCustomObject]@{
            Location = "ProgramData"
            Name = $folder.Name
            Path = $folder.FullName
            LastModified = $folder.LastWriteTime
        }
    }
}

# Check AppData\Roaming
Write-Console "Checking AppData\Roaming..." -ForegroundColor Cyan
foreach ($folder in $appDataRoaming) {
    if (Test-IsOrphan -FolderName $folder.Name -Location "AppData\Roaming") {
        $orphans += [PSCustomObject]@{
            Location = "AppData\Roaming"
            Name = $folder.Name
            Path = $folder.FullName
            LastModified = $folder.LastWriteTime
        }
    }
}

# Check AppData\Local
Write-Console "Checking AppData\Local..." -ForegroundColor Cyan
foreach ($folder in $appDataLocal) {
    if (Test-IsOrphan -FolderName $folder.Name -Location "AppData\Local") {
        $orphans += [PSCustomObject]@{
            Location = "AppData\Local"
            Name = $folder.Name
            Path = $folder.FullName
            LastModified = $folder.LastWriteTime
        }
    }
}

Write-Console ""
Write-Console "===============================" -ForegroundColor Cyan
Write-Console "Scan Complete" -ForegroundColor Cyan
Write-Console "===============================" -ForegroundColor Cyan
Write-Console ""

if ($orphans.Count -gt 0) {
    Write-Console "Found $($orphans.Count) potential orphaned folders:" -ForegroundColor Yellow
    Write-Console ""
    $orphans | Format-Table -Property Location, Name, LastModified -AutoSize
    Write-Console ""
    Write-Console "NOTE: Review these carefully before deleting!" -ForegroundColor Red
    Write-Console "Some may be legitimate programs installed without registry entries." -ForegroundColor Yellow
} else {
    Write-Console "No orphaned folders found!" -ForegroundColor Green
}
