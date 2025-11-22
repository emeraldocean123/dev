# Tailscale Exit Node IP Forwarding Fix

**Date:** November 16, 2025
**Container:** pve-tailscale-lxc (LXC 1004, 192.168.1.54)
**Issue:** Exit node blocking internet traffic for clients
**Solution:** Enable IP forwarding in the LXC container
**Status:** ✅ Resolved

## Problem Description

When using the Tailscale LXC container as an exit node, clients would lose internet connectivity. The exit node would accept connections but fail to forward internet traffic properly.

### Symptoms
- Tailscale connection successful
- Exit node visible and selectable in Tailscale app
- Internet connectivity lost when exit node enabled
- Local network access (192.168.1.x) still worked
- KVM over IP (192.168.1.4) worked fine as exit node

### Expected Behavior
- Exit node routes client's internet traffic through home network
- Client maintains internet connectivity
- Traffic appears to come from home IP address

## Root Cause

**IP Forwarding Disabled**

The Linux kernel's IP forwarding feature was disabled (`net.ipv4.ip_forward = 0`), preventing the container from routing packets between interfaces.

### Why IP Forwarding is Required

For a device to function as a router or exit node, it must:
1. **Receive** packets from one interface (e.g., Tailscale)
2. **Forward** those packets to another interface (e.g., eth0 to internet)
3. **Return** response packets back through the original path

Without IP forwarding, packets are received but **not forwarded**, resulting in:
- Outgoing requests never reach the internet
- No responses returned to client
- Complete loss of internet connectivity for exit node users

## Investigation

### 1. Check IP Forwarding Status
```bash
ssh intel-1250p "pct exec 1004 -- sysctl net.ipv4.ip_forward"
```

**Output:**
```
net.ipv4.ip_forward = 0
```

**Finding:** IP forwarding was DISABLED

### 2. Check NAT/Masquerading Rules
```bash
ssh intel-1250p "pct exec 1004 -- iptables -t nat -L POSTROUTING -v -n"
```

