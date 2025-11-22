# Check Mylio Smart Tag Settings and Current Status
# Examines database for settings tables and current smart tag count

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

Write-Console "=== Mylio Smart Tag Investigation ===" -ForegroundColor Cyan
Write-Console ""

if (-not (Test-Path $sqlite3)) {
    Write-Console "ERROR: sqlite3.exe not found at $sqlite3" -ForegroundColor Red
    exit 1
}

Write-Console "1. Finding settings/config tables..." -ForegroundColor Yellow
Write-Console ""

$settingsTables = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE '%setting%' OR name LIKE '%config%' OR name LIKE '%preference%' OR name LIKE '%option%') ORDER BY name;" 2>&1

if ($settingsTables) {
    Write-Console "Settings tables found:" -ForegroundColor Green
    foreach ($table in $settingsTables) {
        Write-Console "  - $table" -ForegroundColor Gray
    }
} else {
    Write-Console "No settings tables found with standard naming" -ForegroundColor Yellow
}

Write-Console ""
Write-Console "2. Checking current smart tag counts..." -ForegroundColor Yellow
Write-Console ""

# MediaMLImageTags count
$imageTagsCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLImageTags;" 2>&1
Write-Console "MediaMLImageTags: $imageTagsCount rows" -ForegroundColor $(if ($imageTagsCount -eq "0") { "Green" } else { "Red" })

# MediaMLHelper count
$helperCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLHelper WHERE ImageTaggerKeywords IS NOT NULL;" 2>&1
Write-Console "MediaMLHelper (with keywords): $helperCount rows" -ForegroundColor $(if ($helperCount -eq "0") { "Green" } else { "Red" })

# ImageTaggerKeywords count
$taggerCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM ImageTaggerKeywords;" 2>&1
Write-Console "ImageTaggerKeywords: $taggerCount rows" -ForegroundColor $(if ($taggerCount -eq "0") { "Green" } else { "Red" })

# MediaKeywords count
$keywordsCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaKeywords;" 2>&1
Write-Console "MediaKeywords: $keywordsCount rows" -ForegroundColor $(if ($keywordsCount -eq "0") { "Green" } else { "Red" })

Write-Console ""
Write-Console "3. Searching for ML/AI related tables..." -ForegroundColor Yellow
Write-Console ""

$mlTables = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE '%ML%' OR name LIKE '%media%' OR name LIKE '%tag%' OR name LIKE '%smart%') ORDER BY name;" 2>&1

if ($mlTables) {
    Write-Console "ML/Tag related tables:" -ForegroundColor Green
    foreach ($table in $mlTables) {
        $count = & $sqlite3 $dbPath "SELECT COUNT(*) FROM [$table];" 2>&1
        Write-Console "  - $table : $count rows" -ForegroundColor Gray
    }
}

Write-Console ""
Write-Console "4. Looking for configuration in all tables..." -ForegroundColor Yellow
Write-Console ""

# Get all tables
$allTables = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" 2>&1

foreach ($table in $allTables) {
    # Check if table has any column mentioning smart, ml, tag, or ai
    $schema = & $sqlite3 $dbPath "PRAGMA table_info([$table]);" 2>&1
    if ($schema -match "smart|ml|tag|ai|tagger|recognition|face") {
        Write-Console "Table '$table' may contain relevant settings:" -ForegroundColor Cyan
        Write-Console $schema -ForegroundColor DarkGray
        Write-Console ""
    }
}

Write-Console ""
Write-Console "=== Investigation Complete ===" -ForegroundColor Green
