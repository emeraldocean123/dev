# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last Updated:** November 22, 2025
**Status:** Production / Sanitized

## Claude Code Configuration

### Active Configuration
- **Extended thinking mode**: Enabled (`alwaysThinkingEnabled: true`)
- **Permissions**: Wildcard permissions for autonomous operation
- **Tools enabled**: Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Task, BashOutput, KillShell, AskUserQuestion, TodoWrite, NotebookEdit, SlashCommand, Skill

## ⚠️ Configuration & Secrets

**CRITICAL:** This repository uses an **Externalized Configuration** architecture.
- **DO NOT** assume hardcoded IPs (e.g., 192.168.1.x) or MAC addresses.
- **SOURCE OF TRUTH:** Read `.config/homelab.settings.json` to determine the active network topology, hostnames, and user credentials.
- **TEMPLATES:** If the config is missing, refer to `.config/homelab.settings.example.json`.

## Environment Overview

This is a Windows 11 development environment running on an Alienware 18 Area-51 laptop. The environment includes shell configurations, comprehensive network documentation, and management scripts for a homelab Proxmox infrastructure.

## Shell Environment

### Active Shells
- **PowerShell 7**: Primary shell with Oh My Posh theme
- **Git Bash**: Secondary shell
- **Debian WSL**: Available

## Docker Desktop (Windows)

- **Configuration**: `~/.docker/` (config.json, daemon.json)
- **Immich**: v2 (latest stable) running on Port 2283 (mapped locally).

## Network Infrastructure

**Dynamic Topology:**
Refer to `.config/homelab.settings.json` for the current list of:
- Router & Switch IPs
- Proxmox Host IPs (Primary/Secondary)
- NAS Storage IPs
- LXC Container IDs and IPs

**Documentation:**
- Scripts: `infrastructure/network/`
- VPN: `infrastructure/network/vpn/` (Tailscale/Hamachi)

## Script Management

### Location: `infrastructure/proxmox/`

Complete suite of scripts for managing Proxmox, LXC, and network infrastructure.
These scripts are **configuration-aware** and must be deployed using `infrastructure/deployment/deploy-to-proxmox.ps1`.

**Key Scripts:**
1. **lxc-setup.sh** - Bootstrap new containers.
2. **zfs-replicate-pbs.sh** - Automate ZFS replication between hosts.
3. **upgrade-debian.sh** - Safe OS upgrades.

## Development Tools

- **Git**: Configured with unified SSH key
- **Oh My Posh**: Custom theme (jandedobbeleer)
- **Fastfetch**: System info

## 3-Tier Backup Architecture

**Reference:** `infrastructure/backup/README.md`

1. **Layer 1: Primary** - Proxmox Backup Server (PBS)
2. **Layer 2: Off-Host** - ZFS Replication (RTC Wake)
3. **Layer 3: Tertiary** - NAS Archive (Rsync)
