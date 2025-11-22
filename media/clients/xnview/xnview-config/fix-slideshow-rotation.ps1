# Fix XnView MP Slideshow Rotation Issues
# Diagnose and fix EXIF orientation problems

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  XnView MP Rotation Diagnostic" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Check XnView MP settings
$xnviewIni = "$env:APPDATA\XnViewMP\xnview.ini"

if (Test-Path $xnviewIni) {
    Write-Console "[1/3] Checking current XnView MP settings..." -ForegroundColor Yellow

    $content = Get-Content $xnviewIni -Raw

    # Check EXIF rotation setting
    if ($content -match 'useEXIFRotation=(true|false)') {
        $exifRotation = $matches[1]
        if ($exifRotation -eq 'true') {
            Write-Console "  ✅ EXIF rotation: ENABLED" -ForegroundColor Green
        } else {
            Write-Console "  ❌ EXIF rotation: DISABLED" -ForegroundColor Red
            Write-Console "     This is why photos aren't rotating!" -ForegroundColor Yellow
        }
    }

    # Check rotation settings
    if ($content -match 'rotationChangeExif=(true|false)') {
        $rotationChangeExif = $matches[1]
        Write-Console "  Rotation changes EXIF: $rotationChangeExif" -ForegroundColor Gray
    }

    if ($content -match 'rotationUseLossless=(true|false)') {
        $rotationUseLossless = $matches[1]
        Write-Console "  Use lossless rotation: $rotationUseLossless" -ForegroundColor Gray
    }
} else {
    Write-Console "  ⚠️ XnView MP settings file not found" -ForegroundColor Yellow
}

Write-Console "`n[2/3] Common rotation issues:" -ForegroundColor Yellow
Write-Console ""
Write-Console "  Issue 1: EXIF Orientation Mismatch" -ForegroundColor Cyan
Write-Console "    Cause: Image pixels already rotated, but EXIF tag still says 'rotate me'" -ForegroundColor Gray
Write-Console "    Result: Image rotated twice (appears upside-down or wrong orientation)" -ForegroundColor Gray
Write-Console ""
Write-Console "  Issue 2: Missing EXIF Orientation" -ForegroundColor Cyan
Write-Console "    Cause: Some images don't have EXIF orientation tag" -ForegroundColor Gray
Write-Console "    Result: Portrait photos display sideways" -ForegroundColor Gray
Write-Console ""
Write-Console "  Issue 3: Edited photos with stale EXIF" -ForegroundColor Cyan
Write-Console "    Cause: Photo was rotated in another program that didn't update EXIF" -ForegroundColor Gray
Write-Console "    Result: XnView tries to rotate again based on old EXIF data" -ForegroundColor Gray

Write-Console "`n[3/3] Solutions:" -ForegroundColor Yellow
Write-Console ""
Write-Console "  Solution 1: Verify XnView MP Settings" -ForegroundColor Green
Write-Console "    1. Open XnView MP" -ForegroundColor Gray
Write-Console "    2. Go to Tools > Settings (Ctrl+K)" -ForegroundColor Gray
Write-Console "    3. Navigate to Read/Write > Read" -ForegroundColor Gray
Write-Console "    4. Check 'Use EXIF orientation'" -ForegroundColor Gray
Write-Console "    5. Click OK and restart XnView MP" -ForegroundColor Gray
Write-Console ""
Write-Console "  Solution 2: Fix Photos with Wrong Rotation" -ForegroundColor Green
Write-Console "    Option A: Auto-rotate based on EXIF (fixes all at once)" -ForegroundColor Cyan
Write-Console "      1. Open folder in XnView MP Browser mode" -ForegroundColor Gray
Write-Console "      2. Select all images (Ctrl+A)" -ForegroundColor Gray
Write-Console "      3. Tools > Batch Convert" -ForegroundColor Gray
Write-Console "      4. Transformations tab > Add 'Rotate based on EXIF'" -ForegroundColor Gray
Write-Console "      5. This will physically rotate pixels AND reset EXIF to normal" -ForegroundColor Gray
Write-Console ""
Write-Console "    Option B: Manual lossless rotation (one by one)" -ForegroundColor Cyan
Write-Console "      1. Open incorrectly rotated image" -ForegroundColor Gray
Write-Console "      2. Press Ctrl+J to rotate clockwise (lossless)" -ForegroundColor Gray
Write-Console "      3. Or press Ctrl+Shift+J to rotate counter-clockwise" -ForegroundColor Gray
Write-Console "      4. XnView will rotate pixels AND update EXIF to normal (1)" -ForegroundColor Gray
Write-Console ""
Write-Console "  Solution 3: Check Individual Photo EXIF" -ForegroundColor Green
Write-Console "    1. Right-click photo in XnView MP" -ForegroundColor Gray
Write-Console "    2. Select 'View > EXIF Info' (or press I)" -ForegroundColor Gray
Write-Console "    3. Look for 'Orientation' field" -ForegroundColor Gray
Write-Console "    4. Should be 1 (normal) for correctly oriented photos" -ForegroundColor Gray
Write-Console "    5. Values 3, 6, 8 mean rotation needed" -ForegroundColor Gray

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Next Steps" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Test with a single photo first:" -ForegroundColor Yellow
Write-Console "  1. Find a photo that displays wrong in slideshow" -ForegroundColor Gray
Write-Console "  2. Open it in XnView MP viewer (not browser)" -ForegroundColor Gray
Write-Console "  3. Press I to view EXIF" -ForegroundColor Gray
Write-Console "  4. Check the Orientation value" -ForegroundColor Gray
Write-Console ""
Write-Console "If Orientation = 1 but photo is sideways:" -ForegroundColor Cyan
Write-Console "  → Photo pixels are wrong, EXIF is correct" -ForegroundColor Gray
Write-Console "  → Solution: Manually rotate with Ctrl+J" -ForegroundColor Gray
Write-Console ""
Write-Console "If Orientation = 6 or 8 but photo displays wrong:" -ForegroundColor Cyan
Write-Console "  → EXIF rotation not working in XnView MP" -ForegroundColor Gray
Write-Console "  → Solution: Check 'Use EXIF orientation' setting" -ForegroundColor Gray
Write-Console ""
Write-Console "If photo rotates correctly in viewer but wrong in slideshow:" -ForegroundColor Cyan
Write-Console "  → Slideshow might have separate rotation setting" -ForegroundColor Gray
Write-Console "  → Solution: Check Tools > Settings > View > Slideshow" -ForegroundColor Gray
Write-Console ""

Write-Console "Would you like me to open XnView MP settings now? (Manual check needed)" -ForegroundColor Yellow
Write-Console ""
