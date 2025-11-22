# Wake-on-LAN Scripts for Network Infrastructure

Scripts to remotely power on network devices without physical access.

**Last Updated:** October 15, 2025

## Overview

These scripts send Wake-on-LAN (WOL) magic packets to boot devices remotely. Useful for:
- Waking servers after scheduled shutdowns (e.g., N6005 after nightly replication)
- Waking Synology NAS on-demand for tertiary backups
- Remote power-on without physical button access
- Automated workflows requiring device availability

## Available Scripts

### 1. PowerShell Script (Windows)
**File:** `wake-servers.ps1`
**Platform:** Windows PowerShell 5.1+ or PowerShell Core 7+

```powershell
# Wake all devices (default)
./wake-servers.ps1
./wake-servers.ps1 all

# Wake specific device
./wake-servers.ps1 1250p
./wake-servers.ps1 n6005
./wake-servers.ps1 synology

# Wake both Proxmox servers
./wake-servers.ps1 proxmox
```

### 2. Bash Script (Linux/macOS/Git Bash)
**File:** `wake-servers.sh`
**Platform:** Linux, macOS, Git Bash on Windows

```bash
# Wake all devices (default)
./wake-servers.sh
./wake-servers.sh all

# Wake specific device
./wake-servers.sh 1250p
./wake-servers.sh n6005
./wake-servers.sh synology

# Wake both Proxmox servers
./wake-servers.sh proxmox
```

### 3. Shell Aliases (Recommended)

Convenient aliases are configured in your shell profiles for quick access from anywhere:

**PowerShell Aliases:**
```powershell
wake              # Wake all devices
wake-all          # Wake all devices
wake-1250p        # Wake intel-1250p only
wake-n6005        # Wake intel-n6005 only
wake-synology     # Wake Synology NAS only
wake-proxmox      # Wake both Proxmox servers
```

**Bash Aliases:**
```bash
wake              # Wake all devices
wake-all          # Wake all devices
wake-1250p        # Wake intel-1250p only
wake-n6005        # Wake intel-n6005 only
wake-synology     # Wake Synology NAS only
wake-proxmox      # Wake both Proxmox servers
```

**Configuration Files:**
- PowerShell: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- Bash: `~/.bashrc`

**Reload Profile:** Aliases are available after reloading:
```powershell
# PowerShell
. $PROFILE

# Bash
source ~/.bashrc
```

## Device Information

| Device | IP Address | MAC Address | Purpose |
|--------|------------|-------------|---------|
| intel-1250p | 192.168.1.40 | a8:b4:e0:07:9b:cd | Primary Proxmox host, NAS, PBS |
| intel-n6005 | 192.168.1.41 | 7c:2b:e1:13:92:4b | Backup server, ZFS replication |
| synology-1520-nas | 192.168.1.10 | 00:11:32:ff:4a:a5 | Synology DS1520+ NAS, tertiary backup |

## Usage Examples

### Wake All Devices

**PowerShell:**
```powershell
cd ~/Documents/dev/sh
./wake-servers.ps1
```

**Bash:**
```bash
cd ~/Documents/dev/sh
./wake-servers.sh
```

### Wake Synology NAS Only

Synology automatically shuts down after tertiary backup completes. Wake it on-demand:

**PowerShell:**
```powershell
./wake-servers.ps1 synology
```

**Bash:**
```bash
./wake-servers.sh synology
```

### Wake N6005 Only (After Auto-Shutdown)

The N6005 server automatically shuts down after nightly replication at ~3:05 AM. To wake it manually:

**PowerShell:**
```powershell
./wake-servers.ps1 n6005
```

**Bash:**
```bash
./wake-servers.sh n6005
```

### Wake 1250P Only

**PowerShell:**
```powershell
./wake-servers.ps1 1250p
```

**Bash:**
```bash
./wake-servers.sh 1250p
```

### Wake Both Proxmox Servers (Not Synology)

**PowerShell:**
```powershell
./wake-servers.ps1 proxmox
```

**Bash:**
```bash
./wake-servers.sh proxmox
```

