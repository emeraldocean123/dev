# Find videos with Display Matrix rotation metadata in Immich library
# This identifies videos that may have black screen issues with NVENC transcoding

$defaultDevRoot = Join-Path $HOME 'Documents/git/dev'
$defaultImmichLogDir = Join-Path $defaultDevRoot 'media/services/immich/logs'

param(
    [Parameter(Mandatory=$false)]
    [string]$LibraryPath = "D:\Immich\library\library",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = (Join-Path $defaultImmichLogDir ("rotated-videos-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
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

Write-Console "Scanning for videos with Display Matrix rotation metadata..." -ForegroundColor Cyan
Write-Console "This may take several minutes depending on library size..." -ForegroundColor Cyan
Write-Console "Checking side_data for Display Matrix (iPhone landscape videos)" -ForegroundColor Cyan
Write-Console ""

# Create logs directory if it doesn't exist
$logsDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Clear previous results
@"
Videos with Display Matrix rotation metadata:
==============================================

"@ | Out-File -FilePath $OutputFile -Encoding UTF8

$count = 0
$total = 0
$startTime = Get-Date

# Find all video files in the library
$videoFiles = Get-ChildItem -Path $LibraryPath -Recurse -File -Include *.mov,*.MOV,*.mp4,*.MP4,*.m4v,*.M4V -ErrorAction SilentlyContinue

$totalFiles = $videoFiles.Count
Write-Console "Found $totalFiles video files to scan" -ForegroundColor Green
Write-Console ""

# OPTIMIZATION: Call ffprobe once for all videos with JSON output
Write-Console "Analyzing all videos with single ffprobe call (this is much faster)..." -ForegroundColor Yellow

# Build arguments for ffprobe to process all files
$videoPathsFile = [System.IO.Path]::GetTempFileName()
$videoFiles | ForEach-Object { $_.FullName } | Out-File -FilePath $videoPathsFile -Encoding UTF8

# Create concat file for ffprobe
$concatFile = [System.IO.Path]::GetTempFileName()
$videoFiles | ForEach-Object { "file '$($_.FullName -replace "'", "'\''")'" } | Out-File -FilePath $concatFile -Encoding UTF8

# Get all video metadata in one ffprobe call
Write-Console "Running batch ffprobe analysis..." -ForegroundColor Cyan
$ffprobeArgs = @(
    '-v', 'error',
    '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height:stream_side_data=rotation:format=filename',
    '-of', 'json'
)

# Process videos in batches to avoid command line length limits
$batchSize = 100
$allVideoData = @()

for ($i = 0; $i -lt $videoFiles.Count; $i += $batchSize) {
    $batch = $videoFiles[$i..[math]::Min($i + $batchSize - 1, $videoFiles.Count - 1)]
    $batchArgs = $ffprobeArgs + $batch.FullName

    $jsonOutput = & ffprobe @batchArgs 2>$null | Out-String
    if ($jsonOutput) {
        $batchData = $jsonOutput | ConvertFrom-Json
        if ($batchData.streams) {
            $allVideoData += $batchData.streams
        }
    }

    $percentComplete = [math]::Round((($i + $batch.Count) / $totalFiles) * 100, 1)
    Write-Console "  Batch analysis: $($i + $batch.Count) / $totalFiles ($percentComplete%)" -ForegroundColor Gray
}

Write-Console "Creating metadata lookup table..." -ForegroundColor Cyan

# Create hashtable for O(1) lookup by filename
$videoMetadata = @{}
foreach ($stream in $allVideoData) {
    $filename = $stream.format?.filename
    if ($filename) {
        $videoMetadata[$filename] = $stream
    }
}

# Clean up temp files
Remove-Item -Path $videoPathsFile -ErrorAction SilentlyContinue
Remove-Item -Path $concatFile -ErrorAction SilentlyContinue

Write-Console "Processing results from cached metadata..." -ForegroundColor Cyan
Write-Console ""

# Process videos using cached metadata
foreach ($video in $videoFiles) {
    $total++

    # Get cached metadata
    $metadata = $videoMetadata[$video.FullName]

    # Check for rotation in side_data
    $rotation = $null
    if ($metadata.side_data_list) {
        $rotationData = $metadata.side_data_list | Where-Object { $_.rotation } | Select-Object -First 1
        $rotation = $rotationData.rotation
    }

    if ($rotation -and $rotation -ne "0") {
        $count++

        # Get dimensions from cached metadata
        $width = $metadata.width
        $height = $metadata.height
        $dimensions = "${width}x${height}"

        # Get file size in MB
        $sizeMB = [math]::Round($video.Length / 1MB, 2)

        # Output to console
        Write-Console "Found: $($video.FullName)" -ForegroundColor Yellow
        Write-Console "  Rotation: ${rotation}°" -ForegroundColor White
        Write-Console "  Dimensions: $dimensions" -ForegroundColor White
        Write-Console "  Size: ${sizeMB}MB" -ForegroundColor White
        Write-Console ""

        # Append to output file
        @"
Found: $($video.FullName)
  Rotation: ${rotation}°
  Dimensions: $dimensions
  Size: ${sizeMB}MB

"@ | Out-File -FilePath $OutputFile -Encoding UTF8 -Append
    }

    # Progress indicator every 100 videos
    if ($total % 100 -eq 0) {
        $percentComplete = [math]::Round(($total / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $total * $totalFiles
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "Processed $total / $totalFiles videos ($percentComplete%) - Found $count with rotation - ETA: $($remaining.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Console ""
Write-Console "=====================================================" -ForegroundColor Cyan
Write-Console "Scan complete!" -ForegroundColor Green
Write-Console "Total videos scanned: $total" -ForegroundColor White
Write-Console "Videos with Display Matrix rotation: $count" -ForegroundColor Yellow
Write-Console "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Console "Results saved to: $OutputFile" -ForegroundColor White
Write-Console ""
Write-Console "Videos with -90° rotation need re-transcoding with software encoding." -ForegroundColor Yellow
Write-Console "Use 'Refresh Encoded Video' button in Immich UI for each video." -ForegroundColor Yellow

# Append summary to output file
@"

=====================================================
Scan complete!
Total videos scanned: $total
Videos with Display Matrix rotation: $count
Duration: $($duration.ToString('hh\:mm\:ss'))

These videos have black screen issues when transcoded with NVENC.
Use 'Refresh Encoded Video' button in Immich UI to re-transcode with software encoding.
"@ | Out-File -FilePath $OutputFile -Encoding UTF8 -Append

Write-Console ""
Write-Console "Press any key to view the results file..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
notepad $OutputFile


