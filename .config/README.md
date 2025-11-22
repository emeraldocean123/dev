# Homelab Configuration

**Purpose:** Centralized configuration system for all homelab scripts and automation tools.

**Created:** November 21, 2025
**Status:** Phase 5 Foundation - Externalized Configuration

## Overview

This directory contains the centralized configuration for the entire homelab infrastructure. By separating environment-specific data (IP addresses, MAC addresses, usernames, file paths) from code, the repository becomes:

- **Portable**: Share repository publicly without exposing personal infrastructure
- **Maintainable**: Update configuration in one place, all scripts automatically reflect changes
- **Secure**: Real settings are git-ignored, only templates are committed to GitHub

## Files

### `homelab.settings.json` (Git Ignored)

**Your real configuration file** containing actual infrastructure data:
- Network device IPs and MAC addresses
- Container IDs and IP assignments
- Local file paths (Windows-specific)
- SSH key locations
- Backup infrastructure details

**⚠️ NEVER commit this file to Git** - it contains sensitive infrastructure data.

### `homelab.settings.example.json` (Public Template)

Public template with dummy/placeholder values. Other users can:
1. Copy this file to `homelab.settings.json`
2. Replace placeholder values with their own infrastructure
3. Run scripts with their customized configuration

### `homelab.settings.schema.json` (Optional Future Enhancement)

JSON schema file for validation and IDE autocomplete support. Planned for Phase 5.1.

## Quick Start

### Initial Setup

If you're setting up this repository for the first time:

```powershell
# 1. Copy the example template
cd ~/Documents/git/dev/.config
cp homelab.settings.example.json homelab.settings.json

# 2. Edit with your real values
notepad homelab.settings.json

# 3. Verify it's git-ignored (should show no changes)
git status
```

### Configuration Structure

```json
{
    "Owner": "YourName",
    "Network": {
        "Subnet": "192.168.1.0/24",
        "Gateway": "192.168.1.1",
        "Hosts": {
            "Primary": {
                "Name": "proxmox-primary",
                "IP": "192.168.1.40",
                "User": "root",
                "Mac": "00:00:00:00:00:00",
                "Role": "Primary Proxmox VE host",
                "ScriptPath": "/root/sh/"
            },
            "Secondary": { ... },
            "NAS": { ... }
        },
        "Containers": {
            "Docker": { "ID": 1000, "IP": "192.168.1.50" },
            "Immich": { "ID": 1001, "IP": "192.168.1.51" },
            "PBS": { "ID": 1002, "IP": "192.168.1.52" }
        }
    },
    "Paths": {
        "DevRoot": "C:\\Users\\josep\\Documents\\git\\dev",
        "MylioCatalog": "D:\\Mylio\\Pictures",
        "ImmichLibrary": "D:\\Immich\\library",
        "MediaWorkspace": "D:\\Media Workspace"
    },
    "SSH": {
        "KeyFile": "~/.ssh/id_ed25519_unified",
        "ConfigFile": "~/.ssh/config"
    },
    "Backup": {
        "Layer1": {
            "Host": "intel-1250p",
            "Service": "PBS",
            "Schedule": "Daily 2:00 AM"
        },
        "Layer2": {
            "Host": "intel-n6005",
            "Method": "ZFS send/receive"
        },
        "Layer3": {
            "Host": "synology",
            "Method": "rsync via NFS"
        }
    }
}
```

## How Scripts Use Configuration

### PowerShell Scripts

Scripts load configuration into a global variable `$Global:HomelabConfig`:

```powershell
# Load centralized configuration
$configPath = Join-Path $PSScriptRoot ".config\homelab.settings.json"
if (-not (Test-Path $configPath)) {
    Write-Warning "Configuration not found. Using example template."
    $configPath = Join-Path $PSScriptRoot ".config\homelab.settings.example.json"
}
$Global:HomelabConfig = Get-Content $configPath | ConvertFrom-Json

# Access configuration values
$primaryIP = $Global:HomelabConfig.Network.Hosts.Primary.IP
$devRoot = $Global:HomelabConfig.Paths.DevRoot
```

### Bash Scripts (Future Enhancement)

Bash scripts on Proxmox hosts will use a lightweight config parser:

```bash
# Load configuration (planned for Phase 5.1)
source /root/sh/lib/load-config.sh
PRIMARY_IP=$(get_config "Network.Hosts.Primary.IP")
```

## Configuration Reference

### Network Section

| Field | Purpose | Example |
|-------|---------|---------|
| `Subnet` | Network range | `192.168.1.0/24` |
| `Gateway` | Router IP | `192.168.1.1` |
| `Hosts.Primary.IP` | Primary Proxmox host | `192.168.1.40` |
| `Hosts.Primary.Mac` | MAC for Wake-on-LAN | `00:00:00:00:00:00` |
| `Containers.*.ID` | LXC container ID | `1000` |
| `Containers.*.IP` | Container IP address | `192.168.1.50` |

### Paths Section

