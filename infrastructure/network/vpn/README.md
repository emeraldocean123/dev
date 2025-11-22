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
- **10-hamachi-nat.sh.template** - Hamachi NAT iptables script template (requires deployment injection)
- **hamachi-nat.service** - Systemd service for Hamachi NAT

## ⚠️ Template Deployment

**10-hamachi-nat.sh.template** is a TEMPLATE file with placeholders that must be replaced before deployment.

**Placeholders:**
- `{{VPN_CLIENT_1}}` - Hamachi client 1 IP address
- `{{VPN_CLIENT_2}}` - Hamachi client 2 IP address

**Deployment Command:**
```powershell
# Load config and inject values
$config = Get-Content .config/homelab.settings.json | ConvertFrom-Json
$script = (Get-Content infrastructure/network/vpn/10-hamachi-nat.sh.template -Raw) `
    -replace '{{VPN_CLIENT_1}}', $config.Network.VPN.Client1 `
    -replace '{{VPN_CLIENT_2}}', $config.Network.VPN.Client2

# Deploy to router
$script | ssh router "cat > /data/on_boot.d/10-hamachi-nat.sh && chmod +x /data/on_boot.d/10-hamachi-nat.sh"
```

**Required Config (homelab.settings.json):**
```json
{
  "Network": {
    "VPN": {
      "Client1": "192.168.1.100",
      "Client2": "192.168.1.101"
    }
  }
}
```

## Configuration

- **Hamachi Clients**: 192.168.1.100, 192.168.1.101
- **Router**: UCG Fiber (192.168.1.1)
- **Service Location**: `/data/on_boot.d/` on router
- **Systemd Service**: `/etc/systemd/system/hamachi-nat.service`

## Purpose

VPN infrastructure configuration, including Tailscale mesh network and Hamachi static port NAT for preserving source ports through the router.
