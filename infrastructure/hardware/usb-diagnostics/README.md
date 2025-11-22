# USB Diagnostics

USB4, Thunderbolt, and USB-C device diagnostic tools.

## Scripts

### check-usb-hub.ps1
Quick diagnostic for USB4/Thunderbolt hubs and connected devices.

**Features:**
- Lists all USB4/Thunderbolt/USB-C devices
- Checks Ethernet adapter status (if connected via hub)
- Verifies IP configuration
- Tests gateway connectivity

**Usage:**
```powershell
.\check-usb-hub.ps1
```

### check-usb-event-logs.ps1
Scans Windows event logs for USB/Thunderbolt errors and displays device information.

**Features:**
- Recent system events (last 2 hours)
- USB/Thunderbolt errors and warnings
- Driver version information
- Firmware version information

**Usage:**
```powershell
.\check-usb-event-logs.ps1
```

### check-firmware-version.ps1
Displays firmware version for USB4/Thunderbolt controllers.

### check-pnp-devices.ps1
Lists all Plug and Play devices.

### check-pnp-details.ps1
Detailed PnP device information including driver and hardware IDs.

### check-usb4-firmware.ps1
Specific USB4 firmware version checker.

## Common Use Cases

### Troubleshooting USB Hub Issues
```powershell
# Quick check
.\check-usb-hub.ps1

# Check for errors
.\check-usb-event-logs.ps1
```

### Verifying Driver/Firmware Versions
```powershell
.\check-usb-event-logs.ps1  # Shows all driver/firmware info
.\check-firmware-version.ps1  # Quick firmware check
```

## Location

**Path:** `~/Documents/git/dev/hardware/usb-diagnostics`
**Category:** `hardware-diagnostics`
