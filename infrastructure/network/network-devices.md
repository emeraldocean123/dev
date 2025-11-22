# Network Device Inventory
**Last Verified:** October 19, 2025
**Method:** SSH connectivity test + hostname verification + 3-tier backup infrastructure audit + complete system health check

## Network Overview

- **Network Range**: 192.168.1.0/24
- **Gateway Router**: Unifi UCG Fiber (192.168.1.1)
- **Core Switch**: Unifi USW Pro XG-24 (192.168.1.2) - 26 ports
- **Total Online Devices**: 14 (13 via SSH + 1 workstation)
- **Offline/Decommissioned**: Multiple (moved to bottom)

## Online Infrastructure (Verified)

### Network Equipment

| IP | Hostname | MAC Address | Description | SSH Alias |
|----|----------|-------------|-------------|-----------|
| 192.168.1.1 | unifi-ucg-fiber-router | aa:bb:cc:dd:ee:01 | Unifi UCG Fiber Gateway Router | router |
| 192.168.1.2 | unifi-usw-pro-xg-24-switch | aa:bb:cc:dd:ee:02 | Unifi USW Pro XG-24 26-Port Switch | switch |
| 192.168.1.3 | unifi-usp-pdu-pro | aa:bb:cc:dd:ee:03 | Unifi Power Distribution Pro | pdu |
| 192.168.1.4 | glkvm-comet-rm1pe-kvm | aa:bb:cc:dd:ee:04 | GL.iNet Comet RM1-PE KVM over IP | kvm |

**KVM Details:**
- **Model**: GL.iNet Comet RM1-PE (PiKVM)
- **Platform**: Rockchip RV1126BP (Buildroot 2024.02)
- **Memory**: 1GB RAM, 27GB eMMC storage
- **Features**: Remote keyboard/mouse, video streaming (WebRTC/H.264), virtual media mounting
- **Web Interface**: https://192.168.1.4
- **Tailscale**: 100.69.134.31 (v1.88.3, built-in, advertising subnet 192.168.1.0/24 + exit node)
- **Purpose**: Remote out-of-band management for servers and infrastructure devices
- **Hostname**: glkvm-comet-rm1pe-kvm (configured via /etc/hostname, persistent across reboots)

### Proxmox Infrastructure

| IP | Hostname | MAC Address | Description | SSH Alias |
|----|----------|-------------|-------------|-----------|
| 192.168.1.40 | intel-1250p-proxmox-host | aa:bb:cc:dd:ee:10 | Intel 1250P - Primary NAS (4TB NVMe, ZFS) | intel-1250p |
| 192.168.1.41 | intel-n6005-proxmox-host | aa:bb:cc:dd:ee:11 | Intel N6005 - Backup Server (2×4TB Mirror, ZFS) | intel-n6005 |

### LXC Containers (Proxmox)

| IP | Hostname | MAC Address | Description | SSH Alias | Container ID | Host |
|----|----------|-------------|-------------|-----------|--------------|------|
| 192.168.1.50 | pve-docker-lxc | aa:bb:cc:dd:ee:20 | Docker Services Container (Portainer) | docker | LXC 1000 | intel-1250p |
| 192.168.1.51 | pve-immich-lxc | aa:bb:cc:dd:ee:21 | Immich Photo Management (Hardware Transcoding) | immich | LXC 1001 | intel-1250p |
| 192.168.1.52 | pve-proxmox-backup-server-1250p-lxc | aa:bb:cc:dd:ee:22 | Proxmox Backup Server | pbs, pbs-1250p | LXC 1002 | intel-1250p |
| 192.168.1.53 | pve-syncthing-lxc | aa:bb:cc:dd:ee:23 | Syncthing File Sync | syncthing | LXC 1003 | intel-1250p |
| 192.168.1.54 | pve-tailscale-lxc | aa:bb:cc:dd:ee:24 | Tailscale VPN (Subnet Router + Exit Node) | tailscale | LXC 1004 | intel-1250p |

