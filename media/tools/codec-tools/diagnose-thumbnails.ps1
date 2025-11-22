# Diagnose Thumbnail Issues in Mylio October 2025 Folder
# Check file types, extensions, and potential thumbnail problems

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$folderPath = "D:\Mylio\Folder-Joseph\2025\(10) October"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Thumbnail Diagnostic" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Folder: $folderPath`n" -ForegroundColor Gray

if (-not (Test-Path $folderPath)) {
    Write-Console "  ❌ Folder not found!" -ForegroundColor Red
    exit 1
}

# Get all files
$files = Get-ChildItem -Path $folderPath -File | Sort-Object Name

Write-Console "[1/4] File Type Analysis" -ForegroundColor Yellow
Write-Console ""

# Group by extension
$byExtension = $files | Group-Object Extension | Sort-Object Name

foreach ($group in $byExtension) {
    $ext = if ($group.Name) { $group.Name } else { "(no extension)" }
    $totalSize = ($group.Group | Measure-Object -Property Length -Sum).Sum / 1MB

    Write-Console "  $ext : $($group.Count) files ($([math]::Round($totalSize, 2)) MB)" -ForegroundColor White

    # Show sample filenames
    $samples = $group.Group | Select-Object -First 3 | ForEach-Object { $_.Name }
    foreach ($sample in $samples) {
        Write-Console "    - $sample" -ForegroundColor Gray
    }
    if ($group.Count -gt 3) {
        Write-Console "    ... and $($group.Count - 3) more" -ForegroundColor DarkGray
    }
    Write-Console ""
}

Write-Console "[2/4] Extension Case Analysis" -ForegroundColor Yellow
Write-Console ""

# Check for mixed case extensions
$movLowercase = $files | Where-Object { $_.Extension -eq ".mov" }
$movUppercase = $files | Where-Object { $_.Extension -eq ".MOV" }
$heicLowercase = $files | Where-Object { $_.Extension -eq ".heic" }
$heicUppercase = $files | Where-Object { $_.Extension -eq ".HEIC" }

Write-Console "  Video files:" -ForegroundColor Cyan
Write-Console "    .mov (lowercase): $($movLowercase.Count) files" -ForegroundColor $(if ($movLowercase.Count -gt 0) { 'White' } else { 'DarkGray' })
Write-Console "    .MOV (uppercase): $($movUppercase.Count) files" -ForegroundColor $(if ($movUppercase.Count -gt 0) { 'White' } else { 'DarkGray' })

Write-Console ""
Write-Console "  Image files:" -ForegroundColor Cyan
Write-Console "    .heic (lowercase): $($heicLowercase.Count) files" -ForegroundColor $(if ($heicLowercase.Count -gt 0) { 'White' } else { 'DarkGray' })
Write-Console "    .HEIC (uppercase): $($heicUppercase.Count) files" -ForegroundColor $(if ($heicUppercase.Count -gt 0) { 'White' } else { 'DarkGray' })

if ($movUppercase.Count -gt 0 -or $heicUppercase.Count -gt 0) {
    Write-Console ""
    Write-Console "  ⚠️ Mixed extension case detected!" -ForegroundColor Yellow
    Write-Console "     This can cause Windows thumbnail cache issues" -ForegroundColor Gray
}

Write-Console ""
Write-Console "[3/4] Camera App Detection" -ForegroundColor Yellow
Write-Console ""

# Uppercase extensions are likely from ProCamera
Write-Console "  Likely iPhone Camera app (.mov, .heic):" -ForegroundColor Cyan
Write-Console "    Files: $($movLowercase.Count + $heicLowercase.Count)" -ForegroundColor White

Write-Console ""
Write-Console "  Likely ProCamera app (.MOV, .HEIC):" -ForegroundColor Cyan
Write-Console "    Files: $($movUppercase.Count + $heicUppercase.Count)" -ForegroundColor White
if ($movUppercase.Count -gt 0) {
    $sampleProCamera = $movUppercase | Select-Object -First 3 | ForEach-Object { $_.Name }
    Write-Console "    Samples:" -ForegroundColor Gray
    foreach ($sample in $sampleProCamera) {
        Write-Console "      - $sample" -ForegroundColor Gray
    }
}

Write-Console ""
Write-Console "[4/4] Thumbnail Issues & Solutions" -ForegroundColor Yellow
Write-Console ""

