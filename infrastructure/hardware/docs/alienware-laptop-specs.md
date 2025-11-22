# Alienware 18 Area-51 AA18250 - System Specifications

Complete hardware and system specifications for the primary development workstation.

**Last Updated:** October 15, 2025
**Status:** Active - Primary Development Machine

---

## System Information

| Component | Details |
|-----------|---------|
| **Manufacturer** | Alienware (Dell) |
| **Model** | Alienware 18 Area-51 AA18250 |
| **System Family** | Alienware |
| **Serial Number** | CFT6BB4 |
| **System Type** | x64-based PC |
| **Hostname** | alienware-18-area51-aa18250-windows |

---

## Processor (CPU)

| Specification | Details |
|---------------|---------|
| **Model** | Intel Core Ultra 9 275HX |
| **Architecture** | x64 (64-bit) |
| **Physical Cores** | 24 |
| **Logical Processors** | 24 |
| **Base Clock Speed** | 2.7 GHz |
| **Max Turbo Speed** | 5.40 GHz |
| **Technology** | Intel Core Ultra (Arrow Lake-HX) |

---

## Memory (RAM)

| Specification | Details |
|---------------|---------|
| **Total Capacity** | 64 GB (63.46 GiB usable) |
| **Configuration** | 2 × 32 GB modules |
| **Memory Type** | DDR5 SODIMM |
| **Speed** | 6400 MT/s (DDR5-6400) |
| **Form Factor** | SODIMM (FormFactor: 12) |
| **Manufacturer** | Samsung (802C869D802C) |

---

## Graphics (GPU)

### GPU 1: Discrete Graphics (Primary)
| Specification | Details |
|---------------|---------|
| **Model** | NVIDIA GeForce RTX 5090 Laptop GPU |
| **VRAM** | 24 GB (23.49 GiB) |
| **Base Clock** | ~1.5 GHz |
| **Boost Clock** | 3.09 GHz |
| **Driver Version** | 32.0.15.8142 |
| **Architecture** | NVIDIA Blackwell |
| **Connected Display** | LG ULTRAGEAR (3440×1440 @ 144 Hz) |

### GPU 2: Integrated Graphics
| Specification | Details |
|---------------|---------|
| **Model** | Intel Graphics (Arc iGPU) |
| **Shared Memory** | 128 MB (2 GB addressable) |
| **Driver Version** | 32.0.101.6874 |
| **Connected Display** | Built-in display (2560×1600 @ 144 Hz) |

---

## Display

### Internal Display
| Specification | Details |
|---------------|---------|
| **Panel Model** | AUO96B1 |
| **Resolution** | 2560 × 1600 (16:10 aspect ratio) |
| **Refresh Rate** | 144 Hz |
| **Display Type** | Built-in laptop panel |
| **Scaling** | 1.5× (150%) |

### External Display (Primary)
| Specification | Details |
|---------------|---------|
| **Model** | LG ULTRAGEAR |
| **Resolution** | 3440 × 1440 (21:9 ultrawide) |
| **Refresh Rate** | 144 Hz |
| **Display Size** | 34 inches |
| **Connection** | Connected via NVIDIA RTX 5090 |

---

## Storage

### Internal Storage (NVMe SSDs)

#### Drive 1: Primary System Drive
| Specification | Details |
|---------------|---------|
| **Model** | Samsung SSD 9100 PRO |
| **Capacity** | 4 TB (4000 GB) |
| **Interface** | NVMe PCIe Gen5 |
| **Partitions** | C: (3.27 TiB formatted capacity) |
| **Usage** | Windows 11 Pro system drive - 206 GB used / 3.27 TiB (6%) |

#### Drive 2: Bulk Storage & Games
| Specification | Details |
|---------------|---------|
| **Model** | WD_BLACK SN850X |
| **Capacity** | 8 TB (8000 GB) |
| **Interface** | NVMe PCIe Gen4 |
| **Partitions** | D:, E: (7.28 TiB formatted capacity) |
| **Usage (D:)** | Bulk storage, games - 1.09 TiB used / 7.28 TiB (15%) |
| **Usage (E:)** | Additional partition - 384 MB used / 7.28 TiB (essentially empty) |

#### Drive 3: Available for Linux Installation
| Specification | Details |
|---------------|---------|
| **Model** | WD_BLACK SN850X |
| **Capacity** | 8 TB (8000 GB) |
| **Interface** | NVMe PCIe Gen4 |
| **Partitions** | F: (3.64 TiB formatted capacity) |
| **Usage** | 523.69 GB used / 3.64 TiB (14%) - Available for dual-boot Linux |
| **Notes** | Candidate for CachyOS/Omarchy installation |

### External Storage

#### External SSD
| Specification | Details |
|---------------|---------|
| **Model** | Samsung PSSD T9 |
| **Capacity** | 4 TB (4000 GB) |
| **Interface** | USB 3.2 Gen 2×2 (20 Gbps) |
| **Connection** | USB Type-C |
| **Type** | Portable External SSD |

**Total Storage Capacity:** ~24 TB (8TB + 4TB + 8TB internal + 4TB external)

---

## BIOS/Firmware

| Component | Details |
|-----------|---------|
| **Manufacturer** | Alienware |
| **BIOS Version** | 1.6.1 |
| **Release Date** | July 24, 2025 |
| **UEFI/Legacy** | UEFI |

### Boot Configuration
- **Quiet Boot**: Disabled (shows detailed boot messages)
- **Boot UX**: Disabled (text-based boot screen)
- **Secure Boot**: Enabled
- **Fast Boot**: Enabled

---

## Battery

