#!/bin/bash
#
# Shell Configuration Backup Script
# Backs up shell configuration files from their active locations
# Creates both current and timestamped archive backups
#
# DEPLOYMENT:
#   Device: Windows 11 development laptop (Alienware 18)
#   Path:   ~/Documents/dev/sh/backup-shell-configs.sh
#   Backup: Same location (this is the primary copy)
#
# EXECUTION:
#   - Run manually via Git Bash: ./backup-shell-configs.sh
#   - Backs up: Git Bash .bashrc, PowerShell profile, WSL Debian .bashrc
#   - Target: ~/Documents/dev/configs/shell-backups/
#   - Creates timestamped archives in archive/ subdirectory
#
# USAGE:
#   ./backup-shell-configs.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
BACKUP_DIR="$HOME/Documents/dev/configs/shell-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_DIR="$HOME/Documents/dev/configs/shell-backups/archive"

echo -e "${GREEN}=== Shell Configuration Backup ===${NC}"
echo

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
fi

# Create archive directory for timestamped backups
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -p "$ARCHIVE_DIR"
fi

# Function to backup a file
backup_file() {
    local source="$1"
    local dest_name="$2"
    local description="$3"

    if [ -f "$source" ]; then
        echo -e "${GREEN}✓${NC} Backing up $description..."
        cp "$source" "$BACKUP_DIR/$dest_name"
        cp "$source" "$ARCHIVE_DIR/${dest_name}.${TIMESTAMP}"
    else
        echo -e "${RED}✗${NC} $description not found at: $source"
    fi
}

# Backup Git Bash .bashrc
backup_file "$HOME/.bashrc" "bashrc.gitbash" "Git Bash .bashrc"

# Backup PowerShell profile
backup_file "$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1" "Microsoft.PowerShell_profile.ps1" "PowerShell profile"

# Backup WSL Debian .bashrc
if command -v wsl.exe >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backing up WSL Debian .bashrc..."
    wsl -d Debian bash -c "cat ~/.bashrc" > "$BACKUP_DIR/bashrc.wsl-debian" 2>/dev/null || echo -e "${YELLOW}⚠${NC} WSL Debian not running or not accessible"
    if [ -f "$BACKUP_DIR/bashrc.wsl-debian" ]; then
        cp "$BACKUP_DIR/bashrc.wsl-debian" "$ARCHIVE_DIR/bashrc.wsl-debian.${TIMESTAMP}"
    fi
else
    echo -e "${YELLOW}⚠${NC} WSL not available on this system"
fi

echo
echo -e "${GREEN}=== Backup Complete ===${NC}"
echo "Current backups: $BACKUP_DIR"
echo "Archived backups: $ARCHIVE_DIR"
echo
# List backup files (excluding directories)
for file in "$BACKUP_DIR"/*; do
    [ -f "$file" ] && ls -lh "$file"
done
