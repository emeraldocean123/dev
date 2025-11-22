# Dev Folder Cleanup Script
# Executes cleanup operations based on audit findings

[CmdletBinding()]
param(
    [switch]$WhatIf  # Dry run mode
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


$devPath = $devRoot
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Console "=== Dev Folder Cleanup ===" -ForegroundColor Cyan
Write-Console "Started: $timestamp" -ForegroundColor Gray
if ($WhatIf) {
    Write-Console "Mode: DRY RUN (no changes will be made)" -ForegroundColor Yellow
} else {
    Write-Console "Mode: EXECUTE (changes will be applied)" -ForegroundColor Red
}
Write-Console ""

$cleanupLog = @()

# Track statistics
$stats = @{
    FilesDeleted = 0
    FilesArchived = 0
    FilesMoved = 0
    DuplicatesRemoved = 0
    SpaceFreed = 0
}

## 1. Delete old report files (>30 days)
Write-Console "1. Cleaning up old report files..." -ForegroundColor Yellow

$reportFiles = Get-ChildItem -Path $devPath -Recurse -File | Where-Object {
    $_.Extension -eq '.txt' -and
    ($_.Name -match 'report-\d{4}-\d{2}-\d{2}' -or
     $_.Name -match 'scan-\d{4}-\d{2}-\d{2}')
}

foreach ($file in $reportFiles) {
    $age = ((Get-Date) - $file.LastWriteTime).Days

    if ($age -gt 30) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Console "  DELETE (>30 days): $($file.Name) ($sizeMB MB, $age days old)" -ForegroundColor Red

        if (-not $WhatIf) {
            Remove-Item $file.FullName -Force
            $stats.FilesDeleted++
            $stats.SpaceFreed += $file.Length
        }

        $cleanupLog += "Deleted old report: $($file.FullName) ($sizeMB MB, $age days old)"
    }
}

## 2. Archive recent report files
Write-Console "`n2. Archiving recent report files..." -ForegroundColor Yellow

$recentReports = $reportFiles | Where-Object {
    $age = ((Get-Date) - $_.LastWriteTime).Days
    $age -le 30
}

$archiveFolders = @{
    'applications\media-players' = 'applications\media-players\archive'
    'applications\media-players\mylio' = 'applications\media-players\mylio\archive'
    'photos\mylio' = 'photos\mylio\archive'
}

foreach ($file in $recentReports) {
    # Find appropriate archive folder
    $archiveFolder = $null
    foreach ($key in $archiveFolders.Keys) {
        if ($file.DirectoryName -match [regex]::Escape($key)) {
            $archiveFolder = Join-Path $devPath $archiveFolders[$key]
            break
        }
    }

    if ($archiveFolder) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Console "  ARCHIVE: $($file.Name) -> $($archiveFolder)" -ForegroundColor Cyan

        if (-not $WhatIf) {
            # Create archive folder if it doesn't exist
            if (-not (Test-Path $archiveFolder)) {
                New-Item -Path $archiveFolder -ItemType Directory -Force | Out-Null
            }

            # Move file
            Move-Item $file.FullName -Destination $archiveFolder -Force
            $stats.FilesArchived++
        }

        $cleanupLog += "Archived report: $($file.Name) -> $archiveFolder"
    }
}

## 3. Delete files without extensions (excluding standard files)
Write-Console "`n3. Removing files without extensions..." -ForegroundColor Yellow

# Standard files that legitimately have no extension
$excludeNames = @('LICENSE', 'README', 'Makefile', 'Dockerfile', 'Jenkinsfile', 'Vagrantfile', 'Gemfile', 'Procfile')

$noExtFiles = Get-ChildItem -Path $devPath -Recurse -File | Where-Object {
    $_.Extension -eq '' -and $_.Name -notin $excludeNames
}

foreach ($file in $noExtFiles) {
    Write-Console "  DELETE: $($file.FullName)" -ForegroundColor Red

    if (-not $WhatIf) {
        Remove-Item $file.FullName -Force
        $stats.FilesDeleted++
        $stats.SpaceFreed += $file.Length
    }

    $cleanupLog += "Deleted file without extension: $($file.FullName)"
}

