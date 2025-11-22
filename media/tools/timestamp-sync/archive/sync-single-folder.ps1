# Sync Timestamps for a Single Folder
# Interactive script to choose which folder to process

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $null
    $previousForeground = $null
    $previousBackground = $null

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        if ($NoNewline -and $Host -and $Host.UI) {
            $Host.UI.Write($Message)
        } else {
            Write-Information -MessageData $Message
        }
    } catch {
        Write-Information -MessageData $Message
        Write-Verbose "Write-Console fallback: $($_.Exception.Message)"
    } finally {
        if ($rawUI -and $null -ne $previousForeground) {
            try {
                $rawUI.ForegroundColor = $previousForeground
            } catch {
                Write-Verbose "Unable to reset foreground color: $($_.Exception.Message)"
            }
        }

        if ($rawUI -and $PSBoundParameters.ContainsKey('BackgroundColor') -and $null -ne $previousBackground) {
            try {
                $rawUI.BackgroundColor = $previousBackground
            } catch {
                Write-Verbose "Unable to reset background color: $($_.Exception.Message)"
            }
        }
    }
}

param(
    [string]$FolderName = "",
    [switch]$DryRun
)

if (-not $PSBoundParameters.ContainsKey('DryRun')) {
    $DryRun = $false
}

$mylioPath = "D:\Mylio"
$scriptPath = "$PSScriptRoot\sync-timestamps-bidirectional-optimized.ps1"

# Get all top-level folders
$folders = Get-ChildItem -Path $mylioPath -Directory | Sort-Object Name

if ($FolderName -eq "") {
    Write-Console "`n========================================" -ForegroundColor Cyan
    Write-Console "  Available Folders" -ForegroundColor Cyan
    Write-Console "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Console "  [$($i + 1)] $($folders[$i].Name)" -ForegroundColor White
    }

    Write-Console ""
    $choice = Read-Host "Enter folder number (1-$($folders.Count))"

    try {
        $index = [int]$choice - 1
        if ($index -lt 0 -or $index -ge $folders.Count) {
            Write-Console "Invalid choice" -ForegroundColor Red
            exit 1
        }
        $selectedFolder = $folders[$index]
    } catch {
        Write-Console "Invalid input" -ForegroundColor Red
        exit 1
    }
} else {
    $selectedFolder = $folders | Where-Object { $_.Name -eq $FolderName }
    if (-not $selectedFolder) {
        Write-Console "Folder '$FolderName' not found" -ForegroundColor Red
        exit 1
    }
}

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Timestamp Sync - Single Folder" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Selected folder: $($selectedFolder.Name)" -ForegroundColor Yellow
Write-Console "Path: $($selectedFolder.FullName)" -ForegroundColor Gray

if ($DryRun) {
    Write-Console "`nMODE: DRY RUN - No changes will be made" -ForegroundColor Yellow
} else {
    Write-Console "`nMODE: LIVE - Files will be modified!" -ForegroundColor Red
    Write-Console "Press Ctrl+C within 10 seconds to cancel...`n" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Count files in selected folder
$extensions = @('*.jpg', '*.jpeg', '*.png', '*.heic', '*.heif', '*.mov', '*.mp4', '*.avi', '*.mkv', '*.m4v')
$fileCount = (Get-ChildItem -Path $selectedFolder.FullName -Recurse -File -Include $extensions -ErrorAction SilentlyContinue).Count

Write-Console "`nFound $fileCount media files in this folder" -ForegroundColor White
Write-Console "Starting sync...`n" -ForegroundColor Cyan

$startTime = Get-Date

# Run the optimized sync script
if ($DryRun) {
    & $scriptPath -Path $selectedFolder.FullName -DryRun
} else {
    # Explicitly pass -DryRun:$false to override the default
    & $scriptPath -Path $selectedFolder.FullName -DryRun:$false
}

$elapsed = (Get-Date) - $startTime

Write-Console "`n========================================" -ForegroundColor Cyan
Write-Console "  Folder Sync Complete" -ForegroundColor Cyan
Write-Console "========================================`n" -ForegroundColor Cyan

Write-Console "Folder: $($selectedFolder.Name)" -ForegroundColor White
Write-Console "Processing time: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Console ""

