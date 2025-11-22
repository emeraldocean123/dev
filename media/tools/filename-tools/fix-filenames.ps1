#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Batch rename files to add date separators for better readability

.DESCRIPTION
    Renames files from:
        20041128_175354_IMG_uuid.jpg
    To:
        2004-11-28_17-53-54_IMG_uuid.jpg

.PARAMETER Path
    Root directory to process (default: D:\Media Library)

.PARAMETER WhatIf
    Preview changes without actually renaming

.EXAMPLE
    .\fix-filenames.ps1 -WhatIf
    Preview all renames

.EXAMPLE
    .\fix-filenames.ps1
    Perform the renames
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = "D:\Media Library"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
# Pattern to match current filename format: YYYYMMDD_HHMMSS_TYPE_UUID.ext
$pattern = '^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})_(IMG|VID)_(.+)(\..+)$'

Write-Console "=" * 70 -ForegroundColor Cyan
Write-Console "Filename Separator Fix" -ForegroundColor Cyan
Write-Console "=" * 70 -ForegroundColor Cyan
Write-Console ""
Write-Console "Converting filenames from:" -ForegroundColor Yellow
Write-Console "  20041128_175354_IMG_uuid.jpg" -ForegroundColor Gray
Write-Console "To:" -ForegroundColor Yellow
Write-Console "  2004-11-28_17-53-54_IMG_uuid.jpg" -ForegroundColor Green
Write-Console ""

if ($WhatIfPreference) {
    Write-Console "PREVIEW MODE - No files will be renamed" -ForegroundColor Yellow
    Write-Console ""
}

# Count files first
Write-Console "Scanning for files to rename..." -ForegroundColor Cyan
$filesToRename = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
    $_.Name -match $pattern
}

$totalFiles = $filesToRename.Count
Write-Console "Found $($totalFiles.ToString('N0')) files to rename" -ForegroundColor Green
Write-Console ""

if ($totalFiles -eq 0) {
    Write-Console "No files need renaming!" -ForegroundColor Yellow
    exit 0
}

# Estimate time
$estimatedSeconds = [math]::Ceiling($totalFiles / 500)  # ~500 renames/sec
$estimatedMinutes = [math]::Ceiling($estimatedSeconds / 60)

Write-Console "Estimated time: " -NoNewline
if ($estimatedMinutes -lt 1) {
    Write-Console "$estimatedSeconds seconds" -ForegroundColor Cyan
} else {
    Write-Console "$estimatedMinutes minutes ($estimatedSeconds seconds)" -ForegroundColor Cyan
}
Write-Console ""

# Confirm
if (-not $WhatIfPreference) {
    $confirm = Read-Host "Proceed with renaming $($totalFiles.ToString('N0')) files? (y/n)"
    if ($confirm -ne 'y') {
        Write-Console "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Console ""
}

# Perform renames
$renamed = 0
$errors = 0
$startTime = Get-Date

Write-Console "Processing files..." -ForegroundColor Cyan
Write-Console ""

$progressParams = @{
    Activity = "Renaming files"
    Status = "Processing..."
    PercentComplete = 0
}

foreach ($file in $filesToRename) {
    # Update progress every 100 files
    if ($renamed % 100 -eq 0) {
        $progressParams.PercentComplete = ($renamed / $totalFiles) * 100
        $progressParams.Status = "Renamed: $($renamed.ToString('N0')) / $($totalFiles.ToString('N0'))"
        Write-Progress @progressParams
    }

    if ($file.Name -match $pattern) {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]
        $hour = $matches[4]
        $minute = $matches[5]
        $second = $matches[6]
        $type = $matches[7]
        $uuid = $matches[8]
        $ext = $matches[9]

        $newName = "$year-$month-$day`_$hour-$minute-$second`_$type`_$uuid$ext"
        $newPath = Join-Path $file.Directory $newName

        try {
            if ($WhatIfPreference) {
                Write-Console "Would rename: $($file.Name) -> $newName" -ForegroundColor Gray
                $renamed++
            } else {
                Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                $renamed++
            }
        } catch {
            Write-Console "ERROR: Failed to rename $($file.Name): $_" -ForegroundColor Red
            $errors++
        }
    }
}

Write-Progress -Activity "Renaming files" -Completed

$endTime = Get-Date
$duration = $endTime - $startTime
$actualSeconds = [math]::Ceiling($duration.TotalSeconds)
$filesPerSec = [math]::Round($renamed / $duration.TotalSeconds, 2)

Write-Console ""
Write-Console "=" * 70 -ForegroundColor Cyan
Write-Console "COMPLETE" -ForegroundColor Green
Write-Console "=" * 70 -ForegroundColor Cyan
Write-Console ""
Write-Console "Files renamed:    $($renamed.ToString('N0'))" -ForegroundColor Green
if ($errors -gt 0) {
    Write-Console "Errors:           $errors" -ForegroundColor Red
}
Write-Console "Duration:         $actualSeconds seconds" -ForegroundColor Cyan
Write-Console "Speed:            $filesPerSec files/sec" -ForegroundColor Cyan
Write-Console ""

if (-not $WhatIfPreference) {
    Write-Console "All files have been renamed!" -ForegroundColor Green
    Write-Console "New format: YYYY-MM-DD_HH-MM-SS_TYPE_UUID.ext" -ForegroundColor Cyan
} else {
    Write-Console "Preview complete - no files were modified" -ForegroundColor Yellow
}
