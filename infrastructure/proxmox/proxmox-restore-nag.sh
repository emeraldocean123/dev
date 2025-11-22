#!/bin/bash
#
# Proxmox Restore Subscription Nag
# Restore Proxmox subscription nag (undo the patch)
#
# DEPLOYMENT:
#   Device: intel-1250p-proxmox-host (192.168.1.40)
#   Path:   /root/sh/proxmox-restore-nag.sh
#
#   Device: intel-n6005-proxmox-host (192.168.1.41)
#   Path:   /root/sh/proxmox-restore-nag.sh
#
#   Device: pve-proxmox-backup-server-1250p-lxc (192.168.1.52)
#   Path:   /root/sh/proxmox-restore-nag.sh
#
#   Backup: ~/Documents/dev/sh/proxmox-restore-nag.sh (Windows)
#
# USAGE:
#   ./proxmox-restore-nag.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

NAG_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
BACKUP_FILE="${NAG_FILE}.backup"

if [ ! -f "$NAG_FILE" ]; then
    print_error "Could not find $NAG_FILE"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    print_info "Cannot restore - no backup exists"
    exit 1
fi

print_info "Restoring original proxmoxlib.js from backup..."
cp "$BACKUP_FILE" "$NAG_FILE"

print_info "Subscription nag restored"
print_warn "Clear your browser cache or use Ctrl+F5 to see the change"
