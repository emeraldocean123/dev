#!/bin/bash
#
# Shell Configuration Restore Script
# Restores shell configuration files from backups to their active locations
# Creates pre-restore backups before overwriting current configs
#
# DEPLOYMENT:
#   Device: Windows 11 development laptop (Alienware 18)
#   Path:   ~/Documents/dev/sh/restore-shell-configs.sh
#   Backup: Same location (this is the primary copy)
#
# EXECUTION:
#   - Run manually via Git Bash: ./restore-shell-configs.sh
#   - Restores: Git Bash .bashrc, PowerShell profile, WSL Debian .bashrc
#   - Source: ~/Documents/dev/configs/shell-backups/
#   - Creates pre-restore backups with .pre-restore.bak extension
#
# USAGE:
#   ./restore-shell-configs.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
BACKUP_DIR="$HOME/Documents/dev/configs/shell-backups"

echo -e "${GREEN}=== Shell Configuration Restore ===${NC}"
echo

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Backup directory not found: $BACKUP_DIR${NC}"
    exit 1
fi

# Function to restore a file
restore_file() {
    local source="$1"
    local dest="$2"
    local description="$3"

    if [ -f "$source" ]; then
        # Create backup of current file if it exists
        if [ -f "$dest" ]; then
            echo -e "${YELLOW}⚠${NC} Backing up current $description..."
            cp "$dest" "${dest}.pre-restore.bak"
        fi

        echo -e "${GREEN}✓${NC} Restoring $description..."
        cp "$source" "$dest"
    else
        echo -e "${RED}✗${NC} Backup not found for $description at: $source"
    fi
}

# Restore Git Bash .bashrc
restore_file "$BACKUP_DIR/bashrc.gitbash" "$HOME/.bashrc" "Git Bash .bashrc"

# Restore PowerShell profile
restore_file "$BACKUP_DIR/Microsoft.PowerShell_profile.ps1" "$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1" "PowerShell profile"

# Restore WSL Debian .bashrc
if command -v wsl.exe >/dev/null 2>&1; then
    if [ -f "$BACKUP_DIR/bashrc.wsl-debian" ]; then
        echo -e "${GREEN}✓${NC} Restoring WSL Debian .bashrc..."
        # Create backup of current WSL .bashrc
        wsl -d Debian bash -c "[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.pre-restore.bak" 2>/dev/null || true
        # Restore from backup
        cat "$BACKUP_DIR/bashrc.wsl-debian" | wsl -d Debian bash -c "cat > ~/.bashrc"
    else
        echo -e "${YELLOW}⚠${NC} No backup found for WSL Debian .bashrc"
    fi
else
    echo -e "${YELLOW}⚠${NC} WSL not available on this system"
fi

echo
echo -e "${GREEN}=== Restore Complete ===${NC}"
echo "Note: Pre-restore backups saved with .pre-restore.bak extension"
echo "You may need to restart your shell or source the configs:"
echo "  Git Bash: source ~/.bashrc"
echo "  PowerShell: . \$PROFILE"
echo "  WSL: wsl bash -c 'source ~/.bashrc'"
