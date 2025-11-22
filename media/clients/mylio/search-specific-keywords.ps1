# Search for Specific Keywords in Mylio Library
# Searches for user-created tags to be removed

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
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Keyword Search" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Searching for specific keywords in: $Path`n" -ForegroundColor White

# Keywords to search for
$keywords = @(
    "camera pictures",
    "Family",
    "Merlinda",
    "2010-7-24-Grand"
)

Write-Console "Keywords to find:" -ForegroundColor Yellow
foreach ($kw in $keywords) {
    Write-Console "  - $kw" -ForegroundColor Gray
}
Write-Console ""

# Search XMP sidecars first
Write-Console "Searching XMP sidecars..." -ForegroundColor Cyan

$xmpResults = @{}
foreach ($keyword in $keywords) {
    Write-Console "  Searching for: $keyword" -ForegroundColor Gray

    $files = & $exiftoolPath -XMP:Subject -if "`$XMP:Subject =~ /$keyword/i" -ext xmp -r -csv $Path 2>$null |
        ConvertFrom-Csv |
        Where-Object { $_.SourceFile }

    if ($files) {
        $xmpResults[$keyword] = $files
        Write-Console "    Found in $($files.Count) XMP files" -ForegroundColor Green
    } else {
        Write-Console "    Not found in XMP files" -ForegroundColor Gray
    }
}

Write-Console ""

# Search embedded IPTC:Keywords
Write-Console "Searching embedded IPTC:Keywords..." -ForegroundColor Cyan

$iptcResults = @{}
foreach ($keyword in $keywords) {
    Write-Console "  Searching for: $keyword" -ForegroundColor Gray

    $files = & $exiftoolPath -IPTC:Keywords -if "`$IPTC:Keywords =~ /$keyword/i" -r -csv $Path 2>$null |
        ConvertFrom-Csv |
        Where-Object { $_.SourceFile }

    if ($files) {
        $iptcResults[$keyword] = $files
        Write-Console "    Found in $($files.Count) files" -ForegroundColor Green
    } else {
        Write-Console "    Not found in IPTC" -ForegroundColor Gray
    }
}

Write-Console ""

# Search embedded EXIF:XPKeywords
Write-Console "Searching embedded EXIF:XPKeywords..." -ForegroundColor Cyan

$xpkwResults = @{}
foreach ($keyword in $keywords) {
    Write-Console "  Searching for: $keyword" -ForegroundColor Gray

    $files = & $exiftoolPath -EXIF:XPKeywords -if "`$EXIF:XPKeywords =~ /$keyword/i" -r -csv $Path 2>$null |
        ConvertFrom-Csv |
        Where-Object { $_.SourceFile }

    if ($files) {
        $xpkwResults[$keyword] = $files
        Write-Console "    Found in $($files.Count) files" -ForegroundColor Green
    } else {
        Write-Console "    Not found in XPKeywords" -ForegroundColor Gray
    }
}

Write-Console ""

# Generate summary report
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

$totalXmp = ($xmpResults.Values | Measure-Object -Property Count -Sum).Sum
$totalIptc = ($iptcResults.Values | Measure-Object -Property Count -Sum).Sum
$totalXpkw = ($xpkwResults.Values | Measure-Object -Property Count -Sum).Sum

Write-Console "XMP sidecars with keywords: $totalXmp" -ForegroundColor White
Write-Console "Embedded IPTC:Keywords: $totalIptc" -ForegroundColor White
Write-Console "Embedded EXIF:XPKeywords: $totalXpkw" -ForegroundColor White
Write-Console ""

# Save detailed report
$reportPath = "$PSScriptRoot\keyword-search-results-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$report = @"
Keyword Search Results
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path

========================================
SEARCH KEYWORDS
========================================

$($keywords -join ", ")

========================================
XMP SIDECAR RESULTS
========================================

"@

foreach ($kw in $keywords) {
    if ($xmpResults.ContainsKey($kw)) {
        $report += "`n$kw`: $($xmpResults[$kw].Count) files`n"
        $report += "Sample files:`n"
        $xmpResults[$kw] | Select-Object -First 5 | ForEach-Object {
            $report += "  $($_.SourceFile)`n"
        }
    } else {
        $report += "`n$kw`: Not found`n"
    }
}

$report += @"

========================================
EMBEDDED IPTC:KEYWORDS RESULTS
========================================

"@

foreach ($kw in $keywords) {
    if ($iptcResults.ContainsKey($kw)) {
        $report += "`n$kw`: $($iptcResults[$kw].Count) files`n"
        $report += "Sample files:`n"
        $iptcResults[$kw] | Select-Object -First 5 | ForEach-Object {
            $report += "  $($_.SourceFile)`n"
        }
    } else {
        $report += "`n$kw`: Not found`n"
    }
}

$report += @"

========================================
EMBEDDED EXIF:XPKEYWORDS RESULTS
========================================

"@

foreach ($kw in $keywords) {
    if ($xpkwResults.ContainsKey($kw)) {
        $report += "`n$kw`: $($xpkwResults[$kw].Count) files`n"
        $report += "Sample files:`n"
        $xpkwResults[$kw] | Select-Object -First 5 | ForEach-Object {
            $report += "  $($_.SourceFile)`n"
        }
    } else {
        $report += "`n$kw`: Not found`n"
    }
}

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "Detailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green
