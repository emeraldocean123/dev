# Delete stuck sync file from Mylio database
# File: 2009-12-11-29.3gp (Media ID: 268591)

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
$mediaId = 268591
$fileName = "2009-12-11-29"

Write-Console "=== Delete Stuck Sync File from Mylio Database ===" -ForegroundColor Cyan
Write-Console ""

# Check if Mylio is running
$mylioProc = Get-Process | Where-Object { $_.ProcessName -like "*mylio*" }
if ($mylioProc) {
    Write-Console "ERROR: Mylio is currently running!" -ForegroundColor Red
    Write-Console "Process IDs: $($mylioProc.Id -join ', ')" -ForegroundColor Yellow
    Write-Console ""
    Write-Console "Please close Mylio and run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Console "Mylio is not running - safe to proceed" -ForegroundColor Green
Write-Console ""

# Backup database first
$backupPath = "$dbPath.backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
Write-Console "Creating backup: $backupPath" -ForegroundColor Yellow
Copy-Item $dbPath $backupPath -Force
Write-Console "Backup created successfully" -ForegroundColor Green
Write-Console ""

# Verify the record exists
Write-Console "Verifying record exists..." -ForegroundColor Yellow
$verifyResult = & sqlite3 $dbPath "SELECT Id, FileNameNoExt FROM Media WHERE Id = $mediaId;"

if ($verifyResult) {
    Write-Console "Found record: $verifyResult" -ForegroundColor Green
} else {
    Write-Console "ERROR: Record not found in database!" -ForegroundColor Red
    exit 1
}
Write-Console ""

# Delete the record
Write-Console "Deleting Media record ID $mediaId..." -ForegroundColor Yellow

try {
    # Use a simple DELETE without triggers or custom functions
    $null = & sqlite3 $dbPath @"
PRAGMA foreign_keys=OFF;
DELETE FROM Media WHERE Id = $mediaId;
PRAGMA foreign_keys=ON;
"@

    Write-Console "Record deleted successfully" -ForegroundColor Green
    Write-Console ""

    # Verify deletion
    Write-Console "Verifying deletion..." -ForegroundColor Yellow
    $checkResult = & sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Id = $mediaId;"

    if ($checkResult -eq "0") {
        Write-Console "Verification successful - record has been deleted" -ForegroundColor Green
    } else {
        Write-Console "WARNING: Record may still exist!" -ForegroundColor Yellow
    }

} catch {
    Write-Console "ERROR during deletion: $_" -ForegroundColor Red
    Write-Console "Database backup available at: $backupPath" -ForegroundColor Yellow
    exit 1
}

Write-Console ""
Write-Console "=== Cleanup Complete ===" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  - File physically deleted: 2009-12-11-29.3gp" -ForegroundColor Gray
Write-Console "  - Database record deleted: Media ID $mediaId" -ForegroundColor Gray
Write-Console "  - Backup created: $backupPath" -ForegroundColor Gray
Write-Console ""
Write-Console "You can now restart Mylio - the sync should no longer be stuck" -ForegroundColor Green
Write-Console ""
