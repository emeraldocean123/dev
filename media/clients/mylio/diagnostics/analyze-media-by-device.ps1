# Analyze media distribution across devices

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

Write-Console "=== Media Distribution Across Devices ===" -ForegroundColor Cyan
Write-Console ""

# Get DeviceData with MediaCount
Write-Console "Media count by device:" -ForegroundColor Yellow
$query = @"
SELECT
    dd.DeviceId,
    nn.NodeName,
    nn.Nickname,
    dd.MediaCount,
    dd.ResourceCount
FROM DeviceData dd
LEFT JOIN NetworkNode nn ON dd.DeviceId = nn.DeviceId
ORDER BY dd.MediaCount DESC
"@
& $sqlite3 $dbPath "$query" 2>&1
Write-Console ""

# Sum of all MediaCount
Write-Console "Total MediaCount across all devices:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT SUM(MediaCount) FROM DeviceData;" 2>&1
Write-Console ""

# Check if there's a current device  flag
Write-Console "This device:" -ForegroundColor Yellow
$query2 = @"
SELECT
    nn.DeviceId,
    nn.NodeName,
    nn.Nickname,
    nn.IsThisDevice,
    dd.MediaCount
FROM NetworkNode nn
LEFT JOIN DeviceData dd ON nn.DeviceId = dd.DeviceId
WHERE nn.IsThisDevice = 1
"@
& $sqlite3 $dbPath "$query2" 2>&1
Write-Console ""

# Check DeviceData.Paths column
Write-Console "DeviceData paths (binary data):" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT DeviceId, length(Paths) as PathsLength FROM DeviceData WHERE Paths IS NOT NULL;" 2>&1
Write-Console ""

# Sample the Media table to see if there's device info
Write-Console "Checking Media table for device tracking:" -ForegroundColor Yellow
& $sqlite3 $dbPath "SELECT COUNT(DISTINCT RootFolderHash) FROM Media;" 2>&1
Write-Console ""

# Check actual file count on D:\Mylio
Write-Console "Verifying file count..." -ForegroundColor Yellow
$imageExtensions = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.cr2', '.nef', '.arw', '.dng', '.raw')
$videoExtensions = @('.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp', '.mts', '.m2ts', '.mpg', '.mpeg', '.wmv')
$allExtensions = $imageExtensions + $videoExtensions

$fileCount = (Get-ChildItem -Path "D:\Mylio" -Recurse -File | Where-Object {
    $allExtensions -contains $_.Extension.ToLower()
}).Count

Write-Console "  Files on D:\Mylio: $fileCount" -ForegroundColor Green
Write-Console "  Database total: 82622" -ForegroundColor Cyan
Write-Console "  Difference: $(82622 - $fileCount)" -ForegroundColor Yellow
Write-Console ""

Write-Console "=== Conclusion ===" -ForegroundColor Cyan
if ($fileCount -gt 0) {
    $percent = [math]::Round(($fileCount / 82622) * 100, 1)
    Write-Console "Local vault has $percent% of the total library" -ForegroundColor Green
    Write-Console "The remaining $(82622 - $fileCount) files are likely on other devices" -ForegroundColor Yellow
}
Write-Console ""
