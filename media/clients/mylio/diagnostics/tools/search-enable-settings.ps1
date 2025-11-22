# Search for actual enable/disable settings in Mylio database

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

Write-Console "=== Searching for Enable/Disable Settings ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "Checking NetworkNode Flags (may contain feature toggles)..." -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT DeviceId, NodeName, IsThisDevice, Flags, KeepAllDocuments FROM NetworkNode WHERE IsThisDevice=1;"
Write-Console ""

Write-Console "Searching Configuration table for all keys..." -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT ConfigKey, ConfigVal FROM Configuration ORDER BY ConfigKey;"
Write-Console ""

Write-Console "Checking if there are Account-level feature flags..." -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(Account);"
Write-Console ""
& $sqlite3 $dbPath "SELECT FeatureSet0, FeatureSet1, Flags FROM Account;"
Write-Console ""
