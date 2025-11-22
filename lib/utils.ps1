# Shared Utilities Library for Homelab Scripts
# Location: dev/lib/utils.ps1
# Purpose: Centralize common functions to reduce code duplication

<#
.SYNOPSIS
    Writes colored console output in a cross-platform compatible way.
#>
function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray,
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

        if ($NoNewline) {
            if ($Host -and $Host.UI) {
                $Host.UI.Write($Message)
            } else {
                [Console]::Write($Message)
            }
        } else {
            Write-Information -MessageData $Message -InformationAction Continue
        }
    } catch {
        Write-Output $Message
    } finally {
        if ($rawUI) {
            if ($null -ne $previousForeground) { $rawUI.ForegroundColor = $previousForeground }
            if ($null -ne $previousBackground) { $rawUI.BackgroundColor = $previousBackground }
        }
    }
}

<#
.SYNOPSIS
    Ensures the script is running with Administrator privileges.
#>
function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Console "ERROR: This script must be run as Administrator." -ForegroundColor Red
        exit 1
    }
}

<#
.SYNOPSIS
    Checks if a command or executable exists in the system PATH.
#>
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Creates a timestamped backup of a file.
#>
function Backup-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string]$BackupDirectory
    )

    if (-not (Test-Path $FilePath)) {
        Write-Console "ERROR: File not found: $FilePath" -ForegroundColor Red
        return $null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName = Split-Path $FilePath -Leaf

    if ($BackupDirectory) {
        if (-not (Test-Path $BackupDirectory)) {
            New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
        }
        $backupPath = Join-Path $BackupDirectory "$fileName.backup.$timestamp"
    } else {
        $backupPath = "$FilePath.backup.$timestamp"
    }

    Copy-Item -Path $FilePath -Destination $backupPath -Force
    Write-Console "Created backup: $backupPath" -ForegroundColor Green

    return (Get-Item $backupPath)
}

<#
.SYNOPSIS
    Displays a formatted header box.
#>
function Write-Header {
    param($Title)
    Clear-Host
    Write-Host "========================================================" -ForegroundColor Cyan
    $pad = 54 - $Title.Length
    $left = [math]::Floor($pad / 2)
    $right = [math]::Ceiling($pad / 2)
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host ""
}

<#
.SYNOPSIS
    Converts a Windows path to a WSL path using wslpath.
#>
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
