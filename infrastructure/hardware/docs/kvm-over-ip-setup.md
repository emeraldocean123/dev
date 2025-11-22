# KVM-over-IP Setup

**Last Updated:** October 12, 2025
**Status:** Planned - Hardware arriving tomorrow

## Overview

Remote BIOS and console access for Proxmox hosts using GL.iNet Comet KVM-over-IP with hardware KVM switch for multi-device support.

## Hardware Components

### Primary Device: GL.iNet Comet PoE (GL-RM1PE)
- **Model:** GL-RM1PE
- **Type:** KVM-over-IP with PoE support
- **Video:** 4K@30Hz HDMI capture
- **Storage:** 32GB eMMC
- **Network:** Tailscale support for remote access
- **Power:** PoE 802.3af/at or USB-C
- **IP Address:** 192.168.1.80 (static DHCP reservation)

### KVM Switch: 2-Port HDMI KVM
- **Model:** HDMI KVM Switch 2 Port
- **Resolution:** 4K@60Hz
- **USB:** USB 2.0 for keyboard/mouse emulation
- **Switching:** Physical button + hotkey (Scroll Lock 2x)
- **Purpose:** Toggle between n6005 and 1250p

## Network Configuration

**Power Source:**
- UCG Fiber Router Port 4 (PoE+)
- Single cable solution (power + network)

**Network Connection:**
- Device: GL.iNet Comet
- Connection: UCG Fiber Router Port 4
- IP: 192.168.1.80 (static DHCP reservation)
- Access: `http://192.168.1.80` (local), Tailscale (remote)

## Physical Setup

### Cable Topology

```
Intel N6005 (Port 19)              Intel 1250P (Port 18)
    │                                   │
    ├─ HDMI ──┐                    ┌─── HDMI
    └─ USB ───┤                    ├─── USB
              │                    │
         ┌────┴────────────────────┴────┐
         │   HDMI KVM Switch (2-port)   │
         │   Button/Hotkey switching    │
         └────┬─────────────────────────┘
              │
              ├─ HDMI Output
              └─ USB Output
              │
         ┌────┴──────────────────────────┐
         │   GL.iNet Comet (KVM-over-IP) │
         │   192.168.1.80                │
         └────┬──────────────────────────┘
              │
              └─ Ethernet (PoE)
                     │
         ┌───────────┴──────────────┐
         │  UCG Fiber Router Port 4 │
         │  PoE+ Power + Network    │
         └──────────────────────────┘
```

### Connection Details

**Input 1 - Intel N6005:**
- HDMI: n6005 HDMI out → KVM Input 1 HDMI
- USB: n6005 USB port → KVM Input 1 USB

**Input 2 - Intel 1250P:**
- HDMI: 1250p HDMI out → KVM Input 2 HDMI
- USB: 1250p USB port → KVM Input 2 USB

**KVM Output:**
- HDMI: KVM Output → GL.iNet Comet HDMI IN
- USB: KVM Output → GL.iNet Comet USB OUT

**GL.iNet Power/Network:**
- Ethernet: GL.iNet → UCG Fiber Router Port 4 (PoE)
- Power: Via PoE (802.3af/at)

## Usage

### Local Access

1. Open browser: `http://192.168.1.80`
2. Login to GL.iNet web interface
3. View current device (n6005 or 1250p)
4. To switch devices:
   - Press physical button on KVM switch, OR
   - Press Scroll Lock twice (hotkey)
5. Refresh browser to see new device

### Remote Access (Tailscale)

1. Configure Tailscale on GL.iNet Comet
2. Access from anywhere: `http://<tailscale-ip>`
3. Full BIOS access remotely
4. Switch between servers using KVM hotkey

### Common Tasks

**Access n6005 BIOS:**
1. Ensure KVM is switched to Input 1 (n6005)
2. Open browser: `http://192.168.1.80`
3. Power on n6005 (manual or wait for RTC wake at 3:00 AM)
4. Press Del/F2 via browser keyboard to enter BIOS
5. Navigate BIOS settings (disable POST beep)

**Access 1250p BIOS:**
1. Press KVM switch button or hotkey to switch to Input 2
2. Refresh browser
3. Power cycle 1250p if needed
4. Press Del/F2 via browser keyboard

**Troubleshoot Boot Issues:**
1. Switch to affected server via KVM
2. View POST messages in browser
3. Access BIOS/GRUB menu
4. No physical access required

## Static DHCP Configuration

Add to router DHCP reservations:

```bash
# UCG Fiber Router DHCP Reservation
Device: gl-inet-comet-kvm
MAC: <to be determined after setup>
IP: 192.168.1.80
```

## Router Port Configuration

**UCG Fiber Router Port 4:**
- **Before:** Unused (labeled "Ethernet with PoE+")
- **After:** GL.iNet Comet KVM-over-IP
- **Status:** Active @ Auto (1 Gbps expected)
- **PoE:** Active (powering GL.iNet Comet)
- **Purpose:** Remote BIOS/console access for Proxmox hosts

