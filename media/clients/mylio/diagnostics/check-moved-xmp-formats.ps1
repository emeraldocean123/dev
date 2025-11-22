# Check what formats the moved XMP files were actually for

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$movedXmpPath = "D:\Mylio-Moved-XMP"
$mylioPath = "D:\Mylio"

# All possible media extensions
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw', '.bmp', '.gif', '.webp')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv', '.flv', '.webm', '.3g2')
$allExtensions = $imageExtensions + $videoExtensions

Write-Console "=== Checking Moved XMP Files ===" -ForegroundColor Cyan
Write-Console ""

# Get all moved XMP files
$movedXmpFiles = Get-ChildItem -Path $movedXmpPath -Filter "*.xmp" -Recurse -File

Write-Console "Total moved XMP files: $($movedXmpFiles.Count)" -ForegroundColor Yellow
Write-Console ""

$foundMatches = @()
$stillOrphaned = @()

foreach ($xmpFile in $movedXmpFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($xmpFile.FullName)
    $directory = $xmpFile.DirectoryName

    # Calculate the original vault directory
    $relativePath = $directory.Replace($movedXmpPath, "").TrimStart('\')
    $originalDir = Join-Path $mylioPath $relativePath

    $foundMatch = $false
    $matchedFile = ""

    # Check all possible extensions
    foreach ($ext in $allExtensions) {
        $possibleFile = Join-Path $originalDir "$baseName$ext"
        if (Test-Path $possibleFile) {
            $foundMatch = $true
            $matchedFile = $possibleFile
            $foundMatches += [PSCustomObject]@{
                XMPFile = $xmpFile.FullName
                MatchedFile = $matchedFile
                Extension = $ext
            }
            break
        }
    }

    if (-not $foundMatch) {
        $stillOrphaned += $xmpFile.FullName
    }
}

Write-Console "=== Results ===" -ForegroundColor Cyan
Write-Console ""
Write-Console "Files with matches found: $($foundMatches.Count)" -ForegroundColor Green
Write-Console "Still orphaned: $($stillOrphaned.Count)" -ForegroundColor Yellow
Write-Console ""

if ($foundMatches.Count -gt 0) {
    Write-Console "=== Matches Found (should be restored!) ===" -ForegroundColor Green
    Write-Console ""

    # Group by extension
    $byExtension = $foundMatches | Group-Object Extension | Sort-Object Count -Descending

    foreach ($group in $byExtension) {
        Write-Console "$($group.Name) files: $($group.Count)" -ForegroundColor Cyan
        foreach ($match in $group.Group) {
            $relativePath = $match.XMPFile.Replace($movedXmpPath + "\", "")
            Write-Console "  $relativePath" -ForegroundColor Gray
        }
        Write-Console ""
    }
}

if ($stillOrphaned.Count -gt 0) {
    Write-Console "=== Still Orphaned (no matching media file) ===" -ForegroundColor Yellow
    Write-Console ""
    foreach ($orphan in $stillOrphaned) {
        $relativePath = $orphan.Replace($movedXmpPath + "\", "")
        Write-Console "  $relativePath" -ForegroundColor Gray
    }
    Write-Console ""
}

Write-Console "=== Summary ===" -ForegroundColor Cyan
Write-Console ""
if ($foundMatches.Count -gt 0) {
    Write-Console "IMPORTANT: $($foundMatches.Count) XMP files have matching media files!" -ForegroundColor Red
    Write-Console "These should be moved back to the vault." -ForegroundColor Red
    Write-Console ""
    Write-Console "Would you like to create a script to restore them? (Y/N)" -ForegroundColor Yellow
}
Write-Console ""
