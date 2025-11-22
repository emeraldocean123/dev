# Storage Architecture
**Last Updated:** October 11, 2025
**Status:** Verified via SSH and ZFS commands

## Overview

This document describes the storage architecture for the Proxmox homelab infrastructure, including NAS configuration, backup strategy, and ZFS pool layout.

## Infrastructure Hosts

### intel-1250p (192.168.1.40) - Primary NAS & Services
**Role:** Primary storage, NAS, and service host

**Hardware:**
- Single 4TB NVMe SSD
- ZFS pool: `rpool`
- Configuration: Single drive (no RAID)
- Usable capacity: 3.62 TB
- Current usage: 8.87 GB (0%)

**Services Running:**
- Docker (192.168.1.50) - Container services
- Immich (192.168.1.51) - Photo management system
- PBS (192.168.1.52) - Proxmox Backup Server

**Storage Purpose:**
- Primary NAS storage for photos, videos, and media
- Fast access storage for active services
- Proxmox host with LXC containers
- PBS datastore for VM/container backups

**Performance Characteristics:**
- Single NVMe - Maximum read/write performance
- No redundancy (relies on external backups)
- Low fragmentation (0%)
- Healthy status

---

### intel-n6005 (192.168.1.41) - Backup Server
**Role:** Secondary backup host with redundancy

**Hardware:**
- 2x 4TB NVMe SSDs in ZFS mirror
- ZFS pool: `rpool`
- Configuration: RAID1 (mirror-0)
- Usable capacity: 3.62 TB (mirrored)
- Current usage: 2.79 GB (0%)

**Drives:**
- Drive 1: nvme-eui.0025385651412705-part3
- Drive 2: nvme-eui.00253856514126eb-part3

**Storage Purpose:**
- Backup PBS backups from intel-1250p
- Backup photos and videos from datastore
- Redundant storage (can survive single drive failure)
- Secondary Proxmox host (minimal services)

**Performance Characteristics:**
- Mirrored writes (half write speed, full read speed)
- Full redundancy (one drive can fail)
- Low fragmentation (0%)
- Healthy status

---

## Storage Strategy

### Primary Storage (intel-1250p)
```
┌─────────────────────────────────────────┐
│  Intel 1250P - Primary NAS (RAID0)      │
│  4TB NVMe - 3.62TB usable               │
├─────────────────────────────────────────┤
│  • Active media storage                 │
│  • Docker containers                    │
│  • Immich photo library (active)        │
│  • PBS backup datastore (VM backups)    │
│  • Fast performance, no redundancy      │
└─────────────────────────────────────────┘
```

**Advantages:**
- Maximum performance (no RAID overhead)
- Full capacity available (3.62TB)
- Ideal for NAS serving active data
- Fast container I/O

**Risks:**
- Single point of failure (no drive redundancy)
- **Mitigated by:** Regular backups to intel-n6005

---

### Backup Storage (intel-n6005)
```
┌─────────────────────────────────────────┐
│  Intel N6005 - Backup Server (RAID1)    │
│  2x 4TB NVMe - 3.62TB usable (mirror)   │
├─────────────────────────────────────────┤
│  • PBS backup copies                    │
│  • Photo/video archive backups          │
│  • Immich database backups              │
│  • Full redundancy, can lose 1 drive    │
└─────────────────────────────────────────┘
```

**Advantages:**
- Full redundancy (survives single drive failure)
- Ideal for critical backup data
- ZFS scrubbing detects silent corruption
- Automatic healing from mirror

**Trade-offs:**
- Write performance is ~50% of single drive
- Only 3.62TB usable (vs 7.24TB raw capacity)

---

## Backup Workflows

### 1. PBS-to-PBS Replication
**Primary → Backup**
```
intel-1250p (PBS @ .52)  ──sync──>  intel-n6005 (PBS)
    ↓                                    ↓
VM/CT Backups                      Replicated Backups
```

**Implementation:**
- Configure PBS remote on intel-1250p
- Point to PBS instance on intel-n6005
- Schedule sync jobs (nightly/weekly)
- Retention: Keep longer history on n6005

### 2. Photo/Video Backup
**Immich/Datastore → Backup**
```
intel-1250p (Immich @ .51)  ──rsync/zfs-send──>  intel-n6005
    ↓                                                   ↓
Active photo library                           Archive copies
```

**Options:**
- **rsync:** Traditional file-level sync
- **zfs send/receive:** Block-level replication (faster)
- **PBS datastore backup:** Immich data as backup job

### 3. Configuration Backups
**Proxmox Configs**
```
Both hosts  ──backup──>  ~/Documents/dev/sh/
                              ↓
                       Proxmox config backups
```

---

## ZFS Pool Details

