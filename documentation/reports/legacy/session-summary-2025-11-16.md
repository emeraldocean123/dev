# Session Summary - November 16, 2025

<!-- markdownlint-disable MD013 -->

**Topics:** Immich, DigiKam, Tailscale, Windows Port Exclusions
**Issues Resolved:** 3 major issues
**Documentation Created:** 4 comprehensive documents

## Session Overview

This session focused on troubleshooting and documenting several networking and configuration issues related to Immich photo management, DigiKam setup, and Tailscale VPN infrastructure.

## Issues Investigated and Resolved

### 1. Immich Web GUI Not Loading ✅

#### Issue

- Immich web interface stopped loading at `http://localhost:2283`
- Docker containers showed "healthy" but were inaccessible

#### Root Cause

- Windows Hyper-V/WSL2 dynamically reserved port range 2208-2307
- Port 2283 fell within this excluded range after system reboot
- Docker unable to bind to port 2283

#### Solution

- Changed Immich port mapping from `2283:2283` to `8080:2283`
- Updated `D:/Immich/docker-compose.yml`
- Restarted Immich stack
- Updated iOS app configuration to use port 8080

#### Documentation

- `~/Documents/dev/photos/immich-port-change-2025-11-16.md`
- `~/Documents/dev/documentation/guides/windows-docker-port-exclusions.md`

### 2. Tailscale Exit Node Blocking Internet ✅

#### Issue

- Tailscale LXC offering exit node but blocking internet traffic
- Clients lost connectivity when using exit node
- KVM exit node worked fine, but LXC did not

#### Root Cause

- IP forwarding disabled (`net.ipv4.ip_forward = 0`)
- Container could not route packets between interfaces
- NAT/masquerading rules existed but were not processing packets

#### Solution

- Enabled IP forwarding: `echo 1 > /proc/sys/net/ipv4/ip_forward`
- Made permanent: Added `net.ipv4.ip_forward=1` to `/etc/sysctl.conf`
- Verified internet forwarding works
- Tested from client devices

#### Documentation

- `~/Documents/dev/vpn/tailscale-exit-node-fix-2025-11-16.md`

### 3. Tailscale LXC SSH Access Investigation ✅

#### Issue

- Cannot SSH to Tailscale LXC from local network (192.168.1.x)
- Cannot ping container despite it being online
- SSH times out from Proxmox host and laptop

#### Root Cause

- NOT a bug - this is by design for security
- Container configured as Tailscale-only access
- SSH accessible via Tailscale network or Proxmox `pct exec` only
- Reduced attack surface (security feature)

#### Finding

- Container functioning correctly for intended purpose
- Tailscale routing works perfectly
- Exit node functional after IP forwarding fix
- Management access available via Proxmox console

#### Recommendation

- Leave as-is for better security
- Use `pct exec 1004` for local management
- Use Tailscale SSH for remote management

#### Documentation

- `~/Documents/dev/vpn/tailscale-lxc-ssh-investigation-2025-11-16.md`

## DigiKam Configuration (In Progress)

### Current State
- MariaDB 11.4 backend configured and running
- Database location: Docker container `digikam-mariadb` (192.168.1.109:3306)
- Initial scan at ~58% when user rebooted for GPU testing
- GPU acceleration working (NVIDIA RTX 5090)

### Optimal Settings Researched
Based on DigiKam 8.8 documentation for large libraries (82k+ images):

#### GPU Acceleration

- ✅ OpenCL hardware acceleration enabled
- ✅ OpenCL for AI models enabled
- ✅ Video hardware acceleration enabled
- ❌ Software OpenGL disabled (hardware mode active)

#### Metadata Configuration

- ✅ ExifTool backend for read/write operations
- ❌ Update file timestamps disabled (preserve originals)
- ✅ XMP sidecar-only writes (Immich compatibility)
- ✅ Commercial program compatible naming (filename.ext.xmp)
- ✅ Lossless rotation (flag-only method)
- ❌ No direct RAW/DNG file metadata writes

#### Performance Settings

- ❌ Scan at startup disabled (recommended for 82k+ images)
- Cache sizes optimized for 64GB RAM system
- Lazy synchronization enabled

#### ExifTool Version

