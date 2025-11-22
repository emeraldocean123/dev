# Shared Utilities Library for Homelab Scripts
# Location: dev/lib/utils.ps1
# Purpose: Centralize common functions to reduce code duplication

<#
.SYNOPSIS
    Writes colored console output in a cross-platform compatible way.
    Supports global file logging via $Global:LogFile variable.

.DESCRIPTION
    Enhanced console output with:
    - Color support (cross-platform)
    - Automatic file logging if $Global:LogFile is set
    - ANSI code stripping for log files
    - Timestamped log entries

.EXAMPLE
    # Enable logging for a script
    $Global:LogFile = "C:\Logs\homelab.log"
    Write-Console "Starting backup..." -ForegroundColor Green

.NOTES
    Set $Global:LogFile at script startup to enable persistent logging.
    Log format: "yyyy-MM-dd HH:mm:ss | Message"
#>
function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    # Global file logging support (enterprise-grade audit trail)
    if ($Global:LogFile -and $Message) {
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            # Strip ANSI color codes and control characters for clean logs
            $cleanMessage = $Message -replace "\e\[[0-9;]*m", "" -replace "`r", "" -replace "`n", " "
            $logEntry = "$timestamp | $cleanMessage"

            # Ensure log directory exists
            $logDir = Split-Path $Global:LogFile -Parent
            if ($logDir -and -not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            # Append to log file (UTF8 for cross-platform compatibility)
            $logEntry | Out-File -FilePath $Global:LogFile -Append -Encoding utf8
        }
        catch {
            # Logging failure should not crash the script
            # Fall through to console output
        }
    }

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
    Ensures the script is running with Administrator/root privileges.
    Cross-platform: Works on Windows, Linux, and macOS.
#>
function Assert-Admin {
    # PowerShell Core provides $IsWindows, $IsLinux, $IsMacOS
    # For Windows PowerShell 5.1, $IsWindows doesn't exist (assume Windows)
    $isWindowsOS = if ($null -eq $IsWindows) { $true } else { $IsWindows }

    if ($isWindowsOS) {
        # Windows: Check Administrator role
        try {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]$identity

            if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Write-Console "ERROR: This script must be run as Administrator." -ForegroundColor Red
                Write-Console "       Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
                exit 1
            }
        }
        catch {
            Write-Console "WARNING: Could not verify Administrator privileges: $_" -ForegroundColor Yellow
        }
    }
    else {
        # Linux/macOS: Check if running as root (UID 0)
        try {
            $uid = & id -u 2>$null
            if ($LASTEXITCODE -ne 0 -or [int]$uid -ne 0) {
                Write-Console "ERROR: This script must be run as root." -ForegroundColor Red
                Write-Console "       Use: sudo pwsh -File $($MyInvocation.ScriptName)" -ForegroundColor Yellow
                exit 1
            }
        }
        catch {
            Write-Console "WARNING: Could not verify root privileges: $_" -ForegroundColor Yellow
        }
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