| Specification | Details |
|---------------|---------|
| **Model** | DELL 6CK5K53S |
| **Device ID** | 307SMPDELL 6CK5K53S |
| **Battery Type** | Lithium-ion |
| **Status** | 100% charged (AC connected) |

---

## Network Connectivity

### Ethernet
| Specification | Details |
|---------------|---------|
| **Speed** | 10 Gigabit Ethernet |
| **IP Address** | 192.168.1.109/24 |
| **Network** | 192.168.1.0/24 (home network) |
| **Gateway** | 192.168.1.1 (Unifi UCG Fiber Router) |
| **Connection** | Connected to Unifi USW Pro XG-24 switch |

### Public IP
| Component | Details |
|-----------|---------|
| **Public IP** | 73.93.188.131 |
| **ISP** | Xfinity |
| **Location** | Napa, California, USA |

### Wireless
- Intel Wi-Fi 7 BE200 (expected, based on model)
- Wi-Fi 6E/7 support
- Bluetooth 5.4

---

## Operating System

| Component | Details |
|-----------|---------|
| **Operating System** | Microsoft Windows 11 Pro |
| **Version** | 10.0.26200 (25H2) |
| **Build Number** | 26200.6899 |
| **Architecture** | 64-bit (x64) |
| **Install Date** | July 31, 2025 |
| **Kernel** | WIN32_NT 10.0.26200 |

---

## Software Environment

### Shell Environments
- **PowerShell**: PowerShell 7 (primary shell)
  - Profile: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
  - Theme: Oh My Posh (jandedobbeleer)
  - Prompt: Winfetch on startup

- **Git Bash**: Bash 5.2.37 (secondary shell)
  - Profile: `~/.bashrc`
  - Theme: Oh My Posh
  - Prompt: Fastfetch on startup

- **WSL**: Debian (available)

### Window Manager
- **Desktop Environment**: Windows Desktop
- **Window Manager**: Desktop Window Manager 10.0.26100.6899
- **Theme**: Custom - Blue (System: Light, Apps: Light)
- **Terminal**: Windows Terminal
- **Font**: Segoe UI (12pt)

### Development Tools
- Git (with unified SSH key for GitHub)
- Node.js / npm
- Oh My Posh (prompt theming)
- Fastfetch / Winfetch (system information)

---

## Cooling & Power

### Thermal Management
- Alienware Cryo-tech cooling system
- Vapor chamber cooling
- Multiple heat pipes
- High-performance fans

### Power Supply
- 480W AC adapter (estimated based on RTX 5090 + Core Ultra 9 275HX)
- USB-C Power Delivery support

---

## Physical Specifications

| Specification | Details |
|---------------|---------|
| **Form Factor** | Gaming Laptop (18-inch) |
| **Display Size** | 18 inches (diagonal) |
| **Weight** | ~10-12 lbs (estimated) |
| **Chassis** | Alienware Legend 3.0 design |

---

## Performance Summary

### Key Highlights
- **CPU**: 24-core Intel Core Ultra 9 275HX (Arrow Lake-HX) - Top-tier mobile workstation processor
- **GPU**: NVIDIA RTX 5090 Laptop (24GB VRAM) - Flagship laptop GPU with Ray Tracing and DLSS 4
- **RAM**: 64 GB DDR5-6400 - High-capacity, high-speed memory
- **Storage**: 24 TB total (20 TB internal NVMe + 4 TB external)
- **Display**: Dual displays (18" 2560×1600 @ 144Hz + 34" 3440×1440 @ 144Hz ultrawide)

### Use Cases
- High-performance software development
- Network infrastructure management
- Virtualization and containerization (Docker, LXC)
- Multi-monitor productivity workstation
- Gaming (when not working)

---

## Network Integration

This laptop serves as the primary management workstation for the homelab infrastructure:

### Managed Infrastructure
- **Proxmox Host**: intel-1250p (192.168.1.40)
- **LXC Containers**: docker (.50), immich (.51), pbs (.52)
- **Network Equipment**: UCG Fiber Router (.1), USW Pro XG-24 Switch (.2), PDU (.3)
- **Backup Servers**: intel-n6005 (192.168.1.41), Synology DS1520+ (.10)

### SSH Configuration
- Unified ED25519 SSH key: `~/.ssh/id_ed25519_unified`
- SSH config: `~/.ssh/config`
- Access to all infrastructure hosts

### Documentation Location
All infrastructure documentation maintained in `~/Documents/dev/md/`:
- network-devices.md
- switch-port-layout.md
- router-dhcp-config.md
- ssh-config.md
- shell-configs.md

### Scripts Location
Management scripts in `~/Documents/dev/sh/`:
- LXC management scripts
- Wake-on-LAN scripts
- Proxmox configuration scripts
- Backup and replication scripts

---

## Notes

- **Latest Generation Hardware**: Features Intel's latest Core Ultra 9 (Arrow Lake-HX) and NVIDIA's RTX 5090 Laptop GPU (Blackwell architecture)
- **Massive Storage**: 24 TB total storage capacity with multiple high-speed NVMe SSDs
- **High Refresh Displays**: Dual 144Hz displays for smooth operation
- **Network Performance**: 10 Gigabit Ethernet for fast network operations
- **Professional Workstation**: Configured as primary development and infrastructure management machine
- **Windows 11 Pro**: Full professional features with WSL support for Linux workflows

---

## Related Documentation

- **Network Infrastructure**: `~/Documents/dev/md/network-devices.md`
- **Shell Configuration**: `~/Documents/dev/md/shell-configs.md`
- **SSH Configuration**: `~/Documents/dev/md/ssh-config.md`
- **Wake-on-LAN**: `~/Documents/dev/sh/wake-on-lan-README.md`
- **Global Config**: `~/.claude/CLAUDE.md`
