
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Pause All Immich Jobs
# Pauses all background processing jobs to free up system resources
# NOTE: You need to create an API key first in Immich web UI:
#   User Settings -> Account Settings -> API Keys -> Create API Key

param(
    [Parameter(Mandatory=$false)]
    [string]$ImmichHost = "http://localhost:2283",

    [Parameter(Mandatory=$false)]
    [string]$ApiKeyFile = "$PSScriptRoot\..\..\backup\config\.immich-api-key"
)

Write-Console "Pause All Immich Jobs" -ForegroundColor Cyan
Write-Console "====================" -ForegroundColor Cyan
Write-Console ""

# Check if API key file exists
if (-not (Test-Path $ApiKeyFile)) {
    Write-Console "ERROR: API key file not found: $ApiKeyFile" -ForegroundColor Red
    Write-Console ""
    Write-Console "To create an API key:" -ForegroundColor Yellow
    Write-Console "  1. Open Immich web UI (http://localhost:2283)" -ForegroundColor Yellow
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

# All job names from immich-config.json and Immich API
$jobs = @(
    "thumbnailGeneration",
    "metadataExtraction",
    "videoConversion",
    "smartSearch",
    "faceDetection",
    "facialRecognition",
    "sidecar",
    "library",
    "migration",
    "backgroundTask",
    "search",
    "notifications",
    "storageTemplateMigration",
    "ocr"
)

Write-Console "Pausing all Immich background jobs..." -ForegroundColor Yellow
Write-Console ""

# OPTIMIZATION: Use parallel processing for independent API calls (PowerShell 7+)
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
        $body = @{
            command = "pause"
            force = $false
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop

        [PSCustomObject]@{
            Job = $job
            Success = $true
            Error = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Job = $job
            Success = $false
            Error = $_.Exception.Message
        }
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
Write-Console "Run resume-immich-jobs.ps1 to resume background processing." -ForegroundColor White
Write-Console ""


