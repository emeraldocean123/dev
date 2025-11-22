# Tailscale LXC - Local Network Routing Fix

**Date:** November 6, 2025
**Container:** LXC 1004 (pve-tailscale-lxc) at 192.168.1.54
**Issue:** SSH and local network connectivity not working
**Status:** Fixed and documented

---

## Problem Summary

The Tailscale container (LXC 1004) was unreachable via SSH from the local network (192.168.1.0/24). While the container could initiate connections to other local hosts, incoming connections timed out.

### Symptoms

- `ssh tailscale` - Connection timeout
- `ping 192.168.1.54` from host - 100% packet loss
- Ping FROM container TO host - Working correctly
- Tailscale VPN connectivity - Working normally

---

## Root Cause Analysis

### Investigation Process

1. **SSH service check** - SSH was running and listening on port 22 ✓
2. **Network interface check** - eth0 had correct IP 192.168.1.54/24 ✓
3. **Firewall check** - No iptables rules blocking traffic ✓
4. **Packet capture** - Revealed the core issue:

```
tcpdump output:
eth0  In  IP 192.168.1.40 > 192.168.1.54: ICMP echo request
tailscale0 Out IP 192.168.1.54 > 192.168.1.40: ICMP echo reply
```

**The Problem:** Requests arrived on eth0, but replies were sent out through tailscale0 VPN interface.

### Root Cause: Asymmetric Routing

Tailscale's routing configuration was causing local LAN traffic to be routed through the VPN tunnel instead of the local network interface.

**Routing Table 52 (Tailscale):**
```bash
192.168.1.0/24 dev tailscale0 table 52
```

**Routing Policy Rules:**
```
5270: from all lookup 52
```

Rule 5270 directed ALL traffic to check table 52 first, which routed local subnet traffic through the VPN.

### Why This Happened

The container is configured as a **Tailscale subnet router** and **exit node**, advertising the local network (192.168.1.0/24) to remote Tailscale clients. However, the routing rules were overly aggressive and also affected the container's own local traffic routing.

This is a **configuration side effect**, not a security feature. The subnet router needs to advertise the local network to OTHER Tailscale clients, but the container itself should use the local network interface for local traffic.

---

## Solution

### Fix: Priority Routing Rules

Added two routing rules with higher priority than Tailscale's rule to ensure local LAN traffic uses the main routing table:

```bash
# Priority 5260: Traffic FROM local subnet uses main table
ip rule add from 192.168.1.0/24 lookup main priority 5260

# Priority 5265: Traffic TO local subnet uses main table
ip rule add to 192.168.1.0/24 lookup main priority 5265
```

These rules execute BEFORE Tailscale's rule (priority 5270), ensuring local traffic stays local.

### Final Routing Policy Rules

```
0:     from all lookup local
5210:  from all fwmark 0x80000/0xff0000 lookup main
5230:  from all fwmark 0x80000/0xff0000 lookup default
5250:  from all fwmark 0x80000/0xff0000 unreachable
5260:  from 192.168.1.0/24 lookup main           ← NEW
5265:  from all to 192.168.1.0/24 lookup main    ← NEW
5270:  from all lookup 52                        ← Tailscale
32766: from all lookup main
32767: from all lookup default
```

---

## Persistence Configuration

The fix is made persistent via a systemd service that runs on boot.

### Script: /usr/local/bin/fix-local-routing.sh

```bash
#!/bin/bash
# Fix local LAN routing to bypass Tailscale VPN
# This ensures local network traffic goes through eth0 instead of tailscale0

# Add routing rules for local LAN (192.168.1.0/24)
# Priority 5260 and 5265 comes before Tailscale rule 5270
ip rule add from 192.168.1.0/24 lookup main priority 5260 2>/dev/null || true
ip rule add to 192.168.1.0/24 lookup main priority 5265 2>/dev/null || true

exit 0
```

### Systemd Service: /etc/systemd/system/fix-local-routing.service

