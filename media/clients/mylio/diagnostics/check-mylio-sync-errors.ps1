# Check Mylio sync errors and logs

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$catalogPath = "C:\Users\josep\.Mylio_Catalog"
$dbPath = Join-Path $catalogPath "Mylo.mylodb"
$logPath = Join-Path $catalogPath "log"

Write-Console "=== Mylio Sync Diagnostics ===" -ForegroundColor Cyan
Write-Console ""

# Check for crash dump
$crashDump = Get-ChildItem -Path (Join-Path $catalogPath "crashpad\reports") -Filter "*.dmp" -ErrorAction SilentlyContinue
if ($crashDump) {
    Write-Console "CRASH DETECTED:" -ForegroundColor Red
    foreach ($dump in $crashDump) {
        Write-Console "  Crash dump: $($dump.Name)" -ForegroundColor Yellow
        Write-Console "  Created: $($dump.CreationTime)" -ForegroundColor Gray
        Write-Console "  Size: $([math]::Round($dump.Length / 1MB, 2)) MB" -ForegroundColor Gray
    }
    Write-Console ""
}

# Check most recent log files
Write-Console "Recent log files:" -ForegroundColor Yellow
$recentLogs = Get-ChildItem -Path $logPath -Filter "*.etm" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5

foreach ($log in $recentLogs) {
    Write-Console "  $($log.Name)" -ForegroundColor Green
    Write-Console "    Last modified: $($log.LastWriteTime)" -ForegroundColor Gray
    Write-Console "    Size: $([math]::Round($log.Length / 1KB, 2)) KB" -ForegroundColor Gray
}
Write-Console ""

# Try to read the most recent log file for errors
Write-Console "=== Checking most recent log for errors ===" -ForegroundColor Cyan
Write-Console ""

$latestLog = $recentLogs | Select-Object -First 1
if ($latestLog) {
    try {
        $content = Get-Content -Path $latestLog.FullName -Raw -ErrorAction Stop

        # Look for error patterns
        $errors = @()

        if ($content -match "error|exception|failed|crash|abort|fatal") {
            $lines = $content -split "`n"
            $errorLines = $lines | Where-Object { $_ -match "error|exception|failed|crash|abort|fatal" }

            if ($errorLines) {
                Write-Console "Found potential errors:" -ForegroundColor Red
                $errorLines | Select-Object -First 20 | ForEach-Object {
                    Write-Console "  $_" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Console "No obvious errors found in latest log" -ForegroundColor Green
        }
    } catch {
        Write-Console "Could not read log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Console ""

# Check database integrity
Write-Console "=== Database Integrity Check ===" -ForegroundColor Cyan
Write-Console ""

try {
    Add-Type -AssemblyName System.Data.SQLite -ErrorAction Stop
    $connection = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$dbPath;Read Only=True")
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = "PRAGMA integrity_check"
    $result = $command.ExecuteScalar()

    if ($result -eq "ok") {
        Write-Console "Database integrity: OK" -ForegroundColor Green
    } else {
        Write-Console "Database integrity: ISSUES FOUND" -ForegroundColor Red
        Write-Console "  $result" -ForegroundColor Yellow
    }

    $connection.Close()
} catch {
    Write-Console "Could not check database integrity: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Console ""

# Check for stuck processes
Write-Console "=== Mylio Process Status ===" -ForegroundColor Cyan
Write-Console ""

$mylioProcesses = Get-Process | Where-Object { $_.ProcessName -like "*mylio*" -or $_.ProcessName -like "*mylo*" }

if ($mylioProcesses) {
    foreach ($proc in $mylioProcesses) {
        Write-Console "Process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
        Write-Console "  Memory: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Console "  CPU: $($proc.CPU)" -ForegroundColor Gray
        Write-Console "  Started: $($proc.StartTime)" -ForegroundColor Gray
        Write-Console "  Responding: $($proc.Responding)" -ForegroundColor $(if ($proc.Responding) { "Green" } else { "Red" })
    }
} else {
    Write-Console "No Mylio processes running" -ForegroundColor Yellow
}

Write-Console ""

# Check sync status from database
Write-Console "=== Sync Status from Database ===" -ForegroundColor Cyan
Write-Console ""

try {
    Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue
    $connection = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$dbPath;Read Only=True")
    $connection.Open()

    # Check for sync-related tables
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE '%sync%' OR name LIKE '%queue%' OR name LIKE '%task%' OR name LIKE '%job%')"
    $reader = $command.ExecuteReader()

    $syncTables = @()
    while ($reader.Read()) {
        $syncTables += $reader.GetString(0)
    }
    $reader.Close()

    if ($syncTables.Count -gt 0) {
        Write-Console "Sync-related tables found:" -ForegroundColor Yellow
        foreach ($table in $syncTables) {
            Write-Console "  $table" -ForegroundColor Green

            # Try to count rows
            $countCmd = $connection.CreateCommand()
            $countCmd.CommandText = "SELECT COUNT(*) FROM [$table]"
            try {
                $count = $countCmd.ExecuteScalar()
                Write-Console "    Rows: $count" -ForegroundColor Gray
            } catch {
                Write-Console "    Could not count rows" -ForegroundColor Gray
            }
        }
    } else {
        Write-Console "No sync-related tables found" -ForegroundColor Yellow
    }

    $connection.Close()
} catch {
    Write-Console "Could not query sync tables: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Console ""
