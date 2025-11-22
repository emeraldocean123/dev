# Investigate files in Mylio database that aren't on disk

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

Write-Console "=== Investigating Missing Files ===" -ForegroundColor Cyan
Write-Console ""

# First, get the Media table structure
Write-Console "Media table structure:" -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(Media);"
Write-Console ""

# Get sample of records to understand the data
Write-Console "Sample media records (first 5):" -ForegroundColor Yellow
& $sqlite3 $dbPath ".mode column" ".headers on" "SELECT * FROM Media LIMIT 5;"
Write-Console ""

# Find files with paths that don't exist on disk
Write-Console "Checking for files with known paths..." -ForegroundColor Yellow
$allMedia = & $sqlite3 $dbPath "SELECT FileName, FolderPath FROM Media WHERE FileName IS NOT NULL LIMIT 100;" 2>&1

Write-Console "Sample file paths from database:" -ForegroundColor Cyan
$count = 0
foreach ($line in $allMedia) {
    if ($line -and $line.Trim() -ne "" -and $count -lt 10) {
        Write-Console "  $line" -ForegroundColor Gray
        $count++
    }
}
Write-Console ""

# Try to find records by checking common columns
Write-Console "Looking for media with specific characteristics..." -ForegroundColor Yellow
Write-Console ""

# Check if there are cloud-related flags
Write-Console "Checking for cloud/sync related columns:" -ForegroundColor Cyan
$columns = & $sqlite3 $dbPath "PRAGMA table_info(Media);" | Select-String -Pattern "cloud|sync|download|remote|online" -CaseSensitive:$false
if ($columns) {
    Write-Console "Found cloud-related columns:" -ForegroundColor Green
    $columns | ForEach-Object { Write-Console "  $_" -ForegroundColor Gray }
} else {
    Write-Console "No obvious cloud-related columns found" -ForegroundColor Yellow
}
Write-Console ""

# Get files by extension
Write-Console "Files by extension in database:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT SUBSTR(FileName, -4) as Extension, COUNT(*) as Count FROM Media WHERE FileName IS NOT NULL GROUP BY Extension ORDER BY Count DESC LIMIT 20;"
Write-Console ""

# Check MediaFile table if it exists
Write-Console "Checking for MediaFile table..." -ForegroundColor Yellow
$hasMediaFile = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND name='MediaFile';"
if ($hasMediaFile) {
    Write-Console "MediaFile table exists!" -ForegroundColor Green
    & $sqlite3 $dbPath "PRAGMA table_info(MediaFile);"
    Write-Console ""
    Write-Console "MediaFile record count:" -ForegroundColor Yellow
    & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaFile;"
} else {
    Write-Console "No MediaFile table found" -ForegroundColor Yellow
}
Write-Console ""
