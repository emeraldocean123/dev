# Move the 3G2 XMP file back to its proper location

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "=== Restoring 3G2 XMP File ===" -ForegroundColor Cyan
Write-Console ""

$source = "D:\Mylio-Moved-XMP\Folder-Follett\2005\(09) September\2005-09-25-11.xmp"
$dest = "D:\Mylio\Folder-Follett\2005\(09) September\2005-09-25-11.xmp"
$videoFile = "D:\Mylio\Folder-Follett\2005\(09) September\2005-09-25-11.3g2"

if (Test-Path $source) {
    Write-Console "Moving XMP file back to vault..." -ForegroundColor Yellow
    Move-Item -Path $source -Destination $dest -Force

    Write-Console ""
    Write-Console "Successfully moved!" -ForegroundColor Green
    Write-Console "  From: $source" -ForegroundColor Gray
    Write-Console "  To: $dest" -ForegroundColor Gray
    Write-Console ""

    Write-Console "Verifying files now exist together:" -ForegroundColor Yellow
    if (Test-Path $videoFile) {
        Write-Console "  Video (.3g2): EXISTS" -ForegroundColor Green
    } else {
        Write-Console "  Video (.3g2): MISSING" -ForegroundColor Red
    }

    if (Test-Path $dest) {
        Write-Console "  XMP sidecar: EXISTS" -ForegroundColor Green
    } else {
        Write-Console "  XMP sidecar: MISSING" -ForegroundColor Red
    }

} else {
    Write-Console "Source XMP file not found at:" -ForegroundColor Red
    Write-Console "  $source" -ForegroundColor Gray
}

Write-Console ""
