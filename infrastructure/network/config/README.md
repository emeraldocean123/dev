# Network Configuration Files

This directory contains configuration files for network infrastructure scripts.

## Files

### `servers.env` (Local Only - Not Committed)
Contains actual MAC addresses and IP addresses for your network devices.

**Setup:**
```bash
cp servers.env.example servers.env
# Edit servers.env with your specific MAC addresses
```

**Variables:**
- `MAC_1250P` - Intel 1250P Proxmox host MAC address
- `MAC_N6005` - Intel N6005 Proxmox backup host MAC address
- `MAC_SYNOLOGY` - Synology NAS MAC address
- `IP_*` - Optional IP addresses for reference

### `servers.env.example` (Template - Committed)
Template file showing the required format and variables. Copy this to create your local `servers.env`.

## Usage

Scripts in `../wake-on-lan/` automatically load `servers.env` if it exists, otherwise fall back to embedded default values.

## Security Note

The `servers.env` file is excluded from version control via `.gitignore` to prevent accidental exposure of your specific network configuration.
