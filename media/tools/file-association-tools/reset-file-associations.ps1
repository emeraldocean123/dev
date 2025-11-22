# Reset File Associations
# Removes file associations so Windows will prompt to choose a program

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`nResetting file associations...`n" -ForegroundColor Cyan

# Common image and video extensions
$extensions = @(
    # Images
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif',
    '.heic', '.heif', '.avif', '.jxl',

    # Videos
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v',
    '.mpg', '.mpeg', '.3gp', '.ogv',

    # RAW formats
    '.cr2', '.cr3', '.nef', '.arw', '.dng', '.orf', '.rw2'
)

$reset = 0
$skipped = 0

foreach ($ext in $extensions) {
    $userChoicePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"

    if (Test-Path $userChoicePath) {
        try {
            # Remove the UserChoice key (requires admin for some, but try anyway)
            Remove-Item -Path $userChoicePath -Force -ErrorAction Stop
            Write-Console "Reset: $ext" -ForegroundColor Green
            $reset++
        } catch {
            Write-Console "Skipped: $ext (protected)" -ForegroundColor Yellow
            $skipped++
        }
    } else {
        Write-Console "No association: $ext" -ForegroundColor Gray
    }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "Summary" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Reset: $reset extensions" -ForegroundColor Green
Write-Console "Skipped: $skipped extensions (protected)" -ForegroundColor Yellow
Write-Console "`nNext time you open these files, Windows will prompt you to choose a program." -ForegroundColor White
Write-Console "Select XnView MP and check 'Always use this app' to set as default.`n" -ForegroundColor White
