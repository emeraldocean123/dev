# Immich Management Wrapper
# Unified management tool for all Immich operations
# Location: media/services/immich/manage-immich.ps1

param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet("Start", "Stop", "Pause", "Resume", "Status", "Logs", "Maintenance", "Help")]
    [string]$Action = "Help",

    [Parameter(Mandatory=$false)]
    [string]$ImmichHost = "http://localhost:2283",

    [Parameter(Mandatory=$false)]
    [string]$ApiKeyFile = "$PSScriptRoot\backup\config\.immich-api-key",

    [Parameter(Mandatory=$false)]
    [string]$ImmichPath = "D:\Immich"
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\..\lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

function Show-Help {
    Write-Console "`n=== Immich Management Tool ===" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Unified management tool for all Immich operations." -ForegroundColor Gray
    Write-Console ""
    Write-Console "Usage: .\manage-immich.ps1 <Action> [Options]" -ForegroundColor Yellow
    Write-Console ""
    Write-Console "Actions:" -ForegroundColor White
    Write-Console "  Start       - Start Immich containers" -ForegroundColor Green
    Write-Console "  Stop        - Stop Immich containers" -ForegroundColor Red
    Write-Console "  Pause       - Pause background jobs (free up resources)" -ForegroundColor Yellow
    Write-Console "  Resume      - Resume background jobs" -ForegroundColor Green
    Write-Console "  Status      - Show container status" -ForegroundColor Cyan
    Write-Console "  Logs        - Show container logs (live)" -ForegroundColor Gray
    Write-Console "  Maintenance - Run database optimization & cleanup" -ForegroundColor Magenta
    Write-Console "  Help        - Show this help message" -ForegroundColor White
    Write-Console ""
    Write-Console "Options:" -ForegroundColor White
    Write-Console "  -ImmichPath <path>       - Path to Immich directory (default: D:\Immich)" -ForegroundColor Gray
    Write-Console "  -ImmichHost <url>        - Immich host URL (default: http://localhost:2283)" -ForegroundColor Gray
    Write-Console "  -ApiKeyFile <path>       - API key file path (for Pause/Resume)" -ForegroundColor Gray
    Write-Console ""
    Write-Console "Examples:" -ForegroundColor White
    Write-Console "  .\manage-immich.ps1 Start" -ForegroundColor Gray
    Write-Console "  .\manage-immich.ps1 Pause" -ForegroundColor Gray
    Write-Console "  .\manage-immich.ps1 Maintenance" -ForegroundColor Gray
    Write-Console ""
}

