# Hamachi Static Port NAT Script

## Overview
This script configures static port NAT rules on the UCG Fiber router to enable Hamachi VPN functionality for specific clients.

## Purpose
Hamachi VPN requires **static port NAT** (no port translation) to maintain consistent connections to external VPN servers. Without this, the router's default NAT randomizes source ports, breaking VPN connectivity.

## What It Does
The script creates iptables SNAT rules that:
1. Preserve source ports for outbound traffic from Hamachi clients
2. Only translate the source IP to the WAN IP (no port translation)
3. Apply specifically to traffic from 192.168.1.100 and 192.168.1.101

## Equivalent OPNsense Configuration
This replicates the OPNsense NAT rule:
- **Interface:** WAN
- **Source:** 192.168.1.101/32
- **Static Port:** YES
- **NAT Address:** Interface address

## Installation
The script is located at:
- **Router:** `/data/on_boot.d/10-hamachi-nat.sh`
- **Windows:** `~/Documents/dev/sh/10-hamachi-nat.sh`
- **Systemd Service:** `/etc/systemd/system/hamachi-nat.service`

## Automatic Execution
The script runs automatically on boot via systemd service `hamachi-nat.service`.

**Service Management:**
```bash
# Check service status
ssh router "systemctl status hamachi-nat.service"

# Start service manually
ssh router "systemctl start hamachi-nat.service"

# Restart service
ssh router "systemctl restart hamachi-nat.service"

# Disable auto-start on boot (if needed)
ssh router "systemctl disable hamachi-nat.service"

# Re-enable auto-start on boot
ssh router "systemctl enable hamachi-nat.service"
```

## Manual Execution
You can also run the script manually (useful for testing):
```bash
ssh router "/data/on_boot.d/10-hamachi-nat.sh"
```

## Verification
Check active NAT rules:
```bash
ssh router "iptables -t nat -L POSTROUTING -v -n | grep -E '192.168.1.10[01]'"
```

Expected output:
```
    0     0 SNAT       all  --  *      eth4    192.168.1.100        0.0.0.0/0            to:73.93.188.131
    0     0 SNAT       all  --  *      eth4    192.168.1.101        0.0.0.0/0            to:73.93.188.131
```

## Configuration
- **WAN Interface:** eth4 (UCG Fiber default)
- **Hamachi Clients:** 192.168.1.100, 192.168.1.101
- **NAT Type:** SNAT (static port)

## Troubleshooting

### Service Issues
- **Service not starting:** Check service status and logs
  ```bash
  ssh router "systemctl status hamachi-nat.service"
  ssh router "journalctl -u hamachi-nat.service"
  ```
- **Service disabled:** Re-enable the service
  ```bash
  ssh router "systemctl enable hamachi-nat.service"
  ```

### Script Issues
- **Script won't execute:** Check line endings (must be LF, not CRLF)
  ```bash
  ssh router "sed -i 's/\r$//' /data/on_boot.d/10-hamachi-nat.sh"
  ```
- **Rules not applying:** Verify the script is executable
  ```bash
  ssh router "chmod +x /data/on_boot.d/10-hamachi-nat.sh"
  ```
- **Wrong WAN interface:** Update `WAN_IFACE` variable in script if not eth4

### Persistence Notes
- Files in `/data/` persist through reboots on UCG Fiber
- Systemd service file in `/etc/systemd/system/` **may not persist** through firmware updates
- After firmware updates, verify the service still exists:
  ```bash
  ssh router "systemctl status hamachi-nat.service"
  ```
- If service is missing after firmware update, redeploy using the Initial Deployment commands from README.md

## Notes
- The script automatically removes old rules before adding new ones (idempotent)
- Logs to syslog with tag "hamachi-nat"
- Does not interfere with other NAT rules
- Preserves existing router NAT configuration
