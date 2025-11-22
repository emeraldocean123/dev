# Create Test Folder and Copy Sample Files

# Create test folder

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$testPath = 'D:\Mylio-Test'
if (-not (Test-Path $testPath)) {
    New-Item -ItemType Directory -Path $testPath | Out-Null
    Write-Console "Created test folder: D:\Mylio-Test" -ForegroundColor Green
} else {
    Write-Console "Test folder already exists: D:\Mylio-Test" -ForegroundColor Yellow
    # Clean it out
    Remove-Item "$testPath\*" -Force -ErrorAction SilentlyContinue
    Write-Console "Cleaned test folder" -ForegroundColor Yellow
}

# Get 100 random media files from D:\Mylio
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.heif', '*.mov', '*.mp4', '*.avi', '*.mkv', '*.m4v')
Write-Console "`nScanning D:\Mylio for random files..." -ForegroundColor Cyan
$sourceFiles = Get-ChildItem -Path 'D:\Mylio' -Recurse -File -Include $extensions -ErrorAction SilentlyContinue | Get-Random -Count 100

Write-Console "Found $($sourceFiles.Count) files to copy" -ForegroundColor Cyan

# Copy files to test folder
$copied = 0
foreach ($file in $sourceFiles) {
    try {
        Copy-Item -Path $file.FullName -Destination $testPath -Force
        $copied++
    } catch {
        Write-Console "Error copying $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Console "`nCopied $copied files to D:\Mylio-Test" -ForegroundColor Green

$totalFiles = (Get-ChildItem -Path $testPath).Count
Write-Console "Total files in test folder: $totalFiles" -ForegroundColor Yellow
