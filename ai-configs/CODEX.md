# CODEX.md

This file provides guidance to Codex CLI (gpt-5.1-codex) when working with code in this repository.

**Last Updated:** November 21, 2025
**Status:** Production / Sanitized

## ⚠️ Configuration & Secrets

**CRITICAL:** This repository uses an **Externalized Configuration** architecture.
- **DO NOT** assume hardcoded IPs (e.g., 192.168.1.x) or MAC addresses.
- **SOURCE OF TRUTH:** Read `.config/homelab.settings.json` to determine the active network topology, hostnames, and user credentials.
- **TEMPLATES:** If the config is missing, refer to `.config/homelab.settings.example.json`.

## Environment Overview

Windows 11 Development Environment (Alienware 18 Area-51).
Manages a mixed Windows/Linux/Proxmox homelab via SSH and PowerShell.

## Shell Environment

- **Primary:** PowerShell 7 (Oh My Posh)
- **Secondary:** Git Bash / WSL (Debian)

## Infrastructure Management

### Proxmox & LXC
Scripts are located in `infrastructure/proxmox/`.
- **Deployment:** Use `infrastructure/deployment/deploy-to-proxmox.ps1` to push scripts to hosts.
- **Configuration:** Scripts load variables from a generated `config/homelab.env` file on the target host.

### Media Stack
- **Tools:** `media/tools/` (Python & PowerShell)
- **Services:** Immich, DigiKam (Server-side)
- **Clients:** Mylio, MPV (Client-side)

## 3-Tier Backup Architecture

1. **PBS (Primary):** Local fast storage.
2. **ZFS Replication:** Off-site/Secondary host (Automated wake/shutdown).
3. **Synology NAS:** Cold storage archive.
