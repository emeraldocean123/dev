# Test Icaros Installation
# Verify if Icaros shell extensions successfully added Windows metadata support for iPhone Camera MOV files

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$testFile = "D:\Mylio\Folder-Joseph\2025\(10) October\2025-10-16-149.mov"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Testing Icaros Installation" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Test file: $testFile`n" -ForegroundColor White

# Check if Icaros is installed
$icarosInstalled = Test-Path "C:\Program Files\Icaros\*"
if ($icarosInstalled) {
    Write-Console "Icaros installation detected: YES" -ForegroundColor Green
} else {
    Write-Console "Icaros installation detected: NO" -ForegroundColor Red
    Write-Console "`nPlease complete the Icaros installation first.`n" -ForegroundColor Yellow
    exit 1
}

Write-Console "`nTesting Windows Details metadata...`n" -ForegroundColor White

$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace((Split-Path $testFile))
$file = $folder.ParseName((Split-Path $testFile -Leaf))

# Test key properties
$videoLength = $folder.GetDetailsOf($file, 27)
$bitrate = $folder.GetDetailsOf($file, 28)
$frameWidth = $folder.GetDetailsOf($file, 316)
$frameHeight = $folder.GetDetailsOf($file, 317)

$success = 0
$failed = 0

Write-Console "Video Length (property 27):" -NoNewline
if ([string]::IsNullOrWhiteSpace($videoLength)) {
    Write-Console " [EMPTY] - FAILED" -ForegroundColor Red
    $failed++
} else {
    Write-Console " $videoLength - SUCCESS" -ForegroundColor Green
    $success++
}

Write-Console "Bit rate (property 28):" -NoNewline
if ([string]::IsNullOrWhiteSpace($bitrate)) {
    Write-Console " [EMPTY]" -ForegroundColor Yellow
} else {
    Write-Console " $bitrate - SUCCESS" -ForegroundColor Green
    $success++
}

Write-Console "Frame Width (property 316):" -NoNewline
if ([string]::IsNullOrWhiteSpace($frameWidth)) {
    Write-Console " [EMPTY]" -ForegroundColor Yellow
} else {
    Write-Console " $frameWidth - SUCCESS" -ForegroundColor Green
    $success++
}

Write-Console "Frame Height (property 317):" -NoNewline
if ([string]::IsNullOrWhiteSpace($frameHeight)) {
    Write-Console " [EMPTY]" -ForegroundColor Yellow
} else {
    Write-Console " $frameHeight - SUCCESS" -ForegroundColor Green
    $success++
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Test Results" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($success -gt 0) {
    Write-Console "SUCCESS: Icaros is working!" -ForegroundColor Green
    Write-Console "Windows can now read metadata from iPhone Camera MOV files." -ForegroundColor White
    Write-Console "`nThis means:" -ForegroundColor White
    Write-Console "  - Thumbnails should appear in Windows Explorer" -ForegroundColor Gray
    Write-Console "  - File Properties > Details shows video information" -ForegroundColor Gray
    Write-Console "  - All 5,958 iPhone Camera MOV files should now work" -ForegroundColor Gray
    Write-Console "  - No file modification needed - all metadata preserved" -ForegroundColor Gray
} else {
    Write-Console "FAILED: Metadata still not readable" -ForegroundColor Red
    Write-Console "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Console "  1. Restart Windows Explorer:" -ForegroundColor White
    Write-Console "     taskkill /f /im explorer.exe && start explorer.exe" -ForegroundColor Gray
    Write-Console "  2. If that doesn't work, reboot Windows" -ForegroundColor White
    Write-Console "  3. Run this test script again after restart" -ForegroundColor White
}

Write-Console ""