Write-Console "  Common causes for missing thumbnails:" -ForegroundColor Cyan
Write-Console ""
Write-Console "  1. Mixed Extension Case (.mov vs .MOV)" -ForegroundColor White
Write-Console "     → Windows caches thumbnails by extension" -ForegroundColor Gray
Write-Console "     → .MOV and .mov treated as different file types" -ForegroundColor Gray
Write-Console "     → Solution: Rebuild thumbnail cache" -ForegroundColor Green
Write-Console ""

Write-Console "  2. Video Codec Differences" -ForegroundColor White
Write-Console "     → ProCamera may use different codec than iPhone Camera" -ForegroundColor Gray
Write-Console "     → Windows might not support thumbnail for some codecs" -ForegroundColor Gray
Write-Console "     → Solution: Check video codec with MediaInfo" -ForegroundColor Green
Write-Console ""

Write-Console "  3. Windows Thumbnail Cache Corruption" -ForegroundColor White
Write-Console "     → Cache file might be corrupted" -ForegroundColor Gray
Write-Console "     → Solution: Clear thumbnail cache (see below)" -ForegroundColor Green
Write-Console ""

Write-Console "  4. File Association Issues" -ForegroundColor White
Write-Console "     → .MOV might not be associated with proper handler" -ForegroundColor Gray
Write-Console "     → Solution: Associate .MOV with Windows Photos or VLC" -ForegroundColor Green

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Solutions" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

Write-Console "Solution 1: Clear Windows Thumbnail Cache" -ForegroundColor Green
Write-Console ""
Write-Console "  PowerShell commands:" -ForegroundColor White
Write-Console '  Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force' -ForegroundColor Gray
Write-Console '  Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force' -ForegroundColor Gray
Write-Console "  Then restart Windows Explorer or reboot" -ForegroundColor Gray

Write-Console ""
Write-Console "Solution 2: Standardize Extension Case" -ForegroundColor Green
Write-Console ""
Write-Console "  Rename all extensions to lowercase:" -ForegroundColor White
Write-Console "  (This makes Windows treat them consistently)" -ForegroundColor Gray
Write-Console ""
Write-Console "  # Rename .MOV to .mov" -ForegroundColor Gray
Write-Console '  Get-ChildItem "D:\Mylio\Folder-Joseph\2025\(10) October\*.MOV" | Rename-Item -NewName { $_.Name.ToLower() }' -ForegroundColor DarkGray
Write-Console ""
Write-Console "  # Rename .HEIC to .heic" -ForegroundColor Gray
Write-Console '  Get-ChildItem "D:\Mylio\Folder-Joseph\2025\(10) October\*.HEIC" | Rename-Item -NewName { $_.Name.ToLower() }' -ForegroundColor DarkGray

Write-Console ""
Write-Console "Solution 3: Check Video Codec" -ForegroundColor Green
Write-Console ""
Write-Console "  Install MediaInfo:" -ForegroundColor White
Write-Console "    winget install MediaArea.MediaInfo.GUI" -ForegroundColor Gray
Write-Console ""
Write-Console "  Then right-click a .MOV file without thumbnail:" -ForegroundColor White
Write-Console "    → MediaInfo" -ForegroundColor Gray
Write-Console "    → Check Video codec (should be H.264 or HEVC)" -ForegroundColor Gray

Write-Console ""
Write-Console "Solution 4: Test with Different Viewer" -ForegroundColor Green
Write-Console ""
Write-Console "  Try opening files without thumbnails in:" -ForegroundColor White
Write-Console "    - VLC Media Player (handles most codecs)" -ForegroundColor Gray
Write-Console "    - mpv.net (good for videos)" -ForegroundColor Gray
Write-Console "    - XnView MP (good for images)" -ForegroundColor Gray
Write-Console ""
Write-Console "  If they open fine, it's just a Windows thumbnail issue" -ForegroundColor Gray

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Recommended Actions" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

Write-Console "1. ✅ Standardize extension case (lowercase)" -ForegroundColor Green
Write-Console "2. ✅ Clear thumbnail cache" -ForegroundColor Green
Write-Console "3. ✅ Restart Windows Explorer" -ForegroundColor Green
Write-Console "4. ✅ Refresh folder view (F5)" -ForegroundColor Green
Write-Console ""

Write-Console "Would you like to:" -ForegroundColor Yellow
Write-Console "  [1] Rename all extensions to lowercase" -ForegroundColor Cyan
Write-Console "  [2] Clear thumbnail cache" -ForegroundColor Cyan
Write-Console "  [3] Both (recommended)" -ForegroundColor Cyan
Write-Console "  [4] Cancel" -ForegroundColor Gray
Write-Console ""
