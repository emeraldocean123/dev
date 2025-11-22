# PowerShell Profile
# Managed via dev repository: shell-management/powershell/

# --- Path Resolution ---
# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Set root variables for the new structure
$ShellManagementRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$UtilsPath = Join-Path $ShellManagementRoot "utils"

# Add Utils to Path (so you can run winfetch, etc.)
if (Test-Path $UtilsPath) {
    if ($env:Path -notlike "*$UtilsPath*") {
        $env:Path = "$UtilsPath;$env:Path"
    }
}

# --- History Settings ---
$MaximumHistoryCount = 10000
Set-PSReadlineOption -HistorySavePath "$HOME\.ps_history"
Set-PSReadlineOption -HistorySaveStyle SaveIncrementally
Set-PSReadlineOption -MaximumHistoryCount 10000

# --- PSReadLine Settings ---
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    $psReadLineVersion = (Get-Module PSReadLine).Version

    if ($psReadLineVersion -and $psReadLineVersion -ge [version]'2.1.0') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# --- Winfetch (Direct execution - jobs strip ANSI codes) ---
$noFF = [string]::IsNullOrEmpty($env:NO_WINFETCH)
$shown = ($Global:WINFETCH_SHOWN -eq $true) -or (-not [string]::IsNullOrEmpty($env:WINFETCH_SHOWN))

if ($noFF -and -not $shown) {
    if (Get-Command winfetch -ErrorAction SilentlyContinue) {
        try {
            # Run directly - jobs strip ANSI escape codes needed for formatting
            winfetch
        } catch {}
    }
    $Global:WINFETCH_SHOWN = $true
    $env:WINFETCH_SHOWN = '1'
}

# --- Claude Code Date Update ---
$claudeUpdateScript = Join-Path $UtilsPath "Update-ClaudeDate.ps1"

if (Test-Path $claudeUpdateScript) {
    try {
        $lastRunDate = $env:CLAUDE_DATE_LAST_UPDATE
        $todayDate = Get-Date -Format "yyyy-MM-dd"

        if ($lastRunDate -ne $todayDate) {
            & $claudeUpdateScript *>&1 | Out-Null
            $env:CLAUDE_DATE_LAST_UPDATE = $todayDate
        }
    } catch {}
}

# --- Oh My Posh Theme ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $localTheme = Join-Path $PSScriptRoot "jandedobbeleer.omp.json"
    if (Test-Path $localTheme) {
        oh-my-posh init pwsh --config $localTheme | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config jandedobbeleer | Invoke-Expression
    }
}

# --- Git Aliases ---
function gs { git status }
function ga { git add @args }
function gcom { git commit @args }
function gp { git push @args }
function gl { git --no-pager log --oneline -n 10 }
function gd { git --no-pager diff @args }

# --- Wake-on-LAN Aliases ---
$devRoot = Resolve-Path (Join-Path $ShellManagementRoot "..")
$wolScript = Join-Path $devRoot "network\wake-on-lan\wake-servers.ps1"
if (Test-Path $wolScript) {
    function wake { & $wolScript all }
    function wake-all { & $wolScript all }
    function wake-1250p { & $wolScript 1250p }
    function wake-n6005 { & $wolScript n6005 }
    function wake-synology { & $wolScript synology }
    function wake-proxmox { & $wolScript proxmox }
}

# --- Utility Functions ---
function Update-ClaudeDate {
    $script = Join-Path $UtilsPath "Update-ClaudeDate.ps1"
    if (Test-Path $script) { & $script } else { Write-Warning "Script not found: $script" }
}

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ll { Get-ChildItem -Force }
function la { Get-ChildItem -Force }
function l { Get-ChildItem }
function mkcd { param([string]$Path) New-Item -ItemType Directory -Path $Path -Force | Out-Null; Set-Location $Path }

# Quick file find
function ff {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter $Name -ErrorAction SilentlyContinue
}

# Disk usage helper
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

# Profile editing
function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) { code $PSScriptRoot } else { notepad $PROFILE }
}
function Reload-Profile { . $PROFILE }

# Add npm global bin
$npmGlobalPath = Join-Path $HOME '.npm-global'
if (Test-Path $npmGlobalPath) {
    $env:Path = $npmGlobalPath + ';' + $env:Path
}