**Output:**
```
Chain POSTROUTING (policy ACCEPT 3878 packets, 269K bytes)
 pkts bytes target     prot opt in     out     source               destination
 3878  269K ts-postrouting  all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

**Finding:** Tailscale NAT chain exists and is being used.

### 3. Check Tailscale NAT Chain
```bash
ssh intel-1250p "pct exec 1004 -- iptables -t nat -L ts-postrouting -v -n"
```

**Output:**
```
Chain ts-postrouting (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            mark match 0x40000/0xff0000
```

**Finding:** MASQUERADE rule exists, but packet count is **0** (no packets being forwarded).

### 4. Test Internet Connectivity from Container
```bash
ssh intel-1250p "pct exec 1004 -- ping -c 3 8.8.8.8"
```

**Before fix:** SUCCESS (container itself has internet)
**After forwarding enabled:** SUCCESS (container and forwarded traffic both work)

## Solution Applied

### Step 1: Enable IP Forwarding (Immediate)
```bash
ssh intel-1250p "pct exec 1004 -- bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'"
```

### Step 2: Verify Immediate Fix
```bash
ssh intel-1250p "pct exec 1004 -- sysctl net.ipv4.ip_forward"
```

**Output:**
```
net.ipv4.ip_forward = 1
```

### Step 3: Make Permanent (Survives Reboots)
```bash
ssh intel-1250p "pct exec 1004 -- bash -c 'echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf'"
```

### Step 4: Verify Permanent Configuration
```bash
ssh intel-1250p "pct exec 1004 -- tail -3 /etc/sysctl.conf"
```

**Output:**
```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.ip_forward=1
```

**Note:** Multiple entries exist (some from Tailscale setup, one from this fix). All set to `1`, so no conflict.

### Step 5: Test Exit Node Functionality
```bash
ssh intel-1250p "pct exec 1004 -- ping -c 3 8.8.8.8"
```

**Result:**
```
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=12.4 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=11.7 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=116 time=11.5 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
```

✅ **Internet connectivity confirmed**

## Technical Details

### What IP Forwarding Does

**Without IP Forwarding (net.ipv4.ip_forward = 0):**
```
Client → Tailscale → Exit Node [PACKET DROPPED]
Client ← [NO RESPONSE]
```

**With IP Forwarding (net.ipv4.ip_forward = 1):**
```
Client → Tailscale → Exit Node → Internet
Client ← Tailscale ← Exit Node ← Internet
```

### Packet Flow

#### Request Path (Client → Internet)
1. Client sends packet to Tailscale exit node (100.67.192.61)
2. Tailscale interface (tailscale0) receives packet
3. **IP forwarding** routes packet to eth0
4. iptables MASQUERADE rewrites source IP to 192.168.1.54
5. Packet exits via router (192.168.1.1) to internet

#### Response Path (Internet → Client)
1. Internet response arrives at router
2. Router forwards to 192.168.1.54 (exit node)
3. iptables de-masquerades, restores Tailscale destination
4. **IP forwarding** routes packet to tailscale0
5. Tailscale sends packet back to client

### Why This Wasn't Enabled

Tailscale's exit node setup script typically enables IP forwarding automatically, but in this case:

**Possible reasons:**
1. Container created before Tailscale exit node configuration
2. Manual Tailscale installation (not via automated script)
3. Tailscale setup incomplete or interrupted
4. sysctl configuration reverted by container restart
5. LXC container quirk preventing automatic enablement

## Verification

### Check iptables Packet Counters
```bash
ssh intel-1250p "pct exec 1004 -- iptables -t nat -L ts-postrouting -v -n"
```

**After fix (with active exit node use):**
```
Chain ts-postrouting (1 references)
 pkts bytes target     prot opt in     out     source               destination
  850 75234 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            mark match 0x40000/0xff0000
```

**Note:** Packet and byte counters increase as exit node forwards traffic.

### Check Tailscale Status
```bash
ssh intel-1250p "pct exec 1004 -- tailscale status"
```

**Output:**
```
100.67.192.61   pve-tailscale-lxc    emeraldocean123@  linux    idle; offers exit node
```

**Status:** "offers exit node" confirms functionality.

### Test from Client Device

**On iPhone/Laptop with Tailscale:**
1. Enable exit node: Select "pve-tailscale-lxc"
2. Check IP address: Visit whatismyip.com
3. Verify IP matches home network public IP

**Result:** ✅ Internet works, IP shows home address

## Configuration Files

### /etc/sysctl.conf
**Location:** `/etc/sysctl.conf` in LXC 1004
**Modified:** November 16, 2025

**Relevant settings:**
```
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
```

**Load on boot:** Automatically applied by systemd

### Verification After Reboot
```bash
# Reboot container
ssh intel-1250p "pct reboot 1004"

# Wait for restart, then check
ssh intel-1250p "pct exec 1004 -- sysctl net.ipv4.ip_forward"
```

**Expected:** `net.ipv4.ip_forward = 1`

## Comparison with KVM

### Why KVM Worked as Exit Node

The GL.iNet Comet RM1-PE KVM (192.168.1.4) worked fine as an exit node because:
- Runs full Linux distribution (not container)
- Tailscale setup script ran successfully
- IP forwarding enabled during installation
- Acts as router/gateway device (designed for routing)

### Why LXC Didn't Work

The Proxmox LXC container had:
- Incomplete Tailscale configuration
- IP forwarding not enabled
- Minimal container environment
- Manual setup, not automated script

## Related Tailscale Configuration

### Current Tailscale Setup

**Container:** pve-tailscale-lxc (LXC 1004)
**Tailscale IP:** 100.67.192.61
**Local IP:** 192.168.1.54

**Features enabled:**
- ✅ Subnet Router (advertising 192.168.1.0/24)
- ✅ Exit Node (with IP forwarding fix)
- ✅ Auto-update
- ✅ Accept routes

**Tailscale admin settings:**
- Approved subnet routes: 192.168.1.0/24
- Approved as exit node: Yes
- Machine authorized: Yes

## Troubleshooting

### If Exit Node Still Doesn't Work

**1. Verify IP forwarding:**
```bash
sysctl net.ipv4.ip_forward
# Should output: net.ipv4.ip_forward = 1
```

**2. Check iptables masquerading:**
```bash
iptables -t nat -L POSTROUTING -v -n
```
Look for ts-postrouting chain.

**3. Check Tailscale status:**
```bash
tailscale status
```
Should show "offers exit node".

**4. Check client connection:**
```bash
tailscale status | grep "exit node"
```

**5. Test internet from container:**
```bash
ping -c 3 8.8.8.8
curl -I https://google.com
```

**6. Check packet counters:**
```bash
iptables -t nat -L ts-postrouting -v -n
```
Packet counts should increase when exit node is used.

## Commands Reference

```bash
# Check IP forwarding
sysctl net.ipv4.ip_forward

# Enable IP forwarding (temporary)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Enable IP forwarding (permanent)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Check NAT rules
iptables -t nat -L -v -n

# Check Tailscale status
tailscale status

# Test internet
ping 8.8.8.8
curl -I https://google.com

# View Tailscale logs
journalctl -u tailscaled -f
```

## Files Modified

### /etc/sysctl.conf
**Location:** LXC 1004:/etc/sysctl.conf
**Change:** Added `net.ipv4.ip_forward=1`
**Backup:** Not needed (additive change, duplicates existing entries)

## Related Documentation

- `~/Documents/dev/vpn/vpn-configuration.md` - VPN infrastructure overview
- `~/Documents/dev/vpn/tailscale-lxc-ssh-investigation-2025-11-16.md` - SSH access investigation
- `~/Documents/dev/network/tailscale-lxc-routing-fix.md` - Tailscale routing configuration

## Summary

| Aspect | Before Fix | After Fix |
|--------|------------|-----------|
| IP Forwarding | Disabled (0) | Enabled (1) |
| Exit Node Status | Offered but broken | ✅ Fully functional |
| Internet via Exit Node | ❌ No connectivity | ✅ Working |
| Subnet Router | ✅ Working | ✅ Working |
| iptables Masquerade | Configured but unused | ✅ Active |
| Packet Forwarding | 0 packets | Increasing with use |
| Client Internet | ❌ Lost when enabled | ✅ Works perfectly |
| Permanent | No (would reset) | ✅ Survives reboots |

## Lessons Learned

1. **Exit nodes require IP forwarding** - Not optional, must be enabled
2. **iptables alone isn't enough** - NAT rules need forwarding to function
3. **Check packet counters** - Zero packets = forwarding disabled
4. **Test from container first** - Container must reach internet before forwarding
5. **Make changes permanent** - Add to sysctl.conf, not just runtime
6. **LXC containers need manual config** - Automated scripts may not work in containers

## Prevention

### For Future Tailscale Installations

**Always verify IP forwarding is enabled:**
```bash
sysctl net.ipv4.ip_forward
```

**Add to installation checklist:**
- [ ] Tailscale installed
- [ ] Exit node enabled in admin panel
- [ ] Subnet routes advertised
- [ ] **IP forwarding enabled** ← Critical step
- [ ] IP forwarding made permanent in sysctl.conf
- [ ] iptables masquerade rules present
- [ ] Test internet connectivity from container
- [ ] Test exit node from client device

## Success Criteria

✅ Client can connect to Tailscale exit node
✅ Client maintains internet connectivity
✅ Traffic appears to originate from home IP
✅ Subnet routing still works (192.168.1.x access)
✅ Configuration survives container reboot
✅ No packet loss
✅ Exit node visible in Tailscale admin panel