## Installation Checklist

### Hardware Setup
- [ ] Connect n6005 HDMI → KVM Input 1
- [ ] Connect n6005 USB → KVM Input 1
- [ ] Connect 1250p HDMI → KVM Input 2
- [ ] Connect 1250p USB → KVM Input 2
- [ ] Connect KVM HDMI Output → GL.iNet HDMI IN
- [ ] Connect KVM USB Output → GL.iNet USB OUT
- [ ] Connect GL.iNet Ethernet → UCG Router Port 4

### Software Setup
- [ ] Power on GL.iNet (via PoE)
- [ ] Find IP address (check router DHCP leases)
- [ ] Access web interface: `http://<dhcp-ip>`
- [ ] Configure static IP or create DHCP reservation (192.168.1.80)
- [ ] Test video capture from n6005
- [ ] Test KVM switch toggle to 1250p
- [ ] Configure Tailscale for remote access (optional)
- [ ] Update network documentation

### BIOS Configuration
- [ ] Access n6005 BIOS via KVM
- [ ] Disable POST beep
- [ ] Save BIOS settings
- [ ] Test 1250p BIOS access

## Advantages

### vs Physical Access
- No cable swapping
- No monitor/keyboard required
- Access from desk via browser
- Remote access via Tailscale

### vs Individual KVM Units
- Lower cost (~$130 vs ~$200 for two units)
- Single device to manage
- Quick switching via button/hotkey
- Only uses one PoE port

### vs Traditional KVM Switch Only
- Remote browser access
- No physical presence required
- Tailscale for anywhere access
- Record sessions (32GB eMMC)

## Use Cases

### Routine
- Disable n6005 POST beep (one-time BIOS change)
- Check BIOS settings without physical access
- Monitor POST messages during boot

### Troubleshooting
- Boot failures (GRUB menu, kernel panic)
- BIOS configuration issues
- Hardware detection problems
- Container boot issues

### Maintenance
- BIOS updates
- Boot order changes
- Hardware configuration
- Emergency console access

## Limitations

- Only one server viewable at a time (must switch via KVM)
- Requires manual button press or hotkey to switch
- 4K@30Hz limit (sufficient for BIOS/console)
- Cannot control which server is active from browser (hardware switch only)

## Future Enhancements

### Possible Upgrades
- Add third input (if needed for other devices)
- Implement automated switching via smart KVM
- Add power control relays for remote reboot
- Configure session recording for troubleshooting

### Alternative Configurations
- Move to 4-port KVM for additional servers
- Add second GL.iNet unit for dedicated per-host access
- Integrate with Proxmox monitoring for automatic console access

## Security Considerations

- GL.iNet behind firewall (no direct internet exposure)
- Tailscale for secure remote access (if configured)
- BIOS-level access - protect credentials
- Consider VPN-only access for production environments

## Troubleshooting

### No Video Signal
1. Check HDMI cable connections
2. Verify KVM switch has power
3. Press KVM button to cycle inputs
4. Check server is powered on

### Keyboard/Mouse Not Working
1. Verify USB connection from KVM to GL.iNet
2. Check USB connection from KVM to target server
3. Try different USB port on server
4. Restart GL.iNet web interface

### Cannot Access Web Interface
1. Verify GL.iNet has PoE power (LED indicators)
2. Check router DHCP leases for IP address
3. Verify network cable connection
4. Try accessing via IP instead of hostname

### KVM Switch Not Toggling
1. Press physical button firmly
2. Try hotkey: Scroll Lock, Scroll Lock (2x quickly)
3. Check KVM switch LED indicators
4. Verify both inputs are connected

## Documentation Updates

After installation, update these files:
- `network-devices.md` - Add GL.iNet Comet entry
- `switch-port-layout.md` - Document UCG Port 4 usage
- `router-dhcp-config.md` - Add static DHCP reservation

## Support Resources

- GL.iNet Comet documentation: https://docs.gl-inet.com/
- GL.iNet support forum: https://forum.gl-inet.com/
- Tailscale setup guide: https://tailscale.com/kb/

## Cost Summary

| Item | Cost | Purpose |
|------|------|---------|
| GL.iNet Comet PoE | $99 | KVM-over-IP capture device |
| 2-Port HDMI KVM | ~$30 | Hardware switching between servers |
| **Total** | **~$130** | Complete remote BIOS access solution |

**vs Two GL.iNet Units:** Saves ~$70 while providing access to both servers

## Notes

- GL.iNet Comet arriving: October 13, 2025
- KVM switch ordered: October 12, 2025
- Primary goal: Disable n6005 POST beep in BIOS
- Secondary benefit: Remote troubleshooting capability for both Proxmox hosts
- PoE powered - no additional power adapter needed
- One-time setup, permanent remote access solution
