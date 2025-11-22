# iSCSI Analysis and Investigation

**Date:** October 13, 2025
**Status:** Investigation Complete - No immediate need identified

## Current Infrastructure Summary

### intel-1250p (.40) - Primary Host
- **Storage:** Single 4TB NVMe (3.62TB usable)
  - Used: 755GB (20%)
  - Free: 2.89TB (80%)
- **Workload:** All 5 LXC containers run here
- **Storage Breakdown:**
  - PBS datastore: 374GB
  - Media folder: 330GB
  - LXC containers: 48GB
  - System: 3GB
- **iSCSI Capability:** open-iscsi (initiator) installed

### intel-n6005 (.41) - Backup Host
- **Storage:** 2×4TB NVMe RAID1 Mirror (3.62TB usable)
  - Used: 509GB (14%) - Updated October 13, 2025
  - Free: **3.01TB (86%)**
- **Memory:** 31GB total, only 2.9GB used (28GB available)
- **Storage Breakdown:**
  - intel-1250p-proxmox-backup-server: 374GB (ZFS replication from 1250p) - NEW
  - media-replica: REMOVED October 13, 2025 (was 330GB, redundant)
  - System: 3GB
- **iSCSI Capability:** open-iscsi (initiator) installed
- **Available iSCSI Target Package:** istgt

## Current Backup Strategy

1. **PBS on intel-1250p** (LXC 1002, .52)
   - Backs up all 5 LXC containers
   - Backs up host including 330GB media folder
   - Total backup storage: 374GB
   - Storage backend: ZFS dataset on 1250p with 2.8TB free

2. **ZFS Replication** (Implemented October 13, 2025)
   - **PBS datastore:** Replicated from 1250p to n6005 (374GB)
     - Initial full send completed October 13, 2025
     - Incremental replication via `/root/sh/zfs-replicate-pbs.sh`
     - Snapshot retention: 7 days
   - **Media folder:** Already included in PBS host backup (330GB)
     - Redundant media-replica dataset removed October 13, 2025
   - Uses native ZFS send/receive for block-level efficiency
   - Provides off-host redundancy for all backup data

3. **Hardware Redundancy**
   - N6005 has RAID1 mirror (redundant storage)
   - 1250p has single drive (no redundancy)

## iSCSI Investigation Results

### What is iSCSI?
iSCSI (Internet Small Computer System Interface) presents block-level storage over TCP/IP networks. It allows one server (target) to present storage devices to another server (initiator) over the network.

**Key Components:**
- **Target:** Server that provides storage (would be N6005)
- **Initiator:** Server that consumes storage (would be 1250p)
- **LUN:** Logical Unit Number - the actual storage device presented
- **IQN:** iSCSI Qualified Name - unique identifier for targets and initiators

### Potential Use Cases for This Infrastructure

#### Option 1: N6005 as iSCSI Target for Additional PBS Storage
**Configuration:**
- Create 500GB-1TB ZFS zvol on N6005
- Present via iSCSI to 1250p
- Add as second PBS datastore
- Store "off-host" backups on N6005's RAID1 storage

**Pros:**
- Physical separation of backup data
- Leverages N6005's RAID1 redundancy
- Backup data survives if 1250p fails
- N6005 has plenty of free space (3.19TB)

**Cons:**
- Network dependency (backups fail if network down)
- Added complexity vs current setup
- Network latency for backup operations
- Single point of failure (N6005 must be online)
- PBS already has 2.8TB free on local storage

#### Option 2: N6005 as iSCSI Target for VM Storage
**Configuration:**
- Create ZFS zvol for VM disk images
- Present to 1250p as additional storage pool
- Use for less critical VMs or testing

**Pros:**
- Leverages N6005's massive free space
- RAID1 redundancy for VM disks
- Separates VM storage from container storage

**Cons:**
- Network latency for VM I/O (poor performance)
- Network dependency (VMs unavailable if network fails)
- Local ZFS storage is vastly superior for VMs
- 1250p has 2.8TB free locally

#### Option 3: Don't Use iSCSI
**Rationale:**
- Current local ZFS storage works perfectly
- PBS already handles all backup needs
- ZFS replication provides media redundancy
- No network overhead or latency
- Simpler architecture, easier to maintain
- 1250p has plenty of local space (2.8TB free)

## Technical Analysis

### Why iSCSI Might Not Be Needed

1. **Sufficient Local Storage**
   - 1250p has 2.8TB free (80% available)
   - PBS only using 374GB with room to grow
   - No storage pressure on primary host

2. **Existing Redundancy**
   - PBS backs up all containers and host
   - Media folder replicated to N6005 via ZFS
   - N6005 serves as standby/backup server

3. **Performance Considerations**
   - Local ZFS: Direct NVMe access, no network overhead
   - iSCSI: Network latency, TCP/IP overhead, potential bottleneck
   - For PBS and VMs, local storage is significantly faster

