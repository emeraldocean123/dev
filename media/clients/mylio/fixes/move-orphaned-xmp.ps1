# Move Orphaned XMP Files
# Moves orphaned XMP sidecar files to Mylio-Moved-XMP folder, preserving folder structure

param(
    [switch]$DryRun = $false
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$sourceRoot = "D:\Mylio"
$destRoot = "D:\Mylio-Moved-XMP"
$orphanedListFile = "C:\Users\josep\Documents\dev\photos\mylio\archive\orphaned-xmp-2025-11-13-085104.txt"
$logFile = "C:\Users\josep\Documents\dev\photos\mylio\moved-xmp-log.txt"

Write-Console "=== Move Orphaned XMP Files ===" -ForegroundColor Cyan
Write-Console ""

if ($DryRun) {
    Write-Console "DRY RUN MODE - No files will be moved" -ForegroundColor Yellow
    Write-Console ""
}

# Check if orphaned list file exists
if (-not (Test-Path $orphanedListFile)) {
    Write-Console "ERROR: Orphaned list file not found: $orphanedListFile" -ForegroundColor Red
    exit 1
}

# Read orphaned files from the list (skip header lines)
Write-Console "Reading orphaned file list..." -ForegroundColor Yellow
$orphanedFiles = Get-Content $orphanedListFile |
    Where-Object { $_ -match '^D:\\Mylio\\' } |
    ForEach-Object { $_.Trim() }

if ($orphanedFiles.Count -eq 0) {
    Write-Console "No orphaned files found in list" -ForegroundColor Yellow
    exit 0
}

Write-Console "Found $($orphanedFiles.Count) orphaned XMP files to move" -ForegroundColor Green
Write-Console ""

# Verify all files still exist
Write-Console "Verifying files exist..." -ForegroundColor Yellow
$existingFiles = @()
$missingFiles = @()

foreach ($file in $orphanedFiles) {
    if (Test-Path $file) {
        $existingFiles += $file
    } else {
        $missingFiles += $file
    }
}

Write-Console "  Existing: $($existingFiles.Count)" -ForegroundColor Green
if ($missingFiles.Count -gt 0) {
    Write-Console "  Missing: $($missingFiles.Count)" -ForegroundColor Yellow
}
Write-Console ""

if ($existingFiles.Count -eq 0) {
    Write-Console "No files to move (all missing)" -ForegroundColor Yellow
    exit 0
}

# Create destination root if it doesn't exist
if (-not $DryRun) {
    if (-not (Test-Path $destRoot)) {
        New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
        Write-Console "Created destination root: $destRoot" -ForegroundColor Green
    }
}

# Move files
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$moved = 0
$failed = 0
$logEntries = @()

Write-Console "Moving files..." -ForegroundColor Cyan
Write-Console ""

foreach ($sourcePath in $existingFiles) {
    # Calculate relative path from source root
    $relativePath = $sourcePath.Substring($sourceRoot.Length + 1)
    $destPath = Join-Path $destRoot $relativePath
    $destDir = Split-Path $destPath -Parent

    try {
        if (-not $DryRun) {
            # Create destination directory if needed
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            # Move file
            Move-Item -Path $sourcePath -Destination $destPath -Force

            # Log entry
            $logEntries += "$timestamp | MOVED | $relativePath"
            $moved++

            Write-Console "  Moved: $relativePath" -ForegroundColor Green
        } else {
            Write-Console "  [DRY RUN] Would move: $relativePath" -ForegroundColor Yellow
            $moved++
        }
    } catch {
        $failed++
        $logEntries += "$timestamp | FAILED | $relativePath | Error: $($_.Exception.Message)"
        Write-Console "  FAILED: $relativePath" -ForegroundColor Red
        Write-Console "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Console ""

# Write log file
if (-not $DryRun -and $logEntries.Count -gt 0) {
    Write-Console "Writing log file..." -ForegroundColor Yellow

    # Add header if this is a new log session
    $logHeader = @(
        "",
        "=== Move Orphaned XMP Files Session ===",
        "Session Date: $timestamp",
        "Source: $sourceRoot",
        "Destination: $destRoot",
        "Files Processed: $($existingFiles.Count)",
        "Successfully Moved: $moved",
        "Failed: $failed",
        ""
    )

    # Append to existing log or create new
    if (Test-Path $logFile) {
        Add-Content -Path $logFile -Value $logHeader
        Add-Content -Path $logFile -Value $logEntries
    } else {
        Set-Content -Path $logFile -Value $logHeader
        Add-Content -Path $logFile -Value $logEntries
    }

    Write-Console "  Log written to: $logFile" -ForegroundColor Green
}

# Summary
Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Console "  DRY RUN - No files were moved" -ForegroundColor Yellow
} else {
    Write-Console "  Successfully moved: $moved files" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Console "  Failed: $failed files" -ForegroundColor Red
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Console "  Files already missing: $($missingFiles.Count)" -ForegroundColor Yellow
}

Write-Console ""
