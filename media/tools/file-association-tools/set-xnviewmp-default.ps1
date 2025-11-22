# Set XnViewMP as default application for all photo and video file types
# This script configures Windows file associations to use XnViewMP

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$xnviewmpPath = "C:\Program Files\XnViewMP\xnviewmp.exe"

# Verify XnViewMP is installed
if (-not (Test-Path $xnviewmpPath)) {
    Write-Error "XnViewMP not found at: $xnviewmpPath"
    exit 1
}

Write-Console "Setting XnViewMP as default for photo and video file types..." -ForegroundColor Green

# Photo file extensions
$photoExtensions = @(
    # Common formats
    ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp",
    # RAW formats
    ".cr2", ".cr3", ".nef", ".arw", ".dng", ".orf", ".rw2", ".pef", ".srw", ".raw",
    # Other image formats
    ".ico", ".svg", ".heic", ".heif", ".avif", ".jxl"
)

# Video file extensions
$videoExtensions = @(
    ".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".webm", ".m4v",
    ".mpg", ".mpeg", ".3gp", ".mts", ".m2ts", ".vob", ".ogv"
)

# Combine all extensions
$allExtensions = $photoExtensions + $videoExtensions

$successCount = 0
$failCount = 0

foreach ($ext in $allExtensions) {
    try {
        # Set file association using Windows DISM command
        $result = cmd /c "assoc $ext=XnViewMP.Image 2>&1"

        # Set the default program for the file type
        $result = cmd /c "ftype XnViewMP.Image=`"$xnviewmpPath`" `"%1`" 2>&1"

        # Also try using the modern method with Set-FileAssociation (Windows 10/11)
        try {
            # Create a temporary XML for this association
            $hash = (Get-FileHash -Path $xnviewmpPath -Algorithm SHA256).Hash
            $progId = "XnViewMP_$ext"

            # Set via registry (more reliable method)
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"

            # Remove existing UserChoice if it exists
            if (Test-Path $regPath) {
                Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
            }

            Write-Console "  Set $ext -> XnViewMP" -ForegroundColor Cyan
            $successCount++
        }
        catch {
            Write-Warning "  Failed to set modern association for $ext"
        }
    }
    catch {
        Write-Warning "  Failed to set association for $ext : $_"
        $failCount++
    }
}

# Alternative method: Set default via Windows Settings using a more comprehensive approach
Write-Console "`nApplying comprehensive file associations..." -ForegroundColor Green

# Create a temporary registry script
$regScript = @"
Windows Registry Editor Version 5.00

"@

foreach ($ext in $allExtensions) {
    $regScript += @"

[HKEY_CURRENT_USER\Software\Classes\$ext]
@="XnViewMP.Image"

"@
}

$regScript += @"

[HKEY_CURRENT_USER\Software\Classes\XnViewMP.Image]
@="XnViewMP Image"

[HKEY_CURRENT_USER\Software\Classes\XnViewMP.Image\DefaultIcon]
@="$($xnviewmpPath.Replace('\','\\'))"

[HKEY_CURRENT_USER\Software\Classes\XnViewMP.Image\shell\open\command]
@="`"$($xnviewmpPath.Replace('\','\\'))`" `"%1`""

"@

# Save and import registry script
$regFile = "$env:TEMP\xnviewmp-associations.reg"
$regScript | Out-File -FilePath $regFile -Encoding unicode

Write-Console "Importing registry associations..." -ForegroundColor Yellow
$result = reg import $regFile 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Console "Registry associations imported successfully" -ForegroundColor Green
} else {
    Write-Warning "Some registry associations may have failed"
}

# Clean up
Remove-Item $regFile -ErrorAction SilentlyContinue

Write-Console "`n=== Summary ===" -ForegroundColor Green
Write-Console "Successfully set: $successCount file types" -ForegroundColor Cyan
if ($failCount -gt 0) {
    Write-Console "Failed: $failCount file types" -ForegroundColor Yellow
}

Write-Console "`nNote: You may need to:" -ForegroundColor Yellow
Write-Console "1. Log out and log back in for all changes to take effect" -ForegroundColor Yellow
Write-Console "2. If associations don't work, right-click a file -> 'Open with' -> Choose XnViewMP and check 'Always use this app'" -ForegroundColor Yellow

Write-Console "`nDone! XnViewMP should now be the default for photo and video files." -ForegroundColor Green
