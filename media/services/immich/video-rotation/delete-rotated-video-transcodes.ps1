# Delete NVENC transcoded videos for files with Display Matrix rotation
# This forces Immich to re-transcode them with software encoding

$defaultDevRoot = Join-Path $HOME 'Documents/git/dev'
$defaultImmichLogDir = Join-Path $defaultDevRoot 'media/services/immich/logs'

param(
    [Parameter(Mandatory=$false)]
    [string]$RotatedVideosFile = (Join-Path $defaultImmichLogDir 'rotated-videos.txt'),

    [Parameter(Mandatory=$false)]
    [string]$EncodedVideoPath = "D:\Immich\library\encoded-video",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
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

Write-Console "Delete NVENC Transcoded Videos for Rotated Source Files" -ForegroundColor Cyan
Write-Console "========================================================" -ForegroundColor Cyan
Write-Console ""

if (-not (Test-Path $RotatedVideosFile)) {
    $logSearchPath = Split-Path -Parent $RotatedVideosFile
    if (-not $logSearchPath) {
        $logSearchPath = $defaultImmichLogDir
    }
    $latestLog = Get-ChildItem -Path $logSearchPath -Filter 'rotated-videos-*.txt' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog) {
        Write-Console "Rotated videos list not found at $RotatedVideosFile. Using latest log: $($latestLog.FullName)" -ForegroundColor Yellow
        $RotatedVideosFile = $latestLog.FullName
    } else {
        Write-Console "ERROR: Rotated videos list not found: $RotatedVideosFile" -ForegroundColor Red
        Write-Console "Run Find-RotatedVideos.ps1 first to generate the list." -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $EncodedVideoPath)) {
    Write-Console "ERROR: Encoded video path not found: $EncodedVideoPath" -ForegroundColor Red
    exit 1
}

Write-Console "Reading list of rotated videos..." -ForegroundColor Yellow

# Extract UUID filenames from the rotated videos list
$content = Get-Content $RotatedVideosFile -Raw
$uuidPattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
$uuidMatches = [regex]::Matches($content, $uuidPattern)

$uuids = @()
foreach ($match in $uuidMatches) {
    $uuid = $match.Value
    if ($uuid -notin $uuids) {
        $uuids += $uuid
    }
}

Write-Console "Found $($uuids.Count) unique video UUIDs with rotation metadata" -ForegroundColor Green
Write-Console ""

if ($DryRun) {
    Write-Console "DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Console ""
}

# OPTIMIZATION: Get all transcoded files once, then use hashtable lookup
Write-Console "Building index of all transcoded video files (this is much faster)..." -ForegroundColor Yellow
$allTranscodedFiles = Get-ChildItem -Path $EncodedVideoPath -Recurse -Filter "*.mp4" -ErrorAction SilentlyContinue

Write-Console "Creating UUID lookup table from $($allTranscodedFiles.Count) transcoded files..." -ForegroundColor Cyan

# Create hashtable mapping UUID to file object for O(1) lookup
$transcodedLookup = @{}
$uuidRegex = [regex]'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
foreach ($file in $allTranscodedFiles) {
    # Extract UUID from filename (pattern: {uuid}.mp4)
    $matchInfo = $uuidRegex.Match($file.BaseName)
    if ($matchInfo.Success) {
        $fileUuid = $matchInfo.Groups[1].Value
        $transcodedLookup[$fileUuid] = $file
    }
}

Write-Console "Processing $($uuids.Count) rotated video UUIDs..." -ForegroundColor Cyan
Write-Console ""

$deleted = 0
$notFound = 0
$totalSize = 0
$filesToDelete = @()

# Collect files to delete using O(1) hashtable lookup
foreach ($uuid in $uuids) {
    $transcodedFile = $transcodedLookup[$uuid]

    if ($transcodedFile) {
        $fileSize = $transcodedFile.Length
        $totalSize += $fileSize
        $sizeMB = [math]::Round($fileSize / 1MB, 2)

        if ($DryRun) {
            Write-Console "Would delete: $($transcodedFile.FullName) ($sizeMB MB)" -ForegroundColor Gray
            $deleted++
        } else {
            $filesToDelete += $transcodedFile
        }
    } else {
        $notFound++
        # Only show first 10 not found to avoid spam
        if ($notFound -le 10) {
            Write-Console "Not found: $uuid" -ForegroundColor Gray
        } elseif ($notFound -eq 11) {
            Write-Console "... (suppressing further 'not found' messages)" -ForegroundColor DarkGray
        }
    }

    # Progress indicator every 100 files
    if (($deleted + $notFound) % 100 -eq 0) {
        $percentComplete = [math]::Round((($deleted + $notFound) / $uuids.Count) * 100, 1)
        Write-Console "Progress: $($deleted + $notFound) / $($uuids.Count) ($percentComplete%)" -ForegroundColor Cyan
    }
}

# Batch delete files if not dry run
if (-not $DryRun -and $filesToDelete.Count -gt 0) {
    Write-Console ""
    Write-Console "Deleting $($filesToDelete.Count) transcoded files..." -ForegroundColor Yellow

    # Use pipeline for efficient batch deletion
    $filesToDelete | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Console "Deleted: $($_.Name) ($sizeMB MB)" -ForegroundColor Green
            $deleted++
        } catch {
            Write-Console "Failed to delete: $($_.FullName)" -ForegroundColor Red
            Write-Console "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$totalSizeGB = [math]::Round($totalSize / 1GB, 2)

Write-Console ""
Write-Console "========================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Console "DRY RUN COMPLETE" -ForegroundColor Yellow
    Write-Console "Would delete: $deleted transcoded videos" -ForegroundColor White
    Write-Console "Total size: $totalSizeGB GB" -ForegroundColor White
} else {
    Write-Console "DELETION COMPLETE" -ForegroundColor Green
    Write-Console "Deleted: $deleted transcoded videos" -ForegroundColor White
    Write-Console "Not found: $notFound (may not have been transcoded yet)" -ForegroundColor Gray
    Write-Console "Freed space: $totalSizeGB GB" -ForegroundColor White
}
Write-Console ""
Write-Console "Next steps:" -ForegroundColor Yellow
Write-Console "1. Immich will automatically re-transcode these videos when accessed" -ForegroundColor White
Write-Console "2. Or use Immich's 'Transcode All' job to batch re-transcode" -ForegroundColor White
Write-Console "3. New transcodes will use software encoding (libx264)" -ForegroundColor White
Write-Console ""

