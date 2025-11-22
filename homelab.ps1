<#
.SYNOPSIS
    Homelab Management Menu - Unified Launcher
.DESCRIPTION
    Central entry point for all maintenance, media, and infrastructure scripts.
    Handles PowerShell and Bash script execution seamlessly.
#>
param()

# Configuration
$devRoot = $PSScriptRoot

# =============================================================================
# UTILITIES
# =============================================================================

# Import Shared Utilities
$utilsPath = Join-Path $devRoot "lib\utils.ps1"
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    Write-Error "Critical Error: Utilities library not found at $utilsPath"
    exit 1
}

function Invoke-Script {
    param($ScriptPath)

    if (-not (Test-Path $ScriptPath)) {
        Write-Console "Error: Script not found at $ScriptPath" -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return
    }

    $extension = [System.IO.Path]::GetExtension($ScriptPath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($ScriptPath)

    Write-Console "Running: $fileName" -ForegroundColor Yellow
    Write-Console "======================================================" -ForegroundColor DarkGray

    if ($extension -eq ".ps1") {
        # Run PowerShell script from dev root
        Push-Location $devRoot
        try {
            & $ScriptPath
        } finally {
            Pop-Location
        }
    }
    elseif ($extension -eq ".py") {
        # Run Python script from dev root
        Push-Location $devRoot
        try {
            python $ScriptPath
        } finally {
            Pop-Location
        }
    }
    elseif ($extension -eq ".sh") {
        # Run Bash script via WSL from dev root
        # 1. Convert line endings to LF (just in case)
        $content = Get-Content $ScriptPath -Raw
        if ($content -match "`r`n") {
            $content -replace "`r`n","`n" | Set-Content -Path $ScriptPath -NoNewline -Encoding UTF8
        }

        # 2. Convert paths to WSL format
        $wslScriptPath = Get-WslPath -WindowsPath $ScriptPath
        $wslDevRoot = Get-WslPath -WindowsPath $devRoot

        # 3. Execute in WSL from dev root directory
        wsl bash -c "cd '$wslDevRoot' && bash '$wslScriptPath'"
    }
    else {
        Write-Console "Unknown file type: $extension" -ForegroundColor Red
    }

    Write-Console ""
    Write-Console "======================================================" -ForegroundColor DarkGray
    Write-Console "Execution Complete." -ForegroundColor Green
    Read-Host "Press any key to continue..."
}

# =============================================================================
# MENU LOGIC
# =============================================================================

function Show-SubMenu {
    param($CategoryName, $Path)

    while ($true) {
        Write-Header "$($CategoryName.ToUpper()) MENUS"

        $scripts = Get-ChildItem -Path $Path -Recurse -Include *.ps1, *.py, *.sh |
                   Where-Object {
                       $_.Name -notlike "_*" -and
                       $_.Name -notlike "common.ps1" -and
                       $_.DirectoryName -notmatch "[\\/]tools$"
                   } |
                   Sort-Object Name

        if ($scripts.Count -eq 0) {
            Write-Console "No scripts found in $Path" -ForegroundColor Yellow
            Read-Host "Press Enter to go back..."
            return
        }

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            $desc = Get-Content $script.FullName | Select-Object -First 5 |
                    Where-Object { $_ -match "^# .+" } |
                    Select-Object -First 1
            if ($desc) { $desc = $desc -replace "^# ", "" } else { $desc = "Run $($script.Name)" }

            # Calculate relative path for display
            $relPath = $script.FullName.Replace($devRoot + "\", "")

            Write-Console "  $($i + 1). $($script.Name)" -ForegroundColor White
            Write-Console "      - $desc" -ForegroundColor Gray
            Write-Console "      Path: $relPath" -ForegroundColor DarkGray
            Write-Console ""
        }

        Write-Console "  B. Back to main menu" -ForegroundColor Yellow
        Write-Console "======================================================" -ForegroundColor Cyan

        $selection = Read-Host "Select script to run (number or 'B' to back)"

        if ($selection -match "^[Bb]$") { return }

        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $scripts.Count) {
            $scriptToRun = $scripts[[int]$selection - 1]
            Invoke-Script -ScriptPath $scriptToRun.FullName
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Write-Header "MAIN MENU"

        $categories = @(
            @{ Name = "Media - Clients"; Path = "media\clients" },
            @{ Name = "Media - Services"; Path = "media\services" },
            @{ Name = "Media - Tools"; Path = "media\tools" },
            @{ Name = "Infrastructure"; Path = "infrastructure" },
            @{ Name = "Shell Management"; Path = "shell-management" },
            @{ Name = "Documentation & Maintenance"; Path = "documentation" },
            @{ Name = "AI Configs"; Path = "ai-configs" }
        )

        for ($i = 0; $i -lt $categories.Count; $i++) {
            Write-Console "  $($i + 1). $($categories[$i].Name)" -ForegroundColor White
        }

        Write-Console "  Q. Quit" -ForegroundColor Yellow
        Write-Console "======================================================" -ForegroundColor Cyan

        $selection = Read-Host "Select category"

        if ($selection -match "^[Qq]$") { break }

        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $categories.Count) {
            $cat = $categories[[int]$selection - 1]
            Show-SubMenu -CategoryName $cat.Name -Path (Join-Path $devRoot $cat.Path)
        }
    }
}

# =============================================================================
# ENTRY POINT
# =============================================================================

# Initial environment check
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Console "WARNING: WSL is not installed or not in PATH. Bash scripts will fail." -ForegroundColor Red
    Start-Sleep -Seconds 2
}

# Hybrid ENV generation check (only regenerate if stale)
$configJson = Join-Path $devRoot ".config\homelab.settings.json"
$configEnv = Join-Path $devRoot ".config\homelab.env"
$envGenerator = Join-Path $devRoot "shell-management\utils\generate-bash-config.ps1"

if (Test-Path $configJson) {
    $needsRegeneration = $false

    if (-not (Test-Path $configEnv)) {
        # ENV file doesn't exist
        $needsRegeneration = $true
    } else {
        # Check if JSON is newer than ENV
        $jsonTimestamp = (Get-Item $configJson).LastWriteTime
        $envTimestamp = (Get-Item $configEnv).LastWriteTime
        if ($jsonTimestamp -gt $envTimestamp) {
            $needsRegeneration = $true
        }
    }

    if ($needsRegeneration -and (Test-Path $envGenerator)) {
        Write-Console "Configuration changed - regenerating Bash ENV..." -ForegroundColor Yellow
        & $envGenerator | Out-Null
        Write-Console "ENV file updated: .config/homelab.env" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
}

# Start Menu
Show-MainMenu
