# Analyze unknown file types in detail

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

Write-Console "=== Detailed Unknown Files Analysis ===" -ForegroundColor Cyan
Write-Console ""

# Get all files excluding known media/XMP
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw', '.bmp', '.gif', '.webp')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv', '.flv', '.webm', '.3g2')

$unknownFiles = Get-ChildItem -Path $mylioPath -Recurse -File | Where-Object {
    $_.FullName -notlike "*Mylio-Moved-XMP*" -and
    $_.Extension -ne '.xmp' -and
    $imageExtensions -notcontains $_.Extension.ToLower() -and
    $videoExtensions -notcontains $_.Extension.ToLower()
}

# Group by extension
$byExtension = $unknownFiles | Group-Object Extension | Sort-Object Count -Descending

foreach ($group in $byExtension) {
    $ext = $group.Name
    $count = $group.Count

    Write-Console "=== $ext files ($count total) ===" -ForegroundColor Yellow
    Write-Console ""

    # Show all files for this extension
    $group.Group | ForEach-Object {
        $relativePath = $_.FullName.Replace($mylioPath + "\", "")
        $size = "{0:N0} KB" -f ($_.Length / 1KB)
        $created = $_.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
        $modified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        Write-Console "  Path: $relativePath" -ForegroundColor White
        Write-Console "  Size: $size" -ForegroundColor Gray
        Write-Console "  Created: $created" -ForegroundColor Gray
        Write-Console "  Modified: $modified" -ForegroundColor Gray
        Write-Console "  Full path: $($_.FullName)" -ForegroundColor Cyan
        Write-Console ""
    }
}

Write-Console "=== Summary ===" -ForegroundColor Cyan
Write-Console "Total unknown files: $($unknownFiles.Count)" -ForegroundColor Yellow
Write-Console ""
