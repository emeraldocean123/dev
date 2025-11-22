# Python Environment Setup
# ==========================
# Installs required Python dependencies for media tools
# Automates setup for new machines or fresh Python installations
#
# Location: shell-management/utils/setup-python-env.ps1
# Usage: ./setup-python-env.ps1

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Python Environment Setup" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

# Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Console "ERROR: Python not found in PATH" -ForegroundColor Red
    Write-Console ""
    Write-Console "Please install Python 3.8 or higher:" -ForegroundColor Yellow
    Write-Console "  - Windows: https://www.python.org/downloads/" -ForegroundColor Gray
    Write-Console "  - Or use: winget install Python.Python.3.12" -ForegroundColor Gray
    Write-Console ""
    exit 1
}

# Show Python version
$pythonVersion = & python --version 2>&1
Write-Console "Python found: $pythonVersion" -ForegroundColor Green
Write-Console ""

# Check if pip is available
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Console "ERROR: pip not found in PATH" -ForegroundColor Red
    Write-Console ""
    Write-Console "Please ensure pip is installed with Python" -ForegroundColor Yellow
    Write-Console "  - Try: python -m ensurepip --upgrade" -ForegroundColor Gray
    Write-Console ""
    exit 1
}

# Locate requirements.txt
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$requirementsPath = Join-Path $devRoot "media\tools\requirements.txt"

if (-not (Test-Path $requirementsPath)) {
    Write-Console "ERROR: requirements.txt not found" -ForegroundColor Red
    Write-Console "       Expected: $requirementsPath" -ForegroundColor Yellow
    Write-Console ""
    exit 1
}

Write-Console "Requirements file: media/tools/requirements.txt" -ForegroundColor Gray
Write-Console ""

# Install dependencies
Write-Console "Installing Python dependencies..." -ForegroundColor Yellow
Write-Console ""

try {
    & pip install -r $requirementsPath
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Console ""
        Write-Console "========================================" -ForegroundColor Green
        Write-Console "  Python dependencies installed successfully!" -ForegroundColor Green
        Write-Console "========================================" -ForegroundColor Green
        Write-Console ""
        Write-Console "You can now run media tools:" -ForegroundColor Cyan
        Write-Console "  - media-manager.py    (Organize & deduplicate)" -ForegroundColor Gray
        Write-Console "  - metadata-scrubber.py (Remove metadata)" -ForegroundColor Gray
        Write-Console "  - xmp-sidecar.py      (Extract to XMP)" -ForegroundColor Gray
        Write-Console ""
    } else {
        Write-Console ""
        Write-Console "ERROR: pip install failed (exit code: $exitCode)" -ForegroundColor Red
        Write-Console ""
        exit 1
    }
}
catch {
    Write-Console ""
    Write-Console "ERROR: Failed to install dependencies" -ForegroundColor Red
    Write-Console "       $_" -ForegroundColor Yellow
    Write-Console ""
    exit 1
}
