# Find all HEIC files in Mylio and copy them to a staging folder
# This script searches the Mylio folder, identifies all HEIC files,
# and copies them to a staging folder for safe conversion (leaving Mylio intact)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  HEIC File Staging for Conversion" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

# Step 1: Find Mylio folder
Write-Console "[1/5] Searching for Mylio folder..." -ForegroundColor Yellow

$searchPaths = @(
    'C:\Users\josep\Pictures\Mylio',
    'C:\Users\josep\Documents\Mylio',
    'C:\Users\josep\OneDrive\Pictures\Mylio',
    'D:\Mylio',
    'D:\Pictures\Mylio',
    'E:\Mylio',
    'E:\Pictures\Mylio',
    'F:\Mylio',
    'F:\Pictures\Mylio'
)

$mylioPath = $null
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Write-Console "  Found Mylio at: $path" -ForegroundColor Green
        $mylioPath = $path
        break
    }
}

# If not found in common locations, search all drives
if (-not $mylioPath) {
    Write-Console "  Searching all drives..." -ForegroundColor DarkGray
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[C-F]$' }

    foreach ($drive in $drives) {
        $searchPath = Join-Path $drive.Root 'Mylio'
        if (Test-Path $searchPath) {
            Write-Console "  Found Mylio at: $searchPath" -ForegroundColor Green
            $mylioPath = $searchPath
            break
        }

        $picturesPath = Join-Path $drive.Root 'Pictures\Mylio'
        if (Test-Path $picturesPath) {
            Write-Console "  Found Mylio at: $picturesPath" -ForegroundColor Green
            $mylioPath = $picturesPath
            break
        }
    }
}

if (-not $mylioPath) {
    Write-Console "`n  Mylio folder not found in common locations." -ForegroundColor Yellow
    Write-Console "  Please enter the full path to your Mylio folder:" -ForegroundColor Cyan
    $mylioPath = Read-Host "  Path"

    if (-not (Test-Path $mylioPath)) {
        Write-Error "Path does not exist: $mylioPath"
        exit 1
    }
}

Write-Console "`n  Using Mylio folder: $mylioPath`n" -ForegroundColor Green

# Step 2: Search for HEIC files
Write-Console "[2/5] Searching for HEIC files (this may take a moment)..." -ForegroundColor Yellow

$heicFiles = @()
$heicFiles = Get-ChildItem -Path $mylioPath -Filter "*.heic" -Recurse -File -ErrorAction SilentlyContinue

if ($heicFiles.Count -eq 0) {
    Write-Console "  No HEIC files found in Mylio folder." -ForegroundColor Yellow
    Write-Console "`n  Nothing to convert. Exiting.`n" -ForegroundColor Gray
    exit 0
}

# Calculate total size
$totalSize = ($heicFiles | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Console "  Found $($heicFiles.Count) HEIC files" -ForegroundColor Green
Write-Console "  Total size: $([math]::Round($totalSize, 2)) MB`n" -ForegroundColor Green

# Step 3: Show summary and confirm
Write-Console "[3/5] File Distribution:" -ForegroundColor Yellow

# Group by directory
$filesByDir = $heicFiles | Group-Object { $_.DirectoryName }
$topDirs = $filesByDir | Sort-Object Count -Descending | Select-Object -First 10

foreach ($dir in $topDirs) {
    $relativePath = $dir.Name.Replace($mylioPath, "").TrimStart('\')
    if ($relativePath -eq "") { $relativePath = "(root)" }
    Write-Console "  $($dir.Count.ToString().PadLeft(4)) files in: $relativePath" -ForegroundColor Gray
}

if ($filesByDir.Count -gt 10) {
    $remaining = $filesByDir.Count - 10
    Write-Console "  ... and $remaining more directories" -ForegroundColor DarkGray
}

# Step 4: Create staging folder
Write-Console "`n[4/5] Creating staging folder..." -ForegroundColor Yellow

$stagingFolder = Join-Path $env:USERPROFILE "Documents\heic-staging"
if (-not (Test-Path $stagingFolder)) {
    New-Item -Path $stagingFolder -ItemType Directory -Force | Out-Null
    Write-Console "  Created: $stagingFolder" -ForegroundColor Green
} else {
    Write-Console "  Using existing: $stagingFolder" -ForegroundColor Green
}

# Check if staging folder already has files
$existingFiles = Get-ChildItem -Path $stagingFolder -Filter "*.heic" -File -ErrorAction SilentlyContinue
if ($existingFiles.Count -gt 0) {
    Write-Console "`n  Warning: Staging folder already contains $($existingFiles.Count) HEIC files." -ForegroundColor Yellow
    $overwrite = Read-Host "  Clear staging folder and start fresh? (Y/N)"
    if ($overwrite -match "^[Yy]") {
        Remove-Item "$stagingFolder\*" -Force -Recurse
        Write-Console "  Staging folder cleared." -ForegroundColor Green
    } else {
        Write-Console "  Will skip files that already exist in staging." -ForegroundColor Yellow
    }
}

# Confirm before copying
Write-Console "`n  Ready to copy $($heicFiles.Count) HEIC files to staging folder." -ForegroundColor Cyan
Write-Console "  This will NOT modify your Mylio library.`n" -ForegroundColor Gray

$confirm = Read-Host "  Proceed with copying? (Y/N)"
if ($confirm -notmatch "^[Yy]") {
    Write-Console "`n  Cancelled by user.`n" -ForegroundColor Yellow
    exit 0
}

# Step 5: Copy files to staging
Write-Console "`n[5/5] Copying HEIC files to staging..." -ForegroundColor Yellow

$copied = 0
$skipped = 0
$failed = 0

foreach ($file in $heicFiles) {
    # Create unique filename (include part of path hash to avoid collisions)
    $relativePath = $file.DirectoryName.Replace($mylioPath, "").TrimStart('\')
    $pathHash = ($relativePath -replace '[^\w]', '-').Substring(0, [Math]::Min(30, $relativePath.Length))

    if ($pathHash) {
        $newName = "$pathHash-$($file.Name)"
    } else {
        $newName = $file.Name
    }

    $destPath = Join-Path $stagingFolder $newName

    # Skip if already exists
    if (Test-Path $destPath) {
        $skipped++
        continue
    }

    try {
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        $copied++

        if ($copied % 10 -eq 0) {
            Write-Console "  Copied $copied/$($heicFiles.Count) files..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Console "  Failed to copy: $($file.Name)" -ForegroundColor Red
        $failed++
    }
}

# Summary
Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Staging Complete!" -ForegroundColor Green
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "  Files copied: $copied" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Console "  Files skipped: $skipped" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Console "  Files failed: $failed" -ForegroundColor Red
}

Write-Console "`n  Staging folder: $stagingFolder" -ForegroundColor Cyan
Write-Console "  Original Mylio library: UNTOUCHED`n" -ForegroundColor Green

Write-Console "  Next steps:" -ForegroundColor Yellow
Write-Console "  1. Run the conversion script on the staging folder" -ForegroundColor Gray
Write-Console "  2. Import converted JPG files back into Mylio" -ForegroundColor Gray
Write-Console "  3. Verify everything looks good" -ForegroundColor Gray
Write-Console "  4. Optionally delete HEIC files from Mylio`n" -ForegroundColor Gray
