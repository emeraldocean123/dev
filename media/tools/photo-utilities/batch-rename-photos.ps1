# Batch Rename Photos and Videos with XMP Sidecars
# Format: YYYY-MM-DD-HHmmss-cameramake-cameramodel-HHHHHHHH.ext
# Renames both media files and their associated XMP sidecars

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "D:\PhotoMove\PhotoMove-Follett",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,

    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "D:\PhotoMove\backups\rename-backups",

    [Parameter(Mandatory=$false)]
    [string]$LogDirectory = (Join-Path $HOME 'Documents/git/dev/media/tools/photo-utilities/logs')
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
Write-Console "Batch Rename Photos and Videos" -ForegroundColor Cyan
Write-Console "================================" -ForegroundColor Cyan
Write-Console ""
Write-Console "Format: YYYY-MM-DD-HHmmss-cameramake-cameramodel-hash.ext" -ForegroundColor White
Write-Console ""

if ($DryRun) {
    Write-Console "DRY RUN MODE - No files will be renamed" -ForegroundColor Yellow
    Write-Console ""
}

# Check if ExifTool is available
try {
    $null = & exiftool -ver 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "ExifTool returned error code"
    }
    Write-Console "ExifTool found and working" -ForegroundColor Green
} catch {
    Write-Console "ERROR: ExifTool not found or not working." -ForegroundColor Red
    Write-Console "Please install ExifTool and ensure it's in your PATH" -ForegroundColor Yellow
    exit 1
}

# Validate path exists
if (-not (Test-Path $Path)) {
    Write-Console "ERROR: Path does not exist: $Path" -ForegroundColor Red
    exit 1
}

# Create backup directory if needed
if (-not $SkipBackup -and -not $DryRun) {
    if (-not (Test-Path $BackupPath)) {
        Write-Console "Creating backup directory: $BackupPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }
}

# Function to sanitize camera make/model for filename
function Get-SanitizedCameraName {
    param([string]$name)

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $null
    }

    # Convert to lowercase
    $name = $name.ToLower()

    # Replace spaces and special characters with underscores
    $name = $name -replace '[^\w\d]+', '_'

    # Add underscores between letters and numbers (e.g., iphone6plus -> iphone_6_plus)
    $name = $name -replace '([a-z])(\d)', '$1_$2'  # letter followed by number
    $name = $name -replace '(\d)([a-z])', '$1_$2'  # number followed by letter

    # Remove leading/trailing underscores
    $name = $name.Trim('_')

    # Limit length to 30 chars (increased to accommodate underscores)
    if ($name.Length -gt 30) {
        $name = $name.Substring(0, 30).TrimEnd('_')
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $null
    }

    return $name
}

# Function to compute MD5 hash of file content (first 8 chars)
function Get-FileHash8 {
    param([string]$filePath)

    try {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $stream = [System.IO.File]::OpenRead($filePath)
        $hashBytes = $md5.ComputeHash($stream)
        $stream.Close()

        # Convert to hex string and take first 8 characters
        $hashString = [BitConverter]::ToString($hashBytes) -replace '-', ''
        return $hashString.Substring(0, 8).ToLower()
    } catch {
        # Fallback: use random GUID last 8 chars
        return [System.Guid]::NewGuid().ToString("N").Substring(24, 8)
    }
}

Write-Console "Scanning for media files..." -ForegroundColor Yellow

# Get all media files (excluding XMP sidecars)
$mediaFiles = Get-ChildItem -Path $Path -Recurse -File -Include *.jpg,*.jpeg,*.JPG,*.JPEG,*.mp4,*.MP4,*.mov,*.MOV,*.m4v,*.M4V,*.avi,*.AVI,*.mpg,*.MPG,*.mpeg,*.MPEG -ErrorAction SilentlyContinue

$totalFiles = $mediaFiles.Count
Write-Console "Found $totalFiles media files to process" -ForegroundColor Green
Write-Console ""

if ($totalFiles -eq 0) {
    Write-Console "No media files found. Exiting." -ForegroundColor Yellow
    exit 0
}

$processed = 0
$renamed = 0
$skipped = 0
$errors = 0
$startTime = Get-Date

# Log file for rename mapping
if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}
$logFileName = "rename-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$logFile = Join-Path $LogDirectory $logFileName

if (-not $DryRun) {
    "Batch Rename Log - $(Get-Date)" | Out-File -FilePath $logFile -Encoding UTF8
    "Format: YYYY-MM-DD-HHmmss-cameramake-cameramodel-hash.ext" | Out-File -FilePath $logFile -Encoding UTF8 -Append
    "" | Out-File -FilePath $logFile -Encoding UTF8 -Append
}

# OPTIMIZATION: Process files in batches using argument files to avoid command line length limits
Write-Console "Preparing to process $($mediaFiles.Count) files..." -ForegroundColor Yellow
Write-Console "Using argument file approach to avoid command line length limits" -ForegroundColor Yellow

