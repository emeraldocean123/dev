# Orphaned Assets Management

Scripts for finding and cleaning up orphaned files in the Immich library.

## Scripts

### find-orphaned-assets.sh
Finds files in Immich upload directory that aren't tracked in the database.

**Usage:**
```bash
./find-orphaned-assets.sh [upload-directory]
```

Scans the Immich upload directory and compares against the database to identify files that exist on disk but have no database record. These are orphaned assets consuming storage.

**Output:** Creates a report listing all orphaned files with paths and sizes.

### delete-orphaned-assets.sh
Deletes orphaned files identified by the find script.

**Usage:**
```bash
./delete-orphaned-assets.sh <orphan-report-file>
```

Takes the report from `find-orphaned-assets.sh` and safely removes the orphaned files. Creates backup list before deletion.

**⚠️ Warning:** This permanently deletes files. Review the orphan report carefully before running.

## Workflow

1. Run `find-orphaned-assets.sh` to scan for orphans
2. Review the generated report thoroughly
3. Backup important data if uncertain
4. Run `delete-orphaned-assets.sh` with the report file to clean up

## Requirements

- SSH access to Immich LXC container (192.168.1.51)
- Read access to Immich database (PostgreSQL)
- Write access to upload directory for deletion

## Common Causes of Orphaned Files

- Failed uploads that weren't fully cleaned up
- Database restores without corresponding file cleanup
- Manual file moves or deletions
- Import errors

## Related

- Immich upload directory: `/mnt/immich/upload/` on LXC 1001
- Immich database: PostgreSQL on LXC 1001
