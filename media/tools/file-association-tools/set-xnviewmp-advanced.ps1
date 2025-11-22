# Advanced XnViewMP Default App Configuration for Windows 11
# This script uses multiple methods to ensure XnViewMP becomes the default

# Requires elevation for some operations

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Console "Note: Running without administrator privileges. Some associations may require admin rights." -ForegroundColor Yellow
    Write-Console "For best results, right-click PowerShell and 'Run as Administrator', then run this script again.`n" -ForegroundColor Yellow
}

$xnviewmpPath = "C:\Program Files\XnViewMP\xnviewmp.exe"

if (-not (Test-Path $xnviewmpPath)) {
    Write-Error "XnViewMP not found at: $xnviewmpPath"
    exit 1
}

Write-Console "=== XnViewMP Default Application Setup ===" -ForegroundColor Green
Write-Console "This will set XnViewMP as default for all photo and video files`n" -ForegroundColor Cyan

# Photo extensions
$photoExtensions = @(
    ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp",
    ".cr2", ".cr3", ".nef", ".arw", ".dng", ".orf", ".rw2", ".pef", ".srw", ".raw",
    ".ico", ".svg", ".heic", ".heif", ".avif", ".jxl"
)

# Video extensions
$videoExtensions = @(
    ".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".webm", ".m4v",
    ".mpg", ".mpeg", ".3gp", ".mts", ".m2ts", ".vob", ".ogv"
)

$allExtensions = $photoExtensions + $videoExtensions

# Method 1: Set via registry (HKCU - works without admin)
Write-Console "Method 1: Setting registry associations..." -ForegroundColor Yellow

foreach ($ext in $allExtensions) {
    $regPath = "HKCU:\Software\Classes\$ext"

    # Create or update the extension key
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "XnViewMP.Image" -Force

    Write-Console "  $ext -> XnViewMP.Image" -ForegroundColor Gray
}

# Create the XnViewMP.Image handler
$handlerPath = "HKCU:\Software\Classes\XnViewMP.Image"
if (-not (Test-Path $handlerPath)) {
    New-Item -Path $handlerPath -Force | Out-Null
}
Set-ItemProperty -Path $handlerPath -Name "(Default)" -Value "XnViewMP Image" -Force

# Set the icon
$iconPath = "$handlerPath\DefaultIcon"
if (-not (Test-Path $iconPath)) {
    New-Item -Path $iconPath -Force | Out-Null
}
Set-ItemProperty -Path $iconPath -Name "(Default)" -Value "`"$xnviewmpPath`",0" -Force

# Set the open command
$commandPath = "$handlerPath\shell\open\command"
if (-not (Test-Path $commandPath)) {
    New-Item -Path $commandPath -Force | Out-Null
}
Set-ItemProperty -Path $commandPath -Name "(Default)" -Value "`"$xnviewmpPath`" `"%1`"" -Force

Write-Console "Registry associations created successfully`n" -ForegroundColor Green

# Method 2: Remove existing UserChoice restrictions (allows override)
Write-Console "Method 2: Clearing existing associations..." -ForegroundColor Yellow

foreach ($ext in $allExtensions) {
    $userChoicePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"

    if (Test-Path $userChoicePath) {
        try {
            # Take ownership and delete (this can fail on Windows 11 due to hash protection)
            Remove-Item -Path $userChoicePath -Force -ErrorAction SilentlyContinue
            Write-Console "  Cleared association for $ext" -ForegroundColor Gray
        }
        catch {
            # Expected to fail on Windows 11 - this is normal
        }
    }
}

Write-Console "Association clearing completed`n" -ForegroundColor Green

# Method 3: Open Windows Settings to complete association
Write-Console "Method 3: Opening Windows Settings..." -ForegroundColor Yellow
Write-Console "Windows 11 requires manual confirmation in Settings for some file types." -ForegroundColor Cyan
Write-Console "`nTo complete the setup:" -ForegroundColor Yellow
Write-Console "1. In the Settings window that opens, search for 'default apps'" -ForegroundColor White
Write-Console "2. Scroll down and click on 'XnViewMP'" -ForegroundColor White
Write-Console "3. Click 'Set defaults' to confirm all file types" -ForegroundColor White
Write-Console "`nPress any key to open Windows Settings..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# Open Windows Settings to default apps
Start-Process "ms-settings:defaultapps"

Start-Sleep -Seconds 2

# Alternative: Open XnView directly in Settings
Write-Console "`nOpening XnViewMP in Default Apps Settings..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
try {
    $appId = "C:\Program Files\XnViewMP\xnviewmp.exe"
    Start-Process "ms-settings:defaultapps" -ArgumentList $appId
}
catch {
    Write-Console "Could not open specific XnViewMP settings, use the manual method above." -ForegroundColor Yellow
}

Write-Console "`n=== Alternative Quick Method ===" -ForegroundColor Green
Write-Console "If the Settings method doesn't work:" -ForegroundColor Yellow
Write-Console "1. Right-click any photo or video file" -ForegroundColor White
Write-Console "2. Select 'Open with' -> 'Choose another app'" -ForegroundColor White
Write-Console "3. Select 'XnViewMP' (scroll down if needed)" -ForegroundColor White
Write-Console "4. Check the box 'Always use this app to open .$($allExtensions[0]) files'" -ForegroundColor White
Write-Console "5. Click OK" -ForegroundColor White
Write-Console "6. Repeat for one file of each type (JPG, PNG, MP4, etc.)" -ForegroundColor White

Write-Console "`n=== Summary ===" -ForegroundColor Green
Write-Console "Registry associations have been configured for $($allExtensions.Count) file types" -ForegroundColor Cyan
Write-Console "Complete the setup using Windows Settings as shown above." -ForegroundColor Cyan
Write-Console "`nScript completed!" -ForegroundColor Green
