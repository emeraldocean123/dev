# Remove All Keywords and Software Metadata from Mylio Library - Memory Optimized
# Removes keywords from XMP sidecars, IPTC:Keywords, EXIF:XPKeywords, and software metadata
# Cleans: Keywords, CreatorTool, Software, ProcessingSoftware, History, DerivedFrom
# OPTIMIZED: Uses counters instead of accumulating arrays to prevent memory exhaustion

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
    [switch]$DryRun
)

if (-not $PSBoundParameters.ContainsKey('DryRun')) {
    $DryRun = $false
}

$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Remove Keywords & Software Metadata (Memory Optimized)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "MODE: DRY RUN - No changes will be made`n" -ForegroundColor Yellow
} else {
    Write-Console "MODE: LIVE - Keywords and software metadata will be removed!`n" -ForegroundColor Red
    Write-Console "Press Ctrl+C within 5 seconds to cancel..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Write-Console ""
}

Write-Console "Scanning: $Path`n" -ForegroundColor White

# Get file counts (lightweight - just counts, not full objects)
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.heif', '*.mov', '*.mp4', '*.avi', '*.mkv', '*.m4v')
$totalFiles = (Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue).Count
$totalXmp = (Get-ChildItem -Path $Path -Recurse -Filter "*.xmp" -File -ErrorAction SilentlyContinue).Count

Write-Console "Found $totalFiles media files`n" -ForegroundColor White
Write-Console "Found $totalXmp XMP sidecar files`n" -ForegroundColor White

$startTime = Get-Date

# Initialize report file immediately
$reportPath = "$PSScriptRoot\keyword-removal-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$reportHeader = @"
Keyword Removal Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Mode: $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })

========================================
OPERATIONS LOG
========================================

"@

$reportHeader | Out-File -FilePath $reportPath -Encoding UTF8

# Step 1: Preserve device metadata before keyword removal
Write-Console "Step 1: Preserving device metadata to EXIF:Model..." -ForegroundColor Cyan

# Common device name patterns
$devicePatterns = @(
    "iPhone.*",
    "iPad.*",
    "Canon.*",
    "Nikon.*",
    "Sony.*",
    "Panasonic.*",
    "Olympus.*",
    "Fuji.*",
    "Pentax.*",
    "Leica.*",
    "Samsung.*",
    "DSC-.*",
    "EOS.*",
    "ILCE-.*",
    "DMC-.*"
)

if ($DryRun) {
    Write-Console "  Checking which files need device metadata migration..." -ForegroundColor Gray

    # MEMORY OPTIMIZATION: Use streaming counter instead of accumulating array
    $migrationCount = 0
    $processedCount = 0

    # Stream results from ExifTool, process one at a time
    & $exiftoolPath -EXIF:Model -if 'not $EXIF:Model' -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header
        if ($_ -match '\.xmp"?$') { return } # Skip XMP files

        $processedCount++

        if ($processedCount % 100 -eq 0) {
            Write-Console "`r  Checked: $processedCount files" -NoNewline -ForegroundColor Gray
        }

        # Parse CSV line
        $line = $_ | ConvertFrom-Csv
        $filePath = $line.SourceFile
        $xmpPath = $filePath + ".xmp"

        if (Test-Path $xmpPath) {
            # Read XMP keywords (streaming)
            $keywords = & $exiftoolPath -XMP:Subject -csv $xmpPath 2>$null |
                Select-Object -Skip 1 |
                ForEach-Object {
                    $csvLine = $_ | ConvertFrom-Csv
                    $csvLine.'XMP:Subject'
                }

            if ($keywords) {
                # Check if any keyword matches device pattern
                foreach ($keyword in ($keywords -split ',')) {
                    $keyword = $keyword.Trim()
                    foreach ($pattern in $devicePatterns) {
                        if ($keyword -match "^$pattern$") {
                            $migrationCount++
                            break
                        }
                    }
                }
            }
        }

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        if ($processedCount % 1000 -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    Write-Console "`r  Would migrate device metadata for $migrationCount files" -ForegroundColor Yellow
    "Step 1: Would migrate device metadata for $migrationCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Finding files without EXIF:Model..." -ForegroundColor Gray

    # MEMORY OPTIMIZATION: Stream and process one at a time
    $migrationCount = 0
    $processedCount = 0

    & $exiftoolPath -EXIF:Model -if 'not $EXIF:Model' -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header
        if ($_ -match '\.xmp"?$') { return } # Skip XMP files

        $processedCount++

        if ($processedCount % 100 -eq 0) {
            Write-Console "`r  Progress: $processedCount files, migrated: $migrationCount" -NoNewline -ForegroundColor Gray
        }

        # Parse CSV line
        $line = $_ | ConvertFrom-Csv
        $filePath = $line.SourceFile
        $xmpPath = $filePath + ".xmp"

        if (Test-Path $xmpPath) {
            # Read XMP keywords (streaming)
            $keywords = & $exiftoolPath -XMP:Subject -csv $xmpPath 2>$null |
                Select-Object -Skip 1 |
                ForEach-Object {
                    $csvLine = $_ | ConvertFrom-Csv
                    $csvLine.'XMP:Subject'
                }

            if ($keywords) {
                # Check if any keyword matches device pattern
                foreach ($keyword in ($keywords -split ',')) {
                    $keyword = $keyword.Trim()
                    foreach ($pattern in $devicePatterns) {
                        if ($keyword -match "^$pattern$") {
                            # Found device keyword - copy to EXIF:Model
                            & $exiftoolPath "-EXIF:Model=$keyword" -P -overwrite_original $filePath 2>&1 | Out-Null
                            $migrationCount++

                            # Log to report
                            "Migrated: $filePath -> EXIF:Model=$keyword" | Out-File -FilePath $reportPath -Append -Encoding UTF8
                            break
                        }
                    }
                }
            }
        }

        # MEMORY OPTIMIZATION: Force garbage collection every 1000 files
        if ($processedCount % 1000 -eq 0) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    Write-Console "`n  Migrated device metadata to EXIF:Model for $migrationCount files" -ForegroundColor Green
    "Step 1: Migrated device metadata for $migrationCount files" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 2: Remove keywords from XMP sidecars
Write-Console "Step 2: Removing keywords from XMP sidecars..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $xmpWithKeywords = 0

    & $exiftoolPath -Subject -ext xmp -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header

        $line = $_ | ConvertFrom-Csv
        if ($line.Subject -and $line.Subject.Trim() -ne '') {
            $xmpWithKeywords++
        }
    }

    Write-Console "  Would remove keywords from $xmpWithKeywords XMP files" -ForegroundColor Yellow
    "Step 2: Would remove keywords from $xmpWithKeywords XMP files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing Subject from all XMP files..." -ForegroundColor Gray

    $result = & $exiftoolPath -Subject= -ext xmp -r -P -overwrite_original $Path 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Console "  ERROR removing Subject from XMP sidecars. See output below." -ForegroundColor Red
        Write-Console "  $result" -ForegroundColor DarkGray
        throw "ExifTool failed to remove XMP keywords. Review the log output above."
    }

    Write-Console "  Completed XMP sidecar cleanup" -ForegroundColor Green
    "Step 2: Removed keywords from XMP sidecars" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 3: Remove embedded IPTC:Keywords
