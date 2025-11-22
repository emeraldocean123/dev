# Check what file types have XMP sidecars

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

Write-Console "Analyzing XMP sidecar file types..." -ForegroundColor Cyan
Write-Console ""

$xmpFiles = Get-ChildItem -Path $mylioPath -Filter "*.xmp" -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}

Write-Console "Found $($xmpFiles.Count) XMP files" -ForegroundColor Green
Write-Console ""

$fileTypes = @{}
$orphaned = 0

foreach ($xmpFile in $xmpFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($xmpFile.FullName)
    $directory = $xmpFile.DirectoryName
    $foundMatch = $false
    $matchedExt = ""

    # Check images
    foreach ($ext in $imageExtensions) {
        $path = Join-Path $directory "$baseName$ext"
        if (Test-Path $path) {
            $foundMatch = $true
            $matchedExt = $ext
            break
        }
    }

    # Check videos if no image found
    if (-not $foundMatch) {
        foreach ($ext in $videoExtensions) {
            $path = Join-Path $directory "$baseName$ext"
            if (Test-Path $path) {
                $foundMatch = $true
                $matchedExt = $ext
                break
            }
        }
    }

    if ($foundMatch) {
        if ($fileTypes.ContainsKey($matchedExt)) {
            $fileTypes[$matchedExt]++
        } else {
            $fileTypes[$matchedExt] = 1
        }
    } else {
        $orphaned++
    }
}

Write-Console "=== XMP Sidecar File Type Breakdown ===" -ForegroundColor Green
Write-Console ""

# Images
Write-Console "Images:" -ForegroundColor Yellow
$imageTotal = 0
foreach ($ext in $imageExtensions) {
    if ($fileTypes.ContainsKey($ext)) {
        $count = $fileTypes[$ext]
        $imageTotal += $count
        Write-Console "  $ext : $count" -ForegroundColor Gray
    }
}
Write-Console "  Total Images: $imageTotal" -ForegroundColor Green
Write-Console ""

# Videos
Write-Console "Videos:" -ForegroundColor Yellow
$videoTotal = 0
foreach ($ext in $videoExtensions) {
    if ($fileTypes.ContainsKey($ext)) {
        $count = $fileTypes[$ext]
        $videoTotal += $count
        Write-Console "  $ext : $count" -ForegroundColor Gray
    }
}
Write-Console "  Total Videos: $videoTotal" -ForegroundColor Green
Write-Console ""

Write-Console "Orphaned (no matching file): $orphaned" -ForegroundColor $(if ($orphaned -gt 0) { "Yellow" } else { "Gray" })
Write-Console ""

# Summary
$imagePercent = [math]::Round(($imageTotal / $xmpFiles.Count) * 100, 1)
$videoPercent = [math]::Round(($videoTotal / $xmpFiles.Count) * 100, 1)

Write-Console "=== Summary ===" -ForegroundColor Cyan
Write-Console "Total XMP files: $($xmpFiles.Count)" -ForegroundColor White
Write-Console "Images: $imageTotal ($imagePercent%)" -ForegroundColor Green
Write-Console "Videos: $videoTotal ($videoPercent%)" -ForegroundColor Green
Write-Console ""
