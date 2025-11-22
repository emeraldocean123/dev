# Homelab Management Menu
# Master interface for all homelab scripts and tools
# Location: homelab.ps1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Interactive CLI menu requires colored console output')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Global config is shared design pattern across scripts')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '', Justification='UTF-8 without BOM is standard for cross-platform compatibility')]
param()

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "lib\Utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Host "WARNING: Could not find shared library" -ForegroundColor Yellow
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

$devRoot = $PSScriptRoot

# Load centralized configuration
$configPath = Join-Path $PSScriptRoot ".config\homelab.settings.json"
if (Test-Path $configPath) {
    try {
        $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Console "✓ Configuration loaded: $($Global:HomelabConfig.Owner)'s homelab" -ForegroundColor DarkGray
    } catch {
        Write-Console "WARNING: Failed to parse configuration file" -ForegroundColor Yellow
        Write-Console "  Using example template instead" -ForegroundColor Yellow
        $configPath = Join-Path $PSScriptRoot ".config\homelab.settings.example.json"
        $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    }
} else {
    Write-Console "WARNING: Configuration not found at .config\homelab.settings.json" -ForegroundColor Yellow
    Write-Console "  Using example template. Copy homelab.settings.example.json to homelab.settings.json" -ForegroundColor Yellow
    $configPath = Join-Path $PSScriptRoot ".config\homelab.settings.example.json"
    if (Test-Path $configPath) {
        $Global:HomelabConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    } else {
        Write-Console "ERROR: No configuration found. Please create .config\homelab.settings.json" -ForegroundColor Red
        exit 1
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Console "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Console "║          HOMELAB MANAGEMENT INTERFACE                 ║" -ForegroundColor Cyan
    Write-Console "║          Status: Integrated Management (v2.2)         ║" -ForegroundColor Cyan
    Write-Console "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "  Repository: /dev/" -ForegroundColor DarkGray
    Write-Console "  Structure:  Production / Hardened" -ForegroundColor DarkGray
    Write-Console ""
    Write-Console "  --- MEDIA MANAGEMENT ---" -ForegroundColor Yellow
    Write-Console "  1. Media Tools (Dedupe, Scrubber, ExifTool)" -ForegroundColor White
    Write-Console "  2. Media Services (Immich, DigiKam)" -ForegroundColor White
    Write-Console "  3. Media Clients (Mylio, MPV, XnView)" -ForegroundColor White
    Write-Console ""
    Write-Console "  --- INFRASTRUCTURE ---" -ForegroundColor Yellow
    Write-Console "  4. Hardware Diagnostics" -ForegroundColor White
    Write-Console "  5. Network Tools (VPN, WOL)" -ForegroundColor White
    Write-Console "  6. Backup Operations" -ForegroundColor White
    Write-Console "  7. Storage Management" -ForegroundColor White
    Write-Console "  10. Deployment Operations (Proxmox)" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "  --- SYSTEM & REPORTS ---" -ForegroundColor Yellow
    Write-Console "  8. Shell Management" -ForegroundColor White
    Write-Console "  9. System Maintenance & Utils" -ForegroundColor White
    Write-Console "  11. System Health & Reports" -ForegroundColor Cyan
    Write-Console "  12. Backup Configs to Cloud" -ForegroundColor Magenta
    Write-Console ""
    Write-Console "  M. Repository Maintenance" -ForegroundColor Gray
    Write-Console "  Q. Quit" -ForegroundColor Gray
    Write-Console ""
    Write-Console "══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Console ""
}

function Show-ScriptsMenu {
    param(
        [string]$Title,
        [string]$Path,
        [string[]]$ExcludeFiles = @()
    )

    Clear-Host
    Write-Console "╔═══════════════════════════════════════╗" -ForegroundColor Yellow
    $padding = 39 - 3 - $Title.Length
    $titleLine = "║   $Title" + (" " * $padding) + "║"
    Write-Console $titleLine -ForegroundColor Yellow
    Write-Console "╚═══════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Console ""

    if (-not (Test-Path $Path)) {
        Write-Console "  ERROR: Directory not found: $Path" -ForegroundColor Red
        Write-Console "  Press any key to return..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    # Find all PowerShell, Bash, and Python scripts
    $scripts = Get-ChildItem -Path $Path -Recurse -Include "*.ps1","*.sh","*.py" |
        Where-Object {
            $_.Name -notin $ExcludeFiles -and
            $_.Name -notlike "*-README*" -and
            $_.DirectoryName -notlike "*\archive*" -and
            $_.DirectoryName -notlike "*\lib*" -and
            $_.DirectoryName -notlike "*\.venv*"
        } |
        Sort-Object Name

    if ($scripts.Count -eq 0) {
        Write-Console "  No scripts found in this category." -ForegroundColor Yellow
        Write-Console ""
        Write-Console "Press any key to return..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    # Display color legend
    Write-Console "  Color Key: " -NoNewline -ForegroundColor Gray
    Write-Console "PowerShell" -NoNewline -ForegroundColor Green
    Write-Console " | " -NoNewline -ForegroundColor Gray
    Write-Console "Bash" -NoNewline -ForegroundColor Cyan
    Write-Console " | " -NoNewline -ForegroundColor Gray
    Write-Console "Python" -ForegroundColor Magenta
    Write-Console ""

    $scriptMap = @{}
    $index = 1

    foreach ($script in $scripts) {
        $relativePath = $script.FullName.Substring($devRoot.Length + 1)
        $scriptMap[$index] = $script.FullName

        # Get first comment line as description
        $description = ""
        try {
            $firstLines = Get-Content $script.FullName -TotalCount 10
            $commentLine = $firstLines | Where-Object { $_ -match '^#\s*(.+)' } | Select-Object -First 1
            if ($commentLine -match '^#\s*(.+)') {
                $description = " - $($Matches[1])"
            }
        } catch {
            # Silently continue if file cannot be read
            Write-Debug "Could not read script description: $_"
        }

        # Color code based on type
        $color = "Green" # Default PS1
        if ($script.Extension -eq ".py") { $color = "Magenta" }
        if ($script.Extension -eq ".sh") { $color = "Cyan" }

        Write-Console "  $index. $($script.Name)" -ForegroundColor $color
        if ($description) {
            Write-Console "     $description" -ForegroundColor Gray
        }
        Write-Console "     Path: $relativePath" -ForegroundColor DarkGray
        Write-Console ""

        $index++
    }

    Write-Console "  B. Back to main menu" -ForegroundColor Gray
    Write-Console ""
    Write-Console "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Console ""

    $choice = Read-Host "Select script to run (number or 'B' to back)"

    if ($choice -ieq 'B' -or $choice -eq '') {
        return
    }

    if ($scriptMap.ContainsKey([int]$choice)) {
        $targetScript = $scriptMap[[int]$choice]
        $ext = [System.IO.Path]::GetExtension($targetScript)

        Write-Console ""
        Write-Console "Running: $(Split-Path $targetScript -Leaf)" -ForegroundColor Cyan
        Write-Console "═══════════════════════════════════════════" -ForegroundColor Cyan
        Write-Console ""

        try {
            if ($ext -eq ".py") {
                python $targetScript
            } elseif ($ext -eq ".sh") {
                bash $targetScript
            } else {
                & $targetScript
            }
        } catch {
            Write-Console ""
            Write-Console "ERROR: Script failed" -ForegroundColor Red
            Write-Console $_.Exception.Message -ForegroundColor Red
        }

        Write-Console ""
        Write-Console "═══════════════════════════════════════════" -ForegroundColor Cyan
        Write-Console "Press any key to continue..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Console "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

# Main menu loop
do {
    Show-MainMenu
    $userChoice = Read-Host "Select category"

    switch ($userChoice) {
        '1' { Show-ScriptsMenu -Title "MEDIA TOOLS (Universal)" -Path "$devRoot\media\tools" }
        '2' { Show-ScriptsMenu -Title "MEDIA SERVICES (Server)" -Path "$devRoot\media\services" }
        '3' { Show-ScriptsMenu -Title "MEDIA CLIENTS (Apps)" -Path "$devRoot\media\clients" }
        '4' { Show-ScriptsMenu -Title "HARDWARE DIAGNOSTICS" -Path "$devRoot\infrastructure\hardware" }
        '5' { Show-ScriptsMenu -Title "NETWORK TOOLS" -Path "$devRoot\infrastructure\network" }
        '6' { Show-ScriptsMenu -Title "BACKUP OPERATIONS" -Path "$devRoot\infrastructure\backup" }
        '7' { Show-ScriptsMenu -Title "STORAGE MANAGEMENT" -Path "$devRoot\infrastructure\storage" }
        '8' { Show-ScriptsMenu -Title "SHELL MANAGEMENT" -Path "$devRoot\shell-management" }
        '9' { Show-ScriptsMenu -Title "SYSTEM MAINTENANCE" -Path "$devRoot\shell-management\utils" }
        '10' { Show-ScriptsMenu -Title "DEPLOYMENT OPERATIONS" -Path "$devRoot\infrastructure\deployment" }
        '11' { Show-ScriptsMenu -Title "SYSTEM HEALTH & REPORTS" -Path "$devRoot\documentation\reports" }
        '12' {
            $backupScript = Join-Path $devRoot "shell-management\shell-backup\backup-configs-to-cloud.ps1"
            if (Test-Path $backupScript) {
                Clear-Host
                & $backupScript
            } else {
                Write-Console "ERROR: Backup script not found at: $backupScript" -ForegroundColor Red
            }
            Write-Console ""
            Write-Console "Press any key to continue..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        'M' { Show-ScriptsMenu -Title "REPOSITORY MAINTENANCE" -Path "$devRoot\documentation\maintenance" }
        'Q' {
            Write-Console ""
            Write-Console "Exiting..." -ForegroundColor Green
            Write-Console ""
            exit
        }
        default {
            if ($userChoice -ne '') {
                Write-Console "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
} while ($true)

