# Copy test files to Mylio-Test folder

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$sourceDir = "D:\Mylio\Folder-Follett\1940\(01) January"
$destDir = "D:\Mylio-Test"

# Get 15 XMP files with keywords
$xmpFiles = Get-ChildItem "$sourceDir\*.xmp" | Select-Object -First 15

$copied = 0
foreach ($xmp in $xmpFiles) {
    # Copy XMP
    Copy-Item $xmp.FullName $destDir

    # Copy corresponding JPG
    $jpgPath = $xmp.FullName -replace '\.xmp$', '.jpg'
    if (Test-Path $jpgPath) {
        Copy-Item $jpgPath $destDir
        $copied++
    }
}

Write-Console "Copied $copied file pairs (JPG + XMP) to test folder"
