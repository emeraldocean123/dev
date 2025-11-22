# PowerShell Folders Cleanup - November 19, 2025

## Summary

Cleaned up redundant files from `~/Documents/PowerShell/` and `~/Documents/WindowsPowerShell/` after migrating PowerShell profile to version control in the dev repository.

## Changes Made

### PowerShell Folder (~/Documents/PowerShell/)

**Removed:**
- `jandedobbeleer.omp.json` - Duplicate (now in repository)
- `Scripts/` folder - Removed and recreated with symlink

**Kept:**
- `Microsoft.PowerShell_profile.ps1` - Loader that dot-sources repository profile
- `Microsoft.PowerShell_profile.ps1.backup.20251119-085134` - Safety backup
- `Modules/` - Installed PowerShell modules (PSReadLine, PSScriptAnalyzer)

**Added:**
- `Scripts/winfetch.ps1` - Symlink to `~/Documents/git/dev/system-scripts/Scripts/winfetch.ps1`

### WindowsPowerShell Folder (~/Documents/WindowsPowerShell/)

**Added:**
- `Microsoft.PowerShell_profile.ps1` - Loader for Windows PowerShell 5.1

**Kept:**
- `Scripts/` - Empty except for InstalledScriptInfos metadata

### Scripts Folder (~/Documents/PowerShell/Scripts/)

**Recreated with Symlink:**
- `winfetch.ps1` - Symlink to `~/Documents/git/dev/system-scripts/Scripts/winfetch.ps1`

**Note:** Initially removed and recreated multiple times. Final fix required PowerShell's `New-Item -ItemType SymbolicLink` instead of Git Bash's `ln -s` to create proper Windows symlinks with absolute paths.

## Result

Both PowerShell 7 and Windows PowerShell 5.1 now load their profiles from the version-controlled repository at:
```
~/Documents/git/dev/system-scripts/powershell-profile/Microsoft.PowerShell_profile.ps1
```

All profile changes are now tracked in git and apply immediately to new shell sessions.

## Symlink Issues and Fixes

### Problem
After initial cleanup, all shells (PowerShell, Git Bash, Debian WSL) broke due to symlink issues:
- Bash configs used `~` in symlink targets which Git Bash couldn't resolve
- Winfetch symlink also used `~` causing timeouts in PowerShell

### Solution
**Bash configs:** Recreated with absolute paths using `ln -s`:
```bash
ln -s /c/Users/josep/Documents/git/dev/shell-management/bash-configs/.bashrc ~/.bashrc
ln -s /c/Users/josep/Documents/git/dev/shell-management/bash-configs/.bash_profile ~/.bash_profile
```

**Winfetch:** Recreated using PowerShell's `New-Item -ItemType SymbolicLink`:
```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\Documents\PowerShell\Scripts\winfetch.ps1" -Target "$HOME\Documents\git\dev\system-scripts\Scripts\winfetch.ps1"
```

**Key Lesson:** Windows symlinks require absolute paths and PowerShell's native symlink creation for best compatibility.

## Safety

- Original PowerShell 7 profile backed up to `Microsoft.PowerShell_profile.ps1.backup.20251119-085134`
- Modules folder preserved (contains installed PowerShell modules)
- All removed files are available in repository at `system-scripts/Scripts/`
- winfetch.ps1 was restored from Recycle Bin and then properly symlinked
