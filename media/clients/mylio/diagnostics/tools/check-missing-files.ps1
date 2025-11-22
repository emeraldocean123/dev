# Check for missing files using Folder.IsMissing flag

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$sqlite3 = "$env:USERPROFILE\bin\sqlite3.exe"
$dbPath = "C:\Users\josep\.Mylio_Catalog\Mylo.mylodb"

Write-Console "=== Checking for Missing Files ===" -ForegroundColor Cyan
Write-Console ""

# Check Folder.IsMissing flag
Write-Console "Folder IsMissing status:" -ForegroundColor Yellow
$missingFolders = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Folder WHERE IsMissing=1;" 2>&1
$notMissingFolders = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Folder WHERE IsMissing=0 OR IsMissing IS NULL;" 2>&1
Write-Console "  Missing folders: $missingFolders" -ForegroundColor $(if ([int]$missingFolders -gt 0) { "Yellow" } else { "Green" })
Write-Console "  Not missing folders: $notMissingFolders" -ForegroundColor Gray
Write-Console ""

# Check Media records in missing folders
if ([int]$missingFolders -gt 0) {
    Write-Console "Media in missing folders:" -ForegroundColor Yellow

    # Get count of media in folders marked as missing
    $query = @"
SELECT COUNT(*) FROM Media
WHERE ContainingFolderHash IN (
    SELECT UniqueHash FROM Folder WHERE IsMissing=1
)
"@
    $mediaInMissing = & $sqlite3 $dbPath $query 2>&1
    Write-Console "  Media count: $mediaInMissing" -ForegroundColor $(if ([int]$mediaInMissing -gt 0) { "Yellow" } else { "Green" })
    Write-Console ""

    if ([int]$mediaInMissing -gt 0) {
        Write-Console "Sample missing folders:" -ForegroundColor Cyan
        & $sqlite3 $dbPath "SELECT Name, LocalRootOrTemporaryPath, RecursiveChildMedia FROM Folder WHERE IsMissing=1 LIMIT 10;" 2>&1
        Write-Console ""
    }
}

# Check for folder paths
Write-Console "Sample folder paths:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT Name, LocalRootOrTemporaryPath, RecursiveChildMedia FROM Folder WHERE RecursiveChildMedia > 0 ORDER BY RecursiveChildMedia DESC LIMIT 10;" 2>&1
Write-Console ""

# Count media by folder
Write-Console "Total media vs folder counts:" -ForegroundColor Yellow
$totalMedia = & $sqlite3 $dbPath "SELECT COUNT(*) FROM Media;" 2>&1
$folderMediaSum = & $sqlite3 $dbPath "SELECT SUM(RecursiveChildMedia) FROM Folder;" 2>&1
Write-Console "  Media table records: $totalMedia" -ForegroundColor Cyan
Write-Console "  Sum of RecursiveChildMedia: $folderMediaSum" -ForegroundColor Cyan
Write-Console ""

# Check DeviceData table
Write-Console "DeviceData table:" -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(DeviceData);" 2>&1
Write-Console ""
Write-Console "DeviceData records:" -ForegroundColor Cyan
& $sqlite3 $dbPath "SELECT * FROM DeviceData LIMIT 5;" 2>&1
Write-Console ""

# Check NetworkNode structure
Write-Console "NetworkNode table structure:" -ForegroundColor Yellow
& $sqlite3 $dbPath "PRAGMA table_info(NetworkNode);" 2>&1
Write-Console ""
Write-Console "NetworkNode records:" -ForegroundColor Cyan
& $sqlite3 $dbPath "SELECT * FROM NetworkNode LIMIT 5;" 2>&1
Write-Console ""
