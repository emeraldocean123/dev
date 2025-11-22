# Clean XMP keywords from Mylio photo sidecar files
# Removes all keywords from dc:subject blocks while preserving file structure

param(
    [switch]$DryRun = $false,
    [switch]$Scan = $false
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$xmpPath = "D:\Mylio"
$logPath = "C:\Users\josep\Documents\dev\photos\mylio\archive"

Write-Console "=== XMP Keyword Cleanup ===" -ForegroundColor Cyan
Write-Console ""

if ($Scan) {
    Write-Console "SCAN MODE - Analyzing XMP files for keywords..." -ForegroundColor Yellow
} elseif ($DryRun) {
    Write-Console "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
} else {
    Write-Console "CLEANUP MODE - Will remove all keywords from XMP files" -ForegroundColor Yellow
}
Write-Console ""

# Get all XMP files
Write-Console "Scanning for XMP files in $xmpPath..." -ForegroundColor Gray
$xmpFiles = Get-ChildItem -Path $xmpPath -Filter "*.xmp" -Recurse -File
$totalFiles = $xmpFiles.Count

Write-Console "Found $totalFiles XMP files" -ForegroundColor Green
Write-Console ""

if ($totalFiles -eq 0) {
    Write-Console "No XMP files found. Exiting." -ForegroundColor Yellow
    exit 0
}

# Counters
$filesWithKeywords = 0
$filesCleaned = 0
$filesSkipped = 0
$errors = 0
$keywordsFound = @()

# Progress tracking
$processed = 0
$progressInterval = 1000
$startTime = Get-Date

Write-Console "Processing XMP files..." -ForegroundColor Green
Write-Console ""

foreach ($file in $xmpFiles) {
    $processed++

    # Show progress every N files
    if ($processed % $progressInterval -eq 0) {
        $percent = [math]::Round(($processed / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $rate = $processed / $elapsed.TotalSeconds
        $remaining = ($totalFiles - $processed) / $rate
        $eta = [TimeSpan]::FromSeconds($remaining)

        Write-Console "Progress: $processed / $totalFiles ($percent%) - ETA: $($eta.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    }

    try {
        # Read file content
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # Check if file has dc:subject with keywords
        if ($content -match '<dc:subject>\s*<rdf:Bag>\s*<rdf:li>') {
            $filesWithKeywords++

            # Extract keywords for logging
            $matches = [regex]::Matches($content, '<rdf:li>([^<]+)</rdf:li>')
            foreach ($match in $matches) {
                $keyword = $match.Groups[1].Value
                if ($keyword -notin $keywordsFound) {
                    $keywordsFound += $keyword
                }
            }

            if ($Scan) {
                # Just scanning, don't modify
                continue
            }

            if (-not $DryRun) {
                # Replace dc:subject block with empty one
                # This regex matches the entire dc:subject block with keywords
                $pattern = '(<dc:subject>\s*)<rdf:Bag>.*?</rdf:Bag>(\s*</dc:subject>)'
                $replacement = '$1<rdf:Bag/>$2'

                $newContent = $content -replace $pattern, $replacement

                # Verify the replacement worked
                if ($newContent -ne $content) {
                    # Write back to file
                    Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
                    $filesCleaned++
                } else {
                    Write-Console "  Warning: Could not clean $($file.Name)" -ForegroundColor Yellow
                    $filesSkipped++
                }
            } else {
                # Dry run - just count
                $filesCleaned++
            }
        } elseif ($content -match '<dc:subject>\s*<rdf:Bag/>') {
            # Already empty - skip
            $filesSkipped++
        } else {
            # No dc:subject block at all
            $filesSkipped++
        }

    } catch {
        Write-Console "  Error processing $($file.FullName): $_" -ForegroundColor Red
        $errors++
    }
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
Write-Console "Total XMP files: $totalFiles" -ForegroundColor Gray
Write-Console "Files with keywords: $filesWithKeywords" -ForegroundColor $(if ($filesWithKeywords -gt 0) { "Yellow" } else { "Green" })
Write-Console "Files cleaned: $filesCleaned" -ForegroundColor $(if ($filesCleaned -gt 0) { "Green" } else { "Gray" })
Write-Console "Files skipped (already clean): $filesSkipped" -ForegroundColor Gray
Write-Console "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Console ""

if ($keywordsFound.Count -gt 0) {
    Write-Console "Unique keywords found: $($keywordsFound.Count)" -ForegroundColor Yellow
    if ($keywordsFound.Count -le 20) {
        Write-Console "Keywords:" -ForegroundColor Gray
        foreach ($kw in ($keywordsFound | Sort-Object)) {
            Write-Console "  - $kw" -ForegroundColor DarkGray
        }
    } else {
        Write-Console "Sample keywords (first 20):" -ForegroundColor Gray
        foreach ($kw in ($keywordsFound | Sort-Object | Select-Object -First 20)) {
            Write-Console "  - $kw" -ForegroundColor DarkGray
        }
        Write-Console "  ... and $($keywordsFound.Count - 20) more" -ForegroundColor DarkGray
    }
    Write-Console ""
}

if ($Scan) {
    Write-Console "Scan complete! Run without -Scan to clean the files." -ForegroundColor Cyan
    Write-Console ""
    Write-Console "To clean: .\clean-xmp-keywords.ps1" -ForegroundColor Gray
    Write-Console "To dry run: .\clean-xmp-keywords.ps1 -DryRun" -ForegroundColor Gray
} elseif ($DryRun) {
    Write-Console "Dry run complete! Run without -DryRun to actually clean the files." -ForegroundColor Cyan
} else {
    if ($filesCleaned -gt 0) {
        Write-Console "Cleanup complete! $filesCleaned XMP files cleaned." -ForegroundColor Green
    } else {
        Write-Console "All XMP files are already clean!" -ForegroundColor Green
    }
}

Write-Console ""
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Console "Total time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
