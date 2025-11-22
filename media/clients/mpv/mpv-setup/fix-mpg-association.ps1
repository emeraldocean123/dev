# Fix .mpg file association for mpv.net
# Windows 11 requires special handling for default apps

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

Write-Console "`nFixing .mpg file association..." -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

# Find mpv.net
$mpvPath = Get-ChildItem "$env:LOCALAPPDATA\Programs\mpv.net" -Filter "mpvnet.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $mpvPath) {
    Write-Error "mpv.net not found!"
    exit 1
}

Write-Console "`nFound mpv.net at: $($mpvPath.FullName)" -ForegroundColor Green

# Video extensions to fix
$extensions = @('.mpg', '.mpeg', '.mp4', '.mov', '.avi', '.mkv', '.m4v', '.wmv', '.m2ts', '.3gp', '.3g2')

Write-Console "`nConfiguring file associations..." -ForegroundColor Yellow

foreach ($ext in $extensions) {
    Write-Console "`nProcessing $ext..." -ForegroundColor Cyan

    # Remove existing associations in user registry
    $userChoicePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"
    if (Test-Path $userChoicePath) {
        Write-Console "  Removing existing UserChoice..." -ForegroundColor DarkGray
        Remove-Item -Path $userChoicePath -Force -ErrorAction SilentlyContinue
    }

    # Set file type association
    $regPath = "HKCU:\Software\Classes\$ext"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "mpv.net$ext" -Force

    # Create program association
    $progPath = "HKCU:\Software\Classes\mpv.net$ext"
    if (-not (Test-Path $progPath)) {
        New-Item -Path $progPath -Force | Out-Null
    }
    Set-ItemProperty -Path $progPath -Name "(Default)" -Value "mpv.net Video File" -Force
    Set-ItemProperty -Path $progPath -Name "FriendlyTypeName" -Value "mpv.net Video File" -Force

    # Set default icon
    $iconPath = "$progPath\DefaultIcon"
    if (-not (Test-Path $iconPath)) {
        New-Item -Path $iconPath -Force | Out-Null
    }
    Set-ItemProperty -Path $iconPath -Name "(Default)" -Value "`"$($mpvPath.FullName)`",0" -Force

    # Set open command
    $shellPath = "$progPath\shell\open\command"
    if (-not (Test-Path $shellPath)) {
        New-Item -Path $shellPath -Force | Out-Null
    }
    Set-ItemProperty -Path $shellPath -Name "(Default)" -Value "`"$($mpvPath.FullName)`" `"%1`"" -Force

    Write-Console "  ✓ Registry configured" -ForegroundColor Green
}

# Refresh Windows Explorer
Write-Console "`nRefreshing Windows Explorer..." -ForegroundColor Yellow
$code = @'
[DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
'@
Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer -ErrorAction SilentlyContinue
[WinAPI.Explorer]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

# Kill and restart Explorer to ensure changes take effect
Write-Console "Restarting Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Console "`n" -NoNewline
Write-Console "="*60 -ForegroundColor Cyan
Write-Console "File Association Fix Complete!" -ForegroundColor Green
Write-Console "="*60 -ForegroundColor Cyan

Write-Console "`nNext steps:" -ForegroundColor Cyan
Write-Console "  1. Try double-clicking an .mpg file" -ForegroundColor White
Write-Console "  2. If it still asks, choose mpv.net and check 'Always use this app'" -ForegroundColor White
Write-Console "  3. The association should stick after the first manual selection" -ForegroundColor White

Write-Console "`nNote: Windows 11 requires user confirmation for default apps" -ForegroundColor Yellow
Write-Console "This is a security feature and cannot be bypassed programmatically" -ForegroundColor DarkGray
