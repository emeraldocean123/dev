# Hardware

Hardware diagnostic scripts and incident tracking documentation.

## Documentation

- **caldigit-ts5-plus-incident.md** - CalDigit TS5+ hub incident tracking and RMA
- **caldigit-workaround.md** - Quick reference for WiFi priority toggle workaround
- **caldigit-10gbe-crash-analysis.md** - 10GbE driver crash analysis
- **alienware-laptop-specs.md** - Laptop hardware specifications
- **kvm-over-ip-setup.md** - KVM over IP setup documentation

## Diagnostic Tools

Hardware diagnostic scripts organized by function:

### CalDigit Diagnostics (`caldigit-diagnostics/`)
- **check-caldigit.ps1** - Main CalDigit hub diagnostic tool
- **check-caldigit-event-logs.ps1** - Event log analysis
- **check-firmware-version.ps1** - Firmware version checking
- **add-incident-11.ps1** - Incident tracking helper

### Network Diagnostics (`network-diagnostics/`)
- **check-network-metrics.ps1** - Network performance metrics
- **check-rsc-settings.ps1** - Receive Side Coalescing settings

### Network Priority (`network-priority/`)
- **toggle-network-priority.ps1** - Toggle between WiFi and Ethernet priority
- **set-wifi-priority.ps1** - Set WiFi as primary adapter
- **set-ethernet-priority.ps1** - Set Ethernet as primary adapter

### USB Diagnostics (`usb-diagnostics/`)
- **check-pnp-devices.ps1** - PnP device enumeration
- **check-pnp-details.ps1** - Detailed PnP device information
- **check-usb4-firmware.ps1** - USB4 firmware version checking

### AlienFX Tools (`alienfx-tools/`)
- **alienfx-check.ps1** - AlienFX lighting system diagnostics
- **alienfx-task-details.ps1** - Task scheduler details for AlienFX

### System Diagnostics (`system-diagnostics/`)
- **check-boot-time.ps1** - Boot time analysis
- **enable-bluetooth-radio.ps1** - Bluetooth radio management

### Npcap Management (`npcap-management/`)
- **disable-npcap-10gbe.ps1** - Disable Npcap on 10GbE adapter
- **verify-npcap-status.ps1** - Verify Npcap binding status

## Purpose

Hardware-specific diagnostics, troubleshooting procedures, and incident documentation for homelab equipment.
