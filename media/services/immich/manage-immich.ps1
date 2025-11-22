# Immich Management Wrapper
# Convenient wrapper for common Immich operations
# Location: media/services/immich/manage-immich.ps1

param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet("Start", "Stop", "Pause", "Resume", "Status", "Logs", "Maintenance", "Help")]
    [string]$Action = "Help"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$immichControlPath = Join-Path $PSScriptRoot "control"

function Show-Help {
    Write-Console "`n=== Immich Management Wrapper ===" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Usage: .\manage-immich.ps1 <Action>" -ForegroundColor Yellow
    Write-Console ""
    Write-Console "Actions:" -ForegroundColor White
    Write-Console "  Start       - Start Immich containers" -ForegroundColor Green
    Write-Console "  Stop        - Stop Immich containers" -ForegroundColor Red
    Write-Console "  Pause       - Pause background jobs (free up resources)" -ForegroundColor Yellow
    Write-Console "  Resume      - Resume background jobs" -ForegroundColor Green
    Write-Console "  Status      - Show container status" -ForegroundColor Cyan
    Write-Console "  Logs        - Show container logs" -ForegroundColor Gray
    Write-Console "  Maintenance - Run database optimization & cleanup" -ForegroundColor Magenta
    Write-Console "  Help        - Show this help message" -ForegroundColor White
    Write-Console ""
    Write-Console "Examples:" -ForegroundColor White
    Write-Console "  .\manage-immich.ps1 Start" -ForegroundColor Gray
    Write-Console "  .\manage-immich.ps1 Pause" -ForegroundColor Gray
    Write-Console ""
}

switch ($Action) {
    "Start" {
        $script = Join-Path $immichControlPath "start-immich.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "ERROR: start-immich.ps1 not found" -ForegroundColor Red
        }
    }

    "Stop" {
        $script = Join-Path $immichControlPath "stop-immich.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "ERROR: stop-immich.ps1 not found" -ForegroundColor Red
        }
    }

    "Pause" {
        $script = Join-Path $immichControlPath "pause-immich-jobs.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "ERROR: pause-immich-jobs.ps1 not found" -ForegroundColor Red
        }
    }

    "Resume" {
        $script = Join-Path $immichControlPath "resume-immich-jobs.ps1"
        if (Test-Path $script) {
            & $script
        } else {
            Write-Console "ERROR: resume-immich-jobs.ps1 not found" -ForegroundColor Red
        }
    }

    "Status" {
        Write-Console "`n=== Immich Container Status ===" -ForegroundColor Cyan
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "immich|NAMES"
    }

    "Logs" {
        Write-Console "`n=== Immich Logs (Press Ctrl+C to exit) ===" -ForegroundColor Cyan
        Set-Location "D:\Immich"  # Adjust path if needed
        docker compose logs -f --tail=50
    }

    "Maintenance" {
        Write-Console "`n=== Immich Maintenance Mode ===" -ForegroundColor Magenta
        Write-Console ""

        # Check if containers are running
        $immichRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "immich" -Quiet
        if (-not $immichRunning) {
            Write-Console "ERROR: Immich containers are not running" -ForegroundColor Red
            Write-Console "Start Immich first: .\manage-immich.ps1 Start" -ForegroundColor Yellow
            exit 1
        }

        Write-Console "Starting database maintenance tasks..." -ForegroundColor Cyan
        Write-Console ""

        # 1. Database Vacuum (Reclaim space and optimize)
        Write-Console "[1/3] Running VACUUM ANALYZE on database..." -ForegroundColor Yellow
        Set-Location "D:\Immich"
        $vacuumResult = docker compose exec -T immich_postgres psql -U postgres -d immich -c "VACUUM ANALYZE;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Console "  ✓ Database vacuumed successfully" -ForegroundColor Green
        } else {
            Write-Console "  ✗ Vacuum failed: $vacuumResult" -ForegroundColor Red
        }
        Write-Console ""

        # 2. Show database size
        Write-Console "[2/3] Checking database size..." -ForegroundColor Yellow
        $dbSize = docker compose exec -T immich_postgres psql -U postgres -d immich -t -c "SELECT pg_size_pretty(pg_database_size('immich'));" 2>&1
        Write-Console "  Database size: $($dbSize.Trim())" -ForegroundColor Cyan
        Write-Console ""

        # 3. Show top largest tables
        Write-Console "[3/3] Largest tables:" -ForegroundColor Yellow
        docker compose exec -T immich_postgres psql -U postgres -d immich -c "
            SELECT
                schemaname || '.' || tablename AS table,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
            FROM pg_tables
            WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
            ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
            LIMIT 10;
        " 2>&1 | Select-String -Pattern "table|─|bytes|kB|MB|GB" | ForEach-Object {
            Write-Console "  $_" -ForegroundColor Cyan
        }

        Write-Console ""
        Write-Console "Maintenance complete!" -ForegroundColor Green
        Write-Console ""
    }

    "Help" {
        Show-Help
    }

    default {
        Show-Help
    }
}