### Storage (Network Attached)

| IP | Hostname | MAC Address | Description | SSH Alias | Role |
|----|----------|-------------|-------------|-----------|------|
| 192.168.1.10 | synology-1520-nas | aa:bb:cc:dd:ee:30 | Synology DS1520+ NAS (12.8TB available) | synology | Layer 3 Backup - Auto-detect, rsync, auto-shutdown |

**Synology Details:**
- **Model**: Synology DS1520+ (5-bay NAS)
- **Storage**: 371GB used for PBS backups, 12.8TB total available
- **Purpose**: Layer 3 tertiary backup for 3-tier infrastructure
- **Power Management**: On-demand - manually powered on, auto-shutdown after backup
- **Service**: synology-auto-backup.service on intel-1250p monitors and triggers rsync
- **Documentation**: See synology-auto-backup.md for complete automation details

## Offline / Decommissioned Devices

The following devices are configured but currently offline. They may be decommissioned or temporarily powered down.

### LXC Containers (Offline)

| IP | Device | MAC Address | Last Known Description |
|----|--------|-------------|------------------------|
| 192.168.1.55 | pve-karakeep-lxc | aa:bb:cc:dd:ee:40 | Karakeep Self-Hosted Note Taking (Destroyed October 19, 2025) |
| 192.168.1.56 | pve-adguard-lxc | aa:bb:cc:dd:ee:41 | AdGuard DNS Filtering |
| 192.168.1.57 | pve-iventoy-lxc | aa:bb:cc:dd:ee:42 | iVentoy PXE Boot Container |
| 192.168.1.58 | pve-wireguard-lxc | aa:bb:cc:dd:ee:43 | WireGuard VPN Container (Replaced by Tailscale) |
| 192.168.1.59 | - | - | Available / Unassigned |
| 192.168.1.70 | pve-proxmox-backup-server-n6005-lxc | aa:bb:cc:dd:ee:44 | Proxmox Backup Server (Destroyed October 13, 2025) |

### Workstations (Online)

| IP | Device | MAC Address | Description |
|----|--------|-------------|-------------|
| 192.168.1.109 | alienware-18-area51-aa18250 | aa:bb:cc:dd:ee:50 | Alienware 18 Area-51 via CalDigit TS5Plus Dock |

### Workstations (Offline)

| IP | Device | MAC Address | Last Known Description |
|----|--------|-------------|------------------------|
| 192.168.1.103 | hp-dv9500-eth | aa:bb:cc:dd:ee:51 | HP Pavilion Laptop (Ethernet) |
| 192.168.1.104 | hp-dv9500-wifi | aa:bb:cc:dd:ee:52 | HP Pavilion Laptop (WiFi) |
| 192.168.1.105 | msi-ge75-eth | aa:bb:cc:dd:ee:53 | MSI GE75 Raider (Ethernet) |
| 192.168.1.106 | msi-ge75-wifi | aa:bb:cc:dd:ee:54 | MSI GE75 Raider (WiFi) |
| 192.168.1.107 | alienware-18-eth | aa:bb:cc:dd:ee:55 | Alienware 18 Area-51 (Ethernet) |
| 192.168.1.108 | alienware-18-wifi | aa:bb:cc:dd:ee:56 | Alienware 18 Area-51 (WiFi) |

### Other Devices (Previously Documented, Status Unknown)

| IP | Device | MAC Address | Last Known Description |
|----|--------|-------------|------------------------|
| 192.168.1.20 | reolink-nvr | aa:bb:cc:dd:ee:60 | Reolink NVR Security System |
| 192.168.1.21 | epson-et-3830 | aa:bb:cc:dd:ee:61 | Epson ET-3830 Printer |

## VPN Access

**Dual VPN Setup for Redundancy:**

