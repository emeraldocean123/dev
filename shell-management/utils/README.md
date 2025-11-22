# PowerShell Scripts

System-level PowerShell utility scripts backup.

## Purpose

Backup and version control for PowerShell scripts installed in the system Scripts directory (`~/Documents/PowerShell/Scripts/`).

These scripts are referenced by the PowerShell profile and provide system-wide utilities.

## Scripts

### add-exiftool-to-path.ps1
Automatically detects ExifTool installation and adds to User PATH if missing.

**Features:**
- Auto-detection across multiple common locations
- Version verification if already in PATH
- Current session PATH update
- Comprehensive error handling

**Usage:**
```powershell
.\add-exiftool-to-path.ps1
```

**Known Locations Searched:**
- `D:\Files\Programs-Portable\ExifTool`
- `%LOCALAPPDATA%\Programs\ExifTool`
- `%LOCALAPPDATA%\Programs\ExifToolGUI`
- `C:\Program Files\ExifTool`

### Update-ClaudeDate.ps1
Updates Claude Code's date awareness by modifying the CLAUDE.md file.

**Features:**
- Automatically updates "Today's date" in CLAUDE.md
- Runs daily via PowerShell profile
- Manual trigger available

**Usage:**
```powershell
Update-ClaudeDate  # Called from profile
```

**Referenced by:** `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`

### winfetch.ps1
System information display tool (Windows equivalent of neofetch/fastfetch).

**Features:**
- Displays comprehensive system information
- Formatted output with color support
- Hardware, OS, and display information

**Usage:**
```powershell
winfetch
```

## Installation

These scripts are automatically available when placed in:
```
~/Documents/PowerShell/Scripts/
```

PowerShell automatically adds this directory to the module/script search path.

## Backup Strategy

This directory serves as version-controlled backup of system PowerShell scripts.

**Source Location:** `~/Documents/PowerShell/Scripts/`
**Backup Location:** `~/Documents/git/dev/PowerShell/Scripts/` (this directory)

To restore from backup:
```powershell
Copy-Item .\*.ps1 ~\Documents\PowerShell\Scripts\
```

## Location

**Path:** `~/Documents/git/dev/PowerShell/Scripts`
**Category:** `system-utilities`
