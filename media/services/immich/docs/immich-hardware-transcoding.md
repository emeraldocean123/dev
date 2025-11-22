# Immich Hardware Transcoding Configuration
**Last Updated:** October 11, 2025
**Status:** Working - Intel QuickSync (QSV) Active

## Overview

This document describes the hardware transcoding configuration for Immich running in LXC 1001 on intel-1250p, using Intel QuickSync for GPU-accelerated video encoding.

---

## Hardware Configuration

### Host System
- **Hostname**: intel-1250p (192.168.1.40)
- **GPU**: Intel Alder Lake-P GT2 [Iris Xe Graphics]
- **PCI Address**: 00:02.0

### LXC Container
- **Container ID**: 1001
- **IP Address**: 192.168.1.51
- **Hostname**: pve-immich-lxc
- **OS**: Debian 13 (Trixie)

---

## GPU Passthrough Configuration

### LXC Container Config: `/etc/pve/lxc/1001.conf`

```bash
# Allow all devices (needed for GPU)
lxc.cgroup2.devices.allow: a

# Allow specific character devices
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.cgroup2.devices.allow: c 226:128 rwm   # renderD128

# Mount DRI devices into container
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir

# Media directory mount
mp0: /mnt/media,mp=/mnt/media
```

### Device Verification

**On Host (intel-1250p):**
```bash
# Check GPU is present
lspci | grep VGA
# Output: 00:02.0 VGA compatible controller: Intel Corporation Alder Lake-P GT2 [Iris Xe Graphics] (rev 0c)

# Check render device exists
ls -la /dev/dri/
# Should show: renderD128 and card1
```

**In Container:**
```bash
# Check devices are accessible
ls -la /dev/dri/
# Should show: renderD128 (owned by kvm group) and card1 (owned by video group)

# Test VAAPI access
vainfo --display drm --device /dev/dri/renderD128
# Should show: Intel iHD driver with supported codecs
```

---

## Software Requirements

### Required Packages (In Container)

```bash
apt update
apt install -y vainfo intel-media-va-driver libva-drm2
```

### Package Purpose
- **vainfo**: VA-API verification tool
- **intel-media-va-driver**: Intel Media Driver for VAAPI
- **libva-drm2**: VA-API DRM runtime library

### Verify Installation

```bash
# Check available hardware acceleration methods
ffmpeg -hwaccels
# Should show: vaapi, qsv, drm, opencl, vulkan

# Check QSV encoders are available
ffmpeg -encoders | grep qsv
# Should show: h264_qsv, hevc_qsv, etc.

# Test VAAPI functionality
vainfo
# Should show: Intel iHD driver with supported profiles
```

---

## User Permissions Configuration

### Critical Fix: Add Immich User to GPU Groups

The `immich` user must be a member of the groups that own the GPU devices.

```bash
# Add immich user to required groups
usermod -aG video immich
usermod -aG render immich
usermod -aG kvm immich

# Verify group membership
id immich
# Output: uid=999(immich) gid=991(immich) groups=991(immich),44(video),993(kvm),992(render)

# Restart Immich services to apply group changes
systemctl restart immich-web immich-ml
```

**Important:** Without the `kvm` group membership, Immich cannot access `/dev/dri/renderD128` and hardware transcoding will fail silently.

---

## Immich Web UI Configuration

### Hardware Acceleration Settings

Navigate to: **Administration → Settings → Video Transcoding → Hardware Acceleration**

**Working Configuration:**
- **Acceleration API**: `QSV` (Intel QuickSync)
- **Hardware decoding**: `Enabled` ✅
- **Constant quality mode**: `Auto`
- **Temporal AQ**: `Disabled` (NVENC-specific, not applicable)
- **Preferred Hardware Device**: `auto`

**Important Notes:**
1. **QSV works, VAAPI doesn't**: Despite both being available, only QSV successfully enables hardware transcoding in Immich
2. **Must click "Save"**: Settings are not applied until explicitly saved
3. **Restart required**: After saving, restart Immich services to apply changes

### Why QSV Instead of VAAPI?

