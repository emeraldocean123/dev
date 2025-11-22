# Scan XMP Sidecar Files Created by Mylio
# Analyzes structure and content of existing XMP sidecars

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
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  XMP Sidecar Scanner" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Scanning: $Path`n" -ForegroundColor White

# Get all XMP files
$xmpFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.xmp" -File -ErrorAction SilentlyContinue

$totalFiles = $xmpFiles.Count
Write-Console "Found $totalFiles XMP sidecar files`n" -ForegroundColor White

if ($totalFiles -eq 0) {
    Write-Console "No XMP sidecars found. Exiting.`n" -ForegroundColor Yellow
    exit 0
}

# Track XMP structure patterns
$namespaces = @{}
$xmpToolkits = @{}
$mylioFields = @{}
$documentIDs = 0
$hasKeywords = 0
$keywordExamples = @{}
$allElements = @{}

$processedCount = 0
$startTime = Get-Date

Write-Console "Analyzing XMP sidecar structure..." -ForegroundColor Cyan
Write-Console "This may take a while...`n" -ForegroundColor Gray

foreach ($xmpFile in $xmpFiles) {
    $processedCount++

    if ($processedCount % 100 -eq 0) {
        $percentComplete = [math]::Round(($processedCount / $totalFiles) * 100, 1)
        $elapsed = (Get-Date) - $startTime
        $estimatedTotal = $elapsed.TotalSeconds / $processedCount * $totalFiles
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)

        Write-Console "`rProgress: $processedCount / $totalFiles ($percentComplete%) - ETA: $($remaining.ToString('hh\:mm\:ss'))" -NoNewline -ForegroundColor Yellow
    }

    try {
        [xml]$xmpContent = Get-Content $xmpFile.FullName -ErrorAction Stop

        # Get root element and navigate to Description
        $rdfDescription = $xmpContent.GetElementsByTagName("rdf:Description")[0]

        if (-not $rdfDescription) {
            # Try without namespace prefix
            $rdfDescription = $xmpContent.GetElementsByTagName("Description")[0]
        }

        if ($rdfDescription) {
            # Count xmlns declarations
            foreach ($attr in $rdfDescription.Attributes) {
                if ($attr.Name.StartsWith("xmlns:")) {
                    $prefix = $attr.Name -replace '^xmlns:', ''
                    $uri = $attr.Value

                    if (-not $namespaces.ContainsKey($prefix)) {
                        $namespaces[$prefix] = @{ URI = $uri; Count = 0; SampleFile = $xmpFile.Name }
                    }
                    $namespaces[$prefix].Count++
                }
            }

            # Track XMP Toolkit versions
            foreach ($attr in $rdfDescription.Attributes) {
                if ($attr.LocalName -eq "xmptk") {
                    $toolkit = $attr.Value
                    if (-not $xmpToolkits.ContainsKey($toolkit)) {
                        $xmpToolkits[$toolkit] = 0
                    }
                    $xmpToolkits[$toolkit]++
                    break
                }
            }

            # Track all attributes (fields)
            foreach ($attr in $rdfDescription.Attributes) {
                $attrName = $attr.Name
                if (-not $attrName.StartsWith("xmlns:") -and $attrName -ne "rdf:about") {
                    if (-not $allElements.ContainsKey($attrName)) {
                        $allElements[$attrName] = @{ Count = 0; SampleValue = $attr.Value; SampleFile = $xmpFile.Name }
                    }
                    $allElements[$attrName].Count++

                    # Track Mylio-specific fields
                    if ($attrName.StartsWith("MY:")) {
                        if (-not $mylioFields.ContainsKey($attrName)) {
                            $mylioFields[$attrName] = @{ Count = 0; SampleValue = $attr.Value }
                        }
                        $mylioFields[$attrName].Count++
                    }

                    # Track DocumentID presence
                    if ($attrName -eq "xmpMM:DocumentID") {
                        $documentIDs++
                    }
                }
            }

            # Check for keywords (dc:subject)
            $dcSubject = $rdfDescription.GetElementsByTagName("dc:subject")[0]
            if ($dcSubject) {
                $hasKeywords++
                # Get all rdf:li elements under dc:subject
                $keywords = $dcSubject.GetElementsByTagName("rdf:li")

                foreach ($keyword in $keywords) {
                    $keywordText = $keyword.InnerText
                    if ($keywordText) {
                        if (-not $keywordExamples.ContainsKey($keywordText)) {
                            $keywordExamples[$keywordText] = 0
                        }
                        $keywordExamples[$keywordText]++
                    }
                }
            }
        }

    } catch {
        # Skip invalid XML files
        continue
    }
}

Write-Console "`n`n" # Clear progress line

$elapsed = (Get-Date) - $startTime

# Generate Report
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  XMP Toolkits Found" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

