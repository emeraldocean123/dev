# Network Infrastructure

Management scripts and documentation for network adapters, routers, and switches.

## Folder Structure

### **adapter-priority/**
Network adapter priority management (Ethernet vs WiFi).
- Originally created for CalDigit TS5+ hub workaround
- Generic solution for adapter priority conflicts

### **diagnostics/**
Network adapter diagnostics and configuration checks.
- RSC (Receive Side Coalescing) settings
- Network metrics and performance analysis

### **ethernet/**
Ethernet-specific tools and DHCP management.

### **wifi/**
WiFi management utilities.
- Enable/disable WiFi adapters
- Status monitoring

### **npcap/**
Npcap driver management and configuration.

## Root Documentation Files

- **network-devices.md** - Complete network inventory
- **switch-port-layout.md** - 26-port switch configuration
- **router-dhcp-config.md** - DHCP configuration with static reservations
- **ssh-config.md** - SSH configuration documentation
- **tailscale-lxc-routing-fix.md** - Tailscale routing fix for LXC 1004

## Location

**Path:** ~/Documents/dev/network/
**Category:** 
etwork-infrastructure
