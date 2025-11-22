# SSH Configuration Documentation
**Last Updated:** October 19, 2025
**Status:** Verified against live infrastructure

## Unified SSH Key

- **Key File**: `id_ed25519_unified` (ED25519)
- **Fingerprint**: 256 SHA256:2Oa0aH7dI5P+5H7wHTn5gsKWfHUw2oM5POWsBgP7AH8
- **Public Key**: `id_ed25519_unified.pub`
- **PuTTY Format**: `id_ed25519_unified.ppk`
- **Location**: `~/.ssh/`

## Active SSH Hosts (Online & Verified)

### External Services
- **github.com**
  - HostName: github.com
  - User: git
  - Key: id_ed25519_unified
  - Note: Uses Windows-specific IdentityAgent pipe

### Network Infrastructure
- **router** (192.168.1.1)
  - Hostname: unifi-ucg-fiber-router
  - User: root
  - Key: id_ed25519_unified
  - Description: Unifi UCG Fiber Gateway Router

- **switch** (192.168.1.2)
  - Hostname: unifi-usw-pro-xg-24-switch
  - User: follett
  - Key: id_ed25519_unified
  - Description: Unifi USW Pro XG-24 Switch (26 ports)

- **pdu** (192.168.1.3)
  - Hostname: unifi-usp-pdu-pro
  - User: follett
  - Key: id_ed25519_unified
  - Description: Unifi Power Distribution Pro

### Proxmox Infrastructure
- **intel-1250p** (192.168.1.40)
  - Hostname: intel-1250p-proxmox-host
  - User: root
  - Key: id_ed25519_unified
  - Description: Primary Proxmox VE Host (Intel NUC 1250P)

### LXC Containers
- **docker** (192.168.1.50)
  - Hostname: pve-docker-lxc
  - User: root
  - Key: id_ed25519_unified
  - Description: Docker Services Container

- **immich** (192.168.1.51)
  - Hostname: pve-immich-lxc
  - User: root
  - Key: id_ed25519_unified
  - Description: Immich Photo Management System

- **pbs** (192.168.1.52)
  - Hostname: pve-proxmox-backup-server-lxc
  - User: root
  - Key: id_ed25519_unified
  - Description: Proxmox Backup Server

- **syncthing** (192.168.1.53)
  - Hostname: pve-syncthing-lxc
  - User: root
  - Key: id_ed25519_unified
  - Description: Syncthing File Sync

- **tailscale** (192.168.1.54)
  - Hostname: pve-tailscale-lxc
  - User: root
  - Key: id_ed25519_unified
  - Description: Tailscale VPN (Subnet Router + Exit Node)

## SSH Configuration File

**Location**: `~/.ssh/config`

The configuration includes:
- All host entries listed above in IP order
- Unified key for all connections
- ServerAliveInterval: 60 seconds
- ServerAliveCountMax: 3
- IdentitiesOnly: yes (security best practice)
- AddKeysToAgent: yes (convenience)

## Quick SSH Commands

```bash
# Connect to infrastructure
ssh router
ssh switch
ssh pdu
ssh intel-1250p

# Connect to containers
ssh docker
ssh immich
ssh pbs
ssh syncthing
ssh tailscale

# GitHub access
ssh -T git@github.com
```

## Offline/Decommissioned Hosts

The following hosts were previously configured but are currently offline. SSH entries have been removed from active config:

- synology (192.168.1.10)
- intel-n6005 (192.168.1.41)
- karakeep (192.168.1.55) - Removed October 19, 2025
- iventoy (192.168.1.56)
- wireguard (192.168.1.57) - Replaced by Tailscale
- adguard (192.168.1.58)
- hp-eth, hp-wifi (192.168.1.103-104)
- msi-eth, msi-wifi (192.168.1.105-106)
- alienware-eth, alienware-wifi (192.168.1.107-108)

## Default SSH Settings

All hosts inherit these default settings:
- IdentityFile: ~/.ssh/id_ed25519_unified
- AddKeysToAgent: yes
- ServerAliveInterval: 60
- ServerAliveCountMax: 3
- IdentitiesOnly: yes
