# Disable Smart Tags and Face Recognition in Mylio Database
# Also delete any newly generated smart tag data

param(
    [switch]$DryRun = $false
)

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
$sqlite3 = "$env:USERPROFILE\bin\sqlite3.exe"

Write-Console "=== Disable Smart Tags in Mylio Database ===" -ForegroundColor Cyan
Write-Console ""

if ($DryRun) {
    Write-Console "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Console ""
}

# Check if Mylio is running
$mylioProcess = Get-Process -Name "Mylio*" -ErrorAction SilentlyContinue
if ($mylioProcess) {
    Write-Console "ERROR: Mylio is currently running!" -ForegroundColor Red
    Write-Console "Please close Mylio before proceeding." -ForegroundColor Yellow
    exit 1
}

Write-Console "Step 1: Check current smart tag counts..." -ForegroundColor Cyan
Write-Console ""

$imageTagsCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLImageTags;" 2>&1
$helperCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLHelper WHERE ImageTaggerKeywords IS NOT NULL;" 2>&1
$taggerCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM ImageTaggerKeywords;" 2>&1

Write-Console "  MediaMLImageTags: $imageTagsCount rows" -ForegroundColor $(if ($imageTagsCount -eq "0") { "Green" } else { "Red" })
Write-Console "  MediaMLHelper (keywords): $helperCount rows" -ForegroundColor $(if ($helperCount -eq "0") { "Green" } else { "Red" })
Write-Console "  ImageTaggerKeywords: $taggerCount rows" -ForegroundColor $(if ($taggerCount -eq "0") { "Green" } else { "Red" })
Write-Console ""

Write-Console "Step 2: Check current settings..." -ForegroundColor Cyan
Write-Console ""

$faceDetection = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentFaceDetectionVersion';" 2>&1
$imageTaggerMajor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMajor';" 2>&1
$imageTaggerMinor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMinor';" 2>&1

Write-Console "  currentFaceDetectionVersion: $faceDetection" -ForegroundColor Gray
Write-Console "  currentImageTaggerVersionMajor: $imageTaggerMajor" -ForegroundColor Gray
Write-Console "  currentImageTaggerVersionMinor: $imageTaggerMinor" -ForegroundColor Gray
Write-Console ""

