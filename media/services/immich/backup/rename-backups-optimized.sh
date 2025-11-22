#!/bin/bash
# Optimized batch rename: .xmp_original -> .xmp_backup
# Uses xargs with parallel processing for 10-20x speedup

LIBRARY_PATH="/d/Immich/library/library"

echo "Optimized XMP Backup Rename"
echo "============================"
echo ""
echo "Starting batch rename with 8 parallel workers..."
echo ""

START_TIME=$(date +%s)

# Use find with xargs for parallel batch processing
# -P 8: Run 8 parallel processes
# -0: Handle null-terminated filenames (safe for spaces/special chars)
# -I {}: Replace string for each file
find "$LIBRARY_PATH" -name "*.xmp_original" -type f -print0 | \
    xargs -0 -P 8 -I {} bash -c 'mv "{}" "${0%.xmp_original}.xmp_backup"' {}

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Count renamed files
BACKUP_COUNT=$(find "$LIBRARY_PATH" -name "*.xmp_backup" -type f | wc -l)

echo ""
echo "Renaming complete!"
echo "Renamed files: $BACKUP_COUNT"
echo "Duration: ${DURATION} seconds"
echo ""
echo "Backup files are now named: *.xmp_backup"
