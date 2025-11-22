
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

# Import Mylio Photos to Immich using immich-go
# This script imports all photos from D:\Mylio into Immich

Write-Console "Immich-Go Photo Import" -ForegroundColor Cyan
Write-Console "======================" -ForegroundColor Cyan
Write-Console ""

$IMMICH_SERVER = "http://localhost:2283"
$IMMICH_API_KEY = "lUPftoG12Gczf3ZjvHRYstoY7RrZWkTzULLbewSUAA"
$PHOTO_PATH = "D:\Mylio"

# Check if Mylio folder exists
if (-not (Test-Path $PHOTO_PATH)) {
    Write-Console "ERROR: Photo path does not exist: $PHOTO_PATH" -ForegroundColor Red
    exit 1
}

# Check if immich-go is available
$immichGo = Get-Command immich-go -ErrorAction SilentlyContinue
if (-not $immichGo) {
    Write-Console "ERROR: immich-go not found in PATH" -ForegroundColor Red
    Write-Console "Please ensure immich-go is installed and in your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Console "Server: $IMMICH_SERVER" -ForegroundColor Green
Write-Console "Source: $PHOTO_PATH" -ForegroundColor Green
Write-Console ""
Write-Console "Starting import..." -ForegroundColor Yellow
Write-Console ""

# Run immich-go upload from-folder
immich-go upload from-folder --server $IMMICH_SERVER --api-key $IMMICH_API_KEY $PHOTO_PATH

if ($LASTEXITCODE -eq 0) {
    Write-Console ""
    Write-Console "Import completed successfully!" -ForegroundColor Green
} else {
    Write-Console ""
    Write-Console "Import failed with error code: $LASTEXITCODE" -ForegroundColor Red
}

