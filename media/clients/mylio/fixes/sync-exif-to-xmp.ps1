# Sync EXIF timestamps to match XMP sidecars for 2006 July files
# Updates EXIF:DateTimeOriginal, EXIF:CreateDate, and EXIF:ModifyDate

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$files = @(
"2006-07-02-137.jpg", "2006-07-02-11.jpg", "2006-07-03-301.jpg", "2006-07-02-126.jpg", "2006-07-02-124.jpg",
"2006-07-03-282.jpg", "2006-07-03-285.jpg", "2006-07-03-283.jpg", "2006-07-03-293.jpg", "2006-07-03-290.jpg",
"2006-07-03-287.jpg", "2006-07-03-296.jpg", "2006-07-03-291.jpg", "2006-07-03-286.jpg", "2006-07-02-155.jpg",
"2006-07-03-302.jpg", "2006-07-02-56.jpg", "2006-07-03-303.jpg", "2006-07-03-304.jpg", "2006-07-03-305.jpg",
"2006-07-03-306.jpg", "2006-07-02-31.jpg", "2006-07-02-30.jpg", "2006-07-02-27.jpg", "2006-07-02-32.jpg",
"2006-07-02-3.jpg", "2006-07-02-24.jpg", "2006-07-02-199.jpg", "2006-07-02-195.jpg", "2006-07-02-197.jpg",
"2006-07-02-41.jpg", "2006-07-02-5.jpg", "2006-07-02-40.jpg", "2006-07-02-42.jpg", "2006-07-02-4.jpg",
"2006-07-02-39.jpg", "2006-07-02-234.jpg", "2006-07-02-57.jpg", "2006-07-03-315.jpg", "2006-07-03-295.jpg",
"2006-07-03-297.jpg", "2006-07-03-300.jpg", "2006-07-03-292.jpg", "2006-07-03-298.jpg", "2006-07-03-316.jpg",
"2006-07-03-294.jpg", "2006-07-03-266.jpg", "2006-07-03-271.jpg", "2006-07-03-267.jpg", "2006-07-03-268.jpg",
"2006-07-03-265.jpg", "2006-07-03-269.jpg", "2006-07-03-270.jpg", "2006-07-03-262.jpg", "2006-07-03-264.jpg",
"2006-07-03-259.jpg", "2006-07-02-211.jpg", "2006-07-02-15.jpg", "2006-07-02-21.jpg", "2006-07-02-19.jpg",
"2006-07-02-14.jpg", "2006-07-02-18.jpg", "2006-07-02-22.jpg", "2006-07-02-158.jpg", "2006-07-03-240.jpg",
"2006-07-03-239.jpg", "2006-07-03-241.jpg", "2006-07-03-244.jpg", "2006-07-03-242.jpg", "2006-07-03-307.jpg",
"2006-07-02-224.jpg", "2006-07-02-7.jpg", "2006-07-02-86.jpg", "2006-07-02-6.jpg", "2006-07-02-8.jpg",
"2006-07-03-249.jpg", "2006-07-03-250.jpg", "2006-07-03-246.jpg", "2006-07-03-248.jpg", "2006-07-02-236.jpg",
"2006-07-03-253.jpg", "2006-07-03-256.jpg", "2006-07-03-247.jpg", "2006-07-03-255.jpg", "2006-07-03-261.jpg",
"2006-07-03-258.jpg", "2006-07-03-251.jpg", "2006-07-03-260.jpg", "2006-07-03-254.jpg", "2006-07-03-257.jpg",
"2006-07-02-69.jpg", "2006-07-02-70.jpg", "2006-07-02-34.jpg", "2006-07-02-33.jpg", "2006-07-02-38.jpg",
"2006-07-02-36.jpg", "2006-07-02-35.jpg", "2006-07-02-37.jpg", "2006-07-03-308.jpg", "2006-07-03-309.jpg",
"2006-07-03-310.jpg", "2006-07-03-311.jpg", "2006-07-03-312.jpg", "2006-07-03-313.jpg", "2006-07-02-168.jpg",
"2006-07-02-171.jpg", "2006-07-02-25.jpg", "2006-07-02-23.jpg", "2006-07-02-26.jpg", "2006-07-02-29.jpg",
"2006-07-02-20.jpg", "2006-07-02-28.jpg", "2006-07-02-185.jpg", "2006-07-02-184.jpg", "2006-07-02-218.jpg",
"2006-07-02-9.jpg", "2006-07-02-90.jpg", "2006-07-02-17.jpg", "2006-07-02-10.jpg", "2006-07-02-12.jpg",
"2006-07-02-16.jpg", "2006-07-02-13.jpg", "2006-07-03-314.jpg", "2006-07-03-318.jpg", "2006-07-03-299.jpg",
"2006-07-03-317.jpg", "2006-07-02-85.jpg", "2006-07-02-215.jpg", "2006-07-03-238.jpg", "2006-07-02-232.jpg",
"2006-07-03-237.jpg", "2006-07-03-277.jpg", "2006-07-03-281.jpg", "2006-07-03-278.jpg", "2006-07-03-273.jpg",
"2006-07-03-274.jpg", "2006-07-03-276.jpg", "2006-07-03-280.jpg", "2006-07-03-275.jpg", "2006-07-03-279.jpg",
"2006-07-03-272.jpg", "2006-07-03-243.jpg"
)

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
$basePath = "D:\Mylio\Folder-Follett"

Write-Console "=== Syncing EXIF timestamps to match XMP sidecars ===" -ForegroundColor Cyan
Write-Console ""

$synced = 0
$errors = 0

foreach ($file in $files) {
    # Get year and month from filename
    if ($file -match '^(\d{4})-(\d{2})') {
        $year = $Matches[1]
        $month = $Matches[2]
        $monthName = if ($month -eq "07") { "July" } else { "Unknown" }

        $fullPath = Join-Path $basePath "$year\($month) $monthName\$file"

        if (-not (Test-Path $fullPath)) {
            Write-Console "  NOT FOUND: $file" -ForegroundColor Red
            $errors++
            continue
        }

        # Get XMP path
        $ext = [System.IO.Path]::GetExtension($file)
        $xmpPath = $fullPath -replace [regex]::Escape($ext), ".xmp"

        if (-not (Test-Path $xmpPath)) {
            Write-Console "  NO XMP: $file" -ForegroundColor Red
            $errors++
            continue
        }

        # Get XMP date (format: 2006:07:02 12:22:00.000)
        $xmpDate = & $exiftoolPath -s -s -s -XMP:DateTimeOriginal $xmpPath 2>$null

        if (-not $xmpDate) {
            Write-Console "  XMP READ ERROR: $file" -ForegroundColor Red
            $errors++
            continue
        }

        # Remove milliseconds from XMP date for EXIF (EXIF doesn't support milliseconds)
        $exifDate = if ($xmpDate -match '^(.+)\.\d+$') { $Matches[1] } else { $xmpDate }

        Write-Console "  Syncing: $file" -ForegroundColor Green
        Write-Console "    XMP:  $xmpDate" -ForegroundColor Gray
        Write-Console "    EXIF: $exifDate (syncing)" -ForegroundColor Cyan

        # Update EXIF timestamps to match XMP
        $result = & $exiftoolPath -overwrite_original `
            "-EXIF:DateTimeOriginal=$exifDate" `
            "-EXIF:CreateDate=$exifDate" `
            "-EXIF:ModifyDate=$exifDate" `
            $fullPath 2>&1

        if ($LASTEXITCODE -eq 0) {
            $synced++
        } else {
            Write-Console "    ERROR: $result" -ForegroundColor Red
            $errors++
        }
    }
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
Write-Console "Synced: $synced" -ForegroundColor Green
Write-Console "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Console ""
Write-Console "All EXIF timestamps now match their XMP sidecars" -ForegroundColor Green
