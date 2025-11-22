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
Write-Console "Scanning for date corruption in Mylio-renamed files..." -ForegroundColor Cyan
Write-Console "Path: $Path" -ForegroundColor Gray
Write-Console ""

# Pattern to match Mylio date-based filenames: YYYY-MM-DD-*.ext
$datePattern = '^(\d{4})-(\d{2})-(\d{2})-'

# Get all image/video files
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.mov', '*.mp4', '*.avi')
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

$corrupted = @()
$processed = 0
$total = $files.Count

Write-Console "Found $total files to check" -ForegroundColor Yellow
Write-Console ""

foreach ($file in $files) {
    $processed++

    # Progress indicator
    if ($processed % 100 -eq 0) {
        $percent = [math]::Round(($processed / $total) * 100, 1)
        Write-Console "`rProgress: $processed / $total ($percent%)" -NoNewline -ForegroundColor Gray
    }

    # Check if filename matches date pattern
    if ($file.Name -match $datePattern) {
        $filenameYear = [int]$matches[1]
        $filenameMonth = [int]$matches[2]
        $filenameDay = [int]$matches[3]

        # Get EXIF DateTimeOriginal
        try {
            $exifOutput = & exiftool -s -s -s -DateTimeOriginal "$($file.FullName)" 2>$null

            if ($exifOutput) {
                # Parse EXIF date: "YYYY:MM:DD HH:MM:SS"
                if ($exifOutput -match '^(\d{4}):(\d{2}):(\d{2})') {
                    $exifYear = [int]$matches[1]
                    $exifMonth = [int]$matches[2]
                    $exifDay = [int]$matches[3]

                    # Check if dates don't match
                    if ($filenameYear -ne $exifYear -or $filenameMonth -ne $exifMonth -or $filenameDay -ne $exifDay) {
                        $corrupted += [PSCustomObject]@{
                            File = $file.FullName
                            FileName = $file.Name
                            FilenameDate = "$filenameYear-$filenameMonth-$filenameDay"
                            ExifDate = "$exifYear-$exifMonth-$exifDay"
                            ExifFull = $exifOutput
                        }
                    }
                }
            }
        }
        catch {
            # Skip files that can't be read
        }
    }
}

Write-Console "`n"
Write-Console "Scan complete!" -ForegroundColor Green
Write-Console ""

if ($corrupted.Count -gt 0) {
    Write-Console "Found $($corrupted.Count) files with date corruption:" -ForegroundColor Red
    Write-Console ""

    # Group by year discrepancy
    $byYear = $corrupted | Group-Object { $_.FilenameDate.Split('-')[0] } | Sort-Object Name

    foreach ($yearGroup in $byYear) {
        Write-Console "Files with filename date in $($yearGroup.Name):" -ForegroundColor Yellow
        foreach ($item in $yearGroup.Group | Select-Object -First 5) {
            Write-Console "  $($item.FileName)" -ForegroundColor White
            Write-Console "    Filename date: $($item.FilenameDate)" -ForegroundColor Cyan
            Write-Console "    EXIF date:     $($item.ExifDate)" -ForegroundColor Magenta
            Write-Console ""
        }

        if ($yearGroup.Count -gt 5) {
            Write-Console "  ... and $($yearGroup.Count - 5) more files from $($yearGroup.Name)" -ForegroundColor Gray
            Write-Console ""
        }
    }

    # Save full report
    $reportPath = "C:\Users\josep\Documents\dev\applications\media-players\mylio\date-corruption-report.csv"
    $corrupted | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Console "Full report saved to: $reportPath" -ForegroundColor Green

    # Summary statistics
    Write-Console ""
    Write-Console "Summary:" -ForegroundColor Cyan
    Write-Console "  Total files scanned: $total" -ForegroundColor White
    Write-Console "  Files with corruption: $($corrupted.Count)" -ForegroundColor Red
    Write-Console "  Corruption rate: $([math]::Round(($corrupted.Count / $total) * 100, 2))%" -ForegroundColor Yellow
}
else {
    Write-Console "No date corruption detected!" -ForegroundColor Green
}
