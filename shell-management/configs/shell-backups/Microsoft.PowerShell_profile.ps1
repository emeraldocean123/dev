# PowerShell Profile

# History settings
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$MaximumHistoryCount = 10000
Set-PSReadlineOption -HistorySavePath "$HOME\.ps_history"
Set-PSReadlineOption -HistorySaveStyle SaveIncrementally
Set-PSReadlineOption -MaximumHistoryCount 10000

# Enhanced PSReadLine settings
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# Winfetch (optional, once per session)
$noFF = [string]::IsNullOrEmpty($env:NO_WINFETCH)
$shown = ($Global:WINFETCH_SHOWN -eq $true) -or (-not [string]::IsNullOrEmpty($env:WINFETCH_SHOWN))
if ($noFF -and -not $shown) {
    if (Get-Command winfetch -ErrorAction SilentlyContinue) {
        try {
            winfetch
        } catch {}
    }
    $Global:WINFETCH_SHOWN = $true
    $env:WINFETCH_SHOWN = '1'
}

# Auto-update Claude date (runs once per day)
# This ensures Claude Code always knows the current date
$claudeUpdateScript = Join-Path $HOME "Documents\PowerShell\Scripts\Update-ClaudeDate.ps1"
if (Test-Path $claudeUpdateScript) {
    try {
        # Check if we've already run today by storing last run date in an env variable
        $lastRunDate = $env:CLAUDE_DATE_LAST_UPDATE
        $todayDate = Get-Date -Format "yyyy-MM-dd"

        if ($lastRunDate -ne $todayDate) {
            # Run the update script silently
            & $claudeUpdateScript *>&1 | Out-Null
            # Set the environment variable to prevent multiple runs today
            $env:CLAUDE_DATE_LAST_UPDATE = $todayDate
        }
    } catch {
        # Silently ignore any errors to not disrupt the profile loading
    }
}

# Oh My Posh prompt
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    $themePath = Join-Path $HOME 'Documents\PowerShell\jandedobbeleer.omp.json'
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config jandedobbeleer | Invoke-Expression
    }
}

# 5) Git helpers (matches bash aliases)
function gs { git status }
function ga { git add @args }
function gcom { git commit @args }
function gp { git push @args }
function gl { git --no-pager log --oneline -n 10 }  # Changed to -n 10 to match bash
function gd { git --no-pager diff @args }

# Claude date update command (manual trigger)
function Update-ClaudeDate {
    $script = Join-Path $HOME "Documents\PowerShell\Scripts\Update-ClaudeDate.ps1"
    if (Test-Path $script) {
        & $script
    } else {
        Write-Warning "Claude date update script not found at: $script"
    }
}

# Directory navigation (matches bash aliases)
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Directory listing (matches bash aliases)
function ll { Get-ChildItem -Force }  # Shows all files including hidden
function la { Get-ChildItem -Force }  # Same as ll
function l { Get-ChildItem }           # Normal listing without hidden files

# Safety functions (confirm before delete)
function rm { Remove-Item -Confirm @args }
function rmf { Remove-Item -Force @args }  # Force without confirmation

# Useful functions
# Create directory and cd into it
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# Quick file search
function ff {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter $Name -ErrorAction SilentlyContinue
}

# Disk usage helpers
function Get-DiskUsage {
    Get-ChildItem | ForEach-Object {
        $size = if ($_.PSIsContainer) {
            (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } else {
            $_.Length
        }
        [PSCustomObject]@{
            Name = $_.Name
            Size = [math]::Round($size / 1MB, 2)
            Type = if ($_.PSIsContainer) { "Folder" } else { "File" }
        }
    } | Sort-Object Size -Descending
}
Set-Alias -Name ducks -Value Get-DiskUsage

# Quick edit functions
function Edit-Profile { notepad $PROFILE }
function Reload-Profile { . $PROFILE }

# Add npm global bin to PATH
$npmGlobalPath = Join-Path $HOME '.npm-global'
if (Test-Path $npmGlobalPath) {
    $env:Path = $npmGlobalPath + ';' + $env:Path
}

# Git path note (reduced verbosity)
# $git = Get-Command git -ErrorAction SilentlyContinue
# if ($git) { Write-Console "Git: $($git.Source)" -ForegroundColor DarkGray }

# END profile