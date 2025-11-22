# Switch Port Layout
**Device:** Unifi USW Pro XG-24 (192.168.1.2)
**Hardware Address:** 84:78:48:72:ef:ab
**Last Updated:** October 10, 2025
**Source:** Unifi Network Application + SSH verification

## Switch Overview

**Model:** USW-Pro-XG-24
**Total Ports:** 26 (24 RJ45 + 2 SFP28)
- **Ports 1-24:** 10GBASE-T RJ45
- **Ports 25-26:** SFP28+ (10G fiber)

**Management IP:** 192.168.1.2
**Connected to Router:** Port 25 (SFP28+) via 10 GbE fiber uplink

## UCG Fiber Router Ports (Reference)

The router has 8 ports (5 LAN + 1 WAN + 2 SFP+):

| Port | Name                         | Speed   | Status      | Description                                  |
|------|------------------------------|---------|-------------|----------------------------------------------|
| 1    | Port 1                       | Auto    | Unused      | Available                                    |
| 2    | Port 2                       | Auto    | Unused      | Available                                    |
| 3    | Port 3                       | Auto    | Unused      | Available                                    |
| 4    | Port 4                       | Auto    | Unused      | Ethernet with PoE+                           |
| 5    | Port 5 xfinity-xb8-wan-modem | Auto    | Connected   | Xfinity XB8 Gateway                          |
| 6    | SFP+ 1 unifi-usw-pro-xg-24   | 10 GbE  | Connected   | Unifi USW Pro XG-24 Switch                   |
| 7    | SFP+ 2                       | -       | Unused      | Available                                    |

## Switch Port Status Summary

**Active Ports:** 12
**Inactive Ports:** 14

## Detailed Port Layout (USW-Pro-XG-24)

### RJ45 Ports (1-24)

| Port | Name                                          | Speed    | Status      | MAC Address        | IP Address     | Description                           |
|------|-----------------------------------------------|----------|-------------|--------------------|----------------|---------------------------------------|
| 1    | Port 1 unifi-usp-pdu-pro-power                | 1 GbE    | Connected   | 6c:63:f8:ec:fd:73  | 192.168.1.3    | Unifi Power Distribution Pro          |
| 2    | Port 2 sewing-door-bedroom                    | Auto     | Unused      | -                  | -              | Sewing Bedroom                        |
| 3    | Port 3 sewing-garage-bedroom                  | Auto     | Unused      | -                  | -              | Sewing Bedroom                        |
| 4    | Port 4 master-bedroom                         | Auto     | Unused      | -                  | -              | Master Bedroom                        |
| 5    | Port 5 guest-bedroom                          | Auto     | Unused      | -                  | -              | Guest Bedroom                         |
| 6    | Port 6 study-bedroom                          | Auto     | Unused      | -                  | -              | Study Bedroom                         |
| 7    | Port 7                                        | Auto     | Unused      | -                  | -              | Available                             |
| 8    | Port 8                                        | Auto     | Unused      | -                  | -              | Available                             |
| 9    | Port 9 xfinity-xb8-wan-modem                  | Auto     | Unused      | -                  | -              | Xfinity XB8 Gateway                   |
| 10   | Port 10 unifi-ucg-wan-router                  | Auto     | Unused      | -                  | -              | Unifi Cloud Gateway Fiber             |
| 11   | Port 11 intel-1250p-wan-opnsense-router       | Auto     | Unused      | -                  | -              | Intel 1250P OPNsense WAN              |
| 12   | Port 12 linksys-mx4200-wan-joe-router         | 1 GbE    | Connected   | c4:41:1e:fa:dd:d4  | 192.168.1.5    | Linksys MX4200 Joe                    |
| 13   | Port 13 linksys-mx4200-lan-joe-router         | 1 GbE    | Connected   | c4:41:1e:fa:dd:d4  | 192.168.1.5    | Linksys MX4200 Joe                    |
| 14   | Port 14 linksys-mx4200-wan-mark-router        | Auto     | Unused      | -                  | -              | Linksys MX4200 Mark                   |
| 15   | Port 15 linksys-mx4200-wan-kitchen-router     | 1 GbE    | Connected   | ec:71:db:c7:42:84  | 192.168.1.6    | Linksys MX4200 Kitchen                |
| 16   | Port 16 linksys-mx4200-wan-family-router      | 1 GbE    | Connected   | c4:41:1e:fa:dd:bb  | 192.168.1.7    | Linksys MX4200 Family                 |
| 17   | Port 17 linksys-mx4200-wan-gazebo-router      | Auto     | Unused      | -                  | -              | Linksys MX4200 Gazebo                 |
| 18   | Port 18 intel-1250p-pve-host                  | 2.5 GbE  | Connected   | a8:b4:e0:07:9b:cd  | 192.168.1.40   | Intel 1250P PVE Host                  |
| 19   | Port 19 intel-n6005-pve-host                  | 2.5 GbE  | Link Up     | -                  | -              | Intel N6005 PVE Host                  |
| 20   | Port 20 synology-1520-nas                     | 10 GbE   | Link Up     | 00:11:32:ff:4a:a5  | 192.168.1.10   | Synology DS1520+ Port 1 (Bond Member) |
| 21   | Port 21 synology-1520-nas                     | 10 GbE   | Link Up     | 00:11:32:ff:4a:a5  | 192.168.1.10   | Synology DS1520+ Port 2 (Bond Member) |
| 22   | Port 22 synology-1520-nas                     | 10 GbE   | Link Up     | 00:11:32:ff:4a:a5  | 192.168.1.10   | Synology DS1520+ Port 3 (Bond Member) |
| 23   | Port 23 synology-1520-nas                     | 10 GbE   | Link Up     | 00:11:32:ff:4a:a5  | 192.168.1.10   | Synology DS1520+ Port 4 (Bond Member) |
| 24   | Port 24 joe-desk                              | 10 GbE   | Connected   | 64:4b:f0:60:09:40  | 192.168.1.109  | CalDigit TS5Plus → Alienware Laptop   |

