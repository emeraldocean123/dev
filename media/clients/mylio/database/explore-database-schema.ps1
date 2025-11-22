# Explore Mylio database schema to understand file tracking

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

Write-Console "=== Mylio Database Schema Exploration ===" -ForegroundColor Cyan
Write-Console ""

# List all tables
Write-Console "All tables in database:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" 2>&1
Write-Console ""

# Check for Folder table
Write-Console "Checking for Folder-related tables:" -ForegroundColor Yellow
$folderTables = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%Folder%';" 2>&1
if ($folderTables) {
    foreach ($table in $folderTables) {
        Write-Console "  Found: $table" -ForegroundColor Green
        Write-Console "  Structure:" -ForegroundColor Cyan
        & $sqlite3 $dbPath "PRAGMA table_info($table);" 2>&1
        Write-Console "  Record count:" -ForegroundColor Cyan
        & $sqlite3 $dbPath "SELECT COUNT(*) FROM $table;" 2>&1
        Write-Console ""
    }
}

# Check for Volume/Device/Storage tables
Write-Console "Checking for Volume/Device/Storage tables:" -ForegroundColor Yellow
$storageTables = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE '%Volume%' OR name LIKE '%Device%' OR name LIKE '%Storage%' OR name LIKE '%Drive%');" 2>&1
if ($storageTables) {
    foreach ($table in $storageTables) {
        Write-Console "  Found: $table" -ForegroundColor Green
        Write-Console "  Record count:" -ForegroundColor Cyan
        & $sqlite3 $dbPath "SELECT COUNT(*) FROM $table;" 2>&1
    }
    Write-Console ""
}

# Check RootFolder table if it exists
Write-Console "Checking RootFolder table:" -ForegroundColor Yellow
$hasRootFolder = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' AND name='RootFolder';" 2>&1
if ($hasRootFolder) {
    Write-Console "  RootFolder table exists!" -ForegroundColor Green
    & $sqlite3 $dbPath "PRAGMA table_info(RootFolder);" 2>&1
    Write-Console ""
    Write-Console "  Sample RootFolder records:" -ForegroundColor Cyan
    & $sqlite3 $dbPath "SELECT * FROM RootFolder LIMIT 5;" 2>&1
    Write-Console ""
} else {
    Write-Console "  No RootFolder table" -ForegroundColor Gray
}

# Check if there's a way to filter Media by device/location
Write-Console "Sample Media records with key location fields:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT Id, FileNameNoExt, RootFolderHash FROM Media LIMIT 10;" 2>&1
Write-Console ""

# Check NetworkNode for device information
Write-Console "NetworkNode records:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT NodeId, DeviceId, NodeName, IsThisDevice, Flags FROM NetworkNode;" 2>&1
Write-Console ""
