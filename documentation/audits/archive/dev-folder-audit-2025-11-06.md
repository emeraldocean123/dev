# Dev Folder Audit and Cleanup Plan

- **Date**: November 6, 2025
- **Auditor**: Claude Code
- **Purpose**: Comprehensive audit, consolidation, and cleanup of `~/Documents/dev`

---

## Executive Summary

- Reviewed **92 files** across **17 directories**.
- Identified loose Mylio automation files, temporary artifacts, redundant
  backups, and obsolete registry entries.
- Defined folder moves, deletes, and renames to return the tree to the
  documented structure.

---

## Current Structure Analysis

### Root Level (`~/Documents/dev`)

- **Issues**: Too many files in the root; photo tooling scattered.  
- **Files to keep in root**: none.
- **Files to remove**:
  - `temp-1907.txt` (empty)
  - `temp-1980.txt` (empty)
- **Files to move**:
  - All Mylio scripts & docs → `photos/mylio/`
  - `tailscale-lxc-local-routing-fix.md` → `network/`

### Key Issues Identified

- Mylio scripts/logs not grouped under `photos/`.
- Temporary/empty files left in place after troubleshooting.
- Backup copies (`*.backup-<timestamp>`) cluttering hardware incident docs.
- Obsolete registry files linger in `applications/registry/`.
- Meta-scripts (`audit-dev-folder.sh`, `reorganize-dev-folder.sh`) remain even
  though this process is codified.

---

## Recommended Actions by Category

### 1. Mylio Photo Management Files

- **Action**: Create `photos/mylio/` with `archive/` for historical logs.
- **Moves**:
  - `fix-mylio-dates.ps1` → `photos/mylio/fix-mylio-dates.ps1`
  - `fix-mylio-dates-README.md` → `photos/mylio/README.md` (rename)
  - `scan-mylio-dates.ps1` → `photos/mylio/scan-mylio-dates.ps1`
  - `scan-mylio-dates-README.md` → `photos/mylio/scan-README.md` (rename)
  - `mylio-date-anomalies.md` → `photos/mylio/date-anomalies-analysis.md`
  - `mylio-analysis-results.txt` → `photos/mylio/archive/analysis-results.txt`
  - `mylio-video-analysis-results.txt` → `photos/mylio/archive/video-analysis-results.txt`
  - `mylio-corrupted-files-list.txt` → `photos/mylio/archive/corrupted-files-list.txt`
  - `mylio-date-fix-log-20251106-215832.txt` → `photos/mylio/archive/fix-log-20251106.txt`

### 2. Network Documentation

- **Action**: Keep everything under `network/`.
- **Move**: `tailscale-lxc-local-routing-fix.md` → `network/tailscale-lxc-routing-fix.md`.

### 3. Applications Folder

- **Action**: Remove registry exports from `applications/registry/`.
- **Keep**:
  - `applications/edge-tab-organization.md`
  - `applications/remove-edge-tab-organization.sh`
- **Delete**:
  - `applications/registry/Enable-Edge-Tab-Organization.reg`
  - `applications/registry/Remove-Edge-Tab-Organization.reg`

### 4. Backup Folder

- **Action**: Introduce `backup/services/` for systemd files.
- **Move**:
  - `rtc-alarm-on-boot.service` → `backup/services/rtc-alarm-on-boot.service`
  - `synology-auto-backup.service` → `backup/services/synology-auto-backup.service`

### 5. Hardware Folder

- **Action**: Purge stale backups and temp notes.
- **Delete**:
  - `caldigit-ts5-plus-incident.md.backup-20251028-161659`
  - `caldigit-ts5-plus-incident.md.backup-ps-20251028-163744`
  - `incident-11-temp.txt`
- **Review**: `incident-8-entry.md` (keep only if still relevant).

### 6. `sh/` Scripts

- **Action**: Remove meta-audit helpers.
- **Delete**:
  - `sh/audit-dev-folder.sh`
  - `sh/reorganize-dev-folder.sh`