Write-Console "Step 3: Removing embedded IPTC:Keywords..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $iptcCount = 0

    & $exiftoolPath -IPTC:Keywords -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header

        $line = $_ | ConvertFrom-Csv
        if ($line.Keywords -and $line.Keywords.Trim() -ne '') {
            $iptcCount++
        }
    }

    Write-Console "  Would remove IPTC:Keywords from $iptcCount files" -ForegroundColor Yellow
    "Step 3: Would remove IPTC:Keywords from $iptcCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing IPTC:Keywords from all media files..." -ForegroundColor Gray

    $result = & $exiftoolPath -IPTC:Keywords= -r -P -overwrite_original $Path 2>&1

    Write-Console "  Completed IPTC:Keywords cleanup" -ForegroundColor Green
    "Step 3: Removed IPTC:Keywords from media files" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 4: Remove embedded EXIF:XPKeywords
Write-Console "Step 4: Removing embedded EXIF:XPKeywords..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $xpkwCount = 0

    & $exiftoolPath -EXIF:XPKeywords -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header

        $line = $_ | ConvertFrom-Csv
        if ($line.XPKeywords -and $line.XPKeywords.Trim() -ne '') {
            $xpkwCount++
        }
    }

    Write-Console "  Would remove EXIF:XPKeywords from $xpkwCount files" -ForegroundColor Yellow
    "Step 4: Would remove EXIF:XPKeywords from $xpkwCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing EXIF:XPKeywords from all media files..." -ForegroundColor Gray

    $result = & $exiftoolPath -EXIF:XPKeywords= -r -P -overwrite_original $Path 2>&1

    Write-Console "  Completed EXIF:XPKeywords cleanup" -ForegroundColor Green
    "Step 4: Removed EXIF:XPKeywords from media files" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 5: Remove embedded XMP:Subject from media files
