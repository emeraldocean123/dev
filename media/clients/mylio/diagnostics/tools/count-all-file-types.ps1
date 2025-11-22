# Count ALL files in Mylio vault by type

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

Write-Console "=== Complete File Type Analysis ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "Analyzing all files in $mylioPath..." -ForegroundColor Yellow
Write-Console ""

# Get all files and group by extension
$allFiles = Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*"
}

$totalFiles = $allFiles.Count
Write-Console "Total files found: $totalFiles" -ForegroundColor Green
Write-Console ""

# Group by extension
$byExtension = $allFiles | Group-Object Extension | Sort-Object Count -Descending

Write-Console "Files by extension:" -ForegroundColor Yellow
Write-Console ""

# Define known media types
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw', '.bmp', '.gif', '.webp')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv', '.flv', '.webm')
$metadataExtensions = @('.xmp', '.aae', '.json', '.xml')
$databaseExtensions = @('.db', '.sqlite', '.sqlite3', '.mylodb')
$thumbnailExtensions = @('.thm', '.thumbnail')

$imageCount = 0
$videoCount = 0
$xmpCount = 0
$otherMetadata = 0
$databaseCount = 0
$thumbnailCount = 0
$unknownCount = 0
$unknownFiles = @()

foreach ($group in $byExtension) {
    $ext = $group.Name.ToLower()
    $count = $group.Count
    $category = ""

    if ($imageExtensions -contains $ext) {
        $category = "IMAGE"
        $imageCount += $count
    }
    elseif ($videoExtensions -contains $ext) {
        $category = "VIDEO"
        $videoCount += $count
    }
    elseif ($ext -eq '.xmp') {
        $category = "XMP"
        $xmpCount += $count
    }
    elseif ($metadataExtensions -contains $ext) {
        $category = "METADATA"
        $otherMetadata += $count
    }
    elseif ($databaseExtensions -contains $ext) {
        $category = "DATABASE"
        $databaseCount += $count
    }
    elseif ($thumbnailExtensions -contains $ext) {
        $category = "THUMBNAIL"
        $thumbnailCount += $count
    }
    else {
        $category = "UNKNOWN"
        $unknownCount += $count
        $unknownFiles += $group.Group
    }

    $color = switch ($category) {
        "IMAGE" { "Green" }
        "VIDEO" { "Cyan" }
        "XMP" { "Magenta" }
        "METADATA" { "Yellow" }
        "DATABASE" { "Blue" }
        "THUMBNAIL" { "Gray" }
        "UNKNOWN" { "Red" }
    }

    Write-Console ("  {0,-10} {1,10:N0}  [{2}]" -f $ext, $count, $category) -ForegroundColor $color
}

Write-Console ""
Write-Console "=== Summary by Category ===" -ForegroundColor Cyan
Write-Console ""
Write-Console ("  Images:          {0,10:N0}" -f $imageCount) -ForegroundColor Green
Write-Console ("  Videos:          {0,10:N0}" -f $videoCount) -ForegroundColor Cyan
Write-Console ("  XMP sidecars:    {0,10:N0}" -f $xmpCount) -ForegroundColor Magenta
Write-Console ("  Other metadata:  {0,10:N0}" -f $otherMetadata) -ForegroundColor Yellow
Write-Console ("  Database files:  {0,10:N0}" -f $databaseCount) -ForegroundColor Blue
Write-Console ("  Thumbnails:      {0,10:N0}" -f $thumbnailCount) -ForegroundColor Gray
Write-Console ("  Unknown types:   {0,10:N0}" -f $unknownCount) -ForegroundColor Red
Write-Console "  " + ("-" * 30)
Write-Console ("  TOTAL:           {0,10:N0}" -f $totalFiles) -ForegroundColor White
Write-Console ""

# Media files only (what Mylio tracks)
$mediaFiles = $imageCount + $videoCount
Write-Console "Media files (images + videos): $mediaFiles" -ForegroundColor Green
Write-Console "Database expects: 82,622" -ForegroundColor Cyan
Write-Console "Difference: $(82622 - $mediaFiles)" -ForegroundColor Yellow
Write-Console ""

# Show unknown files if any
if ($unknownCount -gt 0) {
    Write-Console "Unknown file types (sample of first 20):" -ForegroundColor Red
    $unknownFiles | Select-Object -First 20 | ForEach-Object {
        $relativePath = $_.FullName.Replace($mylioPath + "\", "")
        Write-Console ("  {0,-15} {1}" -f $_.Extension, $relativePath) -ForegroundColor Gray
    }
    Write-Console ""
}

# All files analysis
Write-Console "=== Accounting Analysis ===" -ForegroundColor Cyan
Write-Console ""
Write-Console "Total files on disk: $totalFiles" -ForegroundColor White
Write-Console "  Media files (images + videos): $mediaFiles" -ForegroundColor Green
Write-Console "  XMP sidecars: $xmpCount" -ForegroundColor Magenta
Write-Console "  Other files: $($totalFiles - $mediaFiles - $xmpCount)" -ForegroundColor Yellow
Write-Console ""
Write-Console "Database tracks: 82,622 media records" -ForegroundColor Cyan
Write-Console "Files on disk: $mediaFiles media files" -ForegroundColor Green
Write-Console "Missing: $(82622 - $mediaFiles) media files" -ForegroundColor Yellow
Write-Console ""