Both QSV and VAAPI access the same Intel QuickSync hardware, but:
- **VAAPI**: Linux API for video acceleration (generic)
- **QSV**: Intel's QuickSync Video API (Intel-specific)
- **Result**: Immich's QSV implementation works correctly, VAAPI implementation does not

---

## Verification

### Check Hardware Transcoding is Active

**1. Check ffmpeg Processes:**
```bash
ps aux | grep ffmpeg | grep -v grep
```

**Look for QSV flags in output:**
```
-init_hw_device qsv=hw,child_device=/dev/dri/renderD128
-c:v h264_qsv
-vf hwupload=extra_hw_frames=64
```

**If NOT using hardware acceleration, you'll see:**
```
-c:v h264    # Software encoder (bad)
```

**2. Check GPU Activity:**
```bash
cat /sys/kernel/debug/dri/128/i915_engine_info | grep -A5 'vcs0'
```

**When hardware transcoding is working:**
```
vcs0
    Awake? 1-3       # GPU is awake and processing
    Runtime: XXXms   # Increasing runtime shows active encoding
```

**When NOT working:**
```
vcs0
    Awake? 0         # GPU is idle
    Runtime: 0ms     # No video processing
```

---

## Troubleshooting

### Issue: Hardware Transcoding Not Working

**Symptoms:**
- ffmpeg uses `-c:v h264` instead of `-c:v h264_qsv`
- GPU shows `Awake? 0` and `Runtime: 0ms`
- High CPU usage during video processing

**Solutions (In Order):**

1. **Check user group membership:**
   ```bash
   id immich
   # Must show: video, render, AND kvm groups
   ```

2. **Add missing groups:**
   ```bash
   usermod -aG kvm immich
   systemctl restart immich-web
   ```

3. **Verify Immich settings:**
   - Go to web UI → Administration → Settings → Video Transcoding
   - Ensure "Acceleration API" is set to **QSV**
   - Click **Save** (critical!)

4. **Restart Immich:**
   ```bash
   systemctl restart immich-web immich-ml
   ```

5. **Wait for new video jobs:**
   - Already-queued jobs may use old settings
   - Wait 15-30 seconds for new ffmpeg processes to start

6. **Verify with commands above**

---

### Issue: Permission Denied Errors

**Symptoms:**
```
[AVHWDeviceContext @ 0x...] Failed to open device /dev/dri/renderD128
```

**Solution:**
```bash
# Check device permissions
ls -la /dev/dri/renderD128
# Should show: crw-rw---- 1 root kvm 226, 128

# Check immich user can access it
su - immich -c "ls -la /dev/dri/renderD128"
# Should succeed without errors

# If fails, add to kvm group
usermod -aG kvm immich
```

---

### Issue: vainfo Works But Immich Doesn't Use GPU

**This is expected behavior.** VAAPI verification with `vainfo` confirms the GPU is accessible, but Immich's VAAPI implementation doesn't work correctly. **Use QSV instead.**

---

## Performance Impact

### With Hardware Transcoding (QSV):
- ✅ Video encoding offloaded to Intel iGPU
- ✅ Lower CPU usage during video processing
- ✅ Faster thumbnail and preview generation
- ✅ GPU video engines (vcs0, vcs1) actively used
- ✅ Better responsiveness for other services

### Without Hardware Transcoding:
- ❌ CPU-only encoding (slow)
- ❌ High CPU usage during video processing
- ❌ Slower media library processing
- ❌ Potential system slowdowns during transcoding

---

## Supported Codecs

### Intel Alder Lake-P GT2 [Iris Xe Graphics] Capabilities

**Video Decode (Hardware-Accelerated Input):**
- MPEG2 (Simple, Main)
- H.264 / AVC (Main, High, Constrained Baseline)
- H.265 / HEVC (Main, Main10, Main12, Main422, Main444)
- VP8
- VP9 (Profile 0-3)
- JPEG

**Video Encode (Hardware-Accelerated Output):**
- H.264 / AVC (Main, High, Constrained Baseline)
- H.265 / HEVC (Main, Main10, Main444)
- VP9 (Profile 0-3)
- JPEG

**Note:** Old MPEG1 videos (pre-2005) are decoded in software but encoded using hardware acceleration when converting to H.264.

---

## Machine Learning Status