- Updated path to use latest version (13.41)
- Created update script for bundled version (optional)
- Script: `~/Documents/dev/applications/digikam/scripts/update-digikam-exiftool.ps1`

### Next Steps for DigiKam
- Allow initial scan to complete (was at 58%)
- Optionally run ExifTool update script as administrator
- Verify scan completes successfully with new settings

## Files Created

### Documentation Files

1. **tailscale-lxc-ssh-investigation-2025-11-16.md**
   - Location: `~/Documents/dev/vpn/`
   - Content: Complete investigation of SSH access issue
   - Findings: By design, not a bug - security feature
   - Access methods documented

2. **tailscale-exit-node-fix-2025-11-16.md**
   - Location: `~/Documents/dev/vpn/`
   - Content: IP forwarding fix for exit node
   - Before/after comparison
   - Troubleshooting guide

3. **immich-port-change-2025-11-16.md**
   - Location: `~/Documents/dev/photos/`
   - Content: Port change from 2283 to 8080
   - Windows port exclusion explanation
   - iOS app update instructions

4. **windows-docker-port-exclusions.md**
   - Location: `~/Documents/dev/documentation/`
   - Content: General guide to Windows port exclusion issues
   - Safe port recommendations
   - Diagnosis and prevention strategies

### Script Files

1. **update-digikam-exiftool.ps1**
  - Location: `~/Documents/dev/applications/digikam/scripts/`
   - Purpose: Update DigiKam bundled ExifTool from 13.36 to 13.41
   - Status: Created, not yet executed (optional)
   - Requires: Administrator privileges

## Configuration Changes

### Docker Compose Files

**D:/Immich/docker-compose.yml**
- Line 26: Changed `'2283:2283'` to `'8080:2283'`
- Reason: Port 2283 blocked by Windows Hyper-V
- Status: ✅ Applied and verified

### LXC Container Configuration

**LXC 1004 (pve-tailscale-lxc) - /etc/sysctl.conf**
- Added: `net.ipv4.ip_forward=1`
- Reason: Enable exit node internet forwarding
- Status: ✅ Applied and permanent

### URLs Updated

#### Immich Access URLs

- Local: `http://localhost:8080` (was :2283)
- Network: `http://192.168.1.109:8080` (was :2283)
- Tailscale: `http://100.98.245.56:8080` (was :2283)
- iOS app: Updated to use port 8080

## Technical Findings

### Windows Port Exclusions

#### Current Excluded Ranges

```
Start Port    End Port
----------    --------
      1808        1907
      1908        2007
      2008        2107
      2108        2207
      2208        2307      ← Blocked Immich port 2283
      2308        2407
      2408        2507
      5357        5357
      50000       50059
```

#### Safe Ports for Docker Services

- 3000-3999 (development servers)
- 8000-8999 (web services) ← Used 8080 for Immich
- 9000-9999 (application servers)
- Standard service ports (3306, 5432, 6379, etc.)

#### Risky Ports

- 1800-2599 (frequently in Hyper-V ranges)
- 49152-65535 (ephemeral range)

### Tailscale LXC Networking

#### IP Addresses

- Local: 192.168.1.54/24 (eth0)
- Tailscale: 100.67.192.61 (tailscale0)

#### Functionality

- ✅ Subnet Router: Advertising 192.168.1.0/24
- ✅ Exit Node: Working after IP forwarding fix
- ✅ Internet Forwarding: NAT/masquerading functional
- ✅ Tailscale SSH: Accessible from Tailscale clients
- ✅ Proxmox Management: Via `pct exec 1004`
- ❌ Local Network SSH: Disabled by design (security)

#### iptables Configuration

- ts-input chain: Filters non-Tailscale traffic from CGNAT range
- ts-postrouting chain: MASQUERADE for exit node traffic
- Packet counters now increasing (was 0 before fix)

## Lessons Learned

### 1. Windows Port Exclusions are Dynamic
- Port ranges change without warning
- Affects Docker Desktop with WSL2 backend
- Check exclusions when containers fail to bind ports
- Use safe port ranges (8000-8999) for new services

### 2. IP Forwarding is Critical for Routing
- Exit nodes require IP forwarding enabled
- iptables rules alone are insufficient
- Zero packet counts indicate forwarding disabled
- Always make changes permanent in sysctl.conf