### Primary VPN: WireGuard on UCG Fiber (Always Available)
- **Endpoint:** emeraldlake.synology.me:51820
- **VPN Subnet:** 192.168.3.0/24
- **Purpose:** Critical always-on access, works even when Proxmox hosts are offline
- **Client:** Joseph (192.168.3.2)

### Secondary VPN: Tailscale on LXC 1004 (Convenience)
- **Tailscale IP:** 100.67.192.61
- **Features:** Subnet router (192.168.1.0/24) + Exit node
- **Purpose:** Easy mesh networking, mobile access, zero-config setup
- **Status:** Online when intel-1250p is running

**See vpn-configuration.md for complete VPN documentation**

## Notes

### Infrastructure Overview
- Network has been significantly reorganized since last documentation
- Many containers and services appear to have been migrated or decommissioned
- Current infrastructure is minimal and focused (router, switch, pdu, KVM, 2 proxmox hosts, 4 active LXC containers, 1 NAS)
- Remote access: Dual VPN setup provides redundancy (WireGuard always-on, Tailscale for convenience)

### 3-Tier Backup Architecture
Complete automated backup infrastructure implemented October 13, 2025:

**Layer 1: Primary Backup (On-Host)**
- Host: intel-1250p (192.168.1.40)
- Service: Proxmox Backup Server (PBS) - LXC 1002 (192.168.1.52)
- Storage: ZFS dataset rpool/intel-1250p-proxmox-backup-server (374GB)
- Schedule: Daily at 2:00 AM (automated via PBS scheduler)
- Backup type: Zero-downtime LXC snapshots
- Containers backed up: All 5 LXC containers (1000-1004)

**Layer 2: Off-Host Replication (RTC Automated)**
- Host: intel-n6005 (192.168.1.41)
- Storage: ZFS dataset rpool/intel-1250p-proxmox-backup-server (375GB replicated)
- Method: ZFS send/receive (block-level incremental)
- Schedule: RTC wake at 2:50 AM, replication at 3:00 AM, auto-shutdown at ~3:05 AM
- Power management: Hardware RTC alarm (BIOS-level), no network/software dependency
- Replication duration: Typically 30-60 seconds
- Script: /root/sh/zfs-replicate-pbs.sh (automated via cron)
- Status: ✅ Fully operational - tested October 14, 2025

**Layer 3: Tertiary Backup (Auto on Power-On)**
- Host: Synology DS1520+ NAS (192.168.1.10)
- Storage: /volume1/backup-proxmox-backup-server (371GB used, 12.8TB available)
- Method: rsync via NFS mount (file-level synchronization)
- Trigger: Auto-detect when Synology powers on (via systemd service on intel-1250p)
- Workflow: Detection (~60s) → rsync → verify → auto-shutdown
- Service: synology-auto-backup.service on intel-1250p
- Cooldown: 1 hour between syncs (prevents excessive runs)
- Power management: On-demand - manually powered on, auto-shutdown after backup complete

### Storage Details
- All PBS backups stored on host ZFS dataset via bind mount (not in container rootfs)
- PBS container rootfs usage: ~680MB (application only)
- Total backup data: ~400GB (5 LXC containers)
- Data replicated to N6005 for off-host redundancy
- Final copy synced to Synology for cold storage/disaster recovery

### Automation Components
- PBS scheduled backups (daily 2 AM)
- ZFS auto-snapshots (hourly, daily, weekly retention)
- RTC wake/sleep automation for N6005 (systemd service)
- Synology auto-detection and sync (systemd service)
- All automation scripts in /root/sh/ on intel-1250p

### Documentation References
- **backup-infrastructure-overview.md** - Complete 3-tier architecture and workflows
- **pbs-backup-config.md** - PBS configuration and troubleshooting
- **synology-auto-backup.md** - Synology automation details
- **iscsi-analysis.md** - iSCSI investigation and ZFS replication implementation
- **vpn-configuration.md** - VPN setup and configuration
- Consider removing offline device entries if permanently decommissioned
