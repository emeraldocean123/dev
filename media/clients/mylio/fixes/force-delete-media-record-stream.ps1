# Force delete media record by streaming SQL dump (memory efficient)
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

Write-Console "=== Force Delete Media Record (Stream Processing) ===" -ForegroundColor Cyan
Write-Console ""

# Check Mylio is not running
$mylioProc = Get-Process -Name "*mylio*" -ErrorAction SilentlyContinue
if ($mylioProc) {
    Write-Console "ERROR: Mylio is running! Please close it first." -ForegroundColor Red
    exit 1
}

Write-Console "Using existing temp directory: $tempDir" -ForegroundColor Yellow
$dumpFile = Join-Path $tempDir "database_dump.sql"
$filteredDumpFile = Join-Path $tempDir "database_dump_filtered.sql"

if (Test-Path $filteredDumpFile) {
    Remove-Item $filteredDumpFile -Force
}

Write-Console "Streaming and filtering dump file (this may take a minute)..." -ForegroundColor Yellow
$linesProcessed = 0
$linesFiltered = 0

# Stream process the file line-by-line
$reader = [System.IO.File]::OpenText($dumpFile)
$writer = [System.IO.StreamWriter]::new($filteredDumpFile, $false, [System.Text.Encoding]::UTF8)

try {
    while ($null -ne ($line = $reader.ReadLine())) {
        $linesProcessed++

        # Show progress every 100,000 lines
        if ($linesProcessed % 100000 -eq 0) {
            Write-Console "  Processed $linesProcessed lines..." -ForegroundColor Gray
        }

        # Skip lines that reference Media ID 268591
        if ($line -match '268591') {
            $linesFiltered++
            continue
        }

        $writer.WriteLine($line)
    }
} finally {
    $reader.Close()
    $writer.Close()
}

Write-Console "Filtered $linesFiltered lines containing 268591 from $linesProcessed total lines" -ForegroundColor Green
Write-Console ""

# Create new database from filtered dump
Write-Console "Creating new database from filtered dump..." -ForegroundColor Yellow
$newDbPath = Join-Path $tempDir "Mylo_new.mylodb"

if (Test-Path $newDbPath) {
    Remove-Item $newDbPath -Force
}

# Import filtered dump
$importCmd = ".read '$filteredDumpFile'"
$importCmd | sqlite3 $newDbPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Console "ERROR: Failed to import filtered database!" -ForegroundColor Red
    Write-Console "Original database is safe at: $dbPath" -ForegroundColor Yellow
    exit 1
}

Write-Console "New database created successfully" -ForegroundColor Green
Write-Console ""

# Verify the record is gone in new database
Write-Console "Verifying deletion in new database..." -ForegroundColor Yellow
$checkResult = sqlite3 $newDbPath "SELECT COUNT(*) FROM Media WHERE Id = $mediaId;" 2>&1

if ($checkResult -eq "0") {
    Write-Console "SUCCESS: Record 268591 not found in new database!" -ForegroundColor Green
} else {
    Write-Console "ERROR: Record still exists in new database!" -ForegroundColor Red
    Write-Console "Count result: $checkResult" -ForegroundColor Yellow
    exit 1
}
Write-Console ""

# Create final backup before replacing
$backupPath = "$dbPath.backup-stream-delete-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
Write-Console "Creating final backup: $backupPath" -ForegroundColor Yellow
Copy-Item $dbPath $backupPath -Force
Write-Console ""

# Replace original database with new one
Write-Console "Replacing original database with cleaned version..." -ForegroundColor Yellow
Move-Item $newDbPath $dbPath -Force
Write-Console "Database replaced successfully!" -ForegroundColor Green
Write-Console ""

# Verify in production database
Write-Console "Final verification..." -ForegroundColor Yellow
$finalCheck = sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Id = $mediaId;" 2>&1

if ($finalCheck -eq "0") {
    Write-Console "VERIFIED: Record 268591 successfully deleted from production database!" -ForegroundColor Green
} else {
    Write-Console "WARNING: Record may still exist! Count: $finalCheck" -ForegroundColor Yellow
}

Write-Console ""
Write-Console "=== Cleanup Complete ===" -ForegroundColor Green
Write-Console ""
Write-Console "Summary:" -ForegroundColor Cyan
Write-Console "  - Backup created: $backupPath" -ForegroundColor Gray
Write-Console "  - Media ID 268591 (2009-12-11-29.3gp) removed from database" -ForegroundColor Gray
Write-Console "  - Filtered $linesFiltered lines from SQL dump" -ForegroundColor Gray
Write-Console ""
Write-Console "You can now restart Mylio" -ForegroundColor Green
Write-Console ""
