# Quick check of smart tag status in Mylio database

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

Write-Console "=== Smart Tag Status Check ===" -ForegroundColor Cyan
Write-Console ""

Write-Console "Checking smart tag counts..." -ForegroundColor Yellow
Write-Console ""

$imageTagsCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLImageTags;" 2>&1
$helperCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaMLHelper WHERE ImageTaggerKeywords IS NOT NULL;" 2>&1
$taggerCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM ImageTaggerKeywords;" 2>&1
$keywordsCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM MediaKeywords;" 2>&1
$faceCount = & $sqlite3 $dbPath "SELECT COUNT(*) FROM FaceRectangle;" 2>&1

Write-Console "MediaMLImageTags: " -NoNewline
if ($imageTagsCount -eq "0") {
    Write-Console $imageTagsCount -ForegroundColor Green
} else {
    Write-Console $imageTagsCount -ForegroundColor Red
}

Write-Console "MediaMLHelper (keywords): " -NoNewline
if ($helperCount -eq "0") {
    Write-Console $helperCount -ForegroundColor Green
} else {
    Write-Console $helperCount -ForegroundColor Red
}

Write-Console "ImageTaggerKeywords: " -NoNewline
if ($taggerCount -eq "0") {
    Write-Console $taggerCount -ForegroundColor Green
} else {
    Write-Console $taggerCount -ForegroundColor Red
}

Write-Console "MediaKeywords: " -NoNewline
if ($keywordsCount -eq "0") {
    Write-Console $keywordsCount -ForegroundColor Green
} else {
    Write-Console $keywordsCount -ForegroundColor Red
}

Write-Console "FaceRectangle: " -NoNewline
if ($faceCount -eq "0") {
    Write-Console $faceCount -ForegroundColor Green
} else {
    Write-Console $faceCount -ForegroundColor Red
}

Write-Console ""
Write-Console "Checking version settings..." -ForegroundColor Yellow
Write-Console ""

$faceDetection = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentFaceDetectionVersion';" 2>&1
$imageTaggerMajor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMajor';" 2>&1
$imageTaggerMinor = & $sqlite3 $dbPath "SELECT ConfigVal FROM Configuration WHERE ConfigKey='currentImageTaggerVersionMinor';" 2>&1

Write-Console "currentFaceDetectionVersion: " -NoNewline
if ($faceDetection -eq "0") {
    Write-Console $faceDetection -ForegroundColor Green
} else {
    Write-Console $faceDetection -ForegroundColor Red
}

Write-Console "currentImageTaggerVersionMajor: " -NoNewline
if ($imageTaggerMajor -eq "0") {
    Write-Console $imageTaggerMajor -ForegroundColor Green
} else {
    Write-Console $imageTaggerMajor -ForegroundColor Red
}

Write-Console "currentImageTaggerVersionMinor: " -NoNewline
if ($imageTaggerMinor -eq "0") {
    Write-Console $imageTaggerMinor -ForegroundColor Green
} else {
    Write-Console $imageTaggerMinor -ForegroundColor Red
}

Write-Console ""

# Summary
$hasSmartTags = ($imageTagsCount -ne "0") -or ($helperCount -ne "0") -or ($taggerCount -ne "0")
$settingsEnabled = ($faceDetection -ne "0") -or ($imageTaggerMajor -ne "0")

if (-not $hasSmartTags -and -not $settingsEnabled) {
    Write-Console "STATUS: " -NoNewline
    Write-Console "All clean! No smart tags and settings disabled." -ForegroundColor Green
} elseif ($hasSmartTags -and $settingsEnabled) {
    Write-Console "STATUS: " -NoNewline
    Write-Console "PROBLEM! Smart tags present AND settings enabled!" -ForegroundColor Red
} elseif ($hasSmartTags) {
    Write-Console "STATUS: " -NoNewline
    Write-Console "WARNING! Smart tags found but settings are disabled." -ForegroundColor Yellow
} elseif ($settingsEnabled) {
    Write-Console "STATUS: " -NoNewline
    Write-Console "WARNING! Settings are enabled but no smart tags yet." -ForegroundColor Yellow
}

Write-Console ""
