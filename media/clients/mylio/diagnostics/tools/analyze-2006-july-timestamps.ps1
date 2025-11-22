# Analyze timestamps for 2006 July photos/videos
# Shows timeline distribution to identify outliers

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
"2006-07-02-134.jpg", "2006-07-02-137.jpg", "2006-07-02-132.jpg", "2006-07-02-136.jpg", "2006-07-02-135.jpg",
"2006-07-02-139.jpg", "2006-07-03-245.mpg", "2006-07-03-284.mpg", "2006-07-02-46.jpg", "2006-07-02-47.jpg",
"2006-07-02-48.jpg", "2006-07-02-49.jpg", "2006-07-02-50.jpg", "2006-07-02-51.jpg", "2006-07-02-52.jpg",
"2006-07-02-53.jpg", "2006-07-02-54.jpg", "2006-07-02-55.jpg", "2006-07-02-11.jpg", "2006-07-03-301.jpg",
"2006-07-02-131.jpg", "2006-07-02-130.jpg", "2006-07-02-128.jpg", "2006-07-02-129.jpg", "2006-07-02-133.jpg",
"2006-07-02-127.jpg", "2006-07-02-122.jpg", "2006-07-02-123.jpg", "2006-07-02-126.jpg", "2006-07-02-125.jpg",
"2006-07-02-124.jpg", "2006-07-02-121.jpg", "2006-07-03-282.jpg", "2006-07-03-285.jpg", "2006-07-03-283.jpg",
"2006-07-03-293.jpg", "2006-07-03-290.jpg", "2006-07-03-287.jpg", "2006-07-03-296.jpg", "2006-07-03-291.jpg",
"2006-07-03-286.jpg", "2006-07-02-163.jpg", "2006-07-02-159.jpg", "2006-07-02-155.jpg", "2006-07-02-160.jpg",
"2006-07-02-157.jpg", "2006-07-02-161.jpg", "2006-07-03-302.jpg", "2006-07-02-56.jpg", "2006-07-03-303.jpg",
"2006-07-03-304.jpg", "2006-07-03-305.jpg", "2006-07-03-306.jpg", "2006-07-02-31.jpg", "2006-07-02-30.jpg",
"2006-07-02-27.jpg", "2006-07-02-32.jpg", "2006-07-02-3.jpg", "2006-07-02-24.jpg", "2006-07-02-199.jpg",
"2006-07-02-196.jpg", "2006-07-02-192.jpg", "2006-07-02-194.jpg", "2006-07-02-195.jpg", "2006-07-02-197.jpg",
"2006-07-02-200.jpg", "2006-07-02-198.jpg", "2006-07-02-201.jpg", "2006-07-02-202.jpg",
"2006-07-02-205.jpg", "2006-07-02-204.jpg", "2006-07-02-101.jpg", "2006-07-02-104.jpg", "2006-07-02-100.jpg",
"2006-07-02-102.jpg", "2006-07-02-106.jpg", "2006-07-02-41.jpg", "2006-07-02-5.jpg", "2006-07-02-40.jpg",
"2006-07-02-42.jpg", "2006-07-02-4.jpg", "2006-07-02-39.jpg", "2006-07-02-183.jpg", "2006-07-02-173.jpg",
"2006-07-02-169.jpg", "2006-07-02-234.jpg", "2006-07-02-167.jpg", "2006-07-02-170.jpg", "2006-07-03-252.mpg",
"2006-07-03-289.mpg", "2006-07-03-263.mpg", "2006-07-03-288.mpg", "2006-07-02-57.jpg", "2006-07-02-58.jpg",
"2006-07-02-116.jpg", "2006-07-02-120.jpg", "2006-07-02-117.jpg", "2006-07-02-119.jpg", "2006-07-02-118.jpg",
"2006-07-02-113.jpg", "2006-07-02-190.jpg", "2006-07-02-188.jpg", "2006-07-02-187.jpg", "2006-07-02-191.jpg",
"2006-07-02-189.jpg", "2006-07-02-193.jpg", "2006-07-03-315.jpg", "2006-07-03-295.jpg", "2006-07-03-297.jpg",
"2006-07-03-300.jpg", "2006-07-03-292.jpg", "2006-07-03-298.jpg", "2006-07-03-316.jpg", "2006-07-03-294.jpg",
"2006-07-03-266.jpg", "2006-07-03-271.jpg", "2006-07-03-267.jpg", "2006-07-03-268.jpg", "2006-07-03-265.jpg",
"2006-07-03-269.jpg", "2006-07-03-270.jpg", "2006-07-03-262.jpg", "2006-07-03-264.jpg", "2006-07-03-259.jpg",
"2006-07-02-203.jpg", "2006-07-02-208.jpg", "2006-07-02-206.jpg", "2006-07-02-209.jpg", "2006-07-02-211.jpg",
"2006-07-02-207.jpg", "2006-07-02-15.jpg", "2006-07-02-21.jpg", "2006-07-02-19.jpg", "2006-07-02-14.jpg",
"2006-07-02-18.jpg", "2006-07-02-22.jpg", "2006-07-02-97.jpg", "2006-07-02-98.jpg", "2006-07-02-95.jpg",
"2006-07-02-96.jpg", "2006-07-02-99.jpg", "2006-07-02-151.jpg", "2006-07-02-156.jpg", "2006-07-02-154.jpg",
"2006-07-02-152.jpg", "2006-07-02-158.jpg", "2006-07-02-153.jpg", "2006-07-03-240.jpg", "2006-07-03-239.jpg",
"2006-07-03-241.jpg", "2006-07-03-244.jpg", "2006-07-03-242.jpg", "2006-07-02-59.jpg", "2006-07-03-307.jpg",
"2006-07-02-60.jpg", "2006-07-02-61.jpg", "2006-07-02-226.jpg", "2006-07-02-228.jpg", "2006-07-02-223.jpg",
"2006-07-02-224.jpg", "2006-07-02-225.jpg", "2006-07-02-227.jpg", "2006-07-02-87.jpg", "2006-07-02-62.jpg",
"2006-07-02-7.jpg", "2006-07-02-86.jpg", "2006-07-02-6.jpg", "2006-07-02-8.jpg", "2006-07-03-249.jpg",
"2006-07-03-250.jpg", "2006-07-03-246.jpg", "2006-07-03-248.jpg", "2006-07-02-140.jpg", "2006-07-02-145.jpg",
"2006-07-02-143.jpg", "2006-07-02-138.jpg", "2006-07-02-141.jpg", "2006-07-02-142.jpg", "2006-07-02-44.jpg",
"2006-07-02-235.jpg", "2006-07-02-181.jpg", "2006-07-02-43.jpg", "2006-07-02-236.jpg", "2006-07-02-45.jpg",
"2006-07-03-253.jpg", "2006-07-03-256.jpg", "2006-07-03-247.jpg", "2006-07-03-255.jpg", "2006-07-03-261.jpg",
"2006-07-03-258.jpg", "2006-07-03-251.jpg", "2006-07-03-260.jpg", "2006-07-03-254.jpg", "2006-07-03-257.jpg",
"2006-07-02-63.jpg", "2006-07-02-64.jpg", "2006-07-02-65.jpg", "2006-07-02-66.jpg", "2006-07-02-67.jpg",
"2006-07-02-68.jpg", "2006-07-02-69.jpg", "2006-07-02-70.jpg", "2006-07-02-34.jpg", "2006-07-02-33.jpg",
"2006-07-02-38.jpg", "2006-07-02-36.jpg", "2006-07-02-35.jpg", "2006-07-02-37.jpg", "2006-07-03-308.jpg",
"2006-07-03-309.jpg", "2006-07-03-310.jpg", "2006-07-03-311.jpg", "2006-07-03-312.jpg", "2006-07-03-313.jpg",
"2006-07-02-168.jpg", "2006-07-02-162.jpg", "2006-07-02-165.jpg", "2006-07-02-166.jpg", "2006-07-02-164.jpg",
"2006-07-02-171.jpg", "2006-07-02-25.jpg", "2006-07-02-23.jpg", "2006-07-02-26.jpg", "2006-07-02-29.jpg",
"2006-07-02-20.jpg", "2006-07-02-28.jpg", "2006-07-02-186.jpg", "2006-07-02-180.jpg", "2006-07-02-178.jpg",
"2006-07-02-182.jpg", "2006-07-02-185.jpg", "2006-07-02-184.jpg", "2006-07-02-144.jpg", "2006-07-02-149.jpg",
"2006-07-02-147.jpg", "2006-07-02-146.jpg", "2006-07-02-150.jpg", "2006-07-02-148.jpg", "2006-07-02-220.jpg",
"2006-07-02-218.jpg", "2006-07-02-216.jpg", "2006-07-02-222.jpg", "2006-07-02-219.jpg", "2006-07-02-221.jpg",
"2006-07-02-172.jpg", "2006-07-02-176.jpg", "2006-07-02-179.jpg", "2006-07-02-175.jpg", "2006-07-02-177.jpg",
"2006-07-02-71.jpg", "2006-07-02-72.jpg", "2006-07-02-73.jpg", "2006-07-02-74.jpg", "2006-07-02-75.jpg",
"2006-07-02-76.jpg", "2006-07-02-77.jpg", "2006-07-02-78.jpg", "2006-07-02-9.jpg",
"2006-07-02-90.jpg", "2006-07-02-79.jpg", "2006-07-02-80.jpg", "2006-07-02-81.jpg", "2006-07-02-82.jpg",
"2006-07-02-83.jpg", "2006-07-02-84.jpg", "2006-07-02-103.jpg", "2006-07-02-174.jpg", "2006-07-02-105.jpg",
"2006-07-02-108.jpg", "2006-07-02-109.jpg", "2006-07-02-107.jpg", "2006-07-02-17.jpg", "2006-07-02-10.jpg",
"2006-07-02-12.jpg", "2006-07-02-16.jpg", "2006-07-02-13.jpg", "2006-07-03-314.jpg", "2006-07-03-318.jpg",
"2006-07-03-299.jpg", "2006-07-03-317.jpg", "2006-07-02-110.jpg", "2006-07-02-111.jpg", "2006-07-02-115.jpg",
"2006-07-02-112.jpg", "2006-07-02-114.jpg", "2006-07-02-93.jpg", "2006-07-02-92.jpg", "2006-07-02-91.jpg",
"2006-07-02-94.jpg", "2006-07-02-88.jpg", "2006-07-02-89.jpg", "2006-07-02-233.jpg",
"2006-07-02-85.jpg", "2006-07-02-217.jpg", "2006-07-02-212.jpg", "2006-07-02-213.jpg", "2006-07-02-214.jpg",
"2006-07-02-215.jpg", "2006-07-02-210.jpg", "2006-07-03-238.jpg", "2006-07-02-229.jpg", "2006-07-02-232.jpg",
"2006-07-02-231.jpg", "2006-07-03-237.jpg", "2006-07-02-230.jpg", "2006-07-03-277.jpg", "2006-07-03-281.jpg",
"2006-07-03-278.jpg", "2006-07-03-273.jpg", "2006-07-03-274.jpg", "2006-07-03-276.jpg", "2006-07-03-280.jpg",
"2006-07-03-275.jpg", "2006-07-03-279.jpg", "2006-07-03-272.jpg", "2006-07-03-243.jpg"
)

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"
$basePath = "D:\Mylio\Folder-Follett"

