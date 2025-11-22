# Find Smart Tag Settings in Configuration Tables

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$dbPath = "C:\Users\josep\.Mylio_Catalog\Mylo.mylodb"
$sqlite3 = "$env:USERPROFILE\bin\sqlite3.exe"

Write-Console "=== Examining Configuration Tables ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "Configuration table schema:" -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(Configuration);"
Write-Console ""

Write-Console "Configuration table contents:" -ForegroundColor Yellow
& $sqlite3 $dbPath ".mode column" ".headers on" "SELECT * FROM Configuration;"
Write-Console ""

Write-Console "SharedConfiguration table schema:" -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(SharedConfiguration);"
Write-Console ""

Write-Console "SharedConfiguration table contents:" -ForegroundColor Yellow
& $sqlite3 $dbPath ".mode column" ".headers on" "SELECT * FROM SharedConfiguration;"
Write-Console ""

Write-Console "Searching for Smart Tag / ML related settings..." -ForegroundColor Yellow
Write-Console ""

# Search Configuration for ML/smart/tag related settings
$configSearch = & $sqlite3 $dbPath "SELECT * FROM Configuration WHERE Key LIKE '%smart%' OR Key LIKE '%ml%' OR Key LIKE '%tag%' OR Key LIKE '%ai%' OR Key LIKE '%face%' OR Key LIKE '%recognition%' OR Key LIKE '%ocr%';" 2>&1

if ($configSearch) {
    Write-Console "Found in Configuration:" -ForegroundColor Green
    Write-Console $configSearch
} else {
    Write-Console "No ML/smart tag settings found in Configuration" -ForegroundColor Yellow
}

Write-Console ""

# Search SharedConfiguration
$sharedSearch = & $sqlite3 $dbPath "SELECT * FROM SharedConfiguration WHERE Key LIKE '%smart%' OR Key LIKE '%ml%' OR Key LIKE '%tag%' OR Key LIKE '%ai%' OR Key LIKE '%face%' OR Key LIKE '%recognition%' OR Key LIKE '%ocr%';" 2>&1

if ($sharedSearch) {
    Write-Console "Found in SharedConfiguration:" -ForegroundColor Green
    Write-Console $sharedSearch
} else {
    Write-Console "No ML/smart tag settings found in SharedConfiguration" -ForegroundColor Yellow
}
