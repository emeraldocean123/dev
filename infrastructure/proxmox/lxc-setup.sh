#!/bin/bash
#
# LXC Container Setup Script
# Complete LXC container setup with flexible command-line options
#
# DEPLOYMENT:
#   Device: intel-1250p-proxmox-host (192.168.1.40) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-setup.sh
#
#   Device: intel-n6005-proxmox-host (192.168.1.41) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-setup.sh
#
#   Device: pve-proxmox-backup-server-1250p-lxc (192.168.1.52) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-setup.sh
#
#   Backup: ~/Documents/dev/sh/lxc-setup.sh (Windows)
#
# USAGE:
#   ./lxc-setup.sh <container_id> [options]

set -e

# Default values
COPY_BASHRC=true
RUN_UPGRADE=true
SOURCE_VERSION="bookworm"
TARGET_VERSION="trixie"
PACKAGES="fastfetch"
HOST_BASHRC="/root/.bashrc"
LXC_BASHRC="/root/.bashrc"
SCRIPT_DIR="$HOME/sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
    cat <<EOF
Usage: $0 <container_id> [options]

Setup and configure LXC containers with various options.

Required:
    <container_id>              LXC container ID (e.g., 100, 101)

Options:
    --skip-bashrc               Don't copy .bashrc from host to LXC
    --skip-upgrade              Don't run Debian version upgrade
    --packages "pkg1 pkg2"      Packages to install (default: fastfetch)
    --no-packages               Don't install any packages
    --source "version"          Source Debian version (default: bookworm)
    --target "version"          Target Debian version (default: trixie)
    --bashrc-path "path"        Custom path to .bashrc on host (default: /root/.bashrc)
    --help                      Show this help message

Examples:
    # Basic setup (copy bashrc, upgrade, install fastfetch)
    $0 100

    # Setup without upgrade
    $0 101 --skip-upgrade

    # Setup with custom packages
    $0 102 --packages "htop tmux vim"

    # Setup with specific Debian versions
    $0 103 --source bullseye --target bookworm

    # Only install packages (skip bashrc and upgrade)
    $0 104 --skip-bashrc --skip-upgrade --packages "curl wget"

EOF
}

# Parse arguments
if [ $# -eq 0 ]; then
    print_error "No container ID provided"
    show_usage
    exit 1
fi

CTID=$1
shift

# Validate container ID is a number
if ! [[ "$CTID" =~ ^[0-9]+$ ]]; then
    print_error "Container ID must be a number"
    exit 1
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-bashrc)
            COPY_BASHRC=false
            shift
            ;;
        --skip-upgrade)
            RUN_UPGRADE=false
            shift
            ;;
        --packages)
            PACKAGES="$2"
            shift 2
            ;;
        --no-packages)
            PACKAGES=""
            shift
            ;;
        --source)
            SOURCE_VERSION="$2"
            shift 2
            ;;
        --target)
            TARGET_VERSION="$2"
            shift 2
            ;;
        --bashrc-path)
            HOST_BASHRC="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if container exists
if ! pct status "$CTID" &>/dev/null; then
    print_error "Container $CTID does not exist"
    exit 1
fi

# Check if container is running
if ! pct status "$CTID" | grep -q "running"; then
    print_error "Container $CTID is not running"
    exit 1
fi

print_info "Setting up LXC container $CTID..."
echo ""

# Backup and copy .bashrc
if [ "$COPY_BASHRC" = true ]; then
    print_info "Backing up and copying .bashrc..."

    if [ ! -f "$HOST_BASHRC" ]; then
        print_warn "Host .bashrc not found at $HOST_BASHRC, skipping..."
    else
        # Backup existing .bashrc in LXC
        pct exec "$CTID" -- bash -c "if [ -f $LXC_BASHRC ]; then cp $LXC_BASHRC ${LXC_BASHRC}.bak; echo 'Backup created'; fi"

        # Copy host .bashrc to LXC
        pct push "$CTID" "$HOST_BASHRC" $LXC_BASHRC
        print_info ".bashrc copied successfully"
    fi
    echo ""
fi

# Run Debian upgrade
if [ "$RUN_UPGRADE" = true ]; then
    print_info "Running Debian upgrade ($SOURCE_VERSION -> $TARGET_VERSION)..."

    if [ ! -f "$SCRIPT_DIR/upgrade-debian.sh" ]; then
        print_error "upgrade-debian.sh not found in $SCRIPT_DIR"
        exit 1
    fi

    # Copy upgrade script to LXC
    pct push "$CTID" "$SCRIPT_DIR/upgrade-debian.sh" /tmp/upgrade-debian.sh

    # Run upgrade script
    pct exec "$CTID" -- bash /tmp/upgrade-debian.sh "$SOURCE_VERSION" "$TARGET_VERSION"

    # Cleanup
    pct exec "$CTID" -- rm /tmp/upgrade-debian.sh

    print_info "Debian upgrade complete"
    echo ""
fi

# Install packages
if [ -n "$PACKAGES" ]; then
    print_info "Installing packages: $PACKAGES"

    pct exec "$CTID" -- bash -c "export DEBIAN_FRONTEND=noninteractive && apt update -y && apt install -y $PACKAGES"

    print_info "Packages installed successfully"
    echo ""
fi

print_info "LXC container $CTID setup complete!"
echo ""
print_info "Summary:"
echo "  - Container ID: $CTID"
echo "  - Bashrc copied: $COPY_BASHRC"
echo "  - Upgrade performed: $RUN_UPGRADE"
[ "$RUN_UPGRADE" = true ] && echo "  - Versions: $SOURCE_VERSION -> $TARGET_VERSION"
[ -n "$PACKAGES" ] && echo "  - Packages installed: $PACKAGES"