### 7. Remaining Categories

- **Network scripts, shell-management, storage, vpn, wake-on-lan**: already
  compliant—no changes required once moves above are completed.

---

## Files to Delete (Summary)

1. `temp-1907.txt`  
2. `temp-1980.txt`  
3. `hardware/incident-11-temp.txt`  
4. `hardware/caldigit-ts5-plus-incident.md.backup-20251028-161659`  
5. `hardware/caldigit-ts5-plus-incident.md.backup-ps-20251028-163744`  
6. `applications/registry/Enable-Edge-Tab-Organization.reg`  
7. `applications/registry/Remove-Edge-Tab-Organization.reg`  
8. `sh/audit-dev-folder.sh`  
9. `sh/reorganize-dev-folder.sh`  
10. `hardware/incident-8-entry.md` (if verified as merged)

---

## Reorganization Summary

### New Folders to Create

1. `photos/mylio/`
2. `photos/mylio/archive/`
3. `backup/services/`

### Files to Rename

- `fix-mylio-dates-README.md` → `photos/mylio/README.md`
- `scan-mylio-dates-README.md` → `photos/mylio/scan-README.md`

### Proposed Tree (Post-Cleanup Snapshot)

```text
dev/
├── applications/
│   ├── edge-tab-organization.md
│   └── remove-edge-tab-organization.sh
├── backup/
│   ├── services/
│   │   ├── rtc-alarm-on-boot.service
│   │   └── synology-auto-backup.service
│   └── *.md (backup docs)
├── documentation/
│   └── audits/
├── hardware/
│   ├── caldigit-ts5-plus-incident.md
│   ├── CALDIGIT-WORKAROUND.md
│   └── diagnostics scripts
├── network/
│   ├── network-devices.md
│   ├── tailscale-lxc-routing-fix.md
│   └── scripts/
├── photos/
│   ├── immich-hardware-transcoding.md
│   ├── photo-vault-architecture.md
│   └── mylio/
│       ├── README.md
│       ├── fix-mylio-dates.ps1
│       ├── scan-mylio-dates.ps1
│       ├── scan-README.md
│       ├── date-anomalies-analysis.md
│       └── archive/
│           ├── analysis-results.txt
│           ├── video-analysis-results.txt
│           ├── corrupted-files-list.txt
│           └── fix-log-20251106.txt
├── sh/
│   ├── proxmox-*.sh
│   ├── upgrade-debian.sh
│   └── wake-servers.sh
├── shell-management/
│   ├── shell-configs.md
│   └── configs/
├── storage/
│   └── storage-architecture.md
├── vpn/
│   └── vpn-configuration.md
└── wake-on-lan/
    ├── wake-on-lan.md
    └── wake-servers.ps1
```

---

## Execution Plan

1. **Phase 1 – Create Folders**: `photos/mylio/`, `photos/mylio/archive/`, `backup/services/`.
2. **Phase 2 – Move Files**: Relocate Mylio assets, archive logs, and systemd services.
3. **Phase 3 - Delete Artifacts**: Remove temp files, backups, obsolete registry
   entries, and meta-scripts.
4. **Phase 4 - Verify**: Confirm references, update docs, and smoke-test scripts
   from new paths.

---

## Risk Assessment

- **Risk Level**: Low
- **Risks**: Moving files could break hard-coded paths; deleting the wrong backup
  might lose context.
- **Mitigations**: Retain this audit, rely on Git history where applicable, and
  validate scripts that reference moved assets.

---

## Post-Cleanup Maintenance

1. Keep the root of `~/Documents/dev/` empty—always file by category.
2. Use `archive/` subfolders for log dumps and long-lived outputs.
3. Delete temporary or backup copies once primary docs are updated.
4. Schedule quarterly audits to ensure categories remain tidy.

---

## Notes

- All script functionality remains intact once paths are updated.
- Documentation is preserved; only duplicates and temp artifacts are removed.
- The reorganized tree improves discoverability and matches the documented taxonomy.
