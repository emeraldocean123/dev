# Scan Mylio folder for video formats and ensure MPV is default

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nScanning for Mylio folder..." -ForegroundColor Cyan
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

# Scan for video files
Write-Console "`n`nScanning for video files in Mylio..." -ForegroundColor Cyan
Write-Console "This may take a moment..." -ForegroundColor DarkGray

$videoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v',
                      '.mpg', '.mpeg', '.m2v', '.3gp', '.3g2', '.ogv', '.ts', '.m2ts',
                      '.mts', '.vob', '.divx', '.xvid', '.rm', '.rmvb', '.asf', '.f4v',
                      '.hevc', '.h264', '.h265')

$foundExtensions = @{}
$totalFiles = 0

Get-ChildItem -Path $mylioPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $ext = $_.Extension.ToLower()
    if ($videoExtensions -contains $ext) {
        if (-not $foundExtensions.ContainsKey($ext)) {
            $foundExtensions[$ext] = 0
        }
        $foundExtensions[$ext]++
        $totalFiles++
    }
}

Write-Console "`n`nScan Results:" -ForegroundColor Cyan
Write-Console "="*60 -ForegroundColor Cyan

if ($foundExtensions.Count -eq 0) {
    Write-Console "`nNo video files found in Mylio folder" -ForegroundColor Yellow
    exit 0
}

Write-Console "`nFound $totalFiles video files across $($foundExtensions.Count) formats:" -ForegroundColor Green
$foundExtensions.GetEnumerator() | Sort-Object Key | ForEach-Object {
    Write-Console "  $($_.Key.PadRight(8)) : $($_.Value) files" -ForegroundColor White
}

# Check which formats are already configured
Write-Console "`n`nChecking current default apps..." -ForegroundColor Cyan

$needsConfig = @()
foreach ($ext in $foundExtensions.Keys) {
    $regPath = "HKCU:\Software\Classes\$ext"
    if (Test-Path $regPath) {
        $defaultValue = (Get-ItemProperty -Path $regPath -Name "(Default)" -ErrorAction SilentlyContinue).'(Default)'
        if ($defaultValue -like "mpv.net*") {
            Write-Console "  ✓ $ext already defaults to mpv.net" -ForegroundColor Green
        } else {
            Write-Console "  ✗ $ext defaults to: $defaultValue" -ForegroundColor Yellow
            $needsConfig += $ext
        }
    } else {
        Write-Console "  ? $ext not configured" -ForegroundColor Yellow
        $needsConfig += $ext
    }
}

# Configure missing formats
if ($needsConfig.Count -gt 0) {
    Write-Console "`n`nConfiguring $($needsConfig.Count) formats for mpv.net..." -ForegroundColor Cyan

    # Find mpv.net
    $mpvPath = Get-ChildItem "$env:LOCALAPPDATA\Programs\mpv.net" -Filter "mpvnet.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $mpvPath) {
        Write-Error "mpv.net not found!"
        exit 1
    }

    foreach ($ext in $needsConfig) {
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
    Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer
    [WinAPI.Explorer]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

    Write-Console "`n✓ All Mylio video formats now default to mpv.net!" -ForegroundColor Green
} else {
    Write-Console "`n✓ All video formats already configured for mpv.net!" -ForegroundColor Green
}

Write-Console "`n"
