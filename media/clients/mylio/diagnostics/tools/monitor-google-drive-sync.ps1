# Monitor Google Drive sync progress

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
$allExtensions = $imageExtensions + $videoExtensions

Write-Console "=== Monitoring Google Drive Sync to Mylio Vault ===" -ForegroundColor Cyan
Write-Console ""

# Count current files
Write-Console "Current file counts:" -ForegroundColor Yellow

$images = (Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $imageExtensions -contains $_.Extension.ToLower()
}).Count

$videos = (Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $videoExtensions -contains $_.Extension.ToLower()
}).Count

$xmpFiles = (Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}).Count

$totalMedia = $images + $videos

Write-Console "  Images: $images" -ForegroundColor Green
Write-Console "  Videos: $videos" -ForegroundColor Green
Write-Console "  XMP files: $xmpFiles" -ForegroundColor Cyan
Write-Console "  Total media (images + videos): $totalMedia" -ForegroundColor Magenta
Write-Console "  Grand total (media + XMP): $($totalMedia + $xmpFiles)" -ForegroundColor White
Write-Console ""

# Expected counts
Write-Console "Expected totals:" -ForegroundColor Yellow
Write-Console "  Database records: 82,622" -ForegroundColor Cyan
Write-Console "  Current total: $($totalMedia + $xmpFiles)" -ForegroundColor White
Write-Console "  Difference: $(82622 - ($totalMedia + $xmpFiles))" -ForegroundColor Yellow
Write-Console ""

# Google Drive sync analysis
Write-Console "Google Drive sync analysis:" -ForegroundColor Yellow
Write-Console "  Files pending (you reported): 36,657" -ForegroundColor Yellow
Write-Console ""

# Check if the pending count matches XMP files
$xmpDifference = 82622 - ($totalMedia + $xmpFiles)
Write-Console "Hypothesis check:" -ForegroundColor Cyan
if ([Math]::Abs(36657 - $xmpDifference) -lt 1000) {
    Write-Console "  Google Drive is likely syncing XMP files!" -ForegroundColor Green
    Write-Console "  The pending count (~36,657) is close to missing files (~$xmpDifference)" -ForegroundColor Green
} else {
    Write-Console "  Pending: 36,657" -ForegroundColor Gray
    Write-Console "  Missing files: $xmpDifference" -ForegroundColor Gray
    Write-Console "  Difference: $([Math]::Abs(36657 - $xmpDifference))" -ForegroundColor Gray
}
Write-Console ""

# Check recent XMP files (created in last hour)
Write-Console "Recently created XMP files (last hour):" -ForegroundColor Yellow
$recentXmp = Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*" -and
    $_.CreationTime -gt (Get-Date).AddHours(-1)
}
Write-Console "  Count: $($recentXmp.Count)" -ForegroundColor $(if ($recentXmp.Count -gt 0) { "Green" } else { "Gray" })

if ($recentXmp.Count -gt 0 -and $recentXmp.Count -le 10) {
    Write-Console "  Sample files:" -ForegroundColor Cyan
    $recentXmp | Select-Object -First 10 | ForEach-Object {
        Write-Console "    $($_.CreationTime.ToString('HH:mm:ss')) - $($_.FullName.Replace($mylioPath + '\', ''))" -ForegroundColor Gray
    }
}
Write-Console ""

Write-Console "=== Monitoring Tip ===" -ForegroundColor Cyan
Write-Console "Run this script again in a few minutes to see if:" -ForegroundColor Gray
Write-Console "  - XMP file count increases" -ForegroundColor Gray
Write-Console "  - Total file count approaches 82,622" -ForegroundColor Gray
Write-Console ""
