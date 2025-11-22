# Install MPV Media Player
# Extracts MPV, sets up Windows integration, and creates Start Menu shortcut

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$archivePath = Join-Path $HOME 'Downloads\mpv-player.7z'
$installPath = Join-Path $HOME 'AppData\Local\mpv'
$startMenuPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

Write-Console "`nInstalling MPV Media Player..." -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

# Step 1: Extract MPV
Write-Console "`n[1/4] Extracting MPV archive..." -ForegroundColor Yellow

if (Test-Path $installPath) {
    Write-Console "  Removing old installation..." -ForegroundColor DarkGray
    Remove-Item $installPath -Recurse -Force
}

New-Item -ItemType Directory -Path $installPath -Force | Out-Null

# Try 7-Zip first
$7zipPath = 'C:\Program Files\7-Zip\7z.exe'
if (Test-Path $7zipPath) {
    & $7zipPath x $archivePath "-o$installPath" -y | Out-Null
    Write-Console "  Extracted using 7-Zip" -ForegroundColor Green
} else {
    # Use Windows built-in tar
    Write-Console "  Using Windows tar..." -ForegroundColor DarkGray
    tar -xf $archivePath -C (Split-Path $installPath) 2>&1 | Out-Null
    Write-Console "  Extracted using tar" -ForegroundColor Green
}

# Find the mpv.exe location (it might be in a subdirectory)
$mpvExe = Get-ChildItem -Path $installPath -Filter "mpv.exe" -Recurse | Select-Object -First 1

if (-not $mpvExe) {
    Write-Error "MPV executable not found after extraction!"
    exit 1
}

$mpvDir = $mpvExe.DirectoryName
Write-Console "  MPV installed to: $mpvDir" -ForegroundColor Green

# Step 2: Run installer batch file if it exists
Write-Console "`n[2/4] Setting up Windows integration..." -ForegroundColor Yellow
$installerBat = Get-ChildItem -Path $mpvDir -Filter "*install*.bat" -File | Select-Object -First 1

if ($installerBat) {
    Write-Console "  Running installer script..." -ForegroundColor DarkGray
    Push-Location $mpvDir
    cmd /c $installerBat.Name 2>&1 | Out-Null
    Pop-Location
    Write-Console "  Windows integration complete" -ForegroundColor Green
} else {
    Write-Console "  No installer script found, skipping..." -ForegroundColor DarkGray
}

# Step 3: Create Start Menu shortcut
Write-Console "`n[3/4] Creating Start Menu shortcut..." -ForegroundColor Yellow
$shortcutPath = Join-Path $startMenuPath "MPV Media Player.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $mpvExe.FullName
$Shortcut.WorkingDirectory = $mpvDir
$Shortcut.Description = "MPV Media Player"
$Shortcut.Save()
Write-Console "  Start Menu shortcut created" -ForegroundColor Green

# Step 4: Add to PATH
Write-Console "`n[4/4] Adding MPV to user PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$mpvDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$mpvDir", "User")
    Write-Console "  Added to PATH" -ForegroundColor Green
} else {
    Write-Console "  Already in PATH" -ForegroundColor DarkGray
}

# Summary
Write-Console "`n" -NoNewline
Write-Console "="*60 -ForegroundColor Cyan
Write-Console "MPV Installation Complete!" -ForegroundColor Green
Write-Console "="*60 -ForegroundColor Cyan

Write-Console "`nMPV Location:" -ForegroundColor Cyan
Write-Console "  $($mpvExe.FullName)" -ForegroundColor White

Write-Console "`nHow to use:" -ForegroundColor Cyan
Write-Console "  - Search 'MPV' in Start Menu" -ForegroundColor White
Write-Console "  - Drag & drop video files onto MPV" -ForegroundColor White
Write-Console "  - Right-click videos > Open with > MPV" -ForegroundColor White
Write-Console "  - Type 'mpv' in terminal to use command-line" -ForegroundColor White

Write-Console "`nBasic keyboard controls:" -ForegroundColor Cyan
Write-Console "  Space     - Play/Pause" -ForegroundColor White
Write-Console "  Left/Right- Seek 5 seconds" -ForegroundColor White
Write-Console "  Up/Down   - Seek 1 minute" -ForegroundColor White
Write-Console "  9/0       - Volume down/up" -ForegroundColor White
Write-Console "  F         - Fullscreen" -ForegroundColor White
Write-Console "  Q         - Quit" -ForegroundColor White

Write-Console "`nNote: Restart terminal for PATH changes to take effect" -ForegroundColor Yellow