# Process in batches to avoid overwhelming PowerShell's JSON parser
$batchSize = 500  # Smaller batches for better memory management
$totalBatches = [Math]::Ceiling($mediaFiles.Count / $batchSize)
Write-Console "Processing in $totalBatches batches of $batchSize files each" -ForegroundColor Yellow
Write-Console ""

# Create hashtable for O(1) lookup by filename
$exifLookup = @{}
$tempArgFile = Join-Path $env:TEMP "exiftool_batch_args.txt"
$tempJsonFile = Join-Path $env:TEMP "exiftool_batch_output.json"

for ($batchNum = 0; $batchNum -lt $totalBatches; $batchNum++) {
    $start = $batchNum * $batchSize
    $end = [Math]::Min(($batchNum + 1) * $batchSize, $mediaFiles.Count)
    $currentBatch = $mediaFiles[$start..($end-1)]

    Write-Console "Reading EXIF data for batch $($batchNum + 1)/$totalBatches (files $($start + 1)-$end)..." -ForegroundColor Cyan

    try {
        # Write file paths to argument file (one per line)
        $currentBatch | ForEach-Object { $_.FullName } | Out-File -FilePath $tempArgFile -Encoding UTF8

        # Call ExifTool and redirect stdout to temp JSON file
        # This completely avoids stderr/stdout mixing issues
        $null = & exiftool -Make -Model -DateTimeOriginal -CreateDate -MediaCreateDate -FileName -json -@ $tempArgFile 2>$null | Out-File -FilePath $tempJsonFile -Encoding UTF8

        # Read JSON from file
        if (Test-Path $tempJsonFile) {
            $jsonContent = Get-Content -Path $tempJsonFile -Raw

            if ($null -ne $jsonContent -and $jsonContent.Trim().Length -gt 0) {
                try {
                    $batchExifData = $jsonContent | ConvertFrom-Json
                    foreach ($exifItem in $batchExifData) {
                        if ($null -ne $exifItem.SourceFile) {
                            $exifLookup[$exifItem.SourceFile] = $exifItem
                        }
                    }
                    Write-Console "  Indexed $($batchExifData.Count) files with EXIF data" -ForegroundColor Green
                } catch {
                    Write-Console "  WARNING: Batch $($batchNum + 1) - Failed to parse JSON: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            } else {
                Write-Console "  WARNING: Batch $($batchNum + 1) returned empty JSON" -ForegroundColor Yellow
            }

            # Delete temp JSON file for next batch
            Remove-Item $tempJsonFile -Force -ErrorAction SilentlyContinue
        } else {
            Write-Console "  WARNING: Batch $($batchNum + 1) - JSON file not created" -ForegroundColor Yellow
        }
    } catch {
        Write-Console "  ERROR processing batch $($batchNum + 1): $($_.Exception.Message)" -ForegroundColor Red
        Write-Console "  Continuing with next batch..." -ForegroundColor Yellow
    }
}

# Clean up temp files
if (Test-Path $tempArgFile) {
    Remove-Item $tempArgFile -Force
}
if (Test-Path $tempJsonFile) {
    Remove-Item $tempJsonFile -Force
}

Write-Console ""
Write-Console "Total EXIF data indexed: $($exifLookup.Count) files" -ForegroundColor Green
Write-Console "Ready to process files" -ForegroundColor Green
Write-Console ""

foreach ($mediaFile in $mediaFiles) {
    $processed++

    try {
        # Look up EXIF data from pre-loaded hashtable (fast!)
        $exif = $exifLookup[$mediaFile.FullName]

        # Extract camera make and model (will use fallback if no EXIF)
        if ($null -ne $exif) {
            $cameraMake = Get-SanitizedCameraName -name $exif.Make
            $cameraModel = Get-SanitizedCameraName -name $exif.Model
        } else {
            # No EXIF data - will use fallback values
            $cameraMake = $null
            $cameraModel = $null
        }

        # If both are missing, use "make-model" as placeholder
        if ([string]::IsNullOrWhiteSpace($cameraMake) -and [string]::IsNullOrWhiteSpace($cameraModel)) {
            $cameraMake = "make"
            $cameraModel = "model"
        } elseif ([string]::IsNullOrWhiteSpace($cameraMake)) {
            $cameraMake = "make"
        } elseif ([string]::IsNullOrWhiteSpace($cameraModel)) {
            $cameraModel = "model"
        }

        # Extract date/time (try multiple fields)
        $dateTimeStr = $null
        if ($null -ne $exif) {
            $dateTimeStr = $exif.DateTimeOriginal
            if ([string]::IsNullOrWhiteSpace($dateTimeStr)) {
                $dateTimeStr = $exif.CreateDate
            }
            if ([string]::IsNullOrWhiteSpace($dateTimeStr)) {
                $dateTimeStr = $exif.MediaCreateDate
            }
        }

        # Fallback to filesystem timestamps if no EXIF date found
        $usedFallback = $false
        $fallbackSource = $null
        if ([string]::IsNullOrWhiteSpace($dateTimeStr)) {
            # Try to extract date from filename (formats: YYYY-MM-DD, YYYY_MM_DD, YYYYMMDD)
            $filenameDate = $null
            if ($mediaFile.BaseName -match '(\d{4})[-_]?(\d{2})[-_]?(\d{2})') {
                try {
                    $filenameDate = [DateTime]::ParseExact("$($matches[1])-$($matches[2])-$($matches[3])", "yyyy-MM-dd", $null)
                } catch {
                    # Invalid date in filename, ignore
                }
            }

            # Get filesystem timestamps
            $creationTime = $mediaFile.CreationTime
            $modifiedTime = $mediaFile.LastWriteTime

            # Choose best timestamp based on filename date if available
            if ($null -ne $filenameDate) {
                # Compare filename date (day only) with filesystem timestamps
                # Check if creation time is on the same day as filename date
                $creationSameDay = $creationTime.Date -eq $filenameDate.Date
                # Check if modified time is on the same day as filename date
                $modifiedSameDay = $modifiedTime.Date -eq $filenameDate.Date

                # Priority: filesystem timestamp if same day (has actual time), else filename date
                if ($creationSameDay) {
                    # Creation time is same day as filename - use it (has actual time)
                    $fileDate = $creationTime
                    $fallbackSource = "creation (same day as filename)"
                } elseif ($modifiedSameDay) {
                    # Modified time is same day as filename - use it (has actual time)
                    $fileDate = $modifiedTime
                    $fallbackSource = "modified (same day as filename)"
                } else {
                    # Neither matches same day - use filename date with midnight time
                    $fileDate = $filenameDate
                    $fallbackSource = "filename"
                }
            } else {
                # No filename date found, use creation time if valid, otherwise modified time
                if ($creationTime -le (Get-Date) -and $creationTime.Year -ge 1990) {
                    $fileDate = $creationTime
                    $fallbackSource = "creation"
                } else {
                    $fileDate = $modifiedTime
                    $fallbackSource = "modified"
                }
            }

            # Format as EXIF-style string for consistent parsing below
            $dateTimeStr = $fileDate.ToString("yyyy:MM:dd HH:mm:ss")
            $usedFallback = $true
        }

        if ([string]::IsNullOrWhiteSpace($dateTimeStr)) {
            Write-Console "Skipped (no date/time): $($mediaFile.Name)" -ForegroundColor Yellow
            $skipped++
            continue
        }

        # Parse date/time (format: 2024:03:15 14:30:22)
        # Replace colons and spaces to get: YYYY-MM-DD-HHmmss
        $dateTimeStr = $dateTimeStr -replace '(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})', '$1-$2-$3-$4$5$6'

        # If the regex didn't match, try simpler fallback
        if ($dateTimeStr -match ':') {
            $dateTimeStr = $dateTimeStr -replace ':', '-'
            $dateTimeStr = $dateTimeStr -replace '\s+', '-'
            # Remove last two hyphens to get HHmmss
            $parts = $dateTimeStr -split '-'
            if ($parts.Length -ge 5) {
                $dateTimeStr = "$($parts[0])-$($parts[1])-$($parts[2])-$($parts[3])$($parts[4])"
                if ($parts.Length -ge 6) {
                    $dateTimeStr += $parts[5]
                }
            }
        }

        # Format: YYYY-MM-DD-HHmmss
        $datePart = $dateTimeStr

        # Compute hash from file content
        $hash = Get-FileHash8 -filePath $mediaFile.FullName

        # Get file extension (lowercase)
        $extension = $mediaFile.Extension.ToLower()

        # Build new filename
        $newName = "${datePart}-${cameraMake}-${cameraModel}-${hash}${extension}"

        # Check if already renamed (same name)
        if ($mediaFile.Name -eq $newName) {
            if ($processed % 100 -eq 0) {
                Write-Console "Already renamed: $($mediaFile.Name)" -ForegroundColor Gray
            }
            continue
        }

        # Build new path
        $newPath = Join-Path $mediaFile.DirectoryName $newName

        # Check for name collision
        if (Test-Path $newPath) {
            Write-Console "ERROR: File already exists: $newName" -ForegroundColor Red
            $errors++
            continue
        }

        # Check for associated XMP sidecar (two possible patterns)
        # Pattern 1: filename.jpg.xmp (extension appended - Immich style)
        $xmpOldPath1 = "$($mediaFile.FullName).xmp"
        # Pattern 2: filename.xmp (extension replaced - alternative style)
        $xmpOldPath2 = Join-Path $mediaFile.DirectoryName ($mediaFile.BaseName + ".xmp")

        $xmpOldPath = $null
        $hasXmp = $false

        if (Test-Path $xmpOldPath1) {
            $xmpOldPath = $xmpOldPath1
            $hasXmp = $true
        } elseif (Test-Path $xmpOldPath2) {
            $xmpOldPath = $xmpOldPath2
            $hasXmp = $true
        }

        if ($DryRun) {
            Write-Console "Would rename:" -ForegroundColor Gray
            Write-Console "  Old: $($mediaFile.Name)" -ForegroundColor Gray
            Write-Console "  New: $newName" -ForegroundColor Gray
            if ($hasXmp) {
                $xmpOldName = Split-Path -Leaf $xmpOldPath
                # XMP gets renamed to match the base name of the new media file (without extension) + .xmp
                $xmpNewName = [System.IO.Path]::GetFileNameWithoutExtension($newName) + ".xmp"
                Write-Console "  XMP: ${xmpOldName} → ${xmpNewName}" -ForegroundColor Gray
            }
        } else {
            # Rename media file
            Rename-Item -Path $mediaFile.FullName -NewName $newName -ErrorAction Stop

            # Rename XMP sidecar if it exists
            if ($hasXmp) {
                # XMP gets renamed to match the base name of the new media file (without extension) + .xmp
                $xmpNewName = [System.IO.Path]::GetFileNameWithoutExtension($newName) + ".xmp"
                $xmpNewPath = Join-Path $mediaFile.DirectoryName $xmpNewName
                Rename-Item -Path $xmpOldPath -NewName $xmpNewName -ErrorAction Stop
            }

            # Log the rename
            $logEntry = "$($mediaFile.Name) → $newName"
            if ($usedFallback -and $null -ne $fallbackSource) {
                $logEntry += " [$fallbackSource timestamp]"
            }
            $logEntry | Out-File -FilePath $logFile -Encoding UTF8 -Append

            if ($hasXmp) {
                $xmpOldName = Split-Path -Leaf $xmpOldPath
                "${xmpOldName} → ${xmpNewName}" | Out-File -FilePath $logFile -Encoding UTF8 -Append
            }

            if ($processed % 10 -eq 0) {
                Write-Console "Renamed: $($mediaFile.Name) → $newName" -ForegroundColor Green
                if ($usedFallback -and $null -ne $fallbackSource) {
                    Write-Console "  (used $fallbackSource timestamp)" -ForegroundColor Yellow
                }
                if ($hasXmp) {
                    Write-Console "  + XMP sidecar" -ForegroundColor Green
                }
            }

            $renamed++
        }

    } catch {
        Write-Console "Error processing: $($mediaFile.Name)" -ForegroundColor Red
        Write-Console "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }

    # Progress indicator every 100 files
    if ($processed % 100 -eq 0) {
        $percentComplete = [math]::Round(($processed / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $filesPerSecond = if ($elapsed.TotalSeconds -gt 0) { [math]::Round($processed / $elapsed.TotalSeconds, 2) } else { 0 }
        $estimatedTotal = if ($filesPerSecond -gt 0) { $totalFiles / $filesPerSecond } else { 0 }
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "Progress: $processed / $totalFiles ($percentComplete%) - Renamed: $renamed - Rate: $filesPerSecond files/sec - ETA: $($remaining.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Console "DRY RUN COMPLETE" -ForegroundColor Yellow
    Write-Console "Would rename: $renamed files" -ForegroundColor White
} else {
    Write-Console "RENAME COMPLETE" -ForegroundColor Green
    Write-Console "Renamed: $renamed files" -ForegroundColor Green
}
Write-Console "Total files: $totalFiles" -ForegroundColor White
Write-Console "Skipped: $skipped" -ForegroundColor Yellow
Write-Console "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "White" })
Write-Console "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White

if (-not $DryRun -and $renamed -gt 0) {
    Write-Console ""
    Write-Console "Rename log saved to: $logFile" -ForegroundColor Yellow
    if (-not $SkipBackup) {
        $backupLogPath = Join-Path $BackupPath $logFileName
        Copy-Item -Path $logFile -Destination $backupLogPath -Force
        Write-Console "Backup copy stored at: $backupLogPath" -ForegroundColor Yellow
    }
}

Write-Console ""
Write-Console "Filename format:" -ForegroundColor White
Write-Console "  YYYY-MM-DD-HHmmss-cameramake-cameramodel-HHHHHHHH.ext" -ForegroundColor Gray
Write-Console ""
Write-Console "Example:" -ForegroundColor White
Write-Console "  2024-03-15-143022-apple-iphone15pro-a3f2c1b8.jpg" -ForegroundColor Gray
Write-Console ""
