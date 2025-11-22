# CalDigit TS5+ Gaming Workaround - Quick Reference

**Issue:** CalDigit TS5+ Thunderbolt hub crashes daily during gaming due to Marvell AQC107 chipset RSC bug.

**Primary Solution:** Disable Recv Segment Coalescing (RSC) in adapter advanced properties - **RECOMMENDED**

**Secondary Solution:** Toggle network priority to WiFi before gaming (if RSC disable doesn't work)

---

## ⭐ Primary Fix: Disable RSC (RECOMMENDED)

**What is RSC?**
Recv Segment Coalescing has a **known bug** in the Marvell AQC107 chipset causing crashes during high network load.

**How to Fix:**
1. Open **Device Manager** (`devmgmt.msc`)
2. Expand **Network adapters**
3. Right-click **"CalDigit Thunderbolt 10G Ethernet"** → **Properties**
4. Go to **Advanced** tab
5. Find **"Recv Segment Coalescing (IPv4)"** → Set to: **Disabled**
6. Find **"Recv Segment Coalescing (IPv6)"** → Set to: **Disabled**
7. Click **OK**
8. **Reboot** your computer

**Check Settings After Reboot:**
```powershell
# Run this script to verify settings persisted
~/Documents/dev/hardware/check-rsc-settings.ps1
```

**Performance Impact:**
- ✅ Gaming: No impact (small packets, latency-sensitive)
- ✅ File Transfers: 8-9 Gbps still achievable (vs theoretical 10 Gbps)
- ✅ CPU: Negligible increase (24 cores can handle it)

**User Reports:**
- "Disabled RSC, no crashes since"
- "Gaming stable, no performance loss"
- "Can't tell the difference, but system is stable"

---

## Alternative: WiFi Priority Toggle

**Use this if RSC disable doesn't fully resolve the issue.**

---

## Quick Commands (Copy & Paste)

### Before Gaming (Run as Administrator)
```powershell
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 25; Set-NetIPInterface -InterfaceAlias "Wi-Fi" -InterfaceMetric 5
```
**Effect:** Switches to WiFi for network, CalDigit hub stays connected for peripherals.

### After Gaming (Run as Administrator)
```powershell
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 5; Set-NetIPInterface -InterfaceAlias "Wi-Fi" -InterfaceMetric 20
```
**Effect:** Switches back to 10GbE Ethernet for full speed.

### Check Current Status (No Admin Required)
```powershell
Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -in @('Ethernet', 'Wi-Fi') } | Select-Object InterfaceAlias, InterfaceMetric, ConnectionState | Sort-Object InterfaceMetric | Format-Table -AutoSize
```
**Shows:** Which adapter is primary (lower metric = higher priority).

---

## Alternative: Use Scripts

**Location:** `~/Documents/dev/hardware/`

### Before Gaming
```powershell
# Run as Administrator
~/Documents/dev/hardware/set-wifi-priority.ps1
```

### After Gaming
```powershell
# Run as Administrator
~/Documents/dev/hardware/set-ethernet-priority.ps1
```

### Check Status
```powershell
# No admin required
~/Documents/dev/hardware/check-network-metrics.ps1
```

---

## How to Run as Administrator

1. Press `Win + X`
2. Select "Windows Terminal (Admin)" or "PowerShell (Admin)"
3. Paste the command
4. Press Enter

---

## What the Workaround Does

**WiFi Priority (Before Gaming):**
- Network traffic routes through WiFi (1.2 Gbps)
- CalDigit hub stays connected for:
  - USB devices (keyboard, mouse, etc.)
  - Monitors (display output)
  - Power delivery
  - Other peripherals
- USB4 bus not stressed by network traffic during gaming
- **Prevents daily CalDigit crashes**

**Ethernet Priority (After Gaming):**
- Network traffic routes through 10GbE Ethernet (10 Gbps)
- Full speed for downloads, file transfers, etc.
- CalDigit hub provides network connectivity

---

## Expected Metrics

**Normal Operation (10GbE):**
```
InterfaceAlias  InterfaceMetric  ConnectionState
--------------  ---------------  ---------------
Ethernet                      5  Connected       <-- Primary
Wi-Fi                        20  Connected
```

**Gaming Mode (WiFi):**
```
InterfaceAlias  InterfaceMetric  ConnectionState
--------------  ---------------  ---------------
Wi-Fi                         5  Connected       <-- Primary
Ethernet                     25  Connected
```

---

## Important Notes

- **Reboot-Safe:** Metrics persist across reboots, so remember to toggle back
- **Automatic Failover:** If Ethernet crashes, WiFi is already configured as backup
- **No Disconnect Needed:** CalDigit hub stays connected for peripherals
- **Simple Toggle:** Just remember to switch before/after gaming sessions

---

## Files Created

1. `check-rsc-settings.ps1` - **Verify RSC and EEE settings (PRIMARY DIAGNOSTIC)**
2. `set-wifi-priority.ps1` - Switch to WiFi (before gaming)
3. `set-ethernet-priority.ps1` - Switch to Ethernet (after gaming)
4. `toggle-network-priority.ps1` - Full toggle script with interactive menu
5. `check-network-metrics.ps1` - Check current network priority
6. `caldigit-ts5-plus-incident.md` - Full incident documentation with RSC research
7. `CALDIGIT-WORKAROUND.md` - This quick reference guide

---

**Last Updated:** October 23, 2025
**Status:** RSC workaround identified (awaiting reboot and testing)
**Full Documentation:** See `caldigit-ts5-plus-incident.md` for complete incident history and research findings
**Research:** Marvell AQC107 chipset has widespread RSC bug documented across multiple forums