$results = @()

Write-Console "Analyzing timestamps for $($files.Count) files..." -ForegroundColor Cyan

foreach ($file in $files) {
    # Get year and month from filename
    if ($file -match '^(\d{4})-(\d{2})') {
        $year = $Matches[1]
        $month = $Matches[2]
        $monthName = if ($month -eq "07") { "July" } else { "Unknown" }

        $fullPath = Join-Path $basePath "$year\($month) $monthName\$file"

        if (-not (Test-Path $fullPath)) {
            continue
        }

        # Get XMP date
        $ext = [System.IO.Path]::GetExtension($file)
        $xmpPath = $fullPath -replace $ext, ".xmp"

        if (Test-Path $xmpPath) {
            $xmpDate = & $exiftoolPath -s -s -s -XMP:DateTimeOriginal $xmpPath 2>$null

            if ($xmpDate -match '^(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})') {
                $results += [PSCustomObject]@{
                    File = $file
                    Timestamp = [datetime]::ParseExact($xmpDate, "yyyy:MM:dd HH:mm:ss.fff", $null)
                    DateStr = "$($Matches[1])-$($Matches[2])-$($Matches[3])"
                    TimeStr = "$($Matches[4]):$($Matches[5]):$($Matches[6])"
                    Hour = [int]$Matches[4]
                }
            }
        }
    }
}

