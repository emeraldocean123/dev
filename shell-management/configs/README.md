# Shell Configuration Management

**Last Updated:** October 11, 2025

This directory contains backups and management tools for all shell configurations across PowerShell 7, Git Bash, and WSL Debian.

## Directory Structure

```
~/Documents/dev/configs/
├── shell-backups/          # Current backups
│   ├── bashrc.gitbash      # Git Bash configuration
│   ├── bashrc.wsl-debian   # WSL Debian configuration
│   └── Microsoft.PowerShell_profile.ps1  # PowerShell 7 profile
└── archive/                # Timestamped backups (automatic)
```

## Management Scripts

Located in `~/Documents/dev/sh/`:

### backup-shell-configs.sh
Backs up all shell configurations to `~/Documents/dev/configs/shell-backups/`
- Creates timestamped archives automatically
- Backs up: Git Bash .bashrc, PowerShell profile, WSL Debian .bashrc

**Usage:**
```bash
cd ~/Documents/dev/sh
./backup-shell-configs.sh
```

### restore-shell-configs.sh
Restores shell configurations from backups
- Creates .pre-restore.bak files before restoring
- Safe to run - backs up current configs first

**Usage:**
```bash
cd ~/Documents/dev/sh
./restore-shell-configs.sh
```

## Active Configuration Locations

| Shell | Config File | Backup Name |
|-------|-------------|-------------|
| Git Bash | `~/.bashrc` | bashrc.gitbash |
| PowerShell 7 | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Microsoft.PowerShell_profile.ps1 |
| WSL Debian | `~/.bashrc` (inside WSL) | bashrc.wsl-debian |

## Shell Features & Optimizations

All three shells now have consistent configurations with the following features:

### 1. History Management
- **Size**: 10,000 commands
- **Deduplication**: Ignores duplicate commands
- **Timestamps**: Shows when each command was run
- **Persistence**: Incremental saving (PowerShell), append mode (Bash)

### 2. Git Aliases (Consistent across all shells)
- `gs` - git status
- `ga` - git add
- `gcom` - git commit
- `gp` - git push
- `gl` - git log (last 10 entries, one line)
- `gd` - git diff

### 3. Navigation Aliases
- `..` - cd up one directory
- `...` - cd up two directories
- `....` - cd up three directories

### 4. Listing Aliases
- `ll` - long list with hidden files
- `la` - same as ll
- `l` - long list without hidden files

### 5. Safety Features
- `rm` - confirm before delete (Bash/WSL)
- `cp` - confirm before overwrite
- `mv` - confirm before move/rename
- PowerShell `rm` has -Confirm by default
- `rmf` (PowerShell) - force delete without confirmation

### 6. Useful Functions

**mkcd** - Create directory and cd into it
```bash
mkcd new-project    # Creates and enters directory
```

**extract** - Extract any archive format (Bash/WSL only)
```bash
extract archive.tar.gz
extract file.zip
```

**ff** - Quick file search
```bash
ff "*.txt"          # Find all .txt files recursively
```

**ducks** - Disk usage sorted by size
```bash
ducks               # Shows largest files/folders
```

**du1** - Disk usage one level deep (Bash/WSL)
```bash
du1                 # Show sizes of immediate subdirectories
```

### 7. Color Support (Bash/WSL)
- Colored ls output
- Colored grep output
- Custom LS_COLORS for better visibility

### 8. PowerShell-Specific Features
- **PSReadLine** enhancements (predictive IntelliSense)
- **Edit-Profile** - Quick edit profile in notepad
- **Reload-Profile** - Reload profile without restarting
- **Claude date auto-update** - Daily automatic updates

### 9. Visual Enhancements
- **Winfetch** (PowerShell) - System info on startup
- **Fastfetch** (Git Bash/WSL) - System info on startup
- **Oh My Posh** - Beautiful prompt (all shells)

## Backup Strategy

**Automatic Timestamped Backups:**
Every time you run `backup-shell-configs.sh`, it:
1. Copies configs to `shell-backups/` (current)
2. Creates timestamped copies in `archive/` (YYYYMMDD_HHMMSS format)

**When to Backup:**
- Before making major changes to shell configs
- After testing new features you want to keep
- Periodically (weekly/monthly)

**Archive Cleanup:**
Old timestamped backups in `archive/` can be deleted manually if they accumulate.

## Recovery Process

If you break your shell configuration:

1. **Quick restore from current backup:**
   ```bash
   cd ~/Documents/dev/sh
   ./restore-shell-configs.sh
   ```

2. **Restore from specific timestamped backup:**
   ```bash
   cd ~/Documents/dev/configs/shell-backups/archive
   ls -lh                    # Find the backup you want
   cp bashrc.gitbash.20251011_152000 ~/.bashrc
   ```

3. **Manual restore:**
   ```bash
   # Git Bash
   cp ~/Documents/dev/configs/shell-backups/bashrc.gitbash ~/.bashrc

   # PowerShell
   cp ~/Documents/dev/configs/shell-backups/Microsoft.PowerShell_profile.ps1 ~/Documents/PowerShell/

   # WSL Debian
   cat ~/Documents/dev/configs/shell-backups/bashrc.wsl-debian | wsl -d Debian bash -c "cat > ~/.bashrc"
   ```

## Testing Your Config

After modifying configs, test in each shell:

**Git Bash:**
```bash
source ~/.bashrc
gs                    # Test git alias
mkcd test-dir         # Test mkcd function
```

**PowerShell:**
```powershell
. $PROFILE
gs                    # Test git alias
mkcd test-dir         # Test mkcd function
```

**WSL Debian:**
```bash
wsl bash -c "source ~/.bashrc && gs"
```

## Maintenance Tips

1. **Keep configs synchronized:** After updating one shell, update others to match
2. **Run backup after changes:** Always backup after making config changes
3. **Test before committing:** Test all functions/aliases before backing up
4. **Document custom additions:** Add comments for custom functions/aliases
5. **Version control:** Consider adding configs to git for even more history

## Notes

- All configurations are optimized for development workflows
- Safety aliases (rm -i, etc.) prevent accidental deletions
- History settings preserve your command history effectively
- Functions are designed to save time on common operations
- Colors improve readability without being distracting
