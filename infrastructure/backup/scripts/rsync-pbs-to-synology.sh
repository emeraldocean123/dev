#!/bin/bash
#
# Rsync PBS Datastore to Synology NAS
# Replicates PBS backup data to NAS via SSH
#
# DEPLOYMENT:
#   Auto-deployed to /root/sh/ via deploy-to-proxmox.ps1
#   Requires /root/sh/config/homelab.env

# --- LOAD CONFIGURATION ---
CONFIG_FILE="$(dirname "$0")/config/homelab.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "[ERROR] Config file not found at $CONFIG_FILE"
    exit 1
fi

# Configuration (Sanitized)
# We use the mount point derived from dataset or explicit path
SOURCE_DIR="${BACKUP_SOURCE_MOUNT:-/mnt/intel-1250p-proxmox-backup-server}"
TARGET_USER="${NAS_USER}"
TARGET_IP="${NAS_IP}"
TARGET_PATH="${NAS_BACKUP_PATH}"
SSH_KEY="${SSH_KEY_PATH:-/root/.ssh/id_ed25519}"

# Validate
if [[ -z "$TARGET_IP" || -z "$TARGET_PATH" ]]; then
    echo "[ERROR] NAS configuration missing from env file."
    exit 1
fi

TARGET="${TARGET_USER}@${TARGET_IP}:${TARGET_PATH}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Execution
info "Starting Sync to Synology..."
info "Source: $SOURCE_DIR"
info "Target: $TARGET"
info "Key:    $SSH_KEY"

# Rsync command
# Using -e to specify ssh key and disable strict host checking for automation
if rsync -avh -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" --delete --stats --info=progress2 \
    "$SOURCE_DIR/" "$TARGET/"; then
    info "Sync successful."
else
    error "Sync failed. Check network connectivity or permissions."
    exit 1
fi

exit 0
