#!/bin/bash
#
# SSH Key Copy Script
# Script to copy unified SSH key and add to host
#
# DEPLOYMENT:
#   Device: intel-1250p-proxmox-host (192.168.1.40) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/ssh-copy-key.sh
#
#   Device: intel-n6005-proxmox-host (192.168.1.41) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/ssh-copy-key.sh
#
#   Device: pve-proxmox-backup-server-1250p-lxc (192.168.1.52) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/ssh-copy-key.sh
#
#   Backup: ~/Documents/dev/sh/ssh-copy-key.sh (Windows)
#
# USAGE:
#   ./ssh-copy-key.sh <source_host> <target_host>
#   Example: ./ssh-copy-key.sh user@windows-host root@192.168.1.50 # NO-LINT: IP-ALLOW (Documentation)

if [ $# -ne 2 ]; then
  echo "Usage: $0 <source_host> <target_host>"
  echo "Example: $0 user@windows-host root@192.168.1.50" # NO-LINT: IP-ALLOW (Documentation)
  exit 1
fi

SOURCE="$1"
TARGET="$2"
KEY_FILE="$HOME/.ssh/id_ed25519_unified.pub"

# Copy the key from source
scp "$SOURCE:~/.ssh/id_ed25519_unified.pub" "$KEY_FILE"

if [ ! -f "$KEY_FILE" ]; then
  echo "Failed to copy key file"
  exit 1
fi

# Add the key to target
ssh-copy-id -i "$KEY_FILE" "$TARGET"
