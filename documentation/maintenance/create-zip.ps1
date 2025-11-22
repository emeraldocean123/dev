# Import shared utilities
$libPath = Join-Path $PSScriptRoot "..\..\lib\Utils.ps1"
if (Test-Path $libPath) { . $libPath } else { Write-Host "WARNING: Utils not found at $libPath" -ForegroundColor Yellow }

# Get dev root (2 levels up from script location)
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")

# Save zip in documentation/archives/
$zipPath = Join-Path $devRoot "documentation\archives\dev-repo.zip"

# Function to check if file is locked
function Test-FileLocked {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $false }

    try {
        $file = [System.IO.File]::Open($Path, 'Open', 'Read', 'None')
        $file.Close()
        return $false
    }
    catch {
        return $true
    }
}

# Try to remove existing zip (with retry logic for locked files)
if (Test-Path $zipPath) {
    Write-Host ""
    Write-Host "Removing existing dev-repo.zip..." -ForegroundColor Yellow

    $maxRetries = 3
    $retryCount = 0
    $removed = $false

    while ($retryCount -lt $maxRetries -and -not $removed) {
        try {
            if (Test-FileLocked -Path $zipPath) {
                if ($retryCount -eq 0) {
                    Write-Host "  File is locked by another process" -ForegroundColor Yellow
                    Write-Host "  Waiting for file to be released..." -ForegroundColor Gray
                }
                Start-Sleep -Seconds 2
                $retryCount++
                continue
            }

            Remove-Item $zipPath -Force -ErrorAction Stop
            $removed = $true
            Write-Host "  ✓ Removed old zip file" -ForegroundColor Green
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "  Retry $retryCount of $maxRetries..." -ForegroundColor Gray
                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $removed) {
        Write-Host ""
        Write-Host "✗ Cannot remove existing zip file - it's locked by another process" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible solutions:" -ForegroundColor Yellow
        Write-Host "  1. Close Windows Explorer if viewing the archives folder" -ForegroundColor Gray
        Write-Host "  2. Close any archive viewer (7-Zip, WinRAR, etc.)" -ForegroundColor Gray
        Write-Host "  3. Close any antivirus scan of the file" -ForegroundColor Gray
        Write-Host "  4. Run: Get-Process | Where-Object {`$_.Path -like '*dev-repo.zip'}" -ForegroundColor Gray
        Write-Host ""

        # Offer timestamped alternative
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $altZipPath = Join-Path $devRoot "documentation\archives\dev-repo-$timestamp.zip"

        $response = Read-Host "Create timestamped backup instead? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            $zipPath = $altZipPath
        }
        else {
            Write-Host "✗ Cancelled" -ForegroundColor Red
            exit 1
        }
    }
}

# Change to dev root and create zip
Write-Host ""
Write-Host "Creating archive..." -ForegroundColor Cyan
Set-Location $devRoot

try {
    Compress-Archive -Path * -DestinationPath $zipPath -CompressionLevel Optimal -Force -ErrorAction Stop

    if (Test-Path $zipPath) {
        $size = (Get-Item $zipPath).Length / 1MB
        Write-Host ""
        Write-Host "✓ Created dev-repo.zip" -ForegroundColor Green
        Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
        Write-Host "  Location: $zipPath" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "✗ Failed to create zip" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "✗ Error creating archive: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}

