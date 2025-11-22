#!/bin/bash
#
# Debian Version Upgrade Script
# Upgrade Debian to a newer version
#
# DEPLOYMENT:
#   Device: intel-1250p-proxmox-host (192.168.1.40)
#   Path:   /root/sh/upgrade-debian.sh
#
#   Device: intel-n6005-proxmox-host (192.168.1.41)
#   Path:   /root/sh/upgrade-debian.sh
#
#   Device: pve-proxmox-backup-server-1250p-lxc (192.168.1.52)
#   Path:   /root/sh/upgrade-debian.sh
#
#   Backup: ~/Documents/dev/sh/upgrade-debian.sh (Windows)
#
# USAGE:
#   ./upgrade-debian.sh [source_version] [target_version]
#   Example: ./upgrade-debian.sh bookworm trixie
#   Defaults: bookworm -> trixie

SOURCE_VERSION="${1:-bookworm}"
TARGET_VERSION="${2:-trixie}"

echo "Upgrading Debian from $SOURCE_VERSION to $TARGET_VERSION..."

# Set environment variables for non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Update sources.list
echo "Updating /etc/apt/sources.list..."
sed -i "s/$SOURCE_VERSION/$TARGET_VERSION/g" /etc/apt/sources.list

# Perform upgrade
echo "Running system upgrade..."
apt update -y && \
apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
apt --fix-broken install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
apt autoremove -y && \
apt clean -y && \
apt autoclean -y

# Modernize sources
echo "Modernizing APT sources..."
echo "Y" | apt modernize-sources

echo "Upgrade from $SOURCE_VERSION to $TARGET_VERSION complete!"