4. **Complexity vs Benefit**
   - iSCSI adds: Target configuration, initiator setup, network dependency
   - Current setup: Simple, local, fast, reliable
   - Added complexity not justified by current needs

5. **Network Dependency Risk**
   - iSCSI storage unavailable if network fails
   - Local storage has no such dependency
   - Critical services should use local storage

### When iSCSI Would Make Sense

iSCSI would be valuable if:

1. **Storage Exhaustion**: 1250p running out of local space (currently 80% free)
2. **Physical Separation Required**: Regulatory/compliance needs for off-host backups
3. **Centralized Storage**: Multiple Proxmox hosts sharing storage (only have 2 hosts)
4. **VM Migration**: Need live migration between hosts (requires shared storage)
5. **Learning/Testing**: Want to gain experience with iSCSI technology

## Recommendations

### Primary Recommendation: Don't Implement iSCSI (Currently)

**Reasoning:**
- Current architecture works well
- No storage pressure (80% free on 1250p)
- PBS and ZFS replication provide adequate redundancy
- Local storage provides better performance
- Simpler architecture is easier to maintain

**Monitor for:**
- PBS storage growing beyond 1TB (consider expansion then)
- Need for live VM migration
- Additional Proxmox hosts added to cluster

### Alternative Recommendation: Test iSCSI for Learning

**If interested in learning iSCSI:**

1. **Create small test zvol (50GB) on N6005**
2. **Install and configure istgt on N6005**
3. **Connect from 1250p as test**
4. **Run performance benchmarks**
5. **Keep configuration documented for future**
6. **Don't use for production until needed**

## Implementation Guide (If Proceeding)

### Step 1: Install iSCSI Target on N6005

```bash
ssh intel-n6005
apt update
apt install istgt
systemctl enable istgt
systemctl start istgt
```

### Step 2: Create ZFS zvol for iSCSI

```bash
# Create 500GB zvol for testing
zfs create -V 500G rpool/iscsi-storage
```

### Step 3: Configure istgt Target

Edit `/etc/istgt/istgt.conf`:

```
[PortalGroup1]
  Portal = 192.168.1.41:3260

[InitiatorGroup1]
  InitiatorName = iqn.2025-10.local.intel-1250p:initiator
  Netmask = 192.168.1.0/24

[LogicalUnit1]
  TargetName = iqn.2025-10.local.intel-n6005:lun1
  TargetAlias = N6005-Storage
  Mapping = PortalGroup1 InitiatorGroup1
  AuthMethod = None
  UseDigest = Auto
  LUN0 Storage = /dev/zvol/rpool/iscsi-storage
  LUN0 Option = "BlockLength 512"
```

### Step 4: Configure iSCSI Initiator on 1250p

```bash
ssh intel-1250p

# Discover targets
iscsiadm -m discovery -t sendtargets -p 192.168.1.41

# Login to target
iscsiadm -m node --targetname iqn.2025-10.local.intel-n6005:lun1 --login

# Verify connection
lsblk
```

### Step 5: Add to Proxmox Storage

Via Proxmox GUI:
1. Datacenter → Storage → Add → iSCSI
2. ID: `iscsi-n6005`
3. Portal: `192.168.1.41`
4. Target: `iqn.2025-10.local.intel-n6005:lun1`

## Current Status

**Decision:** Investigation complete - ZFS replication chosen over iSCSI.

**Implemented on October 13, 2025:**
- ✅ ZFS send/receive for PBS datastore replication (1250p → N6005)
- ✅ Initial full send: 374GB completed
- ✅ Incremental replication script: `/root/sh/zfs-replicate-pbs.sh`
- ✅ Deployed to both hosts for future incremental syncs
- ✅ Snapshot-based replication with 7-day retention
- ✅ Removed redundant media-replica dataset (freed 330GB on N6005)

**Infrastructure is working optimally with:**
- Local ZFS storage on both hosts
- PBS backing up all containers and host on intel-1250p
- **ZFS replication of PBS datastore to N6005 (off-host backup redundancy)**
- Media folder backed up via PBS (included in host backup)
- 80% free space on primary host, 86% free on backup host
- Simple, maintainable architecture

**Next Steps:**
- Schedule regular incremental PBS replication (daily/weekly via cron)
- Monitor storage usage and revisit iSCSI if/when:
  - PBS storage exceeds 1TB
  - Local storage drops below 500GB free
  - Need for VM live migration arises
  - Additional Proxmox hosts added to cluster

## References

- **iSCSI Initiator Package:** open-iscsi (installed on both hosts)
- **iSCSI Target Package:** istgt (available on Debian repositories)
- **Current Storage Status:** See ZFS pool status above
- **Documentation:** Network-devices.md, pbs-backup-config.md

## Notes

- Both hosts have iSCSI initiator (open-iscsi) already installed
- Neither host has iSCSI target software installed
- N6005 has 3.19TB free on RAID1 storage
- 1250p has 2.89TB free on single drive storage
- Current backup strategy is working well
- No compelling use case for iSCSI at this time
