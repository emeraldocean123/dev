# VPN Configuration

VPN infrastructure configuration and documentation.

## Active VPN Solutions

### Tailscale
- Subnet router and exit node on LXC 1004 (192.168.1.54)
- Documentation in network/tailscale-lxc-routing-fix.md

### Hamachi NAT
- Static port NAT configuration for Hamachi VPN clients
- Deployed to UCG Fiber router

## Key Files

- **vpn-configuration.md** - VPN infrastructure overview
- **hamachi-nat.md** - Hamachi NAT configuration documentation
- **10-hamachi-nat.sh** - Hamachi NAT iptables script (deploys to router)
- **hamachi-nat.service** - Systemd service for Hamachi NAT

## Configuration

- **Hamachi Clients**: 192.168.1.100, 192.168.1.101
- **Router**: UCG Fiber (192.168.1.1)
- **Service Location**: `/data/on_boot.d/` on router
- **Systemd Service**: `/etc/systemd/system/hamachi-nat.service`

## Purpose

VPN infrastructure configuration, including Tailscale mesh network and Hamachi static port NAT for preserving source ports through the router.
