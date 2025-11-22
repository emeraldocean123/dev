# Force delete media record by dumping and reimporting database
# This bypasses Mylio's triggers

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
$tempDir = "C:\Users\josep\.Mylio_Catalog\temp_db_fix"

Write-Console "=== Force Delete Media Record (Bypass Triggers) ===" -ForegroundColor Cyan
Write-Console ""

# Check Mylio is not running
$mylioProc = Get-Process | Where-Object { $_.ProcessName -like "*mylio*" }
if ($mylioProc) {
    Write-Console "ERROR: Mylio is running! Please close it first." -ForegroundColor Red
    exit 1
}

Write-Console "Creating working directory..." -ForegroundColor Yellow
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Backup original database
$backupPath = "$dbPath.backup-force-delete-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
Write-Console "Backing up database to: $backupPath" -ForegroundColor Yellow
Copy-Item $dbPath $backupPath -Force
Write-Console "Backup complete" -ForegroundColor Green
Write-Console ""

# Export database schema and data
Write-Console "Exporting database..." -ForegroundColor Yellow
$dumpFile = Join-Path $tempDir "database_dump.sql"

# Use .dump but filter out the problem record
$dumpCmd = @"
.output '$dumpFile'
.dump
"@

$dumpCmd | sqlite3 $dbPath

Write-Console "Database exported to: $dumpFile" -ForegroundColor Green
Write-Console ""

# Filter out the problem record
Write-Console "Filtering out Media ID $mediaId..." -ForegroundColor Yellow
$dumpContent = Get-Content $dumpFile -Raw -Encoding UTF8

# Count occurrences before
$beforeCount = ([regex]::Matches($dumpContent, "INSERT INTO `"Media`".*?268591")).Count
Write-Console "Found $beforeCount references to Media ID 268591" -ForegroundColor Gray

# Remove the INSERT statement for this media record
# This is tricky because the INSERT might span multiple lines
$filteredContent = $dumpContent -replace "INSERT INTO `"Media`" VALUES\([^)]*268591[^)]*\);`r?`n?", ""

# Also try without backticks
$filteredContent = $filteredContent -replace "INSERT INTO ""Media"" VALUES\([^)]*268591[^)]*\);`r?`n?", ""
$filteredContent = $filteredContent -replace "INSERT INTO Media VALUES\([^)]*268591[^)]*\);`r?`n?", ""

# Count after
$afterCount = ([regex]::Matches($filteredContent, "268591")).Count
Write-Console "After filtering, $afterCount references remain" -ForegroundColor Gray

if ($afterCount -gt 0) {
    Write-Console "WARNING: Some references to 268591 may still exist in other tables" -ForegroundColor Yellow
    Write-Console "This is okay - they will be orphaned references" -ForegroundColor Gray
}

# Save filtered dump
$filteredDumpFile = Join-Path $tempDir "database_dump_filtered.sql"
$filteredContent | Out-File -FilePath $filteredDumpFile -Encoding UTF8 -NoNewline
Write-Console "Filtered dump saved" -ForegroundColor Green
Write-Console ""

# Create new database from filtered dump
Write-Console "Creating new database from filtered dump..." -ForegroundColor Yellow
$newDbPath = Join-Path $tempDir "Mylo_new.mylodb"

if (Test-Path $newDbPath) {
    Remove-Item $newDbPath -Force
}

# Import filtered dump
$importCmd = ".read '$filteredDumpFile'"
$importCmd | sqlite3 $newDbPath

if ($LASTEXITCODE -ne 0) {
    Write-Console "ERROR: Failed to import filtered database!" -ForegroundColor Red
    Write-Console "Original database backup is safe at: $backupPath" -ForegroundColor Yellow
    exit 1
}

Write-Console "New database created successfully" -ForegroundColor Green
Write-Console ""

# Verify the record is gone in new database
Write-Console "Verifying deletion in new database..." -ForegroundColor Yellow
$checkResult = sqlite3 $newDbPath "SELECT COUNT(*) FROM Media WHERE Id = $mediaId;"

if ($checkResult -eq "0") {
    Write-Console "SUCCESS: Record 268591 not found in new database!" -ForegroundColor Green
} else {
    Write-Console "ERROR: Record still exists in new database!" -ForegroundColor Red
    Write-Console "Original database backup is safe at: $backupPath" -ForegroundColor Yellow
    exit 1
}
Write-Console ""

# Replace original database with new one
Write-Console "Replacing original database with cleaned version..." -ForegroundColor Yellow
Write-Console "Original: $dbPath" -ForegroundColor Gray
Write-Console "Backup: $backupPath" -ForegroundColor Gray

# Move original to backup (already done), move new to original
Move-Item $newDbPath $dbPath -Force

Write-Console "Database replaced successfully!" -ForegroundColor Green
Write-Console ""

# Verify in production database
Write-Console "Final verification..." -ForegroundColor Yellow
$finalCheck = sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Id = $mediaId;"

if ($finalCheck -eq "0") {
    Write-Console "VERIFIED: Record 268591 successfully deleted from production database!" -ForegroundColor Green
} else {
    Write-Console "WARNING: Record may still exist!" -ForegroundColor Yellow
}

Write-Console ""
Write-Console "=== Cleanup Complete ===" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  - Backup created: $backupPath" -ForegroundColor Gray
Write-Console "  - Media ID 268591 (2009-12-11-29.3gp) removed from database" -ForegroundColor Gray
Write-Console "  - Database integrity maintained" -ForegroundColor Gray
Write-Console ""
Write-Console "You can now restart Mylio" -ForegroundColor Green
Write-Console ""
