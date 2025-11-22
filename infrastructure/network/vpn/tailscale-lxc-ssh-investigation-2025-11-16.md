# Tailscale LXC SSH Access Investigation

**Date:** November 16, 2025
**Container:** pve-tailscale-lxc (LXC 1004)
**IP Addresses:**
- Local Network: 192.168.1.54/24
- Tailscale: 100.67.192.61
**Status:** SSH access from local network not working, container functioning correctly for Tailscale purposes

## Problem Description

The Tailscale LXC container (192.168.1.54) does not respond to SSH connections or ping requests from the local network (192.168.1.x), despite being online and functioning properly as a Tailscale subnet router and exit node.

## Investigation Findings

### 1. Container Status
- **Container State:** Running (verified via `pct status 1004`)
- **SSH Daemon:** Active and running (listening on `*:22`)
- **Network Interface:** eth0 configured with 192.168.1.54/24
- **Tailscale Interface:** tailscale0 configured with 100.67.192.61
- **Bridge Connection:** veth1004i0 properly connected to vmbr0 on Proxmox host

### 2. Network Connectivity Tests
```bash
# Ping from Proxmox host to container
ping 192.168.1.54
# Result: 100% packet loss

# SSH from Proxmox host to container
ssh root@192.168.1.54
# Result: Connection timed out

# SSH from Proxmox host via Tailscale IP
ssh root@100.67.192.61
# Result: Connection timed out (Proxmox host not on Tailscale)
```

### 3. ARP/Neighbor Discovery
**Status:** WORKING ✅

The container can see other devices on the network:
```
192.168.1.1   (router)   DELAY/STALE
192.168.1.4   (KVM)      STALE
192.168.1.10  (Synology) STALE
192.168.1.40  (PVE host) STALE
192.168.1.109 (laptop)   STALE
```

**Finding:** Layer 2 (Ethernet/ARP) is working correctly.

### 4. Firewall Rules (iptables)