## 4. Remove duplicate scripts (keep optimized/latest versions)
Write-Console "`n4. Removing duplicate scripts..." -ForegroundColor Yellow

$duplicateGroups = @{
    'fix-exif-from-filename' = @{
        Keep = 'fix-exif-from-filename-optimized.ps1'
        Remove = @('fix-exif-from-filename.ps1')
        Location = 'applications\media-players\mylio'
    }
    'fix-exif-oldest-date' = @{
        Keep = 'fix-exif-oldest-date-optimized.ps1'
        Remove = @('fix-exif-oldest-date.ps1')
        Location = 'applications\media-players\mylio'
    }
    'clean-mylio-metadata' = @{
        Keep = 'clean-mylio-metadata-v2.ps1'
        Remove = @('clean-mylio-metadata.ps1')
        Location = 'photos\mylio'
    }
}

foreach ($groupName in $duplicateGroups.Keys) {
    $group = $duplicateGroups[$groupName]
    $location = Join-Path $devPath $group.Location

    foreach ($fileName in $group.Remove) {
        $filePath = Join-Path $location $fileName

        if (Test-Path $filePath) {
            $file = Get-Item $filePath
            $sizeMB = [math]::Round($file.Length / 1KB, 1)
            Write-Console "  DELETE DUPLICATE: $fileName (keeping $($group.Keep))" -ForegroundColor Red

            if (-not $WhatIf) {
                Remove-Item $filePath -Force
                $stats.DuplicatesRemoved++
                $stats.SpaceFreed += $file.Length
            }

            $cleanupLog += "Removed duplicate: $fileName (kept $($group.Keep))"
        }
    }
}

# Handle the special case: convert-mylio-videos.ps1 duplicates in different locations
Write-Console "  Checking convert-mylio-videos.ps1 duplicates..." -ForegroundColor Gray
$convertVideos = Get-ChildItem -Path $devPath -Recurse -Filter "convert-mylio-videos.ps1" -File

if ($convertVideos.Count -gt 1) {
    # Keep the most recent one
    $keepFile = $convertVideos | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $removeFiles = $convertVideos | Where-Object { $_.FullName -ne $keepFile.FullName }

    foreach ($file in $removeFiles) {
        Write-Console "  DELETE DUPLICATE: $($file.FullName) (keeping $($keepFile.FullName))" -ForegroundColor Red

        if (-not $WhatIf) {
            Remove-Item $file.FullName -Force
            $stats.DuplicatesRemoved++
            $stats.SpaceFreed += $file.Length
        }

        $cleanupLog += "Removed duplicate convert-mylio-videos.ps1: $($file.FullName)"
    }
}

## 5. Summary
Write-Console "`n=== Cleanup Complete ===" -ForegroundColor Green
Write-Console ""
Write-Console "Statistics:" -ForegroundColor Cyan
Write-Console "  Files deleted: $($stats.FilesDeleted)" -ForegroundColor Gray
Write-Console "  Files archived: $($stats.FilesArchived)" -ForegroundColor Gray
Write-Console "  Files moved: $($stats.FilesMoved)" -ForegroundColor Gray
Write-Console "  Duplicates removed: $($stats.DuplicatesRemoved)" -ForegroundColor Gray
Write-Console "  Space freed: $([math]::Round($stats.SpaceFreed / 1MB, 2)) MB" -ForegroundColor Gray
Write-Console ""

if ($WhatIf) {
    Write-Console "DRY RUN COMPLETE - No changes were made" -ForegroundColor Yellow
    Write-Console "To execute cleanup, run:" -ForegroundColor Yellow
    Write-Console "  .\cleanup-dev-folder.ps1" -ForegroundColor Cyan
} else {
    Write-Console "CLEANUP EXECUTED - Changes have been applied" -ForegroundColor Green

    # Save cleanup log
    $logPath = Join-Path $devRoot "documentation\audits\cleanup-log-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    $cleanupLog | Out-File -FilePath $logPath -Encoding UTF8
    Write-Console "Cleanup log saved to: $logPath" -ForegroundColor Cyan
}
Write-Console ""