foreach ($toolkit in $xmpToolkits.Keys | Sort-Object) {
    $count = $xmpToolkits[$toolkit]
    Write-Console "$toolkit" -ForegroundColor Yellow
    Write-Console "  Count: $count" -ForegroundColor Gray
    Write-Console ""
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  XML Namespaces Used" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

foreach ($ns in $namespaces.Keys | Sort-Object) {
    $uri = $namespaces[$ns].URI
    $count = $namespaces[$ns].Count
    $sample = $namespaces[$ns].SampleFile

    Write-Console "$ns`:" -ForegroundColor Yellow
    Write-Console "  URI: $uri" -ForegroundColor Gray
    Write-Console "  Occurrences: $count" -ForegroundColor Gray
    Write-Console "  Sample: $sample" -ForegroundColor Gray
    Write-Console ""
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Mylio-Specific Fields (MY:*)" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if ($mylioFields.Count -eq 0) {
    Write-Console "No Mylio fields found`n" -ForegroundColor Gray
} else {
    foreach ($field in $mylioFields.Keys | Sort-Object) {
        $count = $mylioFields[$field].Count
        $sample = $mylioFields[$field].SampleValue

        Write-Console "$field" -ForegroundColor Yellow
        Write-Console "  Count: $count" -ForegroundColor Gray
        Write-Console "  Sample value: $sample" -ForegroundColor Gray
        Write-Console ""
    }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Keyword Statistics" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Files with keywords: $hasKeywords / $totalFiles" -ForegroundColor White
Write-Console "Unique keywords: $($keywordExamples.Count)`n" -ForegroundColor White

if ($keywordExamples.Count -gt 0) {
    Write-Console "Top 20 keywords:" -ForegroundColor Yellow
    $topKeywords = $keywordExamples.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 20
    foreach ($kw in $topKeywords) {
        Write-Console "  $($kw.Key) ($($kw.Value) files)" -ForegroundColor Gray
    }
    Write-Console ""
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "XMP files scanned: $processedCount" -ForegroundColor White
Write-Console "Unique namespaces: $($namespaces.Count)" -ForegroundColor White
Write-Console "Unique fields/attributes: $($allElements.Count)" -ForegroundColor White
Write-Console "Mylio-specific fields: $($mylioFields.Count)" -ForegroundColor White
Write-Console "Files with DocumentID: $documentIDs" -ForegroundColor White
Write-Console "Files with keywords: $hasKeywords" -ForegroundColor White
Write-Console "`nProcessing time: $($elapsed.ToString('hh\:mm\:ss'))`n" -ForegroundColor White

# Save detailed report
$reportPath = "$PSScriptRoot\xmp-sidecar-scan-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
$report = @"
XMP Sidecar Scan Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Path: $Path
Files scanned: $processedCount

========================================
XMP TOOLKITS
========================================

"@

foreach ($toolkit in $xmpToolkits.Keys | Sort-Object) {
    $count = $xmpToolkits[$toolkit]
    $report += "$toolkit`: $count files`n"
}

$report += @"

========================================
XML NAMESPACES
========================================

"@

foreach ($ns in $namespaces.Keys | Sort-Object) {
    $uri = $namespaces[$ns].URI
    $count = $namespaces[$ns].Count
    $sample = $namespaces[$ns].SampleFile

    $report += "`n$ns`:`n"
    $report += "  URI: $uri`n"
    $report += "  Occurrences: $count`n"
    $report += "  Sample file: $sample`n"
}

$report += @"

========================================
MYLIO-SPECIFIC FIELDS (MY:*)
========================================

"@

if ($mylioFields.Count -eq 0) {
    $report += "No Mylio fields found`n"
} else {
    foreach ($field in $mylioFields.Keys | Sort-Object) {
        $count = $mylioFields[$field].Count
        $sample = $mylioFields[$field].SampleValue

        $report += "`n$field`:`n"
        $report += "  Count: $count`n"
        $report += "  Sample value: $sample`n"
    }
}

$report += @"

========================================
KEYWORDS
========================================

Files with keywords: $hasKeywords / $totalFiles
Unique keywords: $($keywordExamples.Count)

Top 50 keywords:

"@

$top50Keywords = $keywordExamples.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 50
foreach ($kw in $top50Keywords) {
    $report += "  $($kw.Key) ($($kw.Value) files)`n"
}

$report += @"

========================================
ALL XMP FIELDS (sorted by frequency)
========================================

"@

$sortedElements = $allElements.GetEnumerator() | Sort-Object -Property { $_.Value.Count } -Descending
foreach ($elem in $sortedElements) {
    $report += "`n$($elem.Key): $($elem.Value.Count) occurrences`n"
    $report += "  Sample value: $($elem.Value.SampleValue)`n"
    $report += "  Sample file: $($elem.Value.SampleFile)`n"
}

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Console "Detailed report saved to:" -ForegroundColor White
Write-Console "$reportPath`n" -ForegroundColor Green
