# Proxmox Infrastructure Scripts

Automation scripts for Proxmox Virtual Environment (PVE) and LXC container management.

## 📜 Scripts

### `lxc-setup.sh`
**Purpose:** Bootstraps a new LXC container with standard configurations.

**Features:**
- Copies `.bashrc` from host to container for shell consistency
- Runs `upgrade-debian.sh` automatically
- Installs default packages (e.g., `fastfetch`)

**Usage:**
```bash
./lxc-setup.sh <container_id> [options]

# Examples:
./lxc-setup.sh 105                                    # Basic setup
./lxc-setup.sh 105 --skip-upgrade                     # Skip OS upgrade
./lxc-setup.sh 105 --packages "curl git htop"         # Custom packages
```

### `lxc-utils.sh`
**Purpose:** Helper functions and utilities for individual LXC operations.

**Features:**
- Install packages in existing containers
- Execute commands in containers
- Show container info and list all containers

**Usage:**
```bash
./lxc-utils.sh install <container_id> "package1 package2"
./lxc-utils.sh exec <container_id> "command"
./lxc-utils.sh info <container_id>
./lxc-utils.sh list
```

### `upgrade-debian.sh`
**Purpose:** Performs a non-interactive OS upgrade (e.g., Bookworm → Trixie).

**Safety:**
- Backs up `/etc/apt/sources.list` before modification
- Uses non-interactive mode with safe defaults
- Handles broken packages automatically

**Usage:**
```bash
./upgrade-debian.sh [source_distro] [target_distro]

# Examples:
./upgrade-debian.sh                    # Default: bookworm → trixie
./upgrade-debian.sh bullseye bookworm  # Custom versions
```

### `proxmox-setup-repos.sh`
**Purpose:** Configure Proxmox repositories (detects PVE or PBS automatically).

**Features:**
- Disables enterprise repos
- Adds no-subscription repos
- Removes subscription nag popup
- Backs up configuration before changes

**Usage:**
```bash
./proxmox-setup-repos.sh
```

### `proxmox-restore-nag.sh`
**Purpose:** Restore subscription nag if needed (rarely used).

### `ssh-copy-key.sh`
**Purpose:** Copy unified SSH key between hosts.

**Usage:**
```bash
./ssh-copy-key.sh <target_host>
```

## ⚠️ Critical: Line Ending Requirements

**ALL scripts in this directory MUST use LF (Linux) line endings.**

Windows line endings (CRLF) will cause `\r: command not found` errors when executed on Linux.

**Verification:**
```powershell
# From Windows dev environment:
cd ~/Documents/git/dev
./documentation/maintenance/lint-repository.ps1
```

**Auto-Fix:**
```powershell
./documentation/maintenance/fix-bash-line-endings.ps1
```

## 📦 Deployment

Scripts are maintained in Windows development environment (`~/Documents/git/dev/infrastructure/proxmox/`) and deployed to Proxmox hosts as needed.

**Target Location:** `/root/sh/` on Proxmox hosts

**Deployment Methods:**

### Method 1: Individual Script
```bash
# Copy single script
scp infrastructure/proxmox/lxc-setup.sh intel-1250p:/root/sh/
```

### Method 2: Bulk Deployment
```bash
# Copy all scripts
scp infrastructure/proxmox/*.sh intel-1250p:/root/sh/

# Make executable
ssh intel-1250p "chmod +x /root/sh/*.sh"
```

### Method 3: Selective Update
```bash
# Update only LXC-related scripts
scp infrastructure/proxmox/lxc-*.sh intel-1250p:/root/sh/
```

## 🚀 Common Workflows

### Fresh Proxmox Installation
```bash
ssh intel-1250p
cd /root/sh
./proxmox-setup-repos.sh
```

### New LXC Container Setup
```bash
# Basic setup (copy bashrc, upgrade, install fastfetch)
ssh intel-1250p
cd /root/sh
./lxc-setup.sh 105
```

### Custom LXC Setup
```bash
# Skip upgrade, install specific packages
./lxc-setup.sh 106 --skip-upgrade --packages "htop vim tmux curl"
```

### One-off Operations
```bash
# Install packages in existing container
./lxc-utils.sh install 105 "package1 package2"

# Execute command in container
./lxc-utils.sh exec 105 "df -h"

# Show container info
./lxc-utils.sh info 105
```

## 🔍 Script Features

All scripts include:
- ✅ Colored output (green/yellow/red for info/warn/error)
- ✅ Error handling and validation
- ✅ Container existence and status checks
- ✅ Built-in help with `--help` flag
- ✅ Comprehensive examples

## 🔗 Related Documentation

- Backup automation: `../backup/`
- Network configuration: `../network/`
- Maintenance tools: `../../documentation/maintenance/`
- SSH configuration: `../../network/ssh-config.md`
