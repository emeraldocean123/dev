# Clean Mylio metadata - Remove face recognition, smart tags, and keywords
# Version 2: Properly handles WAL (Write-Ahead Log) files
# IMPORTANT: Run backup-and-examine-mylio-db.ps1 first!

param(
    [switch]$DryRun = $false
)

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

Write-Console "=== Mylio Metadata Cleanup v2 ===" -ForegroundColor Cyan
Write-Console "This version properly handles SQLite WAL files" -ForegroundColor Cyan
Write-Console ""

if ($DryRun) {
    Write-Console "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Console ""
}

# Check if Mylio is running
$mylioProcess = Get-Process -Name "Mylio*" -ErrorAction SilentlyContinue
if ($mylioProcess) {
    Write-Console "ERROR: Mylio is currently running!" -ForegroundColor Red
    Write-Console "Please close Mylio before proceeding." -ForegroundColor Yellow
    exit 1
}

# Check if backup exists
$latestBackup = Get-ChildItem "C:\Users\josep\.Mylio_Catalog\Mylo.mylodb.backup-*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestBackup) {
    Write-Console "ERROR: No backup found!" -ForegroundColor Red
    Write-Console "Please run backup-and-examine-mylio-db.ps1 first." -ForegroundColor Yellow
    exit 1
}

Write-Console "Latest backup: $($latestBackup.Name)" -ForegroundColor Green
Write-Console "Backup date: $($latestBackup.LastWriteTime)" -ForegroundColor Gray
Write-Console ""

# Check for WAL files
$walFile = "$dbPath-wal"
$shmFile = "$dbPath-shm"

if (Test-Path $walFile) {
    $walSize = (Get-Item $walFile).Length / 1KB
    Write-Console "WARNING: WAL file exists ($([math]::Round($walSize, 2)) KB)" -ForegroundColor Yellow
    Write-Console "This contains uncommitted transactions that may restore deleted data." -ForegroundColor Yellow
    Write-Console ""
}

# Define tables to clean
$tablesToClean = @(
    @{
        Name = "FaceRectangle"
        Description = "Face recognition data"
    },
    @{
        Name = "MediaMLImageTags"
        Description = "AI-generated smart tags (confidence scores)"
    },
    @{
        Name = "MediaMLHelper"
        Description = "AI-generated smart tags (tag data and keywords)"
    },
    @{
        Name = "ImageTaggerKeywords"
        Description = "Image tagger keywords"
    },
    @{
        Name = "MediaKeywords"
        Description = "User-added keywords"
    },
    @{
        Name = "OCRKeywords"
        Description = "OCR-extracted text keywords"
    },
    @{
        Name = "CategoryCount"
        Description = "Category names and counts (remember, ignore, etc.)"
    }
)

Write-Console "=== Tables to Clean ===" -ForegroundColor Yellow
foreach ($table in $tablesToClean) {
    Write-Console "  - $($table.Name): $($table.Description)" -ForegroundColor Gray
}
Write-Console ""