## How It Works

1. **Magic Packet Creation**: Scripts create a WOL magic packet containing:
   - 6 bytes of `0xFF` (header)
   - Target MAC address repeated 16 times

2. **Broadcast Transmission**: Packet is sent via UDP to broadcast address `192.168.1.255` on port 9

3. **Hardware Wake**: Network interface card (NIC) detects magic packet and signals BIOS to power on

4. **Boot Process**: Server boots normally as if power button was pressed

## Requirements

### PowerShell Script
- Windows PowerShell 5.1+ or PowerShell Core 7+
- No external dependencies (uses built-in .NET sockets)

### Bash Script
- Bash 4.0+
- **Optional but recommended**: `wakeonlan` utility for better reliability
  - Debian/Ubuntu: `sudo apt install wakeonlan`
  - RHEL/CentOS: `sudo yum install wol`
  - macOS: `brew install wakeonlan`
- **Fallback**: Scripts use netcat (`nc`) if wakeonlan not available

## Server Configuration

Both Proxmox servers are configured with WOL enabled:

1. **BIOS/UEFI Settings:**
   - Wake-on-LAN: Enabled
   - Network Stack: Enabled
   - Power state after power loss: Last state

2. **Network Interface:**
   - WOL mode: Magic packet (g)
   - Verified with: `ethtool <interface> | grep Wake-on`

3. **Network Requirements:**
   - Servers must be on same subnet (192.168.1.0/24)
   - Switch must support WOL (UCG Fiber does)
   - Server must be connected to power

## Troubleshooting

### Server Doesn't Wake

1. **Verify server is powered off (not sleeping)**
   ```bash
   ping 192.168.1.40  # Should timeout
   ```

2. **Check WOL is enabled in BIOS**
   - Boot to BIOS/UEFI
   - Navigate to Power/Network settings
   - Ensure Wake-on-LAN is enabled

3. **Verify network cable is connected**
   - WOL requires physical Ethernet connection
   - WiFi WOL is not supported

4. **Check switch port is active**
   - Some switches disable ports when device is off
   - UCG Fiber keeps ports active

5. **Try from different machine on network**
   - Run script from router or another server
   ```bash
   ssh router
   wakeonlan a8:b4:e0:07:9b:cd
   ```

### Script Errors

**PowerShell: Execution policy error**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Bash: Permission denied**
```bash
chmod +x wake-servers.sh
```

**Bash: wakeonlan not found**
- Install wakeonlan (see Requirements)
- Or: Script will fallback to netcat method

## Integration with Backup Workflow

The N6005 server uses RTC (Real-Time Clock) wake for automated nightly replication:

1. **Automated Wake**: RTC alarm wakes N6005 at 2:50 AM
2. **Replication**: ZFS replication runs at 3:00 AM (~1 minute duration)
3. **Auto-Shutdown**: Server shuts down at ~3:05 AM
4. **Next Alarm Set**: Shutdown service sets next RTC alarm for tomorrow

**Manual wake needed when:**
- Missed scheduled wake (RTC alarm failed)
- Ad-hoc replication required
- Maintenance/testing needed

**Check N6005 status:**
```bash
ping 192.168.1.41
ssh intel-n6005 "uptime"
```

**Wake N6005 manually:**
```bash
./wake-servers.sh n6005
# Wait 30-60 seconds for boot
ssh intel-n6005 "uptime"
```

## Related Documentation

- **network-devices.md** - Complete network inventory with MAC addresses
- **backup-infrastructure-overview.md** - 3-tier backup architecture
- **pbs-backup-config.md** - Proxmox Backup Server configuration

## Notes

- WOL packets are broadcast - all devices on subnet receive them, but only matching MAC responds
- No security in WOL protocol - any device can wake servers (LAN only, not routable)
- Servers take 30-60 seconds to fully boot after WOL packet
- WOL works even when server is fully powered off (requires ATX power connected)
- RTC wake is more reliable for scheduled operations (hardware-level, no network dependency)
- WOL is better for manual/on-demand wake operations