### SFP28+ Ports (25-26)

| Port | Name                                          | Speed    | Status      | MAC Address        | IP Address      | Description                          |
|------|-----------------------------------------------|----------|-------------|--------------------|-----------------|--------------------------------------|
| 25   | SFP28 1 unifi-ucg-fiber-lan-router            | 10 GbE   | Connected   | 94:2a:6f:f6:0c:5d  | 73.93.188.131   | UCG Fiber Router Uplink (PRIMARY)    |
| 26   | SFP28 2 intel-1250p-pve-host lan-opnsense     | 10 GbE   | Connected   | -                  | -               | Intel 1250P PVE Host (PRIMARY)       |

## Port Groups by Function

### Network Infrastructure
- **Port 25 (SFP28 1):** Uplink to UCG Fiber Router @ 10G ✓ **PRIMARY UPLINK**
- **Port 26 (SFP28 2):** Intel 1250P PVE Host @ 10G ✓ **PRIMARY**

### Power Management
- **Port 1:** Unifi Power Distribution Pro @ 1G ✓

### Proxmox Infrastructure
- **Port 26:** Intel 1250P PVE Host @ 10G ✓ **PRIMARY**
- **Port 18:** Intel 1250P PVE Host @ 2.5G ✓
- **Port 19:** Intel N6005 PVE Host @ 2.5G

**Current Configuration:** Port 26 (10G) is the primary PVE host connection.

**Alternative Configuration (OPNsense VM):**
- Port 11 would receive WAN from Xfinity (via patch panel jumper: Port 9 > Port 11)
- Port 26 (10G) would be dedicated to OPNsense VM
- Port 18 (2.5G) would become PVE host management

### Mesh Router Network (Linksys MX4200)
- **Port 12:** Linksys MX4200 Joe @ 1G ✓
- **Port 13:** Linksys MX4200 Joe @ 1G ✓
- **Port 15:** Linksys MX4200 Kitchen @ 1G ✓
- **Port 16:** Linksys MX4200 Family @ 1G ✓
- **Port 14:** Linksys MX4200 Mark
- **Port 17:** Linksys MX4200 Gazebo

### Storage - Synology DS1520+ NAS (Link Aggregation)
**Configuration:** 4-port 802.3ad LACP Bond (40 Gbps aggregate bandwidth)
- **Port 20:** Synology Port 1 @ 10G - Bond Member ✓
- **Port 21:** Synology Port 2 @ 10G - Bond Member ✓
- **Port 22:** Synology Port 3 @ 10G - Bond Member ✓
- **Port 23:** Synology Port 4 @ 10G - Bond Member ✓

**Note:** All 4 ports bonded together as single logical interface
**Aggregate Bandwidth:** Up to 40 Gbps (4 × 10G)
**Device Status:** Offline/powered down (link shows up but no traffic)
**IP Address:** 192.168.1.10 (when online)

### Workstations
- **Port 24:** Joe Desk @ 10G ✓
  - Connected via: CalDigit TS5Plus Thunderbolt Dock
  - Current device: Alienware 18 Area-51 Laptop
  - IP: 192.168.1.109

### Reserved/Planned Ports (Labeled but Unused)
- **Port 9:** Xfinity XB8 Gateway
- **Port 10:** Unifi Cloud Gateway Fiber
- **Port 11:** Intel 1250P OPNsense WAN

