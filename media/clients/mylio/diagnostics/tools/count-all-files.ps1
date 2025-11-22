# Count all media files in Mylio vault and compare to Mylio's count

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$mylioPath = "D:\Mylio"
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv')

Write-Console "Counting files in Mylio vault..." -ForegroundColor Cyan
Write-Console ""

Write-Console "Counting images..." -ForegroundColor Gray
$images = Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $imageExtensions -contains $_.Extension.ToLower()
}
$imageCount = $images.Count

Write-Console "Counting videos..." -ForegroundColor Gray
$videos = Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $videoExtensions -contains $_.Extension.ToLower()
}
$videoCount = $videos.Count

Write-Console "Counting XMP files..." -ForegroundColor Gray
$xmpFiles = Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}
$xmpCount = $xmpFiles.Count

Write-Console "Counting other files..." -ForegroundColor Gray
$allFiles = Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}
$allCount = $allFiles.Count

$otherCount = $allCount - $imageCount - $videoCount - $xmpCount

Write-Console ""
Write-Console "=== File Count Summary ===" -ForegroundColor Green
Write-Console ""
Write-Console "Images:      " -NoNewline; Write-Console $imageCount.ToString("N0") -ForegroundColor Green
Write-Console "Videos:      " -NoNewline; Write-Console $videoCount.ToString("N0") -ForegroundColor Green
Write-Console "XMP files:   " -NoNewline; Write-Console $xmpCount.ToString("N0") -ForegroundColor Green
Write-Console "Other files: " -NoNewline; Write-Console $otherCount.ToString("N0") -ForegroundColor Gray
Write-Console "─────────────────────" -ForegroundColor DarkGray
Write-Console "Total files: " -NoNewline; Write-Console $allCount.ToString("N0") -ForegroundColor Cyan
Write-Console ""
Write-Console "Mylio shows: " -NoNewline; Write-Console "82,622" -ForegroundColor Yellow
Write-Console "Difference:  " -NoNewline
$diff = 82622 - $allCount
Write-Console $diff.ToString("N0") -ForegroundColor $(if ($diff -gt 0) { "Yellow" } else { "Gray" })
Write-Console ""

if ($diff -gt 0) {
    Write-Console "Possible reasons for difference:" -ForegroundColor Yellow
    Write-Console "  - Google Drive sync in progress (downloading files)" -ForegroundColor Gray
    Write-Console "  - Files in Mylio database not yet synced to disk" -ForegroundColor Gray
    Write-Console "  - Files in cloud-only locations" -ForegroundColor Gray
    Write-Console "  - Virtual/thumbnail files counted by Mylio" -ForegroundColor Gray
    Write-Console ""
}

# Show what other files might be
if ($otherCount -gt 0) {
    Write-Console "Note: Other files may include AAE, JSON, or database files." -ForegroundColor Gray
    Write-Console ""
}