if (-not $DryRun) {
    Write-Console "WARNING: This will:" -ForegroundColor Yellow
    Write-Console "  1. Delete all newly generated smart tag data" -ForegroundColor Yellow
    Write-Console "  2. Set Face Detection version to 0 (disabled)" -ForegroundColor Yellow
    Write-Console "  3. Set Image Tagger version to 0 (disabled)" -ForegroundColor Yellow
    Write-Console ""
    $confirm = Read-Host "Type 'DISABLE' to confirm (or anything else to cancel)"

    if ($confirm -ne "DISABLE") {
        Write-Console "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Console ""
Write-Console "Step 3: Delete regenerated smart tag data..." -ForegroundColor Cyan
Write-Console ""

if (-not $DryRun) {
    # Checkpoint WAL first
    Write-Console "  Checkpointing WAL..." -ForegroundColor Gray
    & $sqlite3 $dbPath "PRAGMA wal_checkpoint(TRUNCATE);" 2>&1 | Out-Null
    & $sqlite3 $dbPath "PRAGMA journal_mode=DELETE;" 2>&1 | Out-Null

    # Delete MediaMLImageTags
    Write-Console "  Deleting MediaMLImageTags..." -ForegroundColor Gray
    $result = & $sqlite3 $dbPath "DELETE FROM MediaMLImageTags;" 2>&1
    $newCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLImageTags;" 2>&1
    Write-Console "    Deleted $imageTagsCount rows, now $newCount rows" -ForegroundColor Green

    # Delete MediaMLHelper keywords
    Write-Console "  Clearing MediaMLHelper keywords..." -ForegroundColor Gray
    $result = & $sqlite3 $dbPath "UPDATE MediaMLHelper SET ImageTaggerKeywords = NULL, ImageTaggerVersion = 0, ImageTaggerVersionMinor = 0 WHERE ImageTaggerKeywords IS NOT NULL;" 2>&1
    $newCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLHelper WHERE ImageTaggerKeywords IS NOT NULL;" 2>&1
    Write-Console "    Cleared $helperCount rows, now $newCount rows with keywords" -ForegroundColor Green

    # Delete ImageTaggerKeywords
    Write-Console "  Deleting ImageTaggerKeywords..." -ForegroundColor Gray
    $result = & $sqlite3 $dbPath "DELETE FROM ImageTaggerKeywords;" 2>&1
    $newCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM ImageTaggerKeywords;" 2>&1
    Write-Console "    Deleted $taggerCount rows, now $newCount rows" -ForegroundColor Green

    Write-Console ""
} else {
    Write-Console "  [DRY RUN] Would delete all smart tag data" -ForegroundColor Yellow
    Write-Console ""
}

Write-Console "Step 4: Disable smart tags and face recognition..." -ForegroundColor Cyan
Write-Console ""

if (-not $DryRun) {
    # Set Face Detection to 0 (disabled)
    Write-Console "  Disabling Face Detection..." -ForegroundColor Gray
    & $sqlite3 $dbPath "UPDATE Configuration SET ConfigVal='0' WHERE ConfigKey='currentFaceDetectionVersion';" 2>&1 | Out-Null
    $newVal = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentFaceDetectionVersion';" 2>&1
    Write-Console "    currentFaceDetectionVersion: $faceDetection -> $newVal" -ForegroundColor Green

    # Set Image Tagger to 0 (disabled)
    Write-Console "  Disabling Smart Tags..." -ForegroundColor Gray
    & $sqlite3 $dbPath "UPDATE Configuration SET ConfigVal='0' WHERE ConfigKey='currentImageTaggerVersionMajor';" 2>&1 | Out-Null
    & $sqlite3 $dbPath "UPDATE Configuration SET ConfigVal='0' WHERE ConfigKey='currentImageTaggerVersionMinor';" 2>&1 | Out-Null
    $newMajor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMajor';" 2>&1
    $newMinor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMinor';" 2>&1
    Write-Console "    currentImageTaggerVersionMajor: $imageTaggerMajor -> $newMajor" -ForegroundColor Green
    Write-Console "    currentImageTaggerVersionMinor: $imageTaggerMinor -> $newMinor" -ForegroundColor Green

    Write-Console ""
} else {
    Write-Console "  [DRY RUN] Would set all version numbers to 0" -ForegroundColor Yellow
    Write-Console ""
}

Write-Console "Step 5: Final WAL checkpoint and cleanup..." -ForegroundColor Cyan
Write-Console ""

if (-not $DryRun) {
    # Final checkpoint
    & $sqlite3 $dbPath "PRAGMA wal_checkpoint(TRUNCATE);" 2>&1 | Out-Null
    & $sqlite3 $dbPath "PRAGMA optimize;" 2>&1 | Out-Null
    Write-Console "  WAL checkpoint complete" -ForegroundColor Green

    # Delete WAL files if they exist
    $walFile = "$dbPath-wal"
    $shmFile = "$dbPath-shm"

    if (Test-Path $walFile) {
        Remove-Item $walFile -Force
        Write-Console "  WAL file deleted" -ForegroundColor Green
    }

    if (Test-Path $shmFile) {
        Remove-Item $shmFile -Force
        Write-Console "  SHM file deleted" -ForegroundColor Green
    }

    Write-Console ""
}

Write-Console "=== Summary ===" -ForegroundColor Green
if ($DryRun) {
    Write-Console "Dry run complete - no changes made" -ForegroundColor Yellow
} else {
    Write-Console "Smart Tags and Face Recognition have been disabled in the database!" -ForegroundColor Green
    Write-Console ""
    Write-Console "IMPORTANT:" -ForegroundColor Cyan
    Write-Console "  - All regenerated smart tag data has been deleted" -ForegroundColor Cyan
    Write-Console "  - Face Detection version set to 0 (disabled)" -ForegroundColor Cyan
    Write-Console "  - Image Tagger version set to 0 (disabled)" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "You can now restart Mylio. It should NOT regenerate smart tags." -ForegroundColor Green
    Write-Console ""
    Write-Console "If smart tags still regenerate, please check:" -ForegroundColor Yellow
    Write-Console "  1. Mylio's Preferences/Settings UI" -ForegroundColor Yellow
    Write-Console "  2. Any cloud sync that might restore settings" -ForegroundColor Yellow
}
Write-Console ""