Machine Learning features are enabled and running independently of hardware transcoding:

```bash
# Check ML service status
systemctl status immich-ml

# Check ML processes
ps aux | grep immich_ml
```

**ML Features:**
- ✅ Facial recognition
- ✅ Object detection
- ✅ Scene classification
- ✅ Smart search (CLIP embeddings)

**Note:** ML processing uses CPU, not GPU (normal behavior).

---

## Configuration Files Summary

### Files Modified on intel-1250p Host:
- `/etc/pve/lxc/1001.conf` - GPU passthrough and media mount

### Files Modified in LXC 1001:
- User groups: `immich` added to video, render, kvm groups

### Packages Installed in LXC 1001:
- vainfo
- intel-media-va-driver
- libva-drm2

### Immich Settings (Web UI):
- Administration → Settings → Video Transcoding → Hardware Acceleration
  - Acceleration API: **QSV**
  - Hardware decoding: **Enabled**

---

## Quick Reference Commands

### Check GPU Passthrough:
```bash
# On host
ssh intel-1250p "ls -la /dev/dri/"

# In container
ssh intel-1250p "pct exec 1001 -- ls -la /dev/dri/"
```

### Check Hardware Transcoding Active:
```bash
# Check ffmpeg using QSV
ssh intel-1250p "pct exec 1001 -- ps aux | grep h264_qsv"

# Check GPU activity
ssh intel-1250p "cat /sys/kernel/debug/dri/128/i915_engine_info | grep -A5 vcs0"
```

### Restart Immich:
```bash
ssh intel-1250p "pct exec 1001 -- systemctl restart immich-web immich-ml"
```

### Verify User Groups:
```bash
ssh intel-1250p "pct exec 1001 -- id immich"
# Must show: video, render, kvm groups
```

---

## Historical Notes

### What Didn't Work:
1. **VAAPI**: Despite being available and working with `vainfo`, Immich doesn't use VAAPI for transcoding
2. **Auto-detection**: Immich doesn't automatically detect or enable hardware acceleration
3. **Default settings**: Hardware transcoding is disabled by default even when GPU is available

### What Worked:
1. **QSV**: Intel QuickSync API works perfectly with Immich
2. **KVM group**: Critical missing piece - immich user needed kvm group membership
3. **Explicit configuration**: Must manually enable in web UI and restart services

### Timeline:
- Initial setup: GPU passthrough configured, VAAPI installed
- Issue: ffmpeg not using hardware acceleration despite settings
- Root cause: immich user missing kvm group membership
- Solution: Added to kvm group + switched to QSV
- Result: Hardware transcoding active, GPU encoding confirmed

---

## References

- **Immich Documentation**: https://immich.app/docs/features/hardware-transcoding
- **Intel Media Driver**: https://github.com/intel/media-driver
- **VAAPI**: https://en.wikipedia.org/wiki/Video_Acceleration_API
- **Intel QuickSync**: https://www.intel.com/content/www/us/en/architecture-and-technology/quick-sync-video/quick-sync-video-general.html
- **LXC Device Passthrough**: https://pve.proxmox.com/wiki/Linux_Container#_device_passthrough

---

## Maintenance

### When to Restart Immich:
- After changing hardware acceleration settings
- After modifying user group membership
- After GPU passthrough configuration changes
- After Immich updates

### Monitoring:
- Periodically check GPU activity during video processing
- Monitor CPU usage during media library scans
- Verify ffmpeg processes are using `h264_qsv` encoder
- Check Immich logs for hardware acceleration errors

### Updates:
- Keep intel-media-va-driver updated for best performance
- Update Immich regularly for improved hardware support
- Test hardware transcoding after major updates

---

## Summary

**Working Configuration:**
- ✅ GPU passthrough: Intel Alder Lake-P GT2 → LXC 1001
- ✅ Software: vainfo, intel-media-va-driver, libva-drm2
- ✅ Permissions: immich user in video, render, kvm groups
- ✅ Immich: QSV acceleration enabled, hardware decoding on
- ✅ Result: GPU-accelerated H.264/HEVC encoding active

**Critical Fix:** Adding immich user to kvm group was the key to enabling hardware transcoding.
