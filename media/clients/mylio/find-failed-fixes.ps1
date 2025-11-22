param(
    [string]$Path = "D:\Mylio"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Finding Files That Failed to Fix" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Find exiftool
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
if (-not (Test-Path $exiftoolPath)) {
    $exiftoolPath = (Get-Command exiftool -ErrorAction SilentlyContinue).Source
    if (-not $exiftoolPath) {
        Write-Console "ERROR: ExifTool not found!" -ForegroundColor Red
        exit 1
    }
}

# Pattern to match Mylio date-based filenames
$datePattern = '^(\d{4})-(\d{2})-(\d{2})-'

# Get all media files
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.mov', '*.mp4', '*.avi', '*.m4v', '*.3gp')
Write-Console "Scanning for media files..." -ForegroundColor Gray
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

$total = $files.Count
$checked = 0
$stillMismatched = 0
$failedFiles = @()

Write-Console "Checking $total files for remaining mismatches..." -ForegroundColor Yellow
Write-Console ""

foreach ($file in $files) {
    $checked++

    if ($checked % 1000 -eq 0) {
        $percent = [math]::Round(($checked / $total) * 100, 1)
        Write-Console "`rProgress: $checked / $total ($percent%)" -NoNewline -ForegroundColor Gray
    }

    # Check if filename matches date pattern
    if ($file.Name -notmatch $datePattern) {
        continue
    }

    $filenameYear = [int]$matches[1]
    $filenameMonth = [int]$matches[2]
    $filenameDay = [int]$matches[3]

    # Get current EXIF DateTimeOriginal
    try {
        $exifOutput = & $exiftoolPath -s -s -s -DateTimeOriginal "$($file.FullName)" 2>$null

        if ($exifOutput -and $exifOutput -match '^(\d{4}):(\d{2}):(\d{2})') {
            $exifYear = [int]$matches[1]
            $exifMonth = [int]$matches[2]
            $exifDay = [int]$matches[3]

            # Check if dates STILL don't match (meaning the fix failed)
            if ($filenameYear -ne $exifYear -or $filenameMonth -ne $exifMonth -or $filenameDay -ne $exifDay) {
                $stillMismatched++

                $failedFiles += [PSCustomObject]@{
                    FileName = $file.Name
                    FullPath = $file.FullName
                    FilenameDate = "$filenameYear-$($filenameMonth.ToString('00'))-$($filenameDay.ToString('00'))"
                    ExifDate = "$exifYear-$($exifMonth.ToString('00'))-$($exifDay.ToString('00'))"
                    Extension = $file.Extension.ToLower()
                }
            }
        }
    }
    catch {
        # Ignore read errors for now
    }
}

Write-Console "`n"
Write-Console ""
Write-Console "Results:" -ForegroundColor Cyan
Write-Console "  Files still mismatched: $stillMismatched" -ForegroundColor Yellow
Write-Console ""

if ($stillMismatched -gt 0) {
    Write-Console "Failed Files by Extension:" -ForegroundColor Cyan
    $failedFiles | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object {
        Write-Console "  $($_.Name): $($_.Count) files" -ForegroundColor White
    }
    Write-Console ""

    # Show first 20 examples
    Write-Console "First 20 Examples:" -ForegroundColor Cyan
    $failedFiles | Select-Object -First 20 | ForEach-Object {
        Write-Console "  $($_.FileName)" -ForegroundColor White
        Write-Console "    Filename date: $($_.FilenameDate)" -ForegroundColor Gray
        Write-Console "    EXIF date:     $($_.ExifDate)" -ForegroundColor Gray
        Write-Console "    Path: $($_.FullPath)" -ForegroundColor DarkGray
        Write-Console ""
    }

    # Save full list to file
    $reportPath = "C:\Users\josep\Documents\dev\applications\media-players\mylio\failed-fixes-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    $failedFiles | ForEach-Object {
        "$($_.FileName)`t$($_.FilenameDate)`t$($_.ExifDate)`t$($_.FullPath)"
    } | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Console "Full list saved to: $reportPath" -ForegroundColor Green
}
else {
    Write-Console "All files have been successfully fixed!" -ForegroundColor Green
}

Write-Console ""