**Patch Panel Jumper Configuration:**
- **Current (UCG Fiber active):** Port 9 > Port 10 jumpered
- **Alternative (OPNsense active):** Port 9 > Port 11 would be jumpered
  - Port 26 (10G) would be dedicated to OPNsense VM
  - Port 18 (2.5G) would be PVE host management

### Bedroom Ethernet Drops (Available for Use)
- **Port 2:** Sewing Bedroom
- **Port 3:** Sewing Bedroom
- **Port 4:** Master Bedroom
- **Port 5:** Guest Bedroom
- **Port 6:** Study Bedroom

### Unassigned Ports
- **Port 7-8:** Available

## Active Connections Summary

| Speed        | Port Count | Ports           | Status                    |
|--------------|------------|-----------------|---------------------------|
| 10 GbE       | 7          | 20-26           | 5 Active, 2 Link Up       |
| 2.5 GbE      | 2          | 18-19           | 1 Active, 1 Link Up       |
| 1 GbE        | 5          | 1, 12-13, 15-16 | All Active ✓              |
| Unused       | 12         | 2-11, 14, 17    | Available/Reserved        |

## Network Topology

```
[Internet/WAN]
      ↓
[UCG Fiber Router - 192.168.1.1]
  Port 5 (WAN): Xfinity Cable Modem
  SFP+ 1 (Port 6): 10G Fiber ↓
      ↓
[USW Pro XG-24 Switch - 192.168.1.2]
  Port 25 (SFP28 1): PRIMARY UPLINK
      ↓
  ├─ Port 1:      PDU @ 1G
  ├─ Port 12-13:  Joe Router @ 1G (iMac Desktop)
  ├─ Port 15-16:  Kitchen & Family Routers @ 1G
  ├─ Port 18:     Intel 1250P Proxmox Management @ 2.5G
  │   ├─ Docker (192.168.1.50)
  │   ├─ Immich (192.168.1.51)
  │   └─ PBS (192.168.1.52)
  ├─ Port 20-23:  Synology NAS @ 40G aggregate (4×10G bond) - offline
  ├─ Port 24:     Joe Desk (CalDigit/Alienware) @ 10G
  └─ Port 26:     Intel 1250P OPNsense @ 10G
```

## Performance Notes

- **Router-Switch Uplink:** 10G fiber (SFP+) - no bottleneck
- **Proxmox Management:** 2.5G on Port 18 for host management
- **Proxmox Secondary:** 10G on Port 26 for OPNsense VM and other services
- **Workstation:** Full 10G via CalDigit Thunderbolt dock - excellent performance
- **Mesh Network:** Multiple 1G connections adequate for WiFi distribution
- **NAS:** 4×10G LACP bond = 40 Gbps aggregate (currently offline/powered down)

## Traffic Statistics (from Unifi App)

| Port | Description           | Transmitted | Received | Tx Rate    | Rx Rate    |
|------|-----------------------|-------------|----------|------------|------------|
| 18   | Intel 1250P Proxmox   | 6.56 GB     | 3.69 GB  | 6.79 Mbps  | 693 bps    |
| 24   | Joe Desk Workstation  | 397 GB      | 639 GB   | 311 Mbps   | 272 Mbps   |
| 25   | Router Uplink         | 93.0 GB     | 273 GB   | 18.1 Mbps  | 324 Mbps   |

**Notable:** Port 24 shows heavy usage (1+ TB combined) indicating active development/media work

## Switch Management

**SSH Access:** `ssh switch` (192.168.1.2)
**User:** follett
**Model:** USW-Pro-XG-24
**Hostname:** unifi-usw-pro-xg-24-switch
**Firmware:** 7.2.103+

## Important Notes

### Synology NAS Configuration
- **Bond Type:** 802.3ad LACP (Link Aggregation Control Protocol)
- **Aggregate Bandwidth:** 40 Gbps (4 × 10G ports bonded)
- **Load Balancing:** Dynamic across all 4 links
- **Redundancy:** If one link fails, continues on remaining 3 ports
- **Current Status:** Device powered down, but switch ports show link up
- **MAC Address:** All 4 ports use same MAC (00:11:32:ff:4a:a5) in bond

### Port Naming Convention
- Port labels include planned devices even if not currently connected
- Bedroom drops (2-6) are infrastructure-ready but unused
- Reserved ports (9-11) labeled for potential future WAN configurations

### Capacity Planning
- 12 unused/offline ports available for expansion
- All RJ45 ports support 10GBASE-T (auto-negotiation down to 100M)
- SFP28+ ports can support up to 25G with appropriate transceivers
- Current utilization: ~46% (12 active of 26 total ports)
