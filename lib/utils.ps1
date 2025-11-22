# Shared Utilities Library for Homelab Scripts
# Location: dev/lib/utils.ps1
# Purpose: Centralize common functions to reduce code duplication

<#
.SYNOPSIS
    Writes colored console output in a cross-platform compatible way.

.DESCRIPTION
    Provides consistent colored console output across different PowerShell hosts
    (PowerShell 7, Windows PowerShell, VSCode, etc.) with proper error handling.

.PARAMETER Message
    The message to write to the console.

.PARAMETER ForegroundColor
    The foreground color for the message. Default is Gray.

.PARAMETER BackgroundColor
    The background color for the message (optional).

.PARAMETER NoNewline
    If specified, does not add a newline after the message.

.EXAMPLE
    Write-Console "Success!" -ForegroundColor Green
    Write-Console "Error occurred" -ForegroundColor Red
    Write-Console "Processing..." -ForegroundColor Yellow -NoNewline
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
        # Check if we have access to RawUI
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor

            # Set new colors
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        # Write the message
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
        # Fallback to simple output if colored output fails
        Write-Output $Message
    } finally {
        # Restore original colors
        if ($rawUI) {
            if ($null -ne $previousForeground) {
                $rawUI.ForegroundColor = $previousForeground
            }
            if ($null -ne $previousBackground) {
                $rawUI.BackgroundColor = $previousBackground
            }
        }
    }
}

<#
.SYNOPSIS
    Ensures the script is running with Administrator privileges.

.DESCRIPTION
    Checks if the current PowerShell session has Administrator privileges.
    Exits the script with an error if not running as Administrator.

.EXAMPLE
    Assert-Admin
    # Script continues only if running as Administrator
#>
function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Console "ERROR: This script must be run as Administrator." -ForegroundColor Red
        Write-Console "Please re-run PowerShell as Administrator and try again." -ForegroundColor Yellow
        exit 1
    }
}

<#
.SYNOPSIS
    Checks if a command or executable exists in the system PATH.

.DESCRIPTION
    Tests whether a specified command is available in the current environment.

.PARAMETER Command
    The command name to check (e.g., 'git', 'docker', 'exiftool').

.EXAMPLE
    if (Test-CommandExists 'git') {
        Write-Console "Git is installed" -ForegroundColor Green
    }

.OUTPUTS
    Boolean - True if command exists, False otherwise
#>
function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Creates a timestamped backup of a file.

.DESCRIPTION
    Copies a file to a backup location with a timestamp appended to the filename.

.PARAMETER FilePath
    The path to the file to backup.

.PARAMETER BackupDirectory
    Optional directory to store backups. Defaults to same directory as original file.

.EXAMPLE
    Backup-File -FilePath "C:\config.json"
    # Creates: C:\config.json.backup.20251118-223000

.OUTPUTS
    FileInfo - The backup file object
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

