# Parse the Files and LocalFiles columns to understand their structure

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$sqlite3 = "$env:USERPROFILE\bin\sqlite3.exe"
$dbPath = "C:\Users\josep\.Mylio_Catalog\Mylo.mylodb"

Write-Console "=== Examining Media Files Column Structure ===" -ForegroundColor Cyan
Write-Console ""

# Get a few sample records with the Files and LocalFiles columns
Write-Console "Sample Files column data:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT Id, Files FROM Media WHERE Files IS NOT NULL LIMIT 5;" 2>&1
Write-Console ""

Write-Console "Sample LocalFiles column data:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT Id, LocalFiles FROM Media WHERE LocalFiles IS NOT NULL LIMIT 5;" 2>&1
Write-Console ""

# Check for NULL vs non-NULL in these columns
Write-Console "Files column NULL status:" -ForegroundColor Yellow
$filesNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Files IS NULL;" 2>&1
$filesNotNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Files IS NOT NULL;" 2>&1
Write-Console "  NULL: $filesNull" -ForegroundColor Gray
Write-Console "  NOT NULL: $filesNotNull" -ForegroundColor Gray
Write-Console ""

Write-Console "LocalFiles column NULL status:" -ForegroundColor Yellow
$localNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE LocalFiles IS NULL;" 2>&1
$localNotNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE LocalFiles IS NOT NULL;" 2>&1
Write-Console "  NULL: $localNull" -ForegroundColor Gray
Write-Console "  NOT NULL: $localNotNull" -ForegroundColor Gray
Write-Console ""

# Check SoftFetch columns for cloud files
Write-Console "SoftFetch column statistics:" -ForegroundColor Yellow
Write-Console "SoftFetchOriginal values:" -ForegroundColor Cyan
& $sqlite3 $dbPath "SELECT SoftFetchOriginal, COUNT(*) as Count FROM Media GROUP BY SoftFetchOriginal ORDER BY Count DESC LIMIT 10;" 2>&1
Write-Console ""

Write-Console "SoftFetchPreview values:" -ForegroundColor Cyan
& $sqlite3 $dbPath "SELECT SoftFetchPreview, COUNT(*) as Count FROM Media GROUP BY SoftFetchPreview ORDER BY Count DESC LIMIT 10;" 2>&1
Write-Console ""

# Look for other potential cloud/sync related columns
Write-Console "Checking for cloud/sync indicators:" -ForegroundColor Yellow
Write-Console ""

# Check if there are records with Files but no LocalFiles
Write-Console "Records with Files but no LocalFiles (potential cloud-only):" -ForegroundColor Cyan
$cloudOnly = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Files IS NOT NULL AND LocalFiles IS NULL;" 2>&1
Write-Console "  Count: $cloudOnly" -ForegroundColor $(if ([int]$cloudOnly -gt 0) { "Yellow" } else { "Gray" })
Write-Console ""

# Sample some of those records
if ([int]$cloudOnly -gt 0) {
    Write-Console "Sample cloud-only records:" -ForegroundColor Yellow
    & $sqlite3 $dbPath "SELECT Id, Files, SoftFetchOriginal, SoftFetchPreview FROM Media WHERE Files IS NOT NULL AND LocalFiles IS NULL LIMIT 10;" 2>&1
    Write-Console ""
}

# Check FileNameNoExt and LocalFileNameNoExt
Write-Console "FileNameNoExt statistics:" -ForegroundColor Yellow
$fileNameNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE FileNameNoExt IS NULL;" 2>&1
$fileNameNotNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE FileNameNoExt IS NOT NULL;" 2>&1
Write-Console "  NULL: $fileNameNull" -ForegroundColor Gray
Write-Console "  NOT NULL: $fileNameNotNull" -ForegroundColor Gray
Write-Console ""

Write-Console "LocalFileNameNoExt statistics:" -ForegroundColor Yellow
$localNameNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE LocalFileNameNoExt IS NULL;" 2>&1
$localNameNotNull = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE LocalFileNameNoExt IS NOT NULL;" 2>&1
Write-Console "  NULL: $localNameNull" -ForegroundColor Gray
Write-Console "  NOT NULL: $localNameNotNull" -ForegroundColor Gray
Write-Console ""

# Sample records showing the relationship between these columns
Write-Console "Sample showing FileNameNoExt vs LocalFileNameNoExt:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT Id, FileNameNoExt, LocalFileNameNoExt, Files, LocalFiles FROM Media WHERE FileNameNoExt IS NOT NULL LIMIT 5;" 2>&1
Write-Console ""
