# Configure mpv.net slideshow speed for photos

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nConfiguring mpv.net photo slideshow settings..." -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

# mpv.net config directory
$configDir = Join-Path $env:APPDATA "mpv.net"
$configFile = Join-Path $configDir "mpv.conf"

# Create config directory if it doesn't exist
if (-not (Test-Path $configDir)) {
    Write-Console "`nCreating mpv.net config directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Current settings to add/update
$settings = @"
# Photo/Image Slideshow Settings
# Display each image for this many seconds (default is 1)
image-display-duration=5

# Optional: Loop through images automatically
# loop-playlist=inf

# Optional: Show on-screen display when changing images
# osd-level=1
"@

Write-Console "`nConfiguration:" -ForegroundColor Cyan
Write-Console "  Config file: $configFile" -ForegroundColor White

if (Test-Path $configFile) {
    Write-Console "  Status: Config file exists, will be updated" -ForegroundColor Yellow

    # Read existing config
    $existingContent = Get-Content $configFile -Raw -ErrorAction SilentlyContinue

    # Check if image-display-duration already exists
    if ($existingContent -match 'image-display-duration') {
        Write-Console "`n  Found existing image-display-duration setting" -ForegroundColor Yellow
        Write-Console "  Backing up current config..." -ForegroundColor DarkGray
        Copy-Item $configFile "$configFile.backup" -Force

        # Replace existing setting
        $existingContent = $existingContent -replace '(?m)^#?\s*image-display-duration\s*=.*$', 'image-display-duration=5'
        Set-Content -Path $configFile -Value $existingContent -NoNewline
        Write-Console "  ✓ Updated image-display-duration to 5 seconds" -ForegroundColor Green
    } else {
        # Append new settings
        Add-Content -Path $configFile -Value "`n`n$settings"
        Write-Console "  ✓ Added slideshow settings to config" -ForegroundColor Green
    }
} else {
    Write-Console "  Status: Creating new config file" -ForegroundColor Yellow
    Set-Content -Path $configFile -Value $settings
    Write-Console "  ✓ Created config file with slideshow settings" -ForegroundColor Green
}

Write-Console "`n" -NoNewline
Write-Console "="*60 -ForegroundColor Cyan
Write-Console "mpv.net Slideshow Configuration Complete!" -ForegroundColor Green
Write-Console "="*60 -ForegroundColor Cyan

Write-Console "`nCurrent Settings:" -ForegroundColor Cyan
Write-Console "  Image display duration: 5 seconds" -ForegroundColor White
Write-Console "  (You can adjust this by editing the config file)" -ForegroundColor DarkGray

Write-Console "`nHow to customize:" -ForegroundColor Cyan
Write-Console "  1. Open config file:" -ForegroundColor White
Write-Console "     notepad `"$configFile`"" -ForegroundColor DarkGray
Write-Console "`n  2. Change the number in this line:" -ForegroundColor White
Write-Console "     image-display-duration=5" -ForegroundColor DarkGray
Write-Console "     (Use any number of seconds you want)" -ForegroundColor DarkGray
Write-Console "`n  3. Save and restart mpv.net" -ForegroundColor White

Write-Console "`nCommon values:" -ForegroundColor Cyan
Write-Console "  3  = 3 seconds (faster)" -ForegroundColor White
Write-Console "  5  = 5 seconds (recommended)" -ForegroundColor Green
Write-Console "  10 = 10 seconds (slower)" -ForegroundColor White
Write-Console "  inf = infinite (manual advance only)" -ForegroundColor White

Write-Console "`nKeyboard controls while viewing photos:" -ForegroundColor Cyan
Write-Console "  Space     - Pause/resume slideshow" -ForegroundColor White
Write-Console "  Right/Left - Next/Previous image" -ForegroundColor White
Write-Console "  Page Down/Up - Jump 10 images forward/back" -ForegroundColor White
Write-Console "  q         - Quit" -ForegroundColor White

Write-Console "`nChanges will take effect next time you open photos in mpv.net" -ForegroundColor Yellow