### intel-1250p Pool Configuration
```bash
# Pool: rpool
# Type: Single drive
# Size: 3.62T
# Used: 8.87G (0%)
# Health: ONLINE

NAME                               STATE     READ WRITE CKSUM
rpool                              ONLINE       0     0     0
  nvme-eui.0025385c4140ab77-part3  ONLINE       0     0     0
```

### intel-n6005 Pool Configuration
```bash
# Pool: rpool
# Type: Mirror (RAID1)
# Size: 3.62T
# Used: 2.79G (0%)
# Health: ONLINE

NAME                                 STATE     READ WRITE CKSUM
rpool                                ONLINE       0     0     0
  mirror-0                           ONLINE       0     0     0
    nvme-eui.0025385651412705-part3  ONLINE       0     0     0
    nvme-eui.00253856514126eb-part3  ONLINE       0     0     0
```

---

## Capacity Planning

### Current Usage
| Host | Pool | Capacity | Used | Free | Usage % |
|------|------|----------|------|------|---------|
| intel-1250p | rpool | 3.62TB | 8.87GB | 3.62TB | 0% |
| intel-n6005 | rpool | 3.62TB | 2.79GB | 3.62TB | 0% |

### Projected Growth
Assuming:
- Immich photo library: ~500GB-1TB
- Docker volumes: ~50-100GB
- PBS VM backups: ~500GB-1TB
- Media storage: ~1-2TB

**intel-1250p estimated usage:** 2-3TB (67-83%)
**intel-n6005 backup needs:** 2-3TB (67-83%)

**Recommendation:** Current 4TB drives are adequate for near-term use.

---

## Best Practices

### ZFS Maintenance
1. **Regular scrubs** (monthly):
   ```bash
   ssh intel-1250p "zpool scrub rpool"
   ssh intel-n6005 "zpool scrub rpool"
   ```

2. **Monitor health**:
   ```bash
   ssh intel-1250p "zpool status"
   ssh intel-n6005 "zpool status"
   ```

3. **Check fragmentation**:
   ```bash
   zpool list -o name,size,alloc,free,frag
   ```

### Backup Strategy
1. **3-2-1 Rule:**
   - 3 copies of data
   - 2 different storage types (NVMe + external)
   - 1 offsite copy (cloud or external)

2. **Retention Policy:**
   - Primary (1250p): Keep 7 days of PBS backups
   - Backup (n6005): Keep 30+ days
   - Photos: Keep all copies, never delete

3. **Testing:**
   - Monthly restore tests
   - Verify PBS backup integrity
   - Test ZFS snapshot rollback

---

## Storage Access

### NFS/SMB Shares (Future)
When configuring NAS shares:
- Share from intel-1250p (faster, primary access)
- Use intel-n6005 only for backup operations
- Consider read-only access to backups for recovery

### PBS Access
- Primary PBS: `https://192.168.1.52:8007`
- Backup PBS: Configure on intel-n6005 port 8007

---

## Disaster Recovery

### Scenario 1: intel-1250p Drive Failure
**Impact:** Loss of primary storage and active services

**Recovery:**
1. Replace failed drive
2. Reinstall Proxmox on intel-1250p
3. Restore PBS backups from intel-n6005
4. Restore containers from PBS backups
5. Restore photos/media from intel-n6005

**Downtime:** 2-4 hours

---

### Scenario 2: intel-n6005 Single Drive Failure
**Impact:** Minimal - mirror continues functioning

**Recovery:**
1. Replace failed drive
2. ZFS resilvers automatically
3. No downtime required

**Downtime:** 0 hours

---

### Scenario 3: intel-n6005 Both Drives Fail
**Impact:** Loss of backup redundancy

**Recovery:**
1. Replace both drives
2. Restore from intel-1250p PBS
3. Re-sync backup jobs

**Downtime:** Backup jobs paused during rebuild

---

## Monitoring

### Key Metrics to Monitor
1. **Pool health:** `zpool status` (should always be ONLINE)
2. **Capacity:** Alert at 80% usage
3. **Fragmentation:** Alert at >50%
4. **Scrub errors:** Alert on any CKSUM errors
5. **PBS sync status:** Monitor replication jobs

### Alerting (Future)
Consider setting up:
- Proxmox email alerts for pool status
- PBS notification for failed sync jobs
- ZFS Event Daemon (ZED) notifications

---

## Notes

- Both pools are nearly empty (0% used) - ready for data migration
- No CKSUM errors on either pool (healthy drives)
- Both pools have 0% fragmentation (optimal performance)
- intel-1250p is single drive - prioritize backups to n6005
- intel-n6005 mirror provides excellent data safety for backups
- Consider offsite backups for truly critical data (photos, videos)
