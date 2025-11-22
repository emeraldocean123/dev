# Update all ExifTool installations to version 13.42
# Run this script in PowerShell as Administrator if you get permission errors

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$version = "13.42"
$downloadUrl = "https://exiftool.org/exiftool-$version.zip"
$tempZip = "$env:TEMP\exiftool-$version.zip"
$tempExtract = "$env:TEMP\exiftool-$version"

# ExifTool installation paths (using environment variables for portability)
$installations = @(
    "D:\Files\Programs-Portable\ExifTool",
    "$env:LOCALAPPDATA\Programs\ExifTool",
    "$env:LOCALAPPDATA\Programs\ExifToolGUI",
    "$env:ProgramFiles\digiKam"
)

# Check if DigiKam is running before updating
$digiKamRunning = Get-Process -Name "digikam" -ErrorAction SilentlyContinue
if ($digiKamRunning) {
    Write-Host "WARNING: DigiKam is running. Close it to update its ExifTool." -ForegroundColor Yellow
}

Write-Console "Downloading ExifTool $version..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
    Write-Console "Downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Console "Error downloading: $_" -ForegroundColor Red
    exit 1
}

# Extract
Write-Console "Extracting archive..." -ForegroundColor Cyan
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

# The extracted folder is named "exiftool-13.42" and contains "exiftool(-k).exe"
$sourceExe = Get-ChildItem -Path $tempExtract -Filter "exiftool*.exe" -Recurse | Select-Object -First 1

if (-not $sourceExe) {
    Write-Console "Error: Could not find exiftool.exe in extracted files" -ForegroundColor Red
    exit 1
}

# Update each installation
foreach ($installPath in $installations) {
    if (Test-Path $installPath) {
        Write-Console "`nUpdating: $installPath" -ForegroundColor Yellow

        # Backup existing
        $backupPath = "$installPath\exiftool.exe.bak"
        if (Test-Path "$installPath\exiftool.exe") {
            Copy-Item "$installPath\exiftool.exe" $backupPath -Force
            Write-Console "  Backed up to: exiftool.exe.bak" -ForegroundColor Gray
        }

        # Copy new version
        try {
            Copy-Item $sourceExe.FullName "$installPath\exiftool.exe" -Force

            # Verify
            $newVersion = & "$installPath\exiftool.exe" -ver
            if ($newVersion -eq $version) {
                Write-Console "  SUCCESS: Updated to version $newVersion" -ForegroundColor Green
            } else {
                Write-Console "  WARNING: Version shows as $newVersion (expected $version)" -ForegroundColor Yellow
            }
        } catch {
            Write-Console "  ERROR: $_" -ForegroundColor Red
        }
    } else {
        Write-Console "`nSkipping (not found): $installPath" -ForegroundColor DarkGray
    }
}

# Cleanup
Write-Console "`nCleaning up temporary files..." -ForegroundColor Cyan
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

Write-Console "`nDone! All ExifTool installations have been updated." -ForegroundColor Green
Write-Console "Run 'exiftool -ver' to verify the active version in your PATH.`n" -ForegroundColor Cyan
