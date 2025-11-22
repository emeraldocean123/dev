# Shell Configurations Documentation

This document outlines the profiles, settings, and themes for PowerShell, Debian WSL, and Git Bash on this system.

## PowerShell 7

### Profile
- **Profile Path**: C:\Users\josep\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
- **Status**: Custom profile loaded.
- **Modules**: Oh My Posh, winfetch.
- **Theme/Settings**: Oh My Posh with "jandedobbeleer" theme, winfetch on startup showing system info including local/public IPs.

## Debian WSL

### Profile Files
- **~/.bashrc**: Main configuration with Oh My Posh and fastfetch.

### Bash Settings
- **History**: Default settings.
- **Aliases**: Standard aliases for ls, git, navigation.
- **PATH Additions**:
   - ~/bin
   - Oh My Posh: /mnt/c/Users/josep/AppData/Local/Programs/oh-my-posh/bin

### Theme
- **Prompt**: Oh My Posh with "jandedobbeleer" theme.
- **Startup**: Runs fastfetch showing system info including local/public IPs.

## Git Bash

### Profile Files
- **~/.bashrc**: Configuration with Oh My Posh and fastfetch.

### Bash Settings
- Similar to WSL.
- **PATH Additions**:
   - ~/bin
   - Oh My Posh: /c/Users/josep/AppData/Local/Programs/oh-my-posh/bin

### Theme
- **Prompt**: Oh My Posh with "jandedobbeleer" theme.
- **Startup**: Runs fastfetch showing system info including local/public IPs.

## Notes
- Configurations are unified between Git Bash and WSL for consistency.
- Oh My Posh provides the theme and prompt styling across all shells.
- Fastfetch displays system info including IPs on startup in Git Bash and WSL.
- Winfetch does the same in PowerShell.
- Profiles updated to reflect current setups.