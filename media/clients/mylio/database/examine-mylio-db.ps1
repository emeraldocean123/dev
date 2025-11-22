# Examine Mylio database structure
# This script queries the database in read-only mode

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

# Load System.Data.SQLite assembly (if available)
try {
    Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Data.SQLite\*\System.Data.SQLite.dll"
} catch {
    Write-Console "System.Data.SQLite not found, trying alternative method..." -ForegroundColor Yellow
}

# Create connection string (read-only)
$connectionString = "Data Source=$dbPath;Version=3;Read Only=True;"

try {
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
    $connection.Open()

    Write-Console "=== Connected to Mylio Database ===" -ForegroundColor Green
    Write-Console ""

    # Get all table names
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
    $reader = $command.ExecuteReader()

    $tables = @()
    while ($reader.Read()) {
        $tables += $reader["name"]
    }
    $reader.Close()

    Write-Console "=== Database Tables ($($tables.Count) total) ===" -ForegroundColor Cyan
    Write-Console ""

    # Look for tables related to tags, keywords, faces, smart tags
    $keywords = @("tag", "keyword", "smart", "face", "person", "people", "recognition")

    foreach ($table in $tables) {
        $isRelevant = $false
        foreach ($keyword in $keywords) {
            if ($table -like "*$keyword*") {
                $isRelevant = $true
                break
            }
        }

        if ($isRelevant) {
            Write-Console ">>> $table" -ForegroundColor Yellow

            # Get row count
            $countCmd = $connection.CreateCommand()
            $countCmd.CommandText = "SELECT COUNT(*) FROM [$table];"
            try {
                $count = $countCmd.ExecuteScalar()
                Write-Console "    Rows: $count" -ForegroundColor Gray
            } catch {
                Write-Console "    (Unable to count rows)" -ForegroundColor Gray
            }

            # Get schema
            $schemaCmd = $connection.CreateCommand()
            $schemaCmd.CommandText = "PRAGMA table_info([$table]);"
            $schemaReader = $schemaCmd.ExecuteReader()
            Write-Console "    Columns:" -ForegroundColor Gray
            while ($schemaReader.Read()) {
                $colName = $schemaReader["name"]
                $colType = $schemaReader["type"]
                Write-Console "      - $colName ($colType)" -ForegroundColor DarkGray
            }
            $schemaReader.Close()
            Write-Console ""
        } else {
            Write-Console "  $table" -ForegroundColor DarkGray
        }
    }

    $connection.Close()

} catch {
    Write-Console "Error: $_" -ForegroundColor Red
    Write-Console ""
    Write-Console "SQLite may not be available via .NET" -ForegroundColor Yellow
    Write-Console "You can install DB Browser for SQLite to examine the database manually:" -ForegroundColor Yellow
    Write-Console "https://sqlitebrowser.org/" -ForegroundColor Cyan
}
