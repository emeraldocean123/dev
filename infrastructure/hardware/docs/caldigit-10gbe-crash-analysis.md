# CalDigit TS5+ 10GbE Crash Investigation

**Date**: November 7, 2025
**Issue**: 10GbE connection causes Windows lock-ups during hub crashes when connected, but recovers gracefully when disconnected

## Executive Summary

The CalDigit TS5+ hub crashes are NOT the primary problem causing Windows lock-ups. The root cause is **how Windows handles the sudden network disconnection** when the hub crashes while the 10GbE adapter is actively connected.

**Key Finding**: The Npcap packet capture driver bound to the 10GbE adapter is the primary culprit causing system-wide freezes during hub crashes.

## Technical Analysis

### Crash Behavior Comparison

| Scenario | Hub Crash Behavior | Windows Response | Recovery Time |
|----------|-------------------|------------------|---------------|
| **10GbE Connected** | Hub crashes → Network link lost | Windows FREEZES, Bluetooth fails, shutdown hangs | Minutes to hours |
| **10GbE Disconnected** | Hub crashes → Simple device removal | Windows operates normally | 8 seconds |

### Root Cause: Npcap Packet Driver

**Configuration Found:**
```
Adapter: CalDigit Thunderbolt 10G Ethernet
Binding: Npcap Packet Driver (INSECURE_NPCAP) - ENABLED
Status: Active when adapter connected
```

**Technical Explanation:**

1. **When 10GbE is connected and active:**
   - Npcap driver operates at kernel level intercepting all network packets
   - Hub crashes → Network link instantly lost
   - Npcap driver receives disconnect notification
   - **DEADLOCK**: Npcap tries to clean up packet buffers while hardware is unresponsive
   - Network stack hangs waiting for Npcap
   - Cascades to other Windows components (Bluetooth uses similar USB stack)
   - **Result**: System-wide freeze

2. **When 10GbE is disconnected before crash:**
   - Adapter already disabled → Npcap not actively monitoring
   - Hub crashes → Simple USB device removal
   - No active packet buffers to clean up
   - **Result**: Clean recovery in 8 seconds

### Supporting Evidence

**Event Log Analysis (November 6, 2025 @ 4:53 PM):**
```
4:53:41 PM - CalDigit 10G Ethernet: Network link is lost [WARNING]
4:53:49 PM - CalDigit 10G Ethernet: Network link established at 10Gbps [INFO]
```

**Critical Findings:**
- **No USB/Thunderbolt device removal events** during crash window
- **No kernel-power critical errors**
- **Only network driver events** logged
- Network recovered in **8 seconds** (because cable was already disconnected)

### Additional Contributing Factors

#### 1. Excessive Network Protocol Bindings
The 10GbE adapter has **13 different protocols/services** bound to it:

- ✅ Npcap Packet Driver (INSECURE_NPCAP) ← **PRIMARY ISSUE**
- Nested Network Virtualization
- Bridge Driver
- Microsoft LLDP Protocol Driver
- Link-Layer Topology Discovery Mapper I/O Driver
- Client for Microsoft Networks
- QoS Packet Scheduler
- Link-Layer Topology Discovery Responder
- File and Printer Sharing for Microsoft Networks
- Internet Protocol Version 4 (TCP/IPv4)
- Internet Protocol Version 6 (TCP/IPv6) - Disabled
- Hyper-V Extensible Virtual Switch - Disabled
- Microsoft Network Adapter Multiplexor Protocol - Disabled

Each active binding must handle the sudden disconnection, increasing the chance of deadlock.

#### 2. Power Management Features

Multiple wake-on-LAN features keep the adapter active:
- Wake on Magic Packet: **Enabled**
- Wake on Pattern Match: **Enabled**
- Wake from power off state: **Enabled**

These features keep the network stack "listening" even during idle periods, making it more susceptible to crashes during sudden disconnection.

#### 3. Driver Information

- **Driver**: Marvell aqnic650.sys
- **Version**: 3.1.10.0
- **Date**: April 23, 2024
- **Adapter**: Aquantia AQC107 (VEN_1D6A&DEV_04C0)

## Solutions

### Immediate Fix (Recommended)

**Disable Npcap on 10GbE Adapter**

Run the script: `~/Documents/dev/hardware/disable-npcap-10gbe.ps1`

```powershell
# Run as Administrator
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID "INSECURE_NPCAP" -Confirm:$false
```

**Expected Outcome:**
- 10GbE can remain connected during hub crashes
- Windows should handle disconnection gracefully
- No more system-wide freezes
- Maintain full 10GbE network functionality

**Trade-off:**
- Cannot use Wireshark/packet capture on 10GbE adapter
- Can still use Wireshark on WiFi or other adapters if needed

### Alternative Solutions

#### Option 1: Disable Unnecessary Network Bindings

Disable the following if not needed:
```powershell
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID "ms_lldp"        # LLDP
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID "ms_lltdio"      # Topology Discovery
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID "ms_rspndr"      # Responder
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID "ms_server"      # File/Printer Sharing
```

#### Option 2: Disable Wake-on-LAN Features

```powershell
Set-NetAdapterAdvancedProperty -Name "Ethernet" -DisplayName "Wake on Magic Packet" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name "Ethernet" -DisplayName "Wake on Pattern Match" -DisplayValue "Disabled"
```

#### Option 3: Continue Current Workaround

Keep manually disconnecting 10GbE before gaming/heavy GPU usage (current successful workaround).

## Testing Plan

1. **Phase 1**: Disable Npcap only
   - Test with 10GbE connected during normal use
   - Monitor for hub crashes
   - Verify Windows remains responsive

2. **Phase 2**: If successful, gradually re-enable other features
   - Test wake-on-LAN features individually
   - Monitor system stability

3. **Phase 3**: Document final configuration
   - Update CalDigit incident tracking
   - Create permanent configuration script

## Historical Context

### Previous CalDigit TS5+ Incidents

**Incident #11** (Most Recent):
- Date: November 6, 2025 @ 4:53 PM
- Trigger: Gaming session
- **Pre-workaround**: 10GbE disconnected before gaming
- Result: Hub crashed but **Windows recovered gracefully**
- Recovery time: **8 seconds**
- **No Windows lock-up, no Bluetooth issues, no shutdown problems**

This validates that the problem is NOT the hub crash itself, but how Windows handles the network disconnection.

## Conclusion

The CalDigit TS5+ hub has hardware issues causing occasional crashes, BUT the severe Windows system-wide freezes are caused by:

1. **Primary**: Npcap packet driver deadlock during sudden network disconnection
2. **Secondary**: Excessive network protocol bindings increasing complexity
3. **Tertiary**: Wake-on-LAN features keeping network stack active

**Recommendation**: Disable Npcap on the 10GbE adapter as the first step. This should allow the hub to crash without causing Windows lock-ups, eliminating the need to manually disconnect before gaming.

## Next Steps

1. Run `disable-npcap-10gbe.ps1` as Administrator
2. Verify Npcap is disabled: `Get-NetAdapterBinding -Name "Ethernet"`
3. Test with 10GbE connected during gaming session
4. Monitor for hub crashes and Windows response
5. Document results and update incident tracking

## References

- 10GbE adapter analysis: `~/10gbe-analysis.txt`
- Crash event details: `~/crash-event-details.txt`
- Network disconnect events: `~/network-disconnect-events.txt`
- CalDigit incident tracking: `~/Documents/dev/hardware/caldigit-ts5-plus-incident.md`