Write-Console "Step 5: Removing embedded XMP:Subject from media files..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $embeddedSubjectCount = 0

    & $exiftoolPath -Subject -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header
        if ($_ -match '\.xmp"?$') { return } # Skip XMP sidecars

        $line = $_ | ConvertFrom-Csv
        if ($line.Subject -and $line.Subject.Trim() -ne '') {
            $embeddedSubjectCount++
        }
    }

    Write-Console "  Would remove embedded XMP:Subject from $embeddedSubjectCount files" -ForegroundColor Yellow
    "Step 5: Would remove embedded XMP:Subject from $embeddedSubjectCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing embedded XMP:Subject from all media files..." -ForegroundColor Gray

    # MEMORY OPTIMIZATION: Use single ExifTool call instead of looping by extension
    $result = & $exiftoolPath -Subject= -r -P -overwrite_original -ext jpg -ext jpeg -ext png -ext heic -ext heif -ext mov -ext mp4 -ext avi -ext mkv -ext m4v $Path 2>&1

    Write-Console "  Completed embedded XMP:Subject cleanup" -ForegroundColor Green
    "Step 5: Removed embedded XMP:Subject from media files" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 6: Remove Microsoft keyword fields
Write-Console "Step 6: Removing Microsoft keyword fields..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $msKeywordCount = 0

    & $exiftoolPath -MicrosoftPhoto:LastKeywordXMP -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header

        $line = $_ | ConvertFrom-Csv
        if ($line.LastKeywordXMP -and $line.LastKeywordXMP.Trim() -ne '') {
            $msKeywordCount++
        }
    }

    Write-Console "  Would remove Microsoft keywords from $msKeywordCount files" -ForegroundColor Yellow
    "Step 6: Would remove Microsoft keywords from $msKeywordCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing Microsoft keyword fields from all media files..." -ForegroundColor Gray

    $result = & $exiftoolPath -MicrosoftPhoto:LastKeywordXMP= -XMP:LastKeywordXMP= -r -P -overwrite_original $Path 2>&1

    Write-Console "  Completed Microsoft keyword cleanup" -ForegroundColor Green
    "Step 6: Removed Microsoft keyword fields from media files" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

# Step 7: Remove photo editing software metadata
Write-Console "Step 7: Removing photo editing software metadata..." -ForegroundColor Cyan

if ($DryRun) {
    # MEMORY OPTIMIZATION: Stream count instead of accumulating array
    $softwareCount = 0

    & $exiftoolPath -CreatorTool -r -csv $Path 2>$null | ForEach-Object {
        if ($_ -match '^SourceFile,') { return } # Skip header
        if ($_ -match '\.xmp"?$') { return } # Skip XMP sidecars

        $line = $_ | ConvertFrom-Csv
        if ($line.CreatorTool -and $line.CreatorTool.Trim() -ne '') {
            $softwareCount++
        }
    }

    Write-Console "  Would remove software metadata from $softwareCount files" -ForegroundColor Yellow
    "Step 7: Would remove software metadata from $softwareCount files (Dry Run)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    Write-Console "  Removing photo editing software metadata..." -ForegroundColor Gray
    Write-Console "    (Preserving Camera, ExifTool, and Mylio metadata)" -ForegroundColor DarkGray

    # Remove ONLY photo editing software metadata, preserve camera/Mylio/ExifTool metadata
    # Remove: Adobe products (Photoshop, Lightroom, etc.), editing history, derivatives
    $result = & $exiftoolPath `
        -EXIF:Software= `
        -XMP:CreatorTool= `
        -XMP:History= `
        -XMP:DerivedFrom= `
        -Photoshop:All= `
        -r -P -overwrite_original `
        $Path 2>&1

    Write-Console "  Completed photo editing software metadata cleanup" -ForegroundColor Green
    "Step 7: Removed photo editing software metadata (preserved Camera/Mylio/ExifTool data)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

Write-Console ""

$elapsed = (Get-Date) - $startTime

# Summary
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Console "DRY RUN completed in $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
    Write-Console "`nNo changes were made. Run without -DryRun to remove keywords.`n" -ForegroundColor Yellow
} else {
    Write-Console "Keyword and metadata cleanup completed in $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Console "`nAll keywords and software metadata have been removed from:" -ForegroundColor White
    Write-Console "  - XMP sidecars (XMP:Subject)" -ForegroundColor Gray
    Write-Console "  - Embedded IPTC:Keywords" -ForegroundColor Gray
    Write-Console "  - Embedded EXIF:XPKeywords" -ForegroundColor Gray
    Write-Console "  - Embedded XMP:Subject" -ForegroundColor Gray
    Write-Console "  - Microsoft keyword fields" -ForegroundColor Gray
    Write-Console "  - Photo editing software metadata (CreatorTool, Software, History)" -ForegroundColor Gray
    Write-Console ""
}

# Append summary to report
$summary = @"

========================================
SUMMARY
========================================

Media files: $totalFiles
XMP sidecars: $totalXmp

Processing time: $($elapsed.ToString('hh\:mm\:ss'))

$(if ($DryRun) {
"DRY RUN - No changes were made"
} else {
"Keywords removed from:
- XMP sidecars (XMP:Subject)
- Embedded IPTC:Keywords
- Embedded EXIF:XPKeywords
- Embedded XMP:Subject
- Microsoft keyword fields"
})
"@

$summary | Out-File -FilePath $reportPath -Append -Encoding UTF8

Write-Console "Report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green

