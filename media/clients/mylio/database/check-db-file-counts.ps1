# Check Mylio database for file counts

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

Write-Console "=== Mylio Database File Counts ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "Total Media records:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT COUNT(*) FROM Media;"
Write-Console ""

Write-Console "Media by type:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT MediaType, COUNT(*) as Count FROM Media GROUP BY MediaType ORDER BY Count DESC;"
Write-Console ""

Write-Console "File existence status:" -ForegroundColor Yellow
$exists = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE FileExists=1;"
$notExists = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE FileExists=0;"
Write-Console "  Files on disk: $exists" -ForegroundColor Green
Write-Console "  Files not on disk (cloud/missing): $notExists" -ForegroundColor Yellow
Write-Console ""

Write-Console "Comparison:" -ForegroundColor Cyan
Write-Console "  Database total: $($exists + $notExists)" -ForegroundColor White
Write-Console "  Mylio UI shows: 82,622" -ForegroundColor Yellow
Write-Console ""
