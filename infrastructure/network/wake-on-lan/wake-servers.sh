#!/bin/bash
# Wake-on-LAN Script for Network Infrastructure
# Config-aware: Loads MAC addresses from homelab.env or servers.env

# 1. Try Loading Deployed Config (Proxmox/Linux Env)
if [ -f "$(dirname "$0")/../config/homelab.env" ]; then
    source "$(dirname "$0")/../config/homelab.env"
elif [ -f "$(dirname "$0")/config/homelab.env" ]; then
    # Case where script is deployed flat in /root/sh/ with config/ subdir
    source "$(dirname "$0")/config/homelab.env"
# 2. Try Loading Local Dev Config
elif [ -f "$(dirname "$0")/../config/servers.env" ]; then
    source "$(dirname "$0")/../config/servers.env"
fi

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to send WOL magic packet
send_wol() {
    local mac="$1"
    local server="$2"

    if [ -z "$mac" ]; then
        echo -e "${YELLOW}Skipping $server: MAC address not defined in config.${NC}"
        return
    fi

    echo -e "${CYAN}Sending WOL magic packet to $server ($mac)...${NC}"

    # Platform detection logic (Windows/Linux)
    if command -v wakeonlan &> /dev/null; then
        wakeonlan "$mac"
    elif command -v etherwake &> /dev/null; then
        etherwake "$mac"
    else
        # Fallback for Windows/Git Bash using PowerShell
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$WINDIR" ]]; then
             powershell.exe -NoProfile -Command "
                \$mac = '$mac' -replace '[:-]', ''
                \$packet = [byte[]](,0xFF * 6) + ([byte[]]@(0..5 | % { [Convert]::ToByte(\$mac.Substring(\$_*2, 2), 16) }) * 16)
                \$client = New-Object System.Net.Sockets.UdpClient
                \$client.Connect([System.Net.IPAddress]::Broadcast, 9)
                [void]\$client.Send(\$packet, \$packet.Length)
                \$client.Close()
            " > /dev/null
        fi
    fi
    echo -e "${GREEN}  Packet sent.${NC}"
}

# Main Logic
TARGET="${1:-all}"

# Use variables loaded from config (MAC_1250P, etc.)
case "$TARGET" in
    1250p)    send_wol "$MAC_1250P" "intel-1250p" ;;
    n6005)    send_wol "$MAC_N6005" "intel-n6005" ;;
    synology) send_wol "$MAC_SYNOLOGY" "Synology NAS" ;;
    proxmox)
        send_wol "$MAC_1250P" "intel-1250p"
        send_wol "$MAC_N6005" "intel-n6005"
        ;;
    all)
        send_wol "$MAC_1250P" "intel-1250p"
        send_wol "$MAC_N6005" "intel-n6005"
        send_wol "$MAC_SYNOLOGY" "Synology NAS"
        ;;
    *)
        echo "Usage: $0 [1250p|n6005|synology|proxmox|all]"
        echo "Note: Config file must be present for MAC addresses."
        exit 1
        ;;
esac
