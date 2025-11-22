<#
.SYNOPSIS
    Homelab Management Menu - Unified Launcher
.DESCRIPTION
    Central entry point for all maintenance, media, and infrastructure scripts.
    Handles PowerShell and Bash script execution seamlessly.
#>

# Configuration
$devRoot = $PSScriptRoot
$menuTitle = "HOMELAB MANAGEMENT CONSOLE"

# =============================================================================
# UTILITIES
# =============================================================================

function Write-Header {
    param($Title)
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    $pad = 54 - $Title.Length
    $left = [math]::Floor($pad / 2)
    $right = [math]::Ceiling($pad / 2)
    Write-Host "║$(' ' * $left)$Title$(' ' * $right)║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-WslPath {
    param([string]$WindowsPath)
    # Use wslpath to robustly convert Windows C:\Users... to /mnt/c/Users...
    # Use Start-Process to avoid PowerShell's backslash stripping
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "wsl.exe"
    $pinfo.Arguments = "wslpath -ua `"$WindowsPath`""
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    $result = $p.StandardOutput.ReadToEnd().Trim()
    $error = $p.StandardError.ReadToEnd()

    if ($p.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($result)) {
        Write-Host "Error: Failed to convert path: $WindowsPath" -ForegroundColor Red
        if ($error) { Write-Host "  $error" -ForegroundColor Red }
        return $null
    }

    return $result
}

function Run-Script {
    param($ScriptPath)

    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Error: Script not found at $ScriptPath" -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return
    }

    $extension = [System.IO.Path]::GetExtension($ScriptPath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($ScriptPath)

    Write-Host "Running: $fileName" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor DarkGray

    if ($extension -eq ".ps1") {
        # Run PowerShell script
        & $ScriptPath
    }
    elseif ($extension -eq ".py") {
        # Run Python script
        python $ScriptPath
    }
    elseif ($extension -eq ".sh") {
        # Run Bash script via WSL
        # 1. Convert line endings to LF (just in case)
        $content = Get-Content $ScriptPath -Raw
        if ($content -match "`r`n") {
            $content -replace "`r`n","`n" | Set-Content -Path $ScriptPath -NoNewline -Encoding UTF8
        }

        # 2. Convert Windows Path to WSL Path
        $wslScriptPath = Get-WslPath -WindowsPath $ScriptPath

        # 3. Execute in WSL
        wsl -e bash "$wslScriptPath"
    }
    else {
        Write-Host "Unknown file type: $extension" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "Execution Complete." -ForegroundColor Green
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
                   Where-Object { $_.Name -notlike "_*" -and $_.Name -notlike "common.ps1" } |
                   Sort-Object Name

        if ($scripts.Count -eq 0) {
            Write-Host "No scripts found in $Path" -ForegroundColor Yellow
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

            Write-Host "  $($i + 1). $($script.Name)" -ForegroundColor White
            Write-Host "      - $desc" -ForegroundColor Gray
            Write-Host "      Path: $relPath" -ForegroundColor DarkGray
            Write-Host ""
        }

        Write-Host "  B. Back to main menu" -ForegroundColor Yellow
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan

        $selection = Read-Host "Select script to run (number or 'B' to back)"

        if ($selection -match "^[Bb]$") { return }

        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $scripts.Count) {
            $scriptToRun = $scripts[[int]$selection - 1]
            Run-Script -ScriptPath $scriptToRun.FullName
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Write-Header "MAIN MENU"

        $categories = @(
            @{ Name = "Media Tools"; Path = "media\tools" },
            @{ Name = "Infrastructure"; Path = "infrastructure" },
            @{ Name = "Shell Management"; Path = "shell-management" },
            @{ Name = "Documentation & Maintenance"; Path = "documentation" },
            @{ Name = "AI Configs"; Path = "ai-configs" }
        )

        for ($i = 0; $i -lt $categories.Count; $i++) {
            Write-Host "  $($i + 1). $($categories[$i].Name)" -ForegroundColor White
        }

        Write-Host "  Q. Quit" -ForegroundColor Yellow
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan

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
    Write-Host "WARNING: WSL is not installed or not in PATH. Bash scripts will fail." -ForegroundColor Red
    Start-Sleep -Seconds 2
}

# Start Menu
Show-MainMenu
