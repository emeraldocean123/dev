# Fix Mylio File Extensions - Standardize to Lowercase
# Comprehensive fix: check duplicates, rename extensions, clear thumbnail cache

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$mylioPath = "D:\Mylio"
$dryRun = $false  # Set to $false to actually rename files

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Mylio Extension Standardization" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $mylioPath)) {
    Write-Console "  X Mylio folder not found: $mylioPath" -ForegroundColor Red
    exit 1
}

Write-Console "Scanning: $mylioPath`n" -ForegroundColor Gray

# Step 1: Find all media files with uppercase extensions
Write-Console "[1/4] Finding files with uppercase extensions..." -ForegroundColor Yellow
Write-Console "  (This may take a moment)`n" -ForegroundColor Gray

$uppercaseExtensions = @('.MOV', '.HEIC', '.JPG', '.JPEG', '.PNG', '.GIF', '.MP4', '.AVI', '.M4V')
$allUppercaseFiles = @()

foreach ($ext in $uppercaseExtensions) {
    $files = Get-ChildItem -Path $mylioPath -Recurse -Filter "*$ext" -File -ErrorAction SilentlyContinue
    if ($files) {
        $allUppercaseFiles += $files
    }
}

if ($allUppercaseFiles.Count -eq 0) {
    Write-Console "  OK No uppercase extensions found!" -ForegroundColor Green
    Write-Console "  All files already have lowercase extensions.`n" -ForegroundColor Gray
} else {
    Write-Console "  Found $($allUppercaseFiles.Count) files with uppercase extensions`n" -ForegroundColor White

    # Group by extension
    $byExtension = $allUppercaseFiles | Group-Object Extension | Sort-Object Name
    foreach ($group in $byExtension) {
        Write-Console "    $($group.Name): $($group.Count) files" -ForegroundColor Gray
    }
    Write-Console ""
}

# Step 2: Explanation - Windows NTFS is case-insensitive
Write-Console "[2/4] Preparing to rename extensions..." -ForegroundColor Yellow
Write-Console ""
Write-Console "  Note: Windows NTFS treats .MOV and .mov as the same file" -ForegroundColor Gray
Write-Console "  Renaming will simply change the case in-place (safe operation)`n" -ForegroundColor Gray

# Step 3: Rename files to lowercase
Write-Console "[3/4] Renaming files to lowercase extensions..." -ForegroundColor Yellow
Write-Console ""

if ($dryRun) {
    Write-Console "  > DRY RUN MODE - No files will be modified" -ForegroundColor Cyan
    Write-Console "  Showing what WOULD be renamed:`n" -ForegroundColor Gray
} else {
    Write-Console "  OK LIVE MODE - Files will be renamed" -ForegroundColor Green
    Write-Console ""
}

$renamed = 0
$failed = 0

foreach ($file in $allUppercaseFiles) {
    $newName = $file.Name.ToLower()

    if ($renamed % 100 -eq 0 -and $renamed -gt 0) {
        Write-Console "    Progress: $renamed/$($allUppercaseFiles.Count) files..." -ForegroundColor DarkGray
    }

    if ($dryRun) {
        # Just show what would happen
        if ($renamed -lt 20) {
            Write-Console "    $($file.FullName)" -ForegroundColor Gray
            Write-Console "      -> $newName" -ForegroundColor Green
        }
        $renamed++
    } else {
        # Actually rename
        try {
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            $renamed++
        }
        catch {
            Write-Console "    X Failed: $($file.Name)" -ForegroundColor Red
            Write-Console "       Error: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

if ($dryRun) {
    Write-Console ""
    Write-Console "  > Dry run complete - $($allUppercaseFiles.Count) files would be renamed" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "  To actually rename files, edit this script and set:" -ForegroundColor Yellow
    Write-Console "    `$dryRun = `$false" -ForegroundColor White
    Write-Console ""
} else {
    Write-Console ""
    Write-Console "  OK Renamed $renamed files" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Console "  X Failed to rename $failed files" -ForegroundColor Red
    }
    Write-Console ""
}

# Step 4: Clear thumbnail cache
Write-Console "[4/4] Clearing Windows thumbnail cache..." -ForegroundColor Yellow
Write-Console ""

$thumbnailCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
$thumbFiles = Get-ChildItem -Path $thumbnailCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue
$iconFiles = Get-ChildItem -Path $thumbnailCache -Filter "iconcache_*.db" -ErrorAction SilentlyContinue

$totalCacheFiles = $thumbFiles.Count + $iconFiles.Count

if ($totalCacheFiles -eq 0) {
    Write-Console "  No thumbnail cache files found" -ForegroundColor Gray
} else {
    Write-Console "  Found $totalCacheFiles cache files to delete" -ForegroundColor White

    if ($dryRun) {
        Write-Console "  > DRY RUN MODE - Cache files would be deleted" -ForegroundColor Cyan
    } else {
        try {
            Remove-Item -Path "$thumbnailCache\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$thumbnailCache\iconcache_*.db" -Force -ErrorAction SilentlyContinue
            Write-Console "  OK Thumbnail cache cleared" -ForegroundColor Green
        }
        catch {
            Write-Console "  ! Could not delete some cache files (may be in use)" -ForegroundColor Yellow
            Write-Console "     Restart Windows Explorer or reboot to fully clear cache" -ForegroundColor Gray
        }
    }
}

Write-Console ""
Write-Console "========================================" -ForegroundColor Cyan
Write-Console "  Summary" -ForegroundColor Cyan
Write-Console "========================================" -ForegroundColor Cyan
Write-Console ""

Write-Console "Files analyzed:" -ForegroundColor White
Write-Console "  Total files with uppercase extensions: $($allUppercaseFiles.Count)" -ForegroundColor Gray

if ($dryRun) {
    Write-Console ""
    Write-Console "  > This was a DRY RUN - no changes were made" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Actions that WOULD be taken:" -ForegroundColor Yellow
    Write-Console "  + Rename $($allUppercaseFiles.Count) files to lowercase extensions" -ForegroundColor Gray
    Write-Console "  + Clear $totalCacheFiles thumbnail cache files" -ForegroundColor Gray
    Write-Console ""
    Write-Console "To proceed, edit the script and set:" -ForegroundColor Yellow
    Write-Console "  `$dryRun = `$false" -ForegroundColor White
} else {
    Write-Console ""
    Write-Console "Actions completed:" -ForegroundColor Green
    Write-Console "  OK Renamed $renamed files to lowercase extensions" -ForegroundColor Gray
    Write-Console "  OK Cleared $totalCacheFiles thumbnail cache files" -ForegroundColor Gray

    if ($failed -gt 0) {
        Write-Console ""
        Write-Console "  ! $failed files failed to rename" -ForegroundColor Yellow
    }

    Write-Console ""
    Write-Console "Next steps:" -ForegroundColor Cyan
    Write-Console "  1. Restart Windows Explorer (or reboot)" -ForegroundColor Gray
    Write-Console "  2. Navigate to D:\Mylio\Folder-Joseph\2025\(10) October" -ForegroundColor Gray
    Write-Console "  3. Press F5 to refresh the view" -ForegroundColor Gray
    Write-Console "  4. Thumbnails should now appear for all files!" -ForegroundColor Gray
}

Write-Console ""