| Field | Purpose | Example |
|-------|---------|---------|
| `DevRoot` | Repository root | `C:\\Users\\josep\\Documents\\git\\dev` |
| `MylioCatalog` | Mylio photo library | `D:\\Mylio\\Pictures` |
| `ImmichLibrary` | Immich storage | `D:\\Immich\\library` |
| `MediaWorkspace` | Media processing workspace | `D:\\Media Workspace` |
| `ProxmoxScriptRoot` | Scripts on Proxmox host | `/root/sh/` |

### Backup Section

Defines the 3-tier backup architecture:

- **Layer 1**: Primary backup (PBS on primary host)
- **Layer 2**: Off-host replication (ZFS to secondary host)
- **Layer 3**: Cold storage (rsync to NAS)

## Security Notes

### Git Protection

The `.gitignore` file explicitly protects your real configuration:

```gitignore
# Configuration (protect real settings, allow templates)
.config/homelab.settings.json
infrastructure/network/config/servers.env
media/tools/**/configs/*.json
!media/tools/**/configs/*.example.json
!.config/homelab.settings.example.json
```

Notice the `!` negation pattern - this allows `.example.json` files to be committed while blocking the real settings.

### What Gets Committed

✅ **Public (committed to GitHub):**
- `homelab.settings.example.json` - Template with dummy data
- `README.md` - This documentation
- All scripts that reference `$Global:HomelabConfig`

❌ **Private (git-ignored):**
- `homelab.settings.json` - Your real infrastructure data
- Any `*.env` files with credentials
- Generated reports with system-specific data

### Verifying Protection

Always verify your real settings are protected before committing:

```powershell
# Check git status - should NOT show homelab.settings.json
git status

# Verify the file is ignored
git check-ignore .config/homelab.settings.json
# Output: .config/homelab.settings.json (means it's ignored ✓)

# See what would be committed
git add .config/
git status
# Should only show .example.json and README.md
```

## Migration Guide

### Updating Existing Scripts

Scripts currently using hardcoded values should be refactored to use the central configuration:

**Before:**
```powershell
$primaryHost = "192.168.1.40"
$devRoot = "C:\Users\josep\Documents\git\dev"
```

**After:**
```powershell
$primaryHost = $Global:HomelabConfig.Network.Hosts.Primary.IP
$devRoot = $Global:HomelabConfig.Paths.DevRoot
```

### Scripts Being Refactored

Phase 5 will update these scripts to use centralized configuration:

1. ✅ `homelab.ps1` - Global config loader (Phase 5.0)
2. 📋 `deploy-to-proxmox.ps1` - Deployment automation (Phase 5.1)
3. 📋 `generate-health-report.ps1` - Health monitoring (Phase 5.1)
4. 📋 Network management scripts in `infrastructure/network/scripts/` (Phase 5.2)
5. 📋 Backup scripts in `infrastructure/backup/` (Phase 5.2)

## Troubleshooting

### Configuration Not Found

If scripts can't find `homelab.settings.json`, they fall back to the example template:

```
WARNING: Configuration not found. Using example template.
```

**Solution:** Copy `homelab.settings.example.json` to `homelab.settings.json` and customize with your values.

### Invalid JSON Syntax

If configuration file has syntax errors:

```
ConvertFrom-Json: Invalid JSON primitive
```

**Solution:** Validate JSON syntax at https://jsonlint.com or use PowerShell:

```powershell
Get-Content .config/homelab.settings.json | ConvertFrom-Json
# If this succeeds, JSON is valid
```

### Git Accidentally Tracking Real Settings

If `homelab.settings.json` appears in `git status`:

```powershell
# Remove from staging area
git reset .config/homelab.settings.json

# Verify it's ignored
git check-ignore .config/homelab.settings.json
```

If git is tracking it despite `.gitignore`:

```powershell
# Remove from git index (keeps local file)
git rm --cached .config/homelab.settings.json
git commit -m "fix: remove sensitive config from tracking"
```

## Future Enhancements (Phase 5.1+)

### JSON Schema Validation

Add `homelab.settings.schema.json` for:
- IDE autocomplete support
- Configuration validation on load
- Documentation of all available fields

### Config Hot Reload

Support reloading configuration without restarting `homelab.ps1`:

```powershell
Reload-HomelabConfig  # Planned function
```

### Environment-Specific Configs

Support multiple environments:

```
.config/
├── homelab.settings.json           # Production
├── homelab.settings.dev.json       # Development
├── homelab.settings.example.json   # Template
```

### Bash Script Integration

Create lightweight bash config parser for Proxmox scripts:

```bash
# /root/sh/lib/load-config.sh
get_config() {
    jq -r "$1" < /root/sh/.config/homelab.settings.json
}
```

## Related Documentation

- `homelab.ps1` - Main menu system that loads this configuration
- `infrastructure/deployment/deploy-to-proxmox.ps1` - Deployment automation
- `documentation/reports/generate-health-report.ps1` - Health monitoring
- `infrastructure/network/network-devices.md` - Network inventory

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-21 | 1.0 | Initial configuration system (Phase 5 foundation) |

---

**Phase 5 Status:** Configuration infrastructure complete, script migration in progress.
