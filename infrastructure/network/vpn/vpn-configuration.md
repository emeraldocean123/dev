# VPN Configuration

**Last Updated:** October 12, 2025
**Status:** Dual VPN setup - WireGuard (primary) + Tailscale (secondary)

## Overview

The network uses a redundant dual-VPN architecture for remote access:
- **Primary VPN:** WireGuard on UCG Fiber (always available)
- **Secondary VPN:** Tailscale on LXC container (convenience/mesh networking)

---

## Primary VPN: WireGuard on UCG Fiber

### Configuration

**Server Details:**
- **Location:** UCG Fiber Router (192.168.1.1)
- **Public Endpoint:** emeraldlake.synology.me:51820
- **VPN Subnet:** 192.168.3.0/24
- **Gateway IP:** 192.168.3.1
- **Protocol:** WireGuard (UDP)
- **Port:** 51820

**Routing:**
- VPN clients receive IPs in 192.168.3.0/24 range
- Gateway routes traffic to main LAN (192.168.1.0/24)
- Full network access to all devices

### Clients

| Name | VPN IP | Interface IP | Status |
|------|--------|--------------|--------|
| Joseph | 192.168.3.2 | Assigned | Active |

### DNS Configuration

**DDNS Provider:** Synology DDNS (emeraldlake.synology.me)
- **Why Synology:** Reliable updates, works with UDP protocols
- **Previous Issue:** Cloudflare DDNS caused handshake failures with WireGuard
- **Resolution:** Switched to Synology DDNS (already configured on Synology NAS)

### Advantages

✅ **Always Available:** Router runs 24/7, independent of server uptime
✅ **Critical Access:** Works even when 1250p is powered off
✅ **Native Integration:** Built into UCG Fiber router firmware
✅ **Full Network Access:** Routes to all 192.168.1.0/24 devices
✅ **Reliable DDNS:** Synology DDNS proven to work with WireGuard

### Use Cases

- Remote access when Proxmox hosts are offline
- Full network troubleshooting from remote locations
- Accessing router/switch/PDU management interfaces
- Backup VPN when Tailscale coordination servers are down
- Critical infrastructure that must always be accessible

### Client Configuration

**Typical WireGuard Client Config:**
```ini
[Interface]
PrivateKey = <client-private-key>
Address = 192.168.3.2/24
DNS = 192.168.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = emeraldlake.synology.me:51820
AllowedIPs = 192.168.1.0/24, 192.168.3.0/24
PersistentKeepalive = 25
```

---

## Secondary VPN: Tailscale on LXC Container

### Configuration

**Server Details:**
- **Location:** LXC 1004 on intel-1250p (192.168.1.54)
- **Container Name:** pve-tailscale-lxc
- **Tailscale IP:** 100.67.192.61
- **Account:** emeraldocean123@
- **Status:** Online (when 1250p is running)

**Features Enabled:**
- ✅ Subnet Router (advertises 192.168.1.0/24)
- ✅ Exit Node (route internet traffic through home)
- ✅ Accept Routes (receives routes from other Tailscale devices)

**IP Forwarding:**
- IPv4: Enabled (net.ipv4.ip_forward = 1)
- IPv6: Enabled (net.ipv6.conf.all.forwarding = 1)

### Tailscale Network Devices

| Device | Tailscale IP | Type | Status |
|--------|-------------|------|--------|
| pve-tailscale-lxc | 100.67.192.61 | linux | Online (offers exit node) |
| alienware-18-area51-aa18250-laptop | 100.98.245.56 | windows | Online |
| synology-1520-nas | 100.119.55.112 | linux | Online (offers exit node) |
| synology-223j-nas | 100.90.149.67 | linux | Online (offers exit node) |
| apple-imac-2019-desktop | 100.107.217.98 | macOS | Offline |
| apple-iphone-17-pro-max-phone | 100.71.36.27 | iOS | Offline |
| pve-tailscale-lxc-old | 100.107.3.126 | linux | Offline (replaced) |

### Advantages

✅ **Zero Configuration:** No manual client setup, automatic NAT traversal
✅ **Mesh Networking:** Direct peer-to-peer connections when possible
✅ **Mobile Friendly:** Easy setup on phones/tablets
✅ **Subnet Routing:** Access entire 192.168.1.0/24 network
✅ **Exit Node:** Route internet through home connection
✅ **ACLs:** Fine-grained access control via Tailscale admin
✅ **Key Rotation:** Automatic security key updates

### Use Cases

- Quick access to specific services (Immich, PBS, Proxmox)
- Mobile device access (iPhone, iPad)
- Easy sharing with family/friends
- Accessing home services without port forwarding
- Mesh networking between multiple devices
- Using home internet connection while traveling

### Access Services via Tailscale

Once connected to Tailscale network and subnet routes approved:

**Proxmox Hosts:**
- intel-1250p: https://192.168.1.40:8006
- intel-n6005: https://192.168.1.41:8006

**Services:**
- Immich: http://192.168.1.51:2283
- PBS Primary: https://192.168.1.52:8007
- PBS Replication: https://192.168.1.70:8007
- Portainer: http://192.168.1.50:9000

**Network Equipment:**
- Router: http://192.168.1.1
- Switch: http://192.168.1.2
- PDU: http://192.168.1.3

### Tailscale Admin Console

