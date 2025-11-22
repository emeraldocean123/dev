# Restore all moved XMP files back to Mylio vault

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
$logFile = Join-Path $movedXmpPath "moved-xmp-log.txt"

# All possible media extensions
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw', '.bmp', '.gif', '.webp')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv', '.flv', '.webm', '.3g2')
$allExtensions = $imageExtensions + $videoExtensions

Write-Console "=== Restoring Moved XMP Files ===" -ForegroundColor Cyan
Write-Console ""

# Get all moved XMP files
$movedXmpFiles = Get-ChildItem -Path $movedXmpPath -Filter "*.xmp" -Recurse -File

Write-Console "Total moved XMP files to restore: $($movedXmpFiles.Count)" -ForegroundColor Yellow
Write-Console ""

$restored = @()
$failed = @()
$noMatch = @()

foreach ($xmpFile in $movedXmpFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($xmpFile.FullName)
    $directory = $xmpFile.DirectoryName

    # Calculate the original vault directory
    $relativePath = $directory.Replace($movedXmpPath, "").TrimStart('\')
    $originalDir = Join-Path $mylioPath $relativePath

    # Find matching media file
    $foundMatch = $false
    $matchedFile = ""
    $matchedExt = ""

    foreach ($ext in $allExtensions) {
        $possibleFile = Join-Path $originalDir "$baseName$ext"
        if (Test-Path $possibleFile) {
            $foundMatch = $true
            $matchedFile = $possibleFile
            $matchedExt = $ext
            break
        }
    }

    if ($foundMatch) {
        # Restore XMP file to original location
        $destPath = Join-Path $originalDir "$baseName.xmp"

        try {
            # Ensure destination directory exists
            if (-not (Test-Path $originalDir)) {
                New-Item -ItemType Directory -Path $originalDir -Force | Out-Null
            }

            # Move XMP file back
            Move-Item -Path $xmpFile.FullName -Destination $destPath -Force

            $restored += [PSCustomObject]@{
                XMPFile = $destPath
                MatchedFile = $matchedFile
                Extension = $matchedExt
                RelativePath = $relativePath
            }

            Write-Console "Restored: $relativePath\$baseName.xmp -> $matchedExt" -ForegroundColor Green

        } catch {
            $failed += [PSCustomObject]@{
                XMPFile = $xmpFile.FullName
                Error = $_.Exception.Message
            }
            Write-Console "Failed: $relativePath\$baseName.xmp - $($_.Exception.Message)" -ForegroundColor Red
        }

    } else {
        $noMatch += $xmpFile.FullName
        Write-Console "No match: $relativePath\$baseName.xmp" -ForegroundColor Yellow
    }
}

Write-Console ""
Write-Console "=== Restoration Summary ===" -ForegroundColor Cyan
Write-Console ""
Write-Console "Successfully restored: $($restored.Count)" -ForegroundColor Green
Write-Console "Failed to restore: $($failed.Count)" -ForegroundColor Red
Write-Console "No matching media file: $($noMatch.Count)" -ForegroundColor Yellow
Write-Console ""

# Log restoration
if ($restored.Count -gt 0) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path $logFile -Value ""
    Add-Content -Path $logFile -Value "=== RESTORATION - $timestamp ==="
    Add-Content -Path $logFile -Value "Restored $($restored.Count) XMP files back to Mylio vault"
    Add-Content -Path $logFile -Value ""

    # Group by extension
    $byExtension = $restored | Group-Object Extension | Sort-Object Count -Descending

    foreach ($group in $byExtension) {
        Add-Content -Path $logFile -Value "$($group.Name) files: $($group.Count)"
        foreach ($item in $group.Group) {
            $xmpFileName = [System.IO.Path]::GetFileNameWithoutExtension($item.XMPFile)
            Add-Content -Path $logFile -Value "  RESTORED: $($item.RelativePath)\$xmpFileName.xmp -> $($item.Extension)"
        }
        Add-Content -Path $logFile -Value ""
    }

    Write-Console "Restoration logged to: $logFile" -ForegroundColor Gray
}

# Report breakdown by extension
if ($restored.Count -gt 0) {
    Write-Console "=== Restored Files by Format ===" -ForegroundColor Cyan
    Write-Console ""

    $byExtension = $restored | Group-Object Extension | Sort-Object Count -Descending

    foreach ($group in $byExtension) {
        Write-Console "$($group.Name): $($group.Count) XMP files" -ForegroundColor Cyan
    }
    Write-Console ""
}

# Verify empty directories in moved location
Write-Console "=== Cleanup Check ===" -ForegroundColor Cyan
Write-Console ""

$emptyDirs = Get-ChildItem -Path $movedXmpPath -Directory -Recurse | Where-Object {
    (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0
}

if ($emptyDirs.Count -gt 0) {
    Write-Console "Found $($emptyDirs.Count) empty directories in moved location" -ForegroundColor Yellow
    Write-Console "You can safely delete these empty folders" -ForegroundColor Gray
} else {
    Write-Console "No empty directories found" -ForegroundColor Green
}

Write-Console ""

# Final verification
Write-Console "=== Final Verification ===" -ForegroundColor Cyan
Write-Console ""

$remainingXmp = Get-ChildItem -Path $movedXmpPath -Filter "*.xmp" -Recurse -File

if ($remainingXmp.Count -eq 0) {
    Write-Console "SUCCESS: All XMP files have been restored!" -ForegroundColor Green
    Write-Console "The Mylio-Moved-XMP folder now contains only the log file" -ForegroundColor Gray
} else {
    Write-Console "WARNING: $($remainingXmp.Count) XMP files remain in Mylio-Moved-XMP" -ForegroundColor Yellow
    Write-Console "These files may not have matching media files" -ForegroundColor Gray
}

Write-Console ""
