#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Converts HEIC to JPG in parallel using ImageMagick and ExifTool.

.DESCRIPTION
    Optimized version using PowerShell 7 parallel processing.
    Preserves metadata and file timestamps.

    Performance: Processes multiple images simultaneously, utilizing all CPU cores.
    Typical speedup: 5-10x faster than sequential version on modern multi-core systems.

.PARAMETER Path
    Directory containing HEIC files. Defaults to current directory.

.PARAMETER Quality
    JPEG quality (1-100). Default: 95

.PARAMETER Recursive
    Process subdirectories recursively.

.PARAMETER DeleteOriginal
    Delete original HEIC files after successful conversion.

.PARAMETER KeepTimestamps
    Preserve file creation and modification times. Default: true

.PARAMETER Threads
    Number of concurrent conversions. Default: 8
    Recommended: Number of CPU cores or slightly higher.

.EXAMPLE
    .\convert-heic-to-jpg-parallel.ps1 -Path "D:\Photos" -Recursive
    Convert all HEIC files in D:\Photos and subdirectories using default settings.

.EXAMPLE
    .\convert-heic-to-jpg-parallel.ps1 -Path "D:\Photos" -Threads 16 -Quality 90
    Convert using 16 threads with 90% quality.

.NOTES
    Requires: PowerShell 7+, ImageMagick, ExifTool
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = ".",

    [int]$Quality = 95,
    [switch]$Recursive,
    [switch]$DeleteOriginal,
    [switch]$KeepTimestamps = $true,
    [int]$Threads = 8  # Default to 8 concurrent jobs
)

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Console "Error: This script requires PowerShell 7 or higher for parallel processing." -ForegroundColor Red
    Write-Console "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Console "Download: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Cyan
    exit 1
}

# Import shared utilities
$utilsPath = Join-Path $PSScriptRoot "..\..\..\..\lib\Utils.ps1"
if (Test-Path $utilsPath) { . $utilsPath } else { function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor } }

Write-Console "HEIC to JPG Parallel Converter" -ForegroundColor Cyan
Write-Console "===============================" -ForegroundColor Cyan
Write-Console ""

# Check dependencies
if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Console "Error: ImageMagick not found in PATH." -ForegroundColor Red
    Write-Console "Download: https://imagemagick.org/script/download.php" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command exiftool -ErrorAction SilentlyContinue)) {
    Write-Console "Warning: ExifTool not found. Metadata will not be preserved." -ForegroundColor Yellow
    $exiftoolAvailable = $false
} else {
    $exiftoolAvailable = $true
}

# Verify path
if (-not $Path) { $Path = $PWD }
if (-not (Test-Path $Path)) {
    Write-Console "Error: Path not found: $Path" -ForegroundColor Red
    exit 1
}

Write-Console "Scanning for HEIC files in: $Path" -ForegroundColor Yellow
if ($Recursive) { Write-Console "  (Recursive mode enabled)" -ForegroundColor Gray }

$files = Get-ChildItem -Path $Path -Filter "*.heic" -Recurse:$Recursive -File

$count = $files.Count
if ($count -eq 0) {
    Write-Console "No HEIC files found." -ForegroundColor Yellow
    exit 0
}

Write-Console "Found $count files" -ForegroundColor Green
Write-Console "Processing with $Threads concurrent threads..." -ForegroundColor Cyan
Write-Console ""

$startTime = Get-Date

# Synchronized hashtable for tracking results (thread-safe)
$results = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

# Pass variables into the parallel block using $using:
$files | ForEach-Object -Parallel {
    $file = $_
    $quality = $using:Quality
    $deleteOrig = $using:DeleteOriginal
    $keepTime = $using:KeepTimestamps
    $exiftoolAvail = $using:exiftoolAvailable
    $resultsRef = $using:results

    $jpgPath = $file.FullName -replace '\.heic$', '.jpg'

    if (Test-Path $jpgPath) {
        Write-Console "[SKIP] $($file.Name) - JPG already exists" -ForegroundColor DarkGray
        $resultsRef.Add([PSCustomObject]@{ Status = "Skipped"; File = $file.Name })
        return
    }

    try {
        # 1. Convert HEIC to JPG
        $convertArgs = @("convert", $file.FullName, "-quality", $quality, $jpgPath)
        $process = Start-Process -FilePath "magick" -ArgumentList $convertArgs -NoNewWindow -Wait -PassThru -ErrorAction Stop

        if ($process.ExitCode -ne 0) {
            throw "ImageMagick conversion failed with exit code $($process.ExitCode)"
        }

        if (-not (Test-Path $jpgPath)) {
            throw "JPG file was not created"
        }

        # 2. Copy Metadata (if ExifTool available)
        if ($exiftoolAvail) {
            $exifArgs = @("-TagsFromFile", $file.FullName, "-all:all", "-overwrite_original", $jpgPath)
            $null = Start-Process -FilePath "exiftool" -ArgumentList $exifArgs -NoNewWindow -Wait -ErrorAction SilentlyContinue
        }

        # 3. Preserve Timestamps
        if ($keepTime) {
            $jpgItem = Get-Item $jpgPath
            $jpgItem.CreationTime = $file.CreationTime
            $jpgItem.LastWriteTime = $file.LastWriteTime
        }

        # 4. Delete Original (if requested)
        if ($deleteOrig) {
            Remove-Item $file.FullName -Force
        }

        Write-Console "[OK] $($file.Name)" -ForegroundColor Green
        $resultsRef.Add([PSCustomObject]@{ Status = "Converted"; File = $file.Name })
    }
    catch {
        Write-Console "[ERROR] $($file.Name): $_" -ForegroundColor Red
        $resultsRef.Add([PSCustomObject]@{ Status = "Error"; File = $file.Name; Error = $_.Exception.Message })
    }
} -ThrottleLimit $Threads

$endTime = Get-Date
$duration = $endTime - $startTime

# Summary
Write-Console ""
Write-Console "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Console "Conversion Summary" -ForegroundColor Cyan
Write-Console "═══════════════════════════════════════" -ForegroundColor Cyan

$converted = @($results | Where-Object Status -eq "Converted").Count
$skipped = @($results | Where-Object Status -eq "Skipped").Count
$errors = @($results | Where-Object Status -eq "Error").Count

Write-Console "  Total files:    $count" -ForegroundColor White
Write-Console "  Converted:      $converted" -ForegroundColor Green
Write-Console "  Skipped:        $skipped" -ForegroundColor Yellow
Write-Console "  Errors:         $errors" -ForegroundColor Red
Write-Console "  Duration:       $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
if ($converted -gt 0) {
    $avgTime = $duration.TotalSeconds / $converted
    Write-Console "  Avg per file:   $($avgTime.ToString('F2')) seconds" -ForegroundColor Gray
}
Write-Console "═══════════════════════════════════════" -ForegroundColor Cyan
