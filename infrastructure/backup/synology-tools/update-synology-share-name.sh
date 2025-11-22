#!/bin/bash
#
# Update Synology Share Name in rsync Configuration
# One-time utility script to update rsync service configuration
# Changes destination from /volume1/pbs-backup/ to /volume1/backup-proxmox-backup-server/
#
# DEPLOYMENT:
#   Device: intel-n6005-proxmox-host (192.168.1.41) - TARGET DEVICE
#   Path:   /root/sh/update-synology-share-name.sh
#   Backup: ~/Documents/dev/sh/update-synology-share-name.sh (Windows)
#
# EXECUTION:
#   - Run once on intel-n6005: ./update-synology-share-name.sh
#   - Updates systemd service: pbs-sync-to-synology.service
#   - Creates timestamped backup before modification
#   - Reloads systemd daemon after changes
#   - Verifies new Synology share is accessible
#
# USAGE:
#   ssh intel-n6005
#   cd /root/sh
#   ./update-synology-share-name.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Updating Synology Share Name Configuration ===${NC}\n"

# Check if running on n6005
if [ "$(hostname)" != "intel-n6005" ]; then
    echo -e "${YELLOW}Warning: This script should be run on intel-n6005${NC}"
    echo -e "${YELLOW}Current hostname: $(hostname)${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup original service file
SERVICE_FILE="/etc/systemd/system/pbs-sync-to-synology.service"
BACKUP_FILE="${SERVICE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SERVICE_FILE" ]; then
    echo -e "${RED}Error: Service file not found: $SERVICE_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Backing up original service file...${NC}"
cp "$SERVICE_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}\n"

# Show current configuration
echo -e "${YELLOW}Current rsync destination:${NC}"
grep "ExecStart=" "$SERVICE_FILE"
echo

# Update the service file
echo -e "${YELLOW}Updating rsync destination...${NC}"
sed -i 's|synology:/volume1/pbs-backup/|synology:/volume1/backup-proxmox-backup-server/|g' "$SERVICE_FILE"

# Show new configuration
echo -e "${GREEN}New rsync destination:${NC}"
grep "ExecStart=" "$SERVICE_FILE"
echo

# Reload systemd
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}\n"

# Verify the change
echo -e "${YELLOW}Verifying configuration change...${NC}"
if grep -q "backup-proxmox-backup-server" "$SERVICE_FILE"; then
    echo -e "${GREEN}✓ Configuration updated successfully${NC}\n"
else
    echo -e "${RED}✗ Configuration update failed${NC}\n"
    echo -e "${YELLOW}Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${RED}Backup restored. Please investigate the issue.${NC}"
    exit 1
fi

# Test SSH connection to new share
echo -e "${YELLOW}Testing SSH connection to Synology...${NC}"
if ssh synology "test -d /volume1/backup-proxmox-backup-server && echo 'Directory exists'"; then
    echo -e "${GREEN}✓ Synology share accessible${NC}\n"
else
    echo -e "${RED}✗ Cannot access /volume1/backup-proxmox-backup-server on Synology${NC}"
    echo -e "${YELLOW}Please verify:${NC}"
    echo "  1. Share name is correct: backup-proxmox-backup-server"
    echo "  2. SSH access is configured"
    echo "  3. User 'joseph' has permissions"
    exit 1
fi

# Show next rsync schedule
echo -e "${YELLOW}Next scheduled rsync:${NC}"
systemctl list-timers pbs-sync-to-synology.timer | grep pbs-sync

echo -e "\n${GREEN}=== Configuration Update Complete ===${NC}\n"
echo "Summary of changes:"
echo "  Old: synology:/volume1/pbs-backup/"
echo "  New: synology:/volume1/backup-proxmox-backup-server/"
echo
echo "Next steps:"
echo "  1. Files are already in the new share location (you moved them)"
echo "  2. Next rsync will run: Sunday at 4:00 AM"
echo "  3. Or run manually: systemctl start pbs-sync-to-synology.service"
echo
echo -e "${YELLOW}Backup file saved: $BACKUP_FILE${NC}"
