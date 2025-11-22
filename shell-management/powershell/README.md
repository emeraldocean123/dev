# PowerShell Profile Management

Manages the Windows PowerShell profile configuration as code. This tool allows you to version control your profile in the `dev` repository while keeping it active in your system.

## Files

- **Microsoft.PowerShell_profile.ps1**: The source of truth for your shell profile.
- **deploy-profile.ps1**: "Installs" the profile by creating a loader script in your Windows Documents folder that references this repository file.

## Installation

Run the deployment script once to link your Windows profile to this repository:

```powershell
.\deploy-profile.ps1
```

## Features

- **Portable Paths**: Uses relative paths to locate other scripts in the dev repository.
- **Auto-Updates**: Changes to the repository file take effect immediately in new shells.
- **Safety**: The deploy script backs up your existing profile before overwriting.

## Location

- **Path**: `~/Documents/dev/system-scripts/powershell-profile/`
- **Category**: system-scripts