**Approval Required:**
After initial setup, approve in Tailscale admin console:
- Subnet routes: 192.168.1.0/24
- Exit node capability
- Access: https://login.tailscale.com/admin/machines

---

## Comparison: WireGuard vs Tailscale

| Feature | WireGuard (UCG Fiber) | Tailscale (LXC) |
|---------|----------------------|-----------------|
| **Availability** | 24/7 (router always on) | When 1250p is running |
| **Setup Complexity** | Manual client config | Zero-touch, automatic |
| **Network Access** | Full 192.168.1.0/24 | Full 192.168.1.0/24 (via subnet router) |
| **NAT Traversal** | Requires port forwarding | Automatic (DERP servers) |
| **DDNS Required** | Yes (emeraldlake.synology.me) | No (Tailscale coordination) |
| **Mobile Apps** | Standard WireGuard apps | Tailscale apps (easier) |
| **Performance** | Direct connection, fast | Direct when possible, RELAY when needed |
| **Security** | Self-managed keys | Automatic key rotation |
| **Use Case** | Critical always-on access | Convenience and mesh networking |
| **Dependencies** | Router only | LXC + Proxmox host |

---

## Recommended Usage Strategy

### Use WireGuard When:
- You need guaranteed access (critical maintenance)
- Proxmox hosts might be offline
- You need to troubleshoot network infrastructure
- Tailscale coordination servers are unreachable
- You want complete control over VPN configuration

### Use Tailscale When:
- Quick access to services (Immich, PBS)
- Adding new devices (easier setup)
- Mobile device access (better mobile apps)
- Sharing access with family/friends
- You want mesh networking between devices
- Need to route internet through home (exit node)

---

## Troubleshooting

### WireGuard

**Issue: Handshake Failure**
- Check DDNS resolution: `nslookup emeraldlake.synology.me`
- Verify port 51820 is open on WAN
- Confirm Synology NAS is updating DDNS
- Test direct WAN IP if DDNS fails

**Issue: Cannot Access LAN**
- Verify AllowedIPs includes 192.168.1.0/24
- Check routing table on router
- Confirm firewall rules allow VPN → LAN traffic

**Issue: Cloudflare DDNS Doesn't Work**
- Known issue: Cloudflare proxy mode breaks UDP
- Solution: Use Synology DDNS instead
- Alternative: Use Cloudflare in DNS-only mode (gray cloud)

### Tailscale

**Issue: Cannot Access Subnet Routes**
- Approve routes in Tailscale admin console
- Verify IP forwarding enabled in container
- Check firewall rules on LXC host

**Issue: Poor Performance**
- May be using DERP relay servers
- Check if direct connection established: `tailscale status`
- Verify UDP hole-punching isn't blocked

**Issue: Container Offline**
- WireGuard on UCG Fiber is backup solution
- Check if intel-1250p is powered on
- Verify LXC 1004 is running: `pct status 1004`

---

## Security Considerations

### WireGuard
- Keys must be manually managed and rotated
- Client configs should be encrypted/password protected
- Port 51820 exposed to internet (standard for VPN)
- DDNS endpoint is public knowledge

### Tailscale
- Keys automatically rotated by Tailscale
- Uses industry-standard WireGuard protocol
- ACLs provide fine-grained access control
- MFA available for Tailscale account
- Coordination servers are third-party (Tailscale, Inc.)

### Best Practices
- Use strong passwords for Tailscale account
- Enable MFA on Tailscale account
- Regularly audit connected devices
- Remove old/unused devices from both VPNs
- Keep WireGuard keys secure and rotated
- Monitor VPN logs for suspicious activity

---

## Maintenance

### WireGuard
- **DDNS Updates:** Managed automatically by Synology NAS
- **Firmware Updates:** Check after UCG Fiber updates (config should persist)
- **Key Rotation:** Manual process, recommended annually
- **Client Management:** Add/remove via UniFi Network UI

### Tailscale
- **Updates:** Automatic via Tailscale
- **Key Rotation:** Automatic (handled by Tailscale)
- **Device Management:** Via Tailscale admin console
- **Container Updates:** `apt update && apt upgrade` in LXC 1004

---

## Future Enhancements

### Potential Improvements
- Add more WireGuard clients as needed
- Configure Tailscale on mobile devices
- Set up Tailscale on Synology NAS for redundancy
- Implement Tailscale SSH (ssh via Tailscale network)
- Configure Tailscale MagicDNS for easier service access
- Add Tailscale to UCG Fiber (if supported in future firmware)

### Alternative Configurations
- Run Tailscale on UCG Fiber (currently not officially supported)
- Add Tailscale to n6005 as tertiary backup
- Use Tailscale Funnel for public service exposure
- Configure split-tunnel routing for specific services

---

## Documentation References

- **Network Inventory:** network-devices.md
- **SSH Configuration:** ~/.ssh/config
- **Container Setup:** LXC 1004 (pve-tailscale-lxc)
- **UCG Fiber VPN:** UniFi Network UI → VPN section
- **Tailscale Admin:** https://login.tailscale.com/admin/machines

## Support Resources

- **WireGuard:** https://www.wireguard.com/
- **Tailscale Docs:** https://tailscale.com/kb/
- **UniFi Community:** https://community.ui.com/
- **Synology DDNS:** Built into DSM Control Panel
