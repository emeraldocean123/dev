# 🛠️ Emerald Ocean Dev Platform

A unified, production-hardened management platform for Homelab infrastructure, Media workflows, and System automation.

## 🌟 Features

* **Mission Control:** Centralized `homelab.ps1` dashboard for all operations.
* **Infrastructure as Code:** Automated, config-driven deployment to Proxmox hosts.
* **Media Operations:** Professional-grade tools for video processing, deduplication, and metadata management (Mylio/DigiKam/Immich).
* **Secure by Design:** Strict separation of code and configuration. Zero hardcoded secrets.

## 🚀 Getting Started

This repository uses an **Externalized Configuration** system. No personal data (IPs, Usernames, Paths) is stored in the code.

### 1. Initialization
Run the setup script to generate your local configuration files (git-ignored):
```powershell
.\shell-management\utils\setup-homelab-config.ps1
```

### 2. Configuration

Edit the newly created secrets file with your environment details:

* **Path:** `.config/homelab.settings.json`
* **Action:** Fill in your Proxmox IPs, NAS credentials, and Storage paths.

### 3. Launch

Start the management console:

```powershell
.\homelab.ps1
```

## 📂 Architecture

### Media Management (Unified v2.0)

- **`media/tools/`** - Universal utilities (ExifTool, Dedupe, Scrubber, Video)
- **`media/services/`** - Server-side configs (Immich, DigiKam)
- **`media/clients/`** - Desktop app configs (Mylio, MPV, XnView)

### Infrastructure

- **`infrastructure/deployment/`** - Automated script deployment (SCP/SSH)
- **`infrastructure/network/`** - Network topology, VPN, diagnostics
- **`infrastructure/hardware/`** - Hardware tools (Alienware, CalDigit, USB)
- **`infrastructure/storage/`** - Drive management, architecture
- **`infrastructure/backup/`** - 3-Tier Backup strategies (PBS, ZFS, Rsync)
- **`infrastructure/proxmox/`** - Proxmox/LXC management scripts

### System Configuration

- **`shell-management/`** - Dotfiles (Bash, PowerShell, SSH, Docker, Fastfetch)
- **`.config/`** - (Private) Local environment settings and secrets

## 3-Tier Backup Architecture

The repository implements a fully automated backup strategy:

1. **Layer 1: Primary** - Proxmox Backup Server (PBS) on NVMe.
2. **Layer 2: Off-Host** - Automated ZFS replication with RTC wake-up.
3. **Layer 3: Tertiary** - NAS archival via rsync (Power-on detection).

## License

MIT License
