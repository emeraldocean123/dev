#!/bin/bash
#
# ZFS Replication Script for PBS Datastore
# Replicates PBS datastore to secondary host (intel-n6005)
# Uses incremental ZFS send/receive
#
# DEPLOYMENT:
#   Auto-deployed to /root/sh/ via deploy-to-proxmox.ps1
#   Requires /root/sh/config/homelab.env (generated automatically)

set -e  # Exit on error

# --- LOAD CONFIGURATION ---
# Try production path first, then relative for testing
CONFIG_FILE="$(dirname "$0")/config/homelab.env"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="$(dirname "$0")/../network/config/servers.env"
fi

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "[ERROR] Config file not found at $CONFIG_FILE"
    exit 1
fi

# Validate Variables
if [[ -z "$SECONDARY_IP" || -z "$BACKUP_SOURCE_DATASET" ]]; then
    echo "[ERROR] Required variables (SECONDARY_IP, BACKUP_SOURCE_DATASET) not set in env file."
    exit 1
fi

# Configuration Variables
SOURCE_DATASET="$BACKUP_SOURCE_DATASET"
TARGET_HOST="${SECONDARY_USER}@${SECONDARY_IP}"
TARGET_DATASET="$BACKUP_TARGET_DATASET"
SNAPSHOT_PREFIX="${BACKUP_SNAPSHOT_PREFIX:-pbs-repl}"
KEEP_SNAPSHOTS="${BACKUP_KEEP_SNAPSHOTS:-7}"

# Power management settings
AUTO_SHUTDOWN=true
SHUTDOWN_GRACE_TIME=30

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
power() { echo -e "${BLUE}[POWER]${NC} $1"; }

# Check Hostname (Optional safety check)
if [[ -n "$PRIMARY_HOST" && "$(hostname)" != "$PRIMARY_HOST" ]]; then
    warn "Hostname $(hostname) does not match config PRIMARY_HOST ($PRIMARY_HOST). Continuing anyway..."
fi

# Verify Source
if ! zfs list "$SOURCE_DATASET" &>/dev/null; then
    error "Source dataset $SOURCE_DATASET does not exist"
    exit 1
fi

# Check Target Online
info "Checking target ($TARGET_HOST)..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$TARGET_HOST" "echo 'online'" &>/dev/null; then
    info "Target is online."
else
    warn "Target offline. Attempting WOL..."
    # Call wake script if available
    WAKE_SCRIPT="$(dirname "$0")/wake-servers.sh"
    if [ -x "$WAKE_SCRIPT" ]; then
        $WAKE_SCRIPT "n6005"
        sleep 60 # Wait for boot
    else
        warn "Wake script not found at $WAKE_SCRIPT"
    fi
fi

# Verify target host is reachable
if ! ssh -o ConnectTimeout=5 "$TARGET_HOST" "echo 'Connection test'" &>/dev/null; then
    error "Cannot connect to target host $TARGET_HOST"
    exit 1
fi

info "Starting PBS datastore replication..."
info "Source: $SOURCE_DATASET"
info "Target: $TARGET_DATASET on $TARGET_HOST"

# Create new snapshot
SNAPSHOT_NAME="$SNAPSHOT_PREFIX-$(date +%Y%m%d-%H%M%S)"
FULL_SNAPSHOT="$SOURCE_DATASET@$SNAPSHOT_NAME"

info "Creating snapshot: $FULL_SNAPSHOT"
zfs snapshot "$FULL_SNAPSHOT"

# Get recent snapshots for incremental send
# (Logic simplified for brevity - standard ZFS send/recv follows)
# Checks for common base snapshot on remote
LATEST_REMOTE_SNAP=$(ssh "$TARGET_HOST" "zfs list -H -o name -t snapshot -S creation \"$TARGET_DATASET\" | grep \"@$SNAPSHOT_PREFIX\" | head -n1 | cut -d@ -f2")

if [ -n "$LATEST_REMOTE_SNAP" ]; then
    info "Found common base: $LATEST_REMOTE_SNAP"
    info "Sending incremental stream..."
    zfs send -i "$SOURCE_DATASET@$LATEST_REMOTE_SNAP" "$FULL_SNAPSHOT" | ssh "$TARGET_HOST" "zfs recv -F \"$TARGET_DATASET\""
else
    info "No common base found. Sending FULL stream (may take time)..."
    zfs send "$FULL_SNAPSHOT" | ssh "$TARGET_HOST" "zfs recv \"$TARGET_DATASET\""
fi

info "Replication completed successfully."

# Cleanup old snapshots locally
info "Pruning old local snapshots (keeping $KEEP_SNAPSHOTS)..."
zfs list -H -o name -t snapshot -S creation "$SOURCE_DATASET" | grep "@$SNAPSHOT_PREFIX" | tail -n +$((KEEP_SNAPSHOTS + 1)) | xargs -r -n 1 zfs destroy

# Auto-shutdown target
if [ "$AUTO_SHUTDOWN" = true ]; then
    power "Scheduling remote shutdown..."
    ssh "$TARGET_HOST" "/root/sh/shutdown-with-rtc-wake.sh" || true
fi

exit 0