if (-not $DryRun) {
    Write-Console "WARNING: This will permanently delete data from the database!" -ForegroundColor Red
    Write-Console "Make sure you have a backup before proceeding." -ForegroundColor Yellow
    Write-Console ""
    $confirm = Read-Host "Type 'DELETE' to confirm (or anything else to cancel)"

    if ($confirm -ne "DELETE") {
        Write-Console "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Console ""
Write-Console "=== Starting Cleanup ===" -ForegroundColor Green
Write-Console ""

$cleaned = 0
$errors = 0

# CRITICAL: Force WAL mode off and checkpoint before starting
if (-not $DryRun) {
    Write-Console "Step 1: Checkpointing WAL file..." -ForegroundColor Cyan
    try {
        # Checkpoint the WAL file (commit all transactions to main database)
        $result = & $sqlite3 $dbPath "PRAGMA wal_checkpoint(TRUNCATE);" 2>&1
        Write-Console "  WAL checkpoint complete" -ForegroundColor Green

        # Switch to DELETE journal mode (disables WAL)
        $result = & $sqlite3 $dbPath "PRAGMA journal_mode=DELETE;" 2>&1
        Write-Console "  Journal mode: $result" -ForegroundColor Gray

        Write-Console ""
    } catch {
        Write-Console "  Warning: Could not checkpoint WAL: $_" -ForegroundColor Yellow
        Write-Console ""
    }
}

foreach ($table in $tablesToClean) {
    $tableName = $table.Name
    $description = $table.Description

    Write-Console "Cleaning $tableName..." -ForegroundColor Cyan
    Write-Console "  Description: $description" -ForegroundColor Gray

    if ($DryRun) {
        Write-Console "  [DRY RUN] Would execute: DELETE FROM [$tableName];" -ForegroundColor Yellow
        $cleaned++
    } else {
        try {
            # Get count before delete
            $countBefore = & $sqlite3 $dbPath "SELECT COUNT(*) FROM [$tableName];" 2>&1

            # Delete all rows
            $result = & $sqlite3 $dbPath "DELETE FROM [$tableName];" 2>&1

            if ($LASTEXITCODE -eq 0) {
                # Get count after delete
                $countAfter = & $sqlite3 $dbPath "SELECT COUNT(*) FROM [$tableName];" 2>&1
                Write-Console "  Success: Deleted $countBefore rows (now $countAfter rows)" -ForegroundColor Green
                $cleaned++
            } else {
                Write-Console "  Error: $result" -ForegroundColor Red
                $errors++
            }
        } catch {
            Write-Console "  Error: $_" -ForegroundColor Red
            $errors++
        }
    }
    Write-Console ""
}

# Clear categories from Media table
if (-not $DryRun) {
    Write-Console "Clearing categories from Media table..." -ForegroundColor Cyan
    try {
        # Get count of photos with categories
        $countBefore = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Categories IS NOT NULL AND Categories > 0;" 2>&1
        Write-Console "  Photos with categories: $countBefore" -ForegroundColor Gray

        if ($countBefore -gt 0) {
            # Clear all category assignments
            Write-Console "  Clearing category assignments..." -ForegroundColor Gray
            $result = & $sqlite3 $dbPath "UPDATE Media SET Categories = 0, EffectiveCategories = 0 WHERE Categories > 0;" 2>&1

            if ($LASTEXITCODE -eq 0) {
                $countAfter = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media WHERE Categories IS NOT NULL AND Categories > 0;" 2>&1
                Write-Console "  Success: Cleared categories from $countBefore photos" -ForegroundColor Green
                $cleaned++
            } else {
                Write-Console "  Error: $result" -ForegroundColor Red
                $errors++
            }
        } else {
            Write-Console "  No photos have categories assigned" -ForegroundColor Green
        }
    } catch {
        Write-Console "  Error: $_" -ForegroundColor Red
        $errors++
    }
    Write-Console ""
}

# Clean MediaKeywords5 (FTS5 table) separately
if (-not $DryRun) {
    Write-Console "Cleaning MediaKeywords5 (FTS5 table)..." -ForegroundColor Cyan
    try {
        # Drop the table entirely (will be recreated empty by Mylio)
        Write-Console "  Dropping table..." -ForegroundColor Gray
        $result = & $sqlite3 $dbPath "DROP TABLE IF EXISTS MediaKeywords5;" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Console "  Success: Table dropped" -ForegroundColor Green
            $cleaned++
        } else {
            Write-Console "  Error: $result" -ForegroundColor Red
            $errors++
        }
    } catch {
        Write-Console "  Error: $_" -ForegroundColor Red
        $errors++
    }
    Write-Console ""
}

# CRITICAL: Force WAL checkpoint again and delete WAL files
if (-not $DryRun) {
    Write-Console "Step 2: Final WAL checkpoint and cleanup..." -ForegroundColor Cyan
    try {
        # Final checkpoint
        $result = & $sqlite3 $dbPath "PRAGMA wal_checkpoint(TRUNCATE);" 2>&1
        Write-Console "  Final checkpoint complete" -ForegroundColor Green

        # Close database connection properly
        $result = & $sqlite3 $dbPath "PRAGMA optimize;" 2>&1

        Write-Console ""

        # Delete WAL files if they still exist
        if (Test-Path $walFile) {
            Write-Console "  Deleting WAL file..." -ForegroundColor Gray
            Remove-Item $walFile -Force
            Write-Console "  WAL file deleted" -ForegroundColor Green
        }

        if (Test-Path $shmFile) {
            Write-Console "  Deleting SHM file..." -ForegroundColor Gray
            Remove-Item $shmFile -Force
            Write-Console "  SHM file deleted" -ForegroundColor Green
        }

        Write-Console ""
    } catch {
        Write-Console "  Warning: Could not delete WAL files: $_" -ForegroundColor Yellow
        Write-Console ""
    }
}

# Vacuum the database to reclaim space
if (-not $DryRun) {
    Write-Console "Step 3: Vacuuming database to reclaim space..." -ForegroundColor Cyan
    try {
        $result = & $sqlite3 $dbPath "VACUUM;" 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -notmatch "error") {
            Write-Console "  Database vacuumed successfully" -ForegroundColor Green

            $newSize = (Get-Item $dbPath).Length / 1MB
            Write-Console "  New database size: $([math]::Round($newSize, 2)) MB" -ForegroundColor Gray
        } else {
            Write-Console "  Warning: Vacuum failed, trying incremental..." -ForegroundColor Yellow

            # Try incremental vacuum
            $result = & $sqlite3 $dbPath "PRAGMA incremental_vacuum;" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Console "  Incremental vacuum completed" -ForegroundColor Green
            }
        }
    } catch {
        Write-Console "  Warning: Vacuum failed: $_" -ForegroundColor Yellow
    }
}

Write-Console ""
Write-Console "=== Summary ===" -ForegroundColor Green
if ($DryRun) {
    Write-Console "Dry run completed - no changes made" -ForegroundColor Yellow
    Write-Console "Tables that would be cleaned: $cleaned" -ForegroundColor Gray
} else {
    Write-Console "Tables cleaned: $cleaned" -ForegroundColor Green
    Write-Console "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })

    if ($errors -eq 0) {
        Write-Console ""
        Write-Console "All metadata cleaned successfully!" -ForegroundColor Green
        Write-Console ""
        Write-Console "IMPORTANT: WAL files have been deleted." -ForegroundColor Cyan
        Write-Console "The database is now in DELETE journal mode (not WAL mode)." -ForegroundColor Cyan
        Write-Console ""
        Write-Console "You can now restart Mylio to verify the cleanup worked." -ForegroundColor Green
        Write-Console ""
        Write-Console "Note: XMP files still contain keywords in dc:subject blocks." -ForegroundColor Yellow
        Write-Console "Run clean-xmp-keywords.ps1 to remove those as well." -ForegroundColor Yellow
    }
}

Write-Console ""
Write-Console "Backup location: $($latestBackup.FullName)" -ForegroundColor Cyan