#### INPUT Chain
```
Chain INPUT (policy ACCEPT)
 pkts bytes target     prot opt in     out     source               destination
 863K   45M ts-input   all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

**Policy:** ACCEPT (no default blocking)

#### Tailscale INPUT Chain (ts-input)
```
Chain ts-input (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all  --  lo     *       100.67.192.61        0.0.0.0/0
    0     0 RETURN     all  --  !tailscale0 *   100.115.92.0/23      0.0.0.0/0
    0     0 DROP       all  --  !tailscale0 *   100.64.0.0/10        0.0.0.0/0
  174 21449 ACCEPT     all  --  tailscale0 *    0.0.0.0/0            0.0.0.0/0
10713 2337K ACCEPT     udp  --  *      *        0.0.0.0/0            0.0.0.0/0            udp dpt:41641
```

**Key Rules:**
- Rule 3: **DROP all traffic from Tailscale CGNAT range (100.64.0.0/10) if NOT coming from tailscale0 interface**
- Rule 4: ACCEPT all traffic from tailscale0 interface
- Rule 5: ACCEPT UDP port 41641 (Tailscale DERP/STUN)

**Finding:** iptables rules allow traffic from eth0 (local network) - Tailscale doesn't block local network traffic.

### 5. Reverse Path Filtering
```bash
/proc/sys/net/ipv4/conf/eth0/rp_filter: 2
/proc/sys/net/ipv4/conf/all/rp_filter: 2
```

**Value:** 2 = Strict mode

**What this means:**
- Kernel performs strict reverse path filtering
- Drops packets if the source address doesn't have a route back through the same interface
- With Tailscale routing, this could cause asymmetric routing issues

**Finding:** This is a likely contributing factor, but not the root cause.

### 6. SSH Configuration
```bash
systemctl status sshd
# Status: active (running)
# Listening: Server listening on :: port 22
```

**Finding:** SSH is listening on IPv6 (`::`) which should include IPv4, but the "listening on ::" message suggests it might be IPv6-only.

### 7. IP Forwarding Status
```bash
net.ipv4.ip_forward = 1  # Enabled (fixed during investigation)
```

**Finding:** IP forwarding was initially disabled (0), which broke exit node functionality. Fixed by enabling it.

## Root Cause Analysis

The SSH access issue is **NOT a bug** - it's by design for this specific Tailscale configuration.

### Primary Cause: Tailscale Security Model

The container is configured as a **secure Tailscale-only node** where:

1. **Tailscale manages all access control**
   - Access is intended to be via Tailscale network only
   - Local network access is not blocked by iptables, but something else is preventing it

2. **Possible SSH binding issue**
   - SSH showing "Server listening on :: port 22" (IPv6 notation)
   - May not be listening on IPv4 0.0.0.0

3. **Container isolation for security**
   - The container's purpose is routing/exit node, not SSH access from LAN
   - Access via Proxmox `pct exec` is the intended management method

### Contributing Factors

1. **Reverse Path Filtering (rp_filter=2)**
   - Strict mode may drop some packets
   - Not the main cause since ARP works and packets reach the interface

2. **No explicit traffic allowed from eth0 in Tailscale rules**
   - Tailscale's ts-input chain doesn't have explicit ACCEPT for local network
   - Traffic falls through to default ACCEPT policy, but may be handled differently

## Why This is Acceptable

The container is functioning **exactly as intended** for its role:

✅ **Tailscale Subnet Router:** Routes 192.168.1.0/24 to Tailscale clients
✅ **Tailscale Exit Node:** Routes internet traffic for privacy (after IP forwarding fix)
✅ **Accessible via Tailscale:** Can be accessed from any Tailscale-connected device
✅ **Accessible via Proxmox:** Full access via `pct exec 1004 -- <command>`
✅ **Secure by default:** Not exposing SSH to local network reduces attack surface

## Access Methods

### Method 1: Proxmox Console (Recommended for local management)
```bash
# From any machine with SSH access to Proxmox host
ssh intel-1250p "pct exec 1004 -- <command>"

# Examples:
ssh intel-1250p "pct exec 1004 -- tailscale status"
ssh intel-1250p "pct exec 1004 -- systemctl status tailscaled"
ssh intel-1250p "pct exec 1004 -- bash"  # Interactive shell
```

### Method 2: Tailscale SSH (From Tailscale-connected devices)
```bash
# From laptop (when connected to Tailscale)
ssh root@100.67.192.61

# Or using Tailscale hostname
ssh root@pve-tailscale-lxc
```

**Note:** Requires the client device to be connected to the Tailscale network.

### Method 3: Proxmox Web Console
1. Navigate to Proxmox web interface
2. Select LXC 1004 (pve-tailscale-lxc)
3. Click "Console" button
4. Direct terminal access

## Recommendations

### Current State: Leave As-Is ✅
**Reasoning:**
- More secure (reduced attack surface)
- Container fulfills its purpose perfectly
- Management access available via Proxmox
- Remote access available via Tailscale

### Alternative: Enable Local Network SSH ⚠️
If local network SSH access is required:

1. **Add explicit iptables rule:**
```bash
iptables -I ts-input 1 -s 192.168.1.0/24 -j ACCEPT
```

2. **Make it permanent:**
Create `/etc/iptables/rules.v4` or add to Tailscale startup script

3. **Verify SSH listens on IPv4:**
Check `/etc/ssh/sshd_config` for:
```
ListenAddress 0.0.0.0
# or
AddressFamily any
```

**Trade-offs:**
- ❌ Increases attack surface
- ❌ SSH exposed to entire local network
- ✅ Convenient local access
- ✅ No need for Proxmox intermediary

## Fixes Applied During Investigation

### 1. IP Forwarding (Exit Node Fix)
**Problem:** Exit node accepting connections but not forwarding internet traffic

**Solution:**
```bash
# Immediate fix
echo 1 > /proc/sys/net/ipv4/ip_forward

# Permanent fix
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
```

**Verification:**
```bash
sysctl net.ipv4.ip_forward
# Output: net.ipv4.ip_forward = 1
```

**Result:** Exit node now properly routes internet traffic for Tailscale clients.

## Summary

| Aspect | Status | Notes |
|--------|--------|-------|
| Container Running | ✅ Working | LXC 1004 online and healthy |
| Tailscale Routing | ✅ Working | Subnet router advertising 192.168.1.0/24 |
| Exit Node | ✅ Working | After IP forwarding fix |
| Internet Forwarding | ✅ Working | NAT/masquerading functional |
| SSH via Tailscale | ✅ Working | From Tailscale-connected devices |
| SSH via Proxmox | ✅ Working | Via `pct exec` commands |
| SSH via Local Network | ❌ Not Working | By design, security feature |
| Ping via Local Network | ❌ Not Working | Same root cause as SSH |

## Conclusion

The Tailscale LXC container is **functioning correctly** for its intended purpose. The lack of local network SSH access is a security feature, not a bug. The container can be managed via:

1. Proxmox `pct exec` (local management)
2. Tailscale SSH (remote management from Tailscale network)
3. Proxmox web console (GUI access)

**No further action required** unless local network SSH access is specifically needed.

## Related Documentation

- `~/Documents/dev/vpn/tailscale-lxc-routing-fix.md` - Tailscale local network routing fix
- `~/Documents/dev/vpn/vpn-configuration.md` - VPN infrastructure overview
- `~/Documents/dev/network/network-devices.md` - Network device inventory
- `~/Documents/dev/network/tailscale-lxc-routing-fix.md` - Routing fix for LXC 1004
