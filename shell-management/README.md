# Shell Management

Shell configuration backups and management scripts.

## Active Shells

- **PowerShell 7**: Primary shell with Oh My Posh theme (jandedobbeleer)
- **Git Bash**: Secondary shell with Oh My Posh and fastfetch
- **Debian WSL**: Available with matching configurations

## Key Files

- **shell-configs.md** - Shell profile documentation (PowerShell, Git Bash, WSL)
- **backup-shell-configs.sh** - Backup shell configurations
- **restore-shell-configs.sh** - Restore shell configurations
- **configs/** - Shell configuration backups with archive subfolder

## Configuration Locations

- PowerShell profile: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- Bash config: `~/.bashrc` and `~/.bash_profile`
- Git config: Symlinked to `Documents/dev/configs/Development/.gitconfig`

## Purpose

Centralized backup and restoration of shell configurations across PowerShell, Bash, and WSL environments.