Write-Console ""
Write-Console "=== Timestamp Analysis ===" -ForegroundColor Green
Write-Console "Total files analyzed: $($results.Count)" -ForegroundColor Cyan
Write-Console ""

# Group by date
$byDate = $results | Group-Object DateStr | Sort-Object Name
Write-Console "Files by date:" -ForegroundColor Yellow
foreach ($group in $byDate) {
    Write-Console "  $($group.Name): $($group.Count) files" -ForegroundColor White
}
Write-Console ""

# Group by hour
Write-Console "Files by hour of day:" -ForegroundColor Yellow
$byHour = $results | Group-Object Hour | Sort-Object {[int]$_.Name}
foreach ($group in $byHour) {
    $hourStr = "{0:D2}:00" -f [int]$group.Name
    Write-Console "  $hourStr - $($group.Count) files" -ForegroundColor White
}
Write-Console ""

# Sort chronologically and show first/last
$sorted = $results | Sort-Object Timestamp
Write-Console "Timeline:" -ForegroundColor Yellow
Write-Console "  First: $($sorted[0].File) at $($sorted[0].DateStr) $($sorted[0].TimeStr)" -ForegroundColor White
Write-Console "  Last:  $($sorted[-1].File) at $($sorted[-1].DateStr) $($sorted[-1].TimeStr)" -ForegroundColor White
Write-Console ""

# Show any files outside July 2-3, 2006
$outliers = $results | Where-Object { $_.DateStr -ne "2006-07-02" -and $_.DateStr -ne "2006-07-03" }
if ($outliers.Count -gt 0) {
    Write-Console "Files with unexpected dates:" -ForegroundColor Red
    $outliers | Sort-Object Timestamp | ForEach-Object {
        Write-Console "  $($_.File): $($_.DateStr) $($_.TimeStr)" -ForegroundColor Red
    }
} else {
    Write-Console "All files are within July 2-3, 2006 range." -ForegroundColor Green
}

return $results
