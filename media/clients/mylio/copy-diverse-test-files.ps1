# Copy diverse test files from different years

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$sourcePath = "D:\Mylio\Folder-Follett"
$destPath = "D:\Mylio-Test"

Write-Console "Finding files from diverse years..." -ForegroundColor Cyan

# Get all media files and filter for diverse years
$allFiles = Get-ChildItem -Path $sourcePath -Recurse -File -Include *.jpg,*.jpeg,*.mov,*.mp4 -ErrorAction SilentlyContinue

# Group by year and take 1-2 random files from different years
$years = @(2005, 2010, 2015, 2020, 2022)
$files = @()

foreach ($year in $years) {
    $yearFiles = $allFiles | Where-Object { $_.FullName -match "\\$year\\" } | Get-Random -Count 2
    if ($yearFiles) {
        $files += $yearFiles
    }
}

Write-Console "Found $($files.Count) files from diverse time periods`n" -ForegroundColor White

foreach ($file in $files) {
    # Extract year and month from directory structure
    # Structure: D:\Mylio\Folder-Follett\YEAR\(NN) MonthName\file.jpg
    $year = $file.Directory.Parent.Name
    $month = $file.Directory.Name

    Write-Console "Copying: $year/$month/$($file.Name)" -ForegroundColor Gray

    # Create destination directory
    $destDir = Join-Path $destPath "$year\$month"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    # Copy media file
    Copy-Item $file.FullName -Destination (Join-Path $destDir $file.Name) -Force

    # Copy XMP sidecar if exists
    $xmpPath = $file.FullName + ".xmp"
    if (Test-Path $xmpPath) {
        Copy-Item $xmpPath -Destination (Join-Path $destDir "$($file.Name).xmp") -Force
        Write-Console "  + XMP sidecar" -ForegroundColor DarkGray
    }
}

Write-Console "`nCopied $($files.Count) file pairs to test folder" -ForegroundColor Green
