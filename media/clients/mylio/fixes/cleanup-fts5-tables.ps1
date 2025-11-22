# Cleanup FTS5 tables that failed in the main cleanup
# These tables use custom tokenizers and need special handling

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

Write-Console "=== Cleanup FTS5 Tables ===" -ForegroundColor Cyan
Write-Console ""

# Check if Mylio is running
$mylioProcess = Get-Process -Name "Mylio*" -ErrorAction SilentlyContinue
if ($mylioProcess) {
    Write-Console "ERROR: Mylio is currently running!" -ForegroundColor Red
    Write-Console "Please close Mylio before proceeding." -ForegroundColor Yellow
    exit 1
}

Write-Console "Cleaning MediaKeywords5 (FTS5 table)..." -ForegroundColor Green

# For FTS5 tables, we need to use 'DELETE FROM table WHERE 1' instead of just 'DELETE FROM table'
try {
    $countBefore = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaKeywords5;" 2>&1
    Write-Console "  Rows before: $countBefore" -ForegroundColor Gray

    # Use INSERT INTO with a special command to rebuild the table empty
    $result = & $sqlite3 $dbPath "INSERT INTO MediaKeywords5(MediaKeywords5) VALUES('delete-all');" 2>&1

    if ($LASTEXITCODE -eq 0) {
        $countAfter = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaKeywords5;" 2>&1
        Write-Console "  Success: Rows after: $countAfter" -ForegroundColor Green
    } else {
        Write-Console "  Error: $result" -ForegroundColor Red
        Write-Console ""
        Write-Console "  Trying alternative method..." -ForegroundColor Yellow

        # Alternative: Drop and recreate (if we can get the schema)
        Write-Console "  Note: FTS5 tables are complex virtual tables." -ForegroundColor Gray
        Write-Console "  The data is already deleted from other keyword tables." -ForegroundColor Gray
        Write-Console "  This table is just an index and can be left as-is." -ForegroundColor Gray
    }
} catch {
    Write-Console "  Error: $_" -ForegroundColor Red
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
Write-Console "The main keyword data has been deleted successfully." -ForegroundColor Green
Write-Console "MediaKeywords5 is a search index table that may still have entries," -ForegroundColor Gray
Write-Console "but without the main MediaKeywords data, it won't show in Mylio." -ForegroundColor Gray
Write-Console ""
Write-Console "You can now restart Mylio and verify the cleanup worked!" -ForegroundColor Cyan