### 3. Security by Design May Look Like a Bug
- Tailscale LXC SSH behavior is intentional
- Limited access = reduced attack surface
- Multiple access methods exist (Tailscale, Proxmox)
- Investigate before "fixing" security features

### 4. Container Health ≠ Port Accessibility
- Docker can report "healthy" when ports blocked
- Health checks verify internal functionality only
- Always test external connectivity separately

## Tools and Commands Used

### Diagnostics
```bash
# Check Windows port exclusions
netsh interface ipv4 show excludedportrange protocol=tcp

# Check Docker container status
docker ps --filter name=<container>
docker inspect <container> | grep NetworkSettings

# Check IP forwarding
sysctl net.ipv4.ip_forward

# Check iptables rules
iptables -t nat -L -v -n

# Check Tailscale status
tailscale status

# Test connectivity
curl http://localhost:<port>
ping <ip-address>
```

### Fixes Applied
```bash
# Enable IP forwarding (immediate)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Enable IP forwarding (permanent)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Update Docker Compose port
sed -i "s/'2283:2283'/'8080:2283'/g" docker-compose.yml

# Restart Docker stack
docker-compose down && docker-compose up -d
```

## Documentation Organization

All documentation follows kebab-case naming convention:
- ✅ tailscale-lxc-ssh-investigation-2025-11-16.md
- ✅ tailscale-exit-node-fix-2025-11-16.md
- ✅ immich-port-change-2025-11-16.md
- ✅ windows-docker-port-exclusions.md
- ✅ session-summary-2025-11-16.md

Files organized by category:
- **VPN:** `~/Documents/dev/vpn/`
- **Photos:** `~/Documents/dev/photos/`
- **General:** `~/Documents/dev/documentation/`

## Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Immich | ✅ Working | Port changed to 8080 |
| Immich iOS App | ✅ Updated | Using port 8080 |
| MariaDB | ✅ Working | Port 3306 safe from exclusions |
| Tailscale Exit Node | ✅ Working | IP forwarding enabled |
| Tailscale Subnet Router | ✅ Working | No changes needed |
| Tailscale LXC SSH | ⚠️ By Design | Secure configuration |
| DigiKam Setup | 🔄 In Progress | Scan resuming, settings optimized |
| Documentation | ✅ Complete | 4 files created, all kebab-case |

## References

### Documentation Created
1. `~/Documents/dev/vpn/tailscale-lxc-ssh-investigation-2025-11-16.md`
2. `~/Documents/dev/vpn/tailscale-exit-node-fix-2025-11-16.md`
3. `~/Documents/dev/photos/immich-port-change-2025-11-16.md`
4. `~/Documents/dev/documentation/guides/windows-docker-port-exclusions.md`

### Scripts Created
1. `~/Documents/dev/applications/digikam/scripts/update-digikam-exiftool.ps1`

### Configuration Files Modified
1. `D:/Immich/docker-compose.yml`
2. LXC 1004: `/etc/sysctl.conf`

### Existing Documentation Referenced
- `~/Documents/dev/network/network-devices.md`
- `~/Documents/dev/network/tailscale-lxc-routing-fix.md`
- `~/Documents/dev/vpn/vpn-configuration.md`
- `~/Documents/dev/photos/photo-vault-architecture.md`
- `~/Documents/dev/photos/immich-hardware-transcoding.md`

## Next Steps

1. **DigiKam:**
   - Allow initial scan to complete
   - Optionally run ExifTool update script
   - Verify all settings applied correctly

2. **Testing:**
   - Test Immich from iOS app remotely
   - Test Tailscale exit node from mobile device
   - Verify MariaDB stability for DigiKam

3. **Optional:**
   - Update DigiKam's bundled ExifTool (admin required)
   - Document any additional DigiKam configuration discoveries

## Conclusion

Successfully investigated and resolved three major issues while creating comprehensive documentation. All fixes are permanent and properly documented. The session demonstrated the importance of understanding system architecture, checking for dynamic changes (like Windows port exclusions), and distinguishing between bugs and intentional security features.

**All documentation files follow kebab-case naming convention and are properly organized in the dev folder structure.**

<!-- markdownlint-enable MD013 -->
