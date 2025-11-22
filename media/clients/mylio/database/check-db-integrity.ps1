# Check Mylio database integrity and repair if needed

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
$backupPath = "C:\Users\josep\.Mylio_Catalog\Mylo.mylodb.backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"

Write-Console "=== Mylio Database Integrity Check ===" -ForegroundColor Cyan
Write-Console ""

# Check if database is locked
Write-Console "Checking database lock status..." -ForegroundColor Yellow

try {
    $stream = [System.IO.File]::Open($dbPath, 'Open', 'Read', 'None')
    $stream.Close()
    Write-Console "Database is not locked - accessible" -ForegroundColor Green
} catch {
    Write-Console "WARNING: Database appears to be locked or in use" -ForegroundColor Red
    Write-Console "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Console ""
    Write-Console "Mylio must be closed before running integrity checks" -ForegroundColor Yellow
    Write-Console ""

    # Check if Mylio is running
    $mylioProc = Get-Process | Where-Object { $_.ProcessName -like "*mylio*" }
    if ($mylioProc) {
        Write-Console "Mylio is currently running (PIDs: $($mylioProc.Id -join ', '))" -ForegroundColor Red
        Write-Console "Please close Mylio and run this script again" -ForegroundColor Yellow
        exit 1
    }
}

Write-Console ""

# Run integrity check using sqlite3
Write-Console "=== Running PRAGMA integrity_check ===" -ForegroundColor Cyan
Write-Console ""

$integrityResult = sqlite3 "$dbPath" "PRAGMA integrity_check;"

if ($integrityResult -eq "ok") {
    Write-Console "Database integrity: OK" -ForegroundColor Green
} else {
    Write-Console "Database integrity: FAILED" -ForegroundColor Red
    Write-Console "Errors found:" -ForegroundColor Yellow
    $integrityResult | ForEach-Object {
        Write-Console "  $_" -ForegroundColor Red
    }
    Write-Console ""
    Write-Console "Database corruption detected!" -ForegroundColor Red
}

Write-Console ""

# Check for WAL (Write-Ahead Logging) mode
Write-Console "=== Checking WAL Mode ===" -ForegroundColor Cyan
Write-Console ""

$walMode = sqlite3 "$dbPath" "PRAGMA journal_mode;"
Write-Console "Journal mode: $walMode" -ForegroundColor $(if ($walMode -eq "wal") { "Green" } else { "Yellow" })

# Check for WAL and SHM files
$walFile = "$dbPath-wal"
$shmFile = "$dbPath-shm"

if (Test-Path $walFile) {
    $walSize = (Get-Item $walFile).Length
    Write-Console "WAL file exists: $([math]::Round($walSize / 1KB, 2)) KB" -ForegroundColor Yellow

    if ($walSize -gt 10MB) {
        Write-Console "  WARNING: WAL file is large - may need checkpoint" -ForegroundColor Red
    }
} else {
    Write-Console "No WAL file found" -ForegroundColor Green
}

if (Test-Path $shmFile) {
    Write-Console "SHM file exists: $((Get-Item $shmFile).Length) bytes" -ForegroundColor Gray
} else {
    Write-Console "No SHM file found" -ForegroundColor Green
}

Write-Console ""

# Check database version and schema
Write-Console "=== Database Information ===" -ForegroundColor Cyan
Write-Console ""

$userVersion = sqlite3 "$dbPath" "PRAGMA user_version;"
Write-Console "User version: $userVersion" -ForegroundColor Gray

$pageSize = sqlite3 "$dbPath" "PRAGMA page_size;"
Write-Console "Page size: $pageSize bytes" -ForegroundColor Gray

$pageCount = sqlite3 "$dbPath" "PRAGMA page_count;"
$dbSizeMB = [math]::Round(($pageSize * $pageCount) / 1MB, 2)
Write-Console "Database size: $dbSizeMB MB ($pageCount pages)" -ForegroundColor Gray

Write-Console ""

# Check for foreign key violations
Write-Console "=== Checking Foreign Key Integrity ===" -ForegroundColor Cyan
Write-Console ""

$fkCheck = sqlite3 "$dbPath" "PRAGMA foreign_key_check;"

if ($fkCheck) {
    Write-Console "Foreign key violations found:" -ForegroundColor Red
    $fkCheck | ForEach-Object {
        Write-Console "  $_" -ForegroundColor Yellow
    }
} else {
    Write-Console "No foreign key violations" -ForegroundColor Green
}

Write-Console ""

# Recommend repair options
if ($integrityResult -ne "ok" -or $fkCheck) {
    Write-Console "=== REPAIR RECOMMENDATIONS ===" -ForegroundColor Red
    Write-Console ""
    Write-Console "Database corruption detected. Options:" -ForegroundColor Yellow
    Write-Console ""
    Write-Console "1. RESTORE FROM BACKUP:" -ForegroundColor Cyan
    Write-Console "   Latest backup: $(Get-ChildItem 'C:\Users\josep\.Mylio_Catalog' -Filter 'Mylo.mylodb.backup-*' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name)" -ForegroundColor Gray
    Write-Console "   Command: Copy-Item 'C:\Users\josep\.Mylio_Catalog\Mylo.mylodb.backup-XXXX' '$dbPath' -Force" -ForegroundColor Gray
    Write-Console ""
    Write-Console "2. RUN VACUUM:" -ForegroundColor Cyan
    Write-Console "   This rebuilds the database from scratch" -ForegroundColor Gray
    Write-Console "   Command: sqlite3 '$dbPath' 'VACUUM;'" -ForegroundColor Gray
    Write-Console ""
    Write-Console "3. EXPORT AND REIMPORT:" -ForegroundColor Cyan
    Write-Console "   Export all data to SQL and reimport into clean database" -ForegroundColor Gray
    Write-Console ""
    Write-Console "4. CONTACT MYLIO SUPPORT:" -ForegroundColor Cyan
    Write-Console "   Send them the crash dump and corrupted database for analysis" -ForegroundColor Gray
    Write-Console ""
} else {
    Write-Console "=== Database Health: GOOD ===" -ForegroundColor Green
    Write-Console ""
    Write-Console "Database appears healthy. If sync issues persist:" -ForegroundColor Yellow
    Write-Console "1. Try running WAL checkpoint: sqlite3 '$dbPath' 'PRAGMA wal_checkpoint(TRUNCATE);'" -ForegroundColor Gray
    Write-Console "2. Check if Mylio is actually indexing new files" -ForegroundColor Gray
    Write-Console "3. Verify network connectivity to cloud sync" -ForegroundColor Gray
}

Write-Console ""
