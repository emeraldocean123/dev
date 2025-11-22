# Backup and examine Mylio database
# This script creates a backup and examines the database structure

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
$sqlite3 = "$env:USERPROFILE\bin\sqlite3.exe"

Write-Console "=== Mylio Database Backup and Examination ===" -ForegroundColor Cyan
Write-Console ""

# Check if Mylio is running
$mylioProcess = Get-Process -Name "Mylio*" -ErrorAction SilentlyContinue
if ($mylioProcess) {
    Write-Console "WARNING: Mylio is currently running!" -ForegroundColor Red
    Write-Console "Please close Mylio before proceeding." -ForegroundColor Yellow
    Write-Console ""
    $continue = Read-Host "Continue anyway? (yes/no)"
    if ($continue -ne "yes") {
        Write-Console "Exiting..." -ForegroundColor Yellow
        exit
    }
}

# Step 1: Backup the database
Write-Console "Step 1: Creating backup..." -ForegroundColor Green
try {
    Copy-Item -Path $dbPath -Destination $backupPath -ErrorAction Stop
    $backupSize = (Get-Item $backupPath).Length / 1MB
    Write-Console "  Backup created: $backupPath" -ForegroundColor Gray
    Write-Console "  Size: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Gray
    Write-Console ""
} catch {
    Write-Console "  ERROR: Failed to create backup: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Examine the database
Write-Console "Step 2: Examining database structure..." -ForegroundColor Green
Write-Console ""

# Get all table names
$tablesOutput = & $sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" 2>&1
$tables = $tablesOutput -split "`n" | Where-Object { $_ -match '\S' }

Write-Console "=== Total Tables: $($tables.Count) ===" -ForegroundColor Cyan
Write-Console ""

# Keywords to highlight
$keywords = @('tag', 'keyword', 'smart', 'face', 'person', 'people', 'recognition', 'album', 'category')

$relevantTables = @()

foreach ($table in $tables) {
    $table = $table.Trim()
    if ([string]::IsNullOrWhiteSpace($table)) { continue }

    $isRelevant = $false
    foreach ($keyword in $keywords) {
        if ($table.ToLower().Contains($keyword)) {
            $isRelevant = $true
            break
        }
    }

    if ($isRelevant) {
        $relevantTables += $table
        Write-Console ">>> $table" -ForegroundColor Yellow

        # Get row count
        try {
            $count = & $sqlite3 $dbPath "SELECT COUNT(*) FROM [$table];" 2>&1
            Write-Console "    Rows: $count" -ForegroundColor Gray
        } catch {
            Write-Console "    (Unable to count rows)" -ForegroundColor Gray
        }

        # Get schema
        $schemaOutput = & $sqlite3 $dbPath "PRAGMA table_info([$table]);" 2>&1
        $schemaLines = $schemaOutput -split "`n" | Where-Object { $_ -match '\S' }

        if ($schemaLines.Count -gt 0) {
            Write-Console "    Columns:" -ForegroundColor Gray
            foreach ($line in $schemaLines) {
                # Parse: 0|id|INTEGER|0||1
                if ($line -match '\|([^|]+)\|([^|]+)\|') {
                    $colName = $Matches[1]
                    $colType = $Matches[2]
                    Write-Console "      - $colName ($colType)" -ForegroundColor DarkGray
                }
            }
        }
        Write-Console ""
    } else {
        Write-Console "  $table" -ForegroundColor DarkGray
    }
}

Write-Console ""
Write-Console "=== Relevant Tables Found ===" -ForegroundColor Green
Write-Console "Tables related to keywords, tags, faces, people:" -ForegroundColor Gray
foreach ($table in $relevantTables) {
    Write-Console "  - $table" -ForegroundColor Yellow
}

Write-Console ""
Write-Console "=== Next Steps ===" -ForegroundColor Cyan
Write-Console "1. Review the relevant tables above" -ForegroundColor Gray
Write-Console "2. Decide which tables to clear" -ForegroundColor Gray
Write-Console "3. Run the cleanup script to remove data from selected tables" -ForegroundColor Gray
Write-Console ""
Write-Console "Backup location: $backupPath" -ForegroundColor Green
