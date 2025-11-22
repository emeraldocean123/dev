# Copy Verified Test Files
# Copies specific files that were verified to have keywords for testing

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$testDir = "D:\Mylio-Test"
$exiftoolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe"

# Clean test directory
Write-Console "Cleaning test directory..." -ForegroundColor Cyan
Remove-Item "$testDir\*" -Force -ErrorAction SilentlyContinue

# List of verified files with keywords
$verifiedFiles = @(
    "D:\Mylio\Folder-Follett\2004\(11) November\2004-11-28-16.jpg",           # IPTC:Keywords
    "D:\Mylio\Folder-Follett\2010\(05) May\2010-05-14-1.mov",                 # dc:subject, MicrosoftPhoto:LastKeywordXMP
    "D:\Mylio\Folder-Follett\2010\(07) July\2010-07-18-9.jpg",                # All 4 keyword types
    "D:\Mylio\Folder-Follett\2010\(09) September\2010-09-19-395.jpg",         # 3 keyword types
    "D:\Mylio\Folder-Follett\2010\(11) November\2010-11-25-282.jpg",          # MicrosoftPhoto:LastKeywordXMP, dc:subject
    "D:\Mylio\Folder-Follett\2012\(07) July\2012-07-16-180.jpg"               # IPTC:Keywords, dc:subject
)

Write-Console "`nCopying verified files to test folder..." -ForegroundColor Cyan
$copied = 0

foreach ($file in $verifiedFiles) {
    if (Test-Path $file) {
        # Copy the main file
        Copy-Item $file $testDir
        $copied++

        # Check for XMP sidecar
        $xmpPath = $file + ".xmp"
        if (Test-Path $xmpPath) {
            Copy-Item $xmpPath $testDir
            Write-Console "  Copied: $(Split-Path -Leaf $file) + XMP sidecar" -ForegroundColor Green
        } else {
            Write-Console "  Copied: $(Split-Path -Leaf $file)" -ForegroundColor Green
        }
    } else {
        Write-Console "  NOT FOUND: $file" -ForegroundColor Red
    }
}

Write-Console "`nCopied $copied files to test folder" -ForegroundColor White

# Now test detection on each file
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Testing Keyword Detection" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

$testFiles = Get-ChildItem -Path $testDir -File | Where-Object { $_.Extension -ne '.xmp' }

foreach ($file in $testFiles) {
    Write-Console "File: $($file.Name)" -ForegroundColor Yellow

    # Check IPTC:Keywords
    $iptc = & $exiftoolPath -IPTC:Keywords -csv $file.FullName 2>$null |
        ConvertFrom-Csv |
        Select-Object -ExpandProperty Keywords -ErrorAction SilentlyContinue
    if ($iptc) {
        Write-Console "  [OK] IPTC:Keywords: $iptc" -ForegroundColor Green
    }

    # Check EXIF:XPKeywords
    $xpkw = & $exiftoolPath -EXIF:XPKeywords -csv $file.FullName 2>$null |
        ConvertFrom-Csv |
        Select-Object -ExpandProperty XPKeywords -ErrorAction SilentlyContinue
    if ($xpkw) {
        Write-Console "  [OK] EXIF:XPKeywords: $xpkw" -ForegroundColor Green
    }

    # Check XMP:Subject (embedded)
    $subject = & $exiftoolPath -Subject -csv $file.FullName 2>$null |
        ConvertFrom-Csv |
        Select-Object -ExpandProperty Subject -ErrorAction SilentlyContinue
    if ($subject) {
        Write-Console "  [OK] XMP:Subject: $subject" -ForegroundColor Green
    }

    # Check MicrosoftPhoto:LastKeywordXMP
    $mskw = & $exiftoolPath -MicrosoftPhoto:LastKeywordXMP -csv $file.FullName 2>$null |
        ConvertFrom-Csv |
        Select-Object -ExpandProperty LastKeywordXMP -ErrorAction SilentlyContinue
    if ($mskw) {
        Write-Console "  [OK] MicrosoftPhoto:LastKeywordXMP: $mskw" -ForegroundColor Green
    }

    # Check for XMP sidecar
    $xmpPath = $file.FullName + ".xmp"
    if (Test-Path $xmpPath) {
        $xmpSubject = & $exiftoolPath -Subject -csv $xmpPath 2>$null |
            ConvertFrom-Csv |
            Select-Object -ExpandProperty Subject -ErrorAction SilentlyContinue
        if ($xmpSubject) {
            Write-Console "  [OK] XMP Sidecar Subject: $xmpSubject" -ForegroundColor Green
        }
    }

    Write-Console ""
}

Write-Console "Detection test complete!" -ForegroundColor Cyan
