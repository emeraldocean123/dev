# Test HEIC Viewing in XnView MP
# Verifies HEIC support and keybindings

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$xnviewPath = "C:\Program Files\XnViewMP\xnviewmp.exe"
$heicTestFile = "C:\Users\josep\Documents\heic-staging\Folder-Follett-2018--12--Decem-2018-12-02-21.heic"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  XnView MP HEIC Support Test" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Check XnView MP installation
Write-Console "[1/3] Checking XnView MP installation..." -ForegroundColor Yellow
if (Test-Path $xnviewPath) {
    Write-Console "  ✅ XnView MP found at: $xnviewPath" -ForegroundColor Green
} else {
    Write-Console "  ❌ XnView MP not found!" -ForegroundColor Red
    Write-Console "  Expected location: $xnviewPath" -ForegroundColor Yellow
    exit 1
}

# Check for test HEIC file
Write-Console "`n[2/3] Checking for test HEIC file..." -ForegroundColor Yellow
if (Test-Path $heicTestFile) {
    $file = Get-Item $heicTestFile
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    Write-Console "  ✅ Test file found: $($file.Name)" -ForegroundColor Green
    Write-Console "  Size: $sizeMB MB" -ForegroundColor Gray
    Write-Console "  Date: $($file.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Console "  ⚠️ Test file not found, using first HEIC from staging..." -ForegroundColor Yellow
    $heicTestFile = Get-ChildItem "C:\Users\josep\Documents\heic-staging\*.heic" | Select-Object -First 1 | Select-Object -ExpandProperty FullName

    if ($heicTestFile) {
        Write-Console "  Using: $heicTestFile" -ForegroundColor Cyan
    } else {
        Write-Console "  ❌ No HEIC files found in staging folder!" -ForegroundColor Red
        exit 1
    }
}

# Check Windows HEIF codec
Write-Console "`n[3/3] Checking Windows HEIF codec..." -ForegroundColor Yellow
$heifCodec = Get-AppxPackage -Name "*HEIFImageExtension*" 2>$null

if ($heifCodec) {
    Write-Console "  ✅ HEIF Image Extensions installed" -ForegroundColor Green
    Write-Console "  Version: $($heifCodec.Version)" -ForegroundColor Gray
} else {
    Write-Console "  ⚠️ HEIF Image Extensions not found" -ForegroundColor Yellow
    Write-Console "`n  To install:" -ForegroundColor Cyan
    Write-Console "    1. Open Microsoft Store" -ForegroundColor Gray
    Write-Console "    2. Search for 'HEIF Image Extensions'" -ForegroundColor Gray
    Write-Console "    3. Install (free)" -ForegroundColor Gray
    Write-Console "`n  XnView MP may still work with built-in decoder" -ForegroundColor DarkGray
}

# Open XnView MP with test file
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Opening XnView MP..." -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Test file: $heicTestFile`n" -ForegroundColor Gray

Write-Console "Keybindings to test:" -ForegroundColor Yellow
Write-Console "  LEFT/RIGHT - Navigate previous/next image" -ForegroundColor Gray
Write-Console "  SPACE      - Start/stop slideshow" -ForegroundColor Gray
Write-Console "  HOME/END   - Jump to first/last image" -ForegroundColor Gray
Write-Console "  Mouse wheel - Zoom in/out" -ForegroundColor Gray
Write-Console "  I          - Show EXIF metadata" -ForegroundColor Gray
Write-Console "  F11        - Toggle fullscreen" -ForegroundColor Gray
Write-Console "`n"

Write-Console "Opening XnView MP now..." -ForegroundColor Cyan
Start-Process $xnviewPath -ArgumentList "`"$heicTestFile`""

Write-Console "`n✅ XnView MP launched successfully!`n" -ForegroundColor Green

Write-Console "Verify:" -ForegroundColor Yellow
Write-Console "  1. Image displays correctly" -ForegroundColor Gray
Write-Console "  2. LEFT/RIGHT arrows work for navigation" -ForegroundColor Gray
Write-Console "  3. Press 'I' to see EXIF data (GPS, camera info)" -ForegroundColor Gray
Write-Console "  4. Mouse wheel zooms in/out" -ForegroundColor Gray
Write-Console ""
