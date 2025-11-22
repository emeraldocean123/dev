# Scan Embedded Metadata in All Media Files - Memory Optimized
# Catalogs all metadata groups/tags found across the entire library
# OPTIMIZED: Uses counters and streaming instead of accumulating hashtables

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $null
    $previousForeground = $null
    $previousBackground = $null

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        if ($NoNewline -and $Host -and $Host.UI) {
            $Host.UI.Write($Message)
        } else {
            Write-Information -MessageData $Message
        }
    } catch {
        Write-Information -MessageData $Message
        Write-Verbose "Write-Console fallback: $($_.Exception.Message)"
    } finally {
        if ($rawUI -and $null -ne $previousForeground) {
            try {
                $rawUI.ForegroundColor = $previousForeground
            } catch {
                Write-Verbose "Unable to reset foreground color: $($_.Exception.Message)"
            }
        }

        if ($rawUI -and $PSBoundParameters.ContainsKey('BackgroundColor') -and $null -ne $previousBackground) {
            try {
                $rawUI.BackgroundColor = $previousBackground
            } catch {
                Write-Verbose "Unable to reset background color: $($_.Exception.Message)"
            }
        }
    }
}

param(
    [string]$Path = "D:\Mylio",
    [int]$SampleSize = 0  # 0 = scan all files
)

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Embedded Metadata Scanner (Memory Optimized)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Scanning: $Path" -ForegroundColor White
if ($SampleSize -gt 0) {
    Write-Console "Sample size: $SampleSize files`n" -ForegroundColor Yellow
} else {
    Write-Console "Mode: Full scan (all files)`n" -ForegroundColor Yellow
}

# Get all media files
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.heif', '*.mov', '*.mp4', '*.avi', '*.mkv', '*.m4v')
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

$totalFiles = $files.Count
Write-Console "Found $totalFiles media files`n" -ForegroundColor White

# Sample if requested
if ($SampleSize -gt 0 -and $totalFiles -gt $SampleSize) {
    $files = $files | Get-Random -Count $SampleSize
    Write-Console "Randomly selected $SampleSize files for analysis`n" -ForegroundColor Yellow
}

# MEMORY OPTIMIZATION: Use simple hashtables for counting only
$metadataGroups = @{}
$softwareTags = @{}

$processedCount = 0
$startTime = Get-Date

# MEMORY OPTIMIZATION: Initialize report file immediately
$reportPath = "$PSScriptRoot\embedded-metadata-scan-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$reportHeader = @"
Embedded Metadata Scan Report (Memory Optimized)
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Files scanned: $($files.Count)

========================================
METADATA GROUPS (streaming counts)
========================================

"@

$reportHeader | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "Scanning files for metadata groups and tags..." -ForegroundColor Cyan
Write-Console "This may take a while...`n" -ForegroundColor Gray

foreach ($file in $files) {
    $processedCount++

    if ($processedCount % 100 -eq 0) {
        $percentComplete = [math]::Round(($processedCount / $files.Count) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $processedCount * $files.Count
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "`rProgress: $processedCount / $($files.Count) ($percentComplete%) - ETA: $($remaining.ToString('hh\:mm\:ss'))" -NoNewline -ForegroundColor Yellow

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        if ($processedCount % 1000 -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    try {
        # Get all metadata with group names
        $output = & $exiftoolPath -G -s $file.FullName 2>$null

        foreach ($line in $output) {
            if ($line -match '^\[([^\]]+)\]\s+(\S+)\s*:\s*(.*)$') {
                $group = $matches[1]
                $tag = $matches[2]
                $value = $matches[3]

                # Track groups (count only)
                if (-not $metadataGroups.ContainsKey($group)) {
                    $metadataGroups[$group] = 0
                }
                $metadataGroups[$group]++

                # Track software-related tags with values
                if ($tag -match 'Software|Creator|Application|ProcessingSoftware|OwnerName|Editor') {
                    $fullTag = "$group`:$tag"
                    if (-not $softwareTags.ContainsKey($fullTag)) {
                        $softwareTags[$fullTag] = @{}
                    }
                    if (-not $softwareTags[$fullTag].ContainsKey($value)) {
                        $softwareTags[$fullTag][$value] = 0
                    }
                    $softwareTags[$fullTag][$value]++
                }
            }
        }

    } catch {
        Write-Verbose "Skipping $($file.FullName) due to metadata read error: $($_.Exception.Message)"
        continue
    }
}

Write-Console "`n`n" # Clear progress line

$elapsed = (Get-Date) - $startTime

# Generate Report
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Metadata Groups Found" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

$sortedGroups = $metadataGroups.GetEnumerator() | Sort-Object -Property Value -Descending

foreach ($group in $sortedGroups) {
    $name = $group.Key
    $count = $group.Value

    Write-Console "$name" -ForegroundColor Yellow
    Write-Console "  Occurrences: $count" -ForegroundColor Gray
    Write-Console ""

    # Stream to report file
    "$name`: $count occurrences`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Software Tags Found" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Append software tags section to report
"`n========================================`nSOFTWARE TAGS`n========================================`n`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($softwareTags.Count -eq 0) {
    Write-Console "No software tags found`n" -ForegroundColor Gray
    "No software tags found`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    foreach ($tag in $softwareTags.Keys | Sort-Object) {
        Write-Console "$tag`:" -ForegroundColor Yellow
        "$tag`:`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8

        foreach ($value in $softwareTags[$tag].Keys | Sort-Object) {
            $count = $softwareTags[$tag][$value]
            Write-Console "  $value ($count occurrences)" -ForegroundColor Gray
            "  $value ($count occurrences)`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
        }
        Write-Console ""
        "`n" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Files scanned: $processedCount" -ForegroundColor White
Write-Console "Unique metadata groups: $($metadataGroups.Count)" -ForegroundColor White
Write-Console "Software tags: $($softwareTags.Count)" -ForegroundColor White
Write-Console "`nProcessing time: $($elapsed.ToString('hh\:mm\:ss'))`n" -ForegroundColor White

# Append summary to report
$summary = @"

========================================
SUMMARY
========================================

Files scanned: $processedCount
Unique metadata groups: $($metadataGroups.Count)
Software tags: $($softwareTags.Count)
Processing time: $($elapsed.ToString('hh\:mm\:ss'))

"@

$summary | Out-File -FilePath $reportPath -Append -Encoding UTF8

Write-Console "Detailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green

