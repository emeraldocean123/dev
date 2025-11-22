# Configure MPV for all Mylio photo and video formats

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nConfiguring MPV for all Mylio media..." -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

# Common locations to check
$searchPaths = @(
    'C:\Users\josep\Pictures\Mylio',
    'C:\Users\josep\Documents\Mylio',
    'C:\Users\josep\OneDrive\Pictures\Mylio',
    'D:\Mylio',
    'D:\Pictures\Mylio',
    'F:\Mylio',
    'F:\Pictures\Mylio'
)

$mylioPath = $null
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Write-Console "`n✓ Found Mylio at: $path" -ForegroundColor Green
        $mylioPath = $path
        break
    }
}

if (-not $mylioPath) {
    # Search more broadly
    Write-Console "`nSearching drives for Mylio folder..." -ForegroundColor Yellow
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[C-F]$' }
    foreach ($drive in $drives) {
        $searchPath = Join-Path $drive.Root 'Mylio'
        if (Test-Path $searchPath) {
            Write-Console "`n✓ Found Mylio at: $searchPath" -ForegroundColor Green
            $mylioPath = $searchPath
            break
        }

        # Also check in Pictures
        $picturesPath = Join-Path $drive.Root 'Pictures\Mylio'
        if (Test-Path $picturesPath) {
            Write-Console "`n✓ Found Mylio at: $picturesPath" -ForegroundColor Green
            $mylioPath = $picturesPath
            break
        }
    }
}

if (-not $mylioPath) {
    Write-Console "`n✗ Mylio folder not found" -ForegroundColor Red
    Write-Console "Please enter the full path to your Mylio folder:" -ForegroundColor Yellow
    $mylioPath = Read-Host "Path"

    if (-not (Test-Path $mylioPath)) {
        Write-Error "Path does not exist: $mylioPath"
        exit 1
    }
}

# All photo and video formats found in Mylio
Write-Console "`nConfiguring file associations..." -ForegroundColor Cyan

# Photo formats
$photoExtensions = @('.jpg', '.heic', '.png', '.jpeg', '.bmp', '.webp', '.gif')

# Video formats
$videoExtensions = @('.mov', '.mp4', '.mpg', '.avi', '.m4v', '.m2ts', '.wmv', '.3gp', '.3g2')

# Combine all media extensions
$allExtensions = $photoExtensions + $videoExtensions

Write-Console "  Photos: $($photoExtensions.Count) formats" -ForegroundColor White
Write-Console "  Videos: $($videoExtensions.Count) formats" -ForegroundColor White
Write-Console "  Total: $($allExtensions.Count) file types" -ForegroundColor Green

Write-Console "`n`nConfiguring all formats for mpv.net..." -ForegroundColor Cyan

# Find mpv.net
$mpvPath = Get-ChildItem "$env:LOCALAPPDATA\Programs\mpv.net" -Filter "mpvnet.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $mpvPath) {
    Write-Error "mpv.net not found!"
    exit 1
}

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

            Write-Console "  ✓ Configured $ext" -ForegroundColor Green
        }
        catch {
            Write-Console "  ✗ Failed to configure $ext" -ForegroundColor Red
        }
}

# Refresh shell
Write-Console "`nRefreshing file associations..." -ForegroundColor Yellow
$code = @'
[DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
'@
Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer -ErrorAction SilentlyContinue
[WinAPI.Explorer]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Console "`n✓ All Mylio photo and video formats now default to mpv.net!`n" -ForegroundColor Green
