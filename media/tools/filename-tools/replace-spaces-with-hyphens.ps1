#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Replaces spaces with hyphens in filenames.

.DESCRIPTION
    Scans a directory (and optionally subdirectories) for files containing spaces in their names
    and renames them by replacing spaces with hyphens.
    Example: "My Photo.jpg" -> "My-Photo.jpg"

.PARAMETER Path
    The directory to process. Defaults to current location.

.PARAMETER Recurse
    If set, processes subdirectories as well.

.PARAMETER FilesOnly
    If set, only renames files, ignoring directory names.

.PARAMETER WhatIf
    Preview the changes without actually renaming files.

.EXAMPLE
    .\replace-spaces-with-hyphens.ps1 -Path "D:\Photos" -Recurse -WhatIf
    Preview renaming all files in D:\Photos and subfolders.

.EXAMPLE
    .\replace-spaces-with-hyphens.ps1 -Path "D:\Photos"
    Rename files in the specified folder.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = ".",
    [switch]$Recurse,
    [switch]$FilesOnly
)

# Import shared utilities if available
$utilsPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $utilsPath) { . $utilsPath } else { function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor } }

Write-Console "Filename Space Replacement Tool" -ForegroundColor Cyan
Write-Console "===============================" -ForegroundColor Cyan
Write-Console ""

if (-not (Test-Path $Path)) {
    Write-Console "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

$searchOption = if ($Recurse) { "AllDirectories" } else { "TopDirectoryOnly" }
Write-Console "Scanning '$Path' for files with spaces..." -ForegroundColor Yellow
if ($Recurse) { Write-Console "  (Recursive scan enabled)" -ForegroundColor Gray }

# Gather items
$items = Get-ChildItem -Path $Path -Recurse:$Recurse | Where-Object { $_.Name -match ' ' }

if ($FilesOnly) {
    $items = $items | Where-Object { -not $_.PSIsContainer }
}

$total = $items.Count
Write-Console "Found $total items with spaces." -ForegroundColor $(if ($total -gt 0) { 'Green' } else { 'Yellow' })
Write-Console ""

if ($total -eq 0) {
    exit
}

if ($WhatIfPreference) {
    Write-Console "PREVIEW MODE (No changes will be made)" -ForegroundColor Yellow
    Write-Console ""
}

$renamed = 0
$errors = 0
$skipped = 0

foreach ($item in $items) {
    $newName = $item.Name.Replace(' ', '-')
    $newPath = Join-Path $item.DirectoryName $newName

    # Check for collision
    if (Test-Path $newPath) {
        Write-Console "SKIP: '$newName' already exists." -ForegroundColor Red
        $skipped++
        continue
    }

    if ($WhatIfPreference) {
        Write-Console "Rename: '$($item.Name)' -> '$newName'" -ForegroundColor Gray
        $renamed++
    } else {
        try {
            Rename-Item -Path $item.FullName -NewName $newName -ErrorAction Stop
            Write-Console "Renamed: '$($item.Name)' -> '$newName'" -ForegroundColor Green
            $renamed++
        } catch {
            Write-Console "ERROR: Failed to rename '$($item.Name)': $($_.Exception.Message)" -ForegroundColor Red
            $errors++
        }
    }
}

Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  Processed: $renamed" -ForegroundColor Green
Write-Console "  Skipped:   $skipped" -ForegroundColor Yellow
Write-Console "  Errors:    $errors" -ForegroundColor Red