switch ($Action) {
    "Start" {
        Write-Console "Starting Immich..." -ForegroundColor Green

        # Check if Immich directory exists
        if (-not (Test-Path $ImmichPath)) {
            Write-Console "ERROR: Immich directory not found: $ImmichPath" -ForegroundColor Red
            exit 1
        }

        # Change to Immich directory and start containers
        Push-Location $ImmichPath
        try {
            docker compose up -d

            # Wait for containers to start
            Write-Console "`nWaiting for containers to start..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5

            # Check status
            Write-Console "`nContainer Status:" -ForegroundColor Cyan
            docker ps --format "table {{.Names}}`t{{.Status}}" | Select-String -Pattern "immich|NAMES"

            Write-Console "`nImmich is ready!" -ForegroundColor Green
            Write-Console "`nAccess Immich at: $ImmichHost" -ForegroundColor Cyan
            Write-Console "`nTo view logs:" -ForegroundColor Yellow
            Write-Console "  docker compose logs -f" -ForegroundColor Gray
            Write-Console "`nTo stop Immich:" -ForegroundColor Yellow
            Write-Console "  .\manage-immich.ps1 Stop" -ForegroundColor Gray
        }
        finally {
            Pop-Location
        }
    }

    "Stop" {
        Write-Console "Stopping Immich..." -ForegroundColor Yellow

        # Check if Immich directory exists
        if (-not (Test-Path $ImmichPath)) {
            Write-Console "ERROR: Immich directory not found: $ImmichPath" -ForegroundColor Red
            exit 1
        }

        # Change to Immich directory and stop containers
        Push-Location $ImmichPath
        try {
            docker compose down
            Write-Console "`nImmich stopped successfully" -ForegroundColor Green
        }
        finally {
            Pop-Location
        }
    }

    "Pause" {
        Write-Console "Pause All Immich Jobs" -ForegroundColor Cyan
        Write-Console "====================" -ForegroundColor Cyan
        Write-Console ""

        # Check if API key file exists
        if (-not (Test-Path $ApiKeyFile)) {
            Write-Console "ERROR: API key file not found: $ApiKeyFile" -ForegroundColor Red
            Write-Console ""
            Write-Console "To create an API key:" -ForegroundColor Yellow
            Write-Console "  1. Open Immich web UI ($ImmichHost)" -ForegroundColor Yellow
            Write-Console "  2. Go to: User Settings -> Account Settings -> API Keys" -ForegroundColor Yellow
            Write-Console "  3. Click 'Create API Key' and give it a name (e.g., 'Job Control')" -ForegroundColor Yellow
            Write-Console "  4. Copy the API key" -ForegroundColor Yellow
            Write-Console "  5. Save it to: $ApiKeyFile" -ForegroundColor Yellow
            Write-Console ""
            Write-Console "Example command to create the file:" -ForegroundColor Gray
            Write-Console "  echo 'YOUR_API_KEY_HERE' > '$ApiKeyFile'" -ForegroundColor Gray
            Write-Console ""
            exit 1
        }

        # Read API key
        $apiKey = (Get-Content $ApiKeyFile -Raw).Trim()

        if (-not $apiKey) {
            Write-Console "ERROR: API key file is empty: $ApiKeyFile" -ForegroundColor Red
            exit 1
        }

        # All job names from Immich API
        $jobs = @(
            "thumbnailGeneration", "metadataExtraction", "videoConversion",
            "smartSearch", "faceDetection", "facialRecognition",
            "sidecar", "library", "migration", "backgroundTask",
            "search", "notifications", "storageTemplateMigration", "ocr"
        )

        Write-Console "Pausing all Immich background jobs..." -ForegroundColor Yellow
        Write-Console ""

        # Use parallel processing for independent API calls (PowerShell 7+)
        $results = $jobs | ForEach-Object -Parallel {
            $job = $_
            $immichHostValue = $using:ImmichHost
            $key = $using:apiKey

            try {
                $uri = "$immichHostValue/api/jobs/$job"
                $headers = @{
                    "Content-Type" = "application/json"
                    "Accept" = "application/json"
                    "x-api-key" = $key
                }
                $body = @{ command = "pause"; force = $false } | ConvertTo-Json

                Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop

                [PSCustomObject]@{ Job = $job; Success = $true; Error = $null }
            }
            catch {
                [PSCustomObject]@{ Job = $job; Success = $false; Error = $_.Exception.Message }
            }
        } -ThrottleLimit 10

        # Display results
        $pausedCount = 0
        $errorCount = 0

        foreach ($result in $results) {
            if ($result.Success) {
                Write-Console "  ✓ Paused: $($result.Job)" -ForegroundColor Green
                $pausedCount++
            } else {
                Write-Console "  ✗ Failed to pause: $($result.Job)" -ForegroundColor Red
                Write-Console "    Error: $($result.Error)" -ForegroundColor Red
                $errorCount++
            }
        }

        Write-Console ""
        Write-Console "====================" -ForegroundColor Cyan
        if ($errorCount -eq 0) {
            Write-Console "All jobs paused successfully! ($pausedCount jobs)" -ForegroundColor Green
        } else {
            Write-Console "Paused $pausedCount jobs with $errorCount errors" -ForegroundColor Yellow
        }
        Write-Console ""
        Write-Console "System resources freed up." -ForegroundColor White
        Write-Console "Run '.\manage-immich.ps1 Resume' to resume background processing." -ForegroundColor White
        Write-Console ""
    }

    "Resume" {
        Write-Console "Resume All Immich Jobs" -ForegroundColor Cyan
        Write-Console "======================" -ForegroundColor Cyan
        Write-Console ""

        # Check if API key file exists
        if (-not (Test-Path $ApiKeyFile)) {
            Write-Console "ERROR: API key file not found: $ApiKeyFile" -ForegroundColor Red
            Write-Console ""
            Write-Console "To create an API key:" -ForegroundColor Yellow
            Write-Console "  1. Open Immich web UI ($ImmichHost)" -ForegroundColor Yellow
            Write-Console "  2. Go to: User Settings -> Account Settings -> API Keys" -ForegroundColor Yellow
            Write-Console "  3. Click 'Create API Key' and give it a name (e.g., 'Job Control')" -ForegroundColor Yellow
            Write-Console "  4. Copy the API key" -ForegroundColor Yellow
            Write-Console "  5. Save it to: $ApiKeyFile" -ForegroundColor Yellow
            Write-Console ""
            Write-Console "Example command to create the file:" -ForegroundColor Gray
            Write-Console "  echo 'YOUR_API_KEY_HERE' > '$ApiKeyFile'" -ForegroundColor Gray
            Write-Console ""
            exit 1
        }

        # Read API key
        $apiKey = (Get-Content $ApiKeyFile -Raw).Trim()

        if (-not $apiKey) {
            Write-Console "ERROR: API key file is empty: $ApiKeyFile" -ForegroundColor Red
            exit 1
        }

        # All job names from Immich API
        $jobs = @(
            "thumbnailGeneration", "metadataExtraction", "videoConversion",
            "smartSearch", "faceDetection", "facialRecognition",
            "sidecar", "library", "migration", "backgroundTask",
            "search", "notifications", "storageTemplateMigration", "ocr"
        )

        Write-Console "Resuming all Immich background jobs..." -ForegroundColor Yellow
        Write-Console ""

        # Use parallel processing for independent API calls (PowerShell 7+)
        $results = $jobs | ForEach-Object -Parallel {
            $job = $_
            $immichHostValue = $using:ImmichHost
            $key = $using:apiKey

            try {
                $uri = "$immichHostValue/api/jobs/$job"
                $headers = @{
                    "Content-Type" = "application/json"
                    "Accept" = "application/json"
                    "x-api-key" = $key
                }
                $body = @{ command = "resume"; force = $false } | ConvertTo-Json

                Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop

                [PSCustomObject]@{ Job = $job; Success = $true; Error = $null }
            }
            catch {
                [PSCustomObject]@{ Job = $job; Success = $false; Error = $_.Exception.Message }
            }
        } -ThrottleLimit 10

        # Display results
        $resumedCount = 0
        $errorCount = 0

        foreach ($result in $results) {
            if ($result.Success) {
                Write-Console "  ✓ Resumed: $($result.Job)" -ForegroundColor Green
                $resumedCount++
            } else {
                Write-Console "  ✗ Failed to resume: $($result.Job)" -ForegroundColor Red
                Write-Console "    Error: $($result.Error)" -ForegroundColor Red
                $errorCount++
            }
        }

        Write-Console ""
        Write-Console "======================" -ForegroundColor Cyan
        if ($errorCount -eq 0) {
            Write-Console "All jobs resumed successfully! ($resumedCount jobs)" -ForegroundColor Green
        } else {
            Write-Console "Resumed $resumedCount jobs with $errorCount errors" -ForegroundColor Yellow
        }
        Write-Console ""
        Write-Console "Immich background processing is now active." -ForegroundColor White
        Write-Console ""
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