```ini
[Unit]
Description=Fix local LAN routing to bypass Tailscale VPN
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-local-routing.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### Service Status

- **Enabled:** Yes (runs automatically on boot)
- **Location:** `/etc/systemd/system/fix-local-routing.service`
- **Script:** `/usr/local/bin/fix-local-routing.sh`

---

## Verification

### Test Local Connectivity

```bash
# From Proxmox host
ping -c 4 192.168.1.54
ssh tailscale "uname -a"
```

**Expected Results:**
- Ping: 0% packet loss, ~0.05ms latency
- SSH: Immediate connection, no timeout

### Verify Routing Rules

```bash
ssh tailscale "ip rule show | head -10"
```

**Expected Output:**
```
5260: from 192.168.1.0/24 lookup main
5265: from all to 192.168.1.0/24 lookup main
5270: from all lookup 52
```

### Verify Tailscale Still Works

```bash
ssh tailscale "tailscale status"
```

**Expected:** VPN connections to remote devices still functional

---

## Impact and Behavior

### What Changed

**Before Fix:**
- Local LAN traffic → Routed through Tailscale VPN tunnel
- Result: Asymmetric routing, connection timeouts
- SSH: Not working from local network
- Ping: Not working from local network

**After Fix:**
- Local LAN traffic → Routed through eth0 (local network)
- Result: Direct local connectivity
- SSH: Working from local network
- Ping: Working from local network
- Tailscale VPN: Still working for remote access

### What Still Works

1. ✓ **Tailscale VPN:** Remote Tailscale clients can still connect
2. ✓ **Subnet Router:** Remote clients can still access 192.168.1.0/24 through this container
3. ✓ **Exit Node:** This container can still act as an exit node
4. ✓ **Local Network:** Container is now accessible from local LAN

---

## Troubleshooting

### If SSH/Ping Stops Working After Reboot

Check if the service is running:
```bash
ssh intel-1250p "pct exec 1004 -- systemctl status fix-local-routing.service"
```

Manually apply the fix:
```bash
ssh intel-1250p "pct exec 1004 -- /usr/local/bin/fix-local-routing.sh"
```

### Check Current Routing Rules

```bash
ssh intel-1250p "pct exec 1004 -- ip rule show"
```

Look for rules 5260 and 5265 with priority BEFORE rule 5270.

### Remove the Fix (If Needed)

```bash
ssh tailscale "ip rule del priority 5260; ip rule del priority 5265"
```

**Warning:** This will break local network connectivity again.

---

## Technical Details

### Container Configuration

- **LXC ID:** 1004
- **Hostname:** pve-tailscale-lxc
- **IP Address:** 192.168.1.54/24
- **Gateway:** 192.168.1.1
- **Interfaces:** eth0 (local), tailscale0 (VPN)

### Tailscale Configuration

- **Role:** Subnet router + Exit node
- **Advertised Routes:** 192.168.1.0/24
- **Tailscale IP:** 100.67.192.61
- **Routing Table:** 52 (custom table created by Tailscale)

### Why Priority 5260/5265?

These priorities are chosen to be:
1. Lower than 5270 (Tailscale's rule) - executes first
2. Higher than 5250 (fwmark unreachable) - doesn't interfere with Tailscale's internal routing
3. In the Tailscale rule range - keeps all Tailscale-related rules grouped together

---

## Related Files

- **Container Config:** `/etc/pve/lxc/1004.conf`
- **Fix Script:** `/usr/local/bin/fix-local-routing.sh` (in container)
- **Systemd Service:** `/etc/systemd/system/fix-local-routing.service` (in container)
- **SSH Config:** `~/.ssh/config` (tailscale host entry)

---

## Summary

This was a **configuration issue** caused by Tailscale's subnet router routing rules being too broad. The fix ensures that local network traffic stays on the local network while maintaining Tailscale's VPN and subnet router functionality for remote clients.

**The fix is:**
- ✓ Minimal (two routing rules)
- ✓ Non-invasive (doesn't modify Tailscale config)
- ✓ Persistent (systemd service)
- ✓ Safe (can be easily removed if needed)
- ✓ Tested (working as of November 6, 2025)
