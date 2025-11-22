#!/bin/bash
#
# LXC Utility Functions
# Common LXC operations as individual commands
#
# DEPLOYMENT:
#   Device: intel-1250p-proxmox-host (192.168.1.40) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-utils.sh
#
#   Device: intel-n6005-proxmox-host (192.168.1.41) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-utils.sh
#
#   Device: pve-proxmox-backup-server-1250p-lxc (192.168.1.52) # NO-LINT: IP-ALLOW (Documentation)
#   Path:   /root/sh/lxc-utils.sh
#
#   Backup: ~/Documents/dev/sh/lxc-utils.sh (Windows)
#
# USAGE:
#   ./lxc-utils.sh <action> <container_id> [args...]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    cat <<EOF
Usage: $0 <action> <container_id> [args...]

Common LXC container operations utility.

Actions:
    install <ctid> <packages>    Install packages in LXC
    upgrade <ctid> [src] [tgt]   Upgrade Debian (default: bookworm->trixie)
    copy-bashrc <ctid> [path]    Copy .bashrc to LXC (default: /root/.bashrc)
    exec <ctid> <command>        Execute command in LXC
    info <ctid>                  Show container information
    list                         List all LXC containers

Examples:
    # Install packages
    $0 install 100 "htop vim tmux"

    # Upgrade Debian
    $0 upgrade 100
    $0 upgrade 101 bullseye bookworm

    # Copy bashrc
    $0 copy-bashrc 100

    # Execute command
    $0 exec 100 "uname -a"

    # Show container info
    $0 info 100

    # List all containers
    $0 list

EOF
}

# Validate container exists and is running
validate_container() {
    local ctid=$1

    if ! pct status "$ctid" &>/dev/null; then
        print_error "Container $ctid does not exist"
        exit 1
    fi

    if ! pct status "$ctid" | grep -q "running"; then
        print_error "Container $ctid is not running"
        exit 1
    fi
}

# Install packages
action_install() {
    local ctid=$1
    shift
    local packages="$*"

    if [ -z "$packages" ]; then
        print_error "No packages specified"
        exit 1
    fi

    validate_container "$ctid"

    print_info "Installing packages in container $ctid: $packages"
    pct exec "$ctid" -- bash -c "apt update -y && apt install -y $packages"
    print_info "Installation complete"
}

# Upgrade Debian
action_upgrade() {
    local ctid=$1
    local source="${2:-bookworm}"
    local target="${3:-trixie}"

    validate_container "$ctid"

    print_info "Upgrading container $ctid from $source to $target..."

    # Copy upgrade script to LXC
    pct push "$ctid" "$HOME/sh/upgrade-debian.sh" /tmp/upgrade-debian.sh

    # Run upgrade
    pct exec "$ctid" -- bash /tmp/upgrade-debian.sh "$source" "$target"

    # Cleanup
    pct exec "$ctid" -- rm /tmp/upgrade-debian.sh

    print_info "Upgrade complete"
}

# Copy bashrc
action_copy_bashrc() {
    local ctid=$1
    local host_bashrc="${2:-/root/.bashrc}"
    local lxc_bashrc="/root/.bashrc"

    validate_container "$ctid"

    if [ ! -f "$host_bashrc" ]; then
        print_error "Host .bashrc not found at $host_bashrc"
        exit 1
    fi

    print_info "Copying .bashrc to container $ctid..."

    # Backup existing
    pct exec "$ctid" -- bash -c "if [ -f $lxc_bashrc ]; then cp $lxc_bashrc ${lxc_bashrc}.bak; fi"

    # Copy new
    pct push "$ctid" "$host_bashrc" $lxc_bashrc

    print_info ".bashrc copied successfully"
}

# Execute command
action_exec() {
    local ctid=$1
    shift
    local command="$*"

    if [ -z "$command" ]; then
        print_error "No command specified"
        exit 1
    fi

    validate_container "$ctid"

    print_info "Executing in container $ctid: $command"
    pct exec "$ctid" -- bash -c "$command"
}

# Show container info
action_info() {
    local ctid=$1

    if ! pct status "$ctid" &>/dev/null; then
        print_error "Container $ctid does not exist"
        exit 1
    fi

    echo -e "${BLUE}Container $ctid Information:${NC}"
    echo ""

    echo "Status:"
    pct status "$ctid"
    echo ""

    echo "Configuration:"
    pct config "$ctid" | head -20
    echo ""

    if pct status "$ctid" | grep -q "running"; then
        echo "Hostname:"
        pct exec "$ctid" -- hostname
        echo ""

        echo "OS Info:"
        pct exec "$ctid" -- cat /etc/os-release | grep -E "PRETTY_NAME|VERSION="
    fi
}

# List all containers
action_list() {
    print_info "LXC Containers:"
    echo ""
    pct list
}

# Main
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

ACTION=$1
shift

case $ACTION in
    install)
        if [ $# -lt 2 ]; then
            print_error "install requires <container_id> <packages>"
            exit 1
        fi
        action_install "$@"
        ;;
    upgrade)
        if [ $# -lt 1 ]; then
            print_error "upgrade requires <container_id> [source] [target]"
            exit 1
        fi
        action_upgrade "$@"
        ;;
    copy-bashrc)
        if [ $# -lt 1 ]; then
            print_error "copy-bashrc requires <container_id> [bashrc_path]"
            exit 1
        fi
        action_copy_bashrc "$@"
        ;;
    exec)
        if [ $# -lt 2 ]; then
            print_error "exec requires <container_id> <command>"
            exit 1
        fi
        action_exec "$@"
        ;;
    info)
        if [ $# -lt 1 ]; then
            print_error "info requires <container_id>"
            exit 1
        fi
        action_info "$@"
        ;;
    list)
        action_list
        ;;
    --help|-h)
        show_usage
        exit 0
        ;;
    *)
        print_error "Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac
