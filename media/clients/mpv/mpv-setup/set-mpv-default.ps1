# Set mpv.net as Default Video Player
# This script associates all common video file types with mpv.net

# Check for admin privileges

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
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

Write-Console "`nSetting mpv.net as default video player..." -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

# Find mpv.net executable
$mpvPath = Get-ChildItem "$env:LOCALAPPDATA\Programs\mpv.net" -Filter "mpvnet.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $mpvPath) {
    Write-Error "mpv.net executable not found! Please install mpv.net first."
    exit 1
}

Write-Console "`nFound mpv.net at: $($mpvPath.FullName)" -ForegroundColor Green

# Photo formats found in Mylio
$photoExtensions = @(
    '.jpg', '.heic', '.png', '.jpeg', '.bmp', '.webp', '.gif'
)

# Common video file extensions
$videoExtensions = @(
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v',
    '.mpg', '.mpeg', '.m2v', '.3gp', '.3g2', '.ogv', '.ts', '.m2ts',
    '.mts', '.vob', '.divx', '.xvid', '.rm', '.rmvb', '.asf', '.f4v'
)

# Combine all media extensions
$allExtensions = $photoExtensions + $videoExtensions

Write-Console "`nRegistering mpv.net for all Mylio photo and video formats..." -ForegroundColor Yellow
Write-Console "  Photos: $($photoExtensions.Count) formats" -ForegroundColor White
Write-Console "  Videos: $($videoExtensions.Count) formats" -ForegroundColor White
Write-Console "  Total: $($allExtensions.Count) file types" -ForegroundColor Cyan

$successCount = 0
$failCount = 0

foreach ($ext in $allExtensions) {
    try {
        # Create file type association
        $regPath = "HKCU:\Software\Classes\$ext"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "mpv.net$ext"

        # Create program association
        $progPath = "HKCU:\Software\Classes\mpv.net$ext"
        if (-not (Test-Path $progPath)) {
            New-Item -Path $progPath -Force | Out-Null
        }

        $shellPath = "$progPath\shell\open\command"
        if (-not (Test-Path $shellPath)) {
            New-Item -Path $shellPath -Force | Out-Null
        }
        Set-ItemProperty -Path $shellPath -Name "(Default)" -Value "`"$($mpvPath.FullName)`" `"%1`""

        Write-Console "  ✓ $ext" -ForegroundColor Green -NoNewline
        $successCount++

        if ($successCount % 6 -eq 0) {
            Write-Console ""
        }
    }
    catch {
        Write-Console "  ✗ $ext" -ForegroundColor Red -NoNewline
        $failCount++
    }
}

Write-Console "`n"

# Update file explorer icon cache
Write-Console "Refreshing file associations..." -ForegroundColor Yellow
$code = @'
[DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
'@
Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer
[WinAPI.Explorer]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Console "`n" -NoNewline
Write-Console "="*60 -ForegroundColor Cyan
Write-Console "Default App Configuration Complete!" -ForegroundColor Green
Write-Console "="*60 -ForegroundColor Cyan

Write-Console "`nResults:" -ForegroundColor Cyan
Write-Console "  Successfully configured: $successCount file types" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Console "  Failed: $failCount file types" -ForegroundColor Red
}

Write-Console "`nNote:" -ForegroundColor Yellow
Write-Console "  - Right-click any video file to verify mpv.net appears" -ForegroundColor White
Write-Console "  - Some file types may require opening once via 'Open with' first" -ForegroundColor White
Write-Console "  - File Explorer may need to be restarted to see changes" -ForegroundColor White

Write-Console "`nmpv.net is now your default video player!" -ForegroundColor Green
