# Test Different Tone Mapping Algorithms for HDR Videos
# Run this script to test different tone mapping settings

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("hable", "mobius", "bt.2446a", "reinhard", "restore")]
    [string]$ToneMapping = ""
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
$configPath = "$env:APPDATA\mpv.net\mpv.conf"
$backupPath = "$env:APPDATA\mpv.net\mpv.conf.backup"

function Show-Menu {
    Write-Console "`n=== MPV.NET Tone Mapping Tester ===" -ForegroundColor Cyan
    Write-Console ""
    Write-Console "Current tone mapping algorithm:" -ForegroundColor Yellow
    $current = Get-Content $configPath | Select-String "^tone-mapping="
    if ($current) {
        Write-Console "  $($current.Line)" -ForegroundColor Green
    } else {
        Write-Console "  None configured" -ForegroundColor Red
    }
    Write-Console ""
    Write-Console "Available tone mapping algorithms:" -ForegroundColor Cyan
    Write-Console "  1. hable    - Filmic (Uncharted 2) - Natural film-like look [RECOMMENDED]"
    Write-Console "  2. mobius   - Preserves detail in bright scenes"
    Write-Console "  3. bt.2446a - ITU standard - Very accurate colors"
    Write-Console "  4. reinhard - Classic algorithm - Softer look"
    Write-Console "  5. restore  - Restore original backup"
    Write-Console "  Q. Quit"
    Write-Console ""
}

function Set-ToneMapping {
    param([string]$Algorithm)

    # Backup if not already backed up
    if (-not (Test-Path $backupPath)) {
        Copy-Item $configPath $backupPath
        Write-Console "Created backup: $backupPath" -ForegroundColor Green
    }

    # Read config
    $config = Get-Content $configPath

    # Update tone mapping line
    $updated = $false
    for ($i = 0; $i -lt $config.Length; $i++) {
        if ($config[$i] -match "^tone-mapping=") {
            $config[$i] = "tone-mapping=$Algorithm"
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        Write-Console "Error: Could not find tone-mapping line in config" -ForegroundColor Red
        return
    }

    # Write updated config
    $config | Set-Content $configPath

    Write-Console "`n✓ Updated tone mapping to: $Algorithm" -ForegroundColor Green
    Write-Console "`nNow test an HDR video with mpv.net to see the difference!" -ForegroundColor Cyan
    Write-Console "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Restore-Backup {
    if (Test-Path $backupPath) {
        Copy-Item $backupPath $configPath -Force
        Write-Console "`n✓ Restored original configuration from backup" -ForegroundColor Green
        Write-Console "`nPress any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Console "`nNo backup found at: $backupPath" -ForegroundColor Red
        Write-Console "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Main logic
if ($ToneMapping) {
    # Command-line argument provided
    if ($ToneMapping -eq "restore") {
        Restore-Backup
    } else {
        Set-ToneMapping $ToneMapping
    }
} else {
    # Interactive menu
    while ($true) {
        Clear-Host
        Show-Menu

        $choice = Read-Host "Select an option"

        switch ($choice.ToLower()) {
            "1" { Set-ToneMapping "hable" }
            "2" { Set-ToneMapping "mobius" }
            "3" { Set-ToneMapping "bt.2446a" }
            "4" { Set-ToneMapping "reinhard" }
            "5" { Restore-Backup }
            "q" {
                Write-Console "`nGoodbye!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Console "`nInvalid choice. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}
