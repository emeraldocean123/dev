#!/bin/bash
# Wait for XMP sanitization to complete, then rename backup files
# This script monitors for completion and renames .xmp_original to .xmp_backup

LIBRARY_PATH="/d/Immich/library/library"
TOTAL_FILES=78123
CHECK_INTERVAL=60  # Check every 60 seconds

echo "XMP Backup Renaming Monitor"
echo "==========================="
echo ""
echo "Waiting for sanitization to complete..."
echo "Target: $TOTAL_FILES files"
echo ""

while true; do
    # Count current backup files
    CURRENT_COUNT=$(find "$LIBRARY_PATH" -name "*.xmp_original" -type f | wc -l)
    PERCENT=$((CURRENT_COUNT * 100 / TOTAL_FILES))

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Progress: $CURRENT_COUNT / $TOTAL_FILES ($PERCENT%)"

    # Check if complete
    if [ "$CURRENT_COUNT" -ge "$TOTAL_FILES" ]; then
        echo ""
        echo "Sanitization complete! Found $CURRENT_COUNT backup files."
        echo "Starting backup file renaming..."
        echo ""

        # Rename all .xmp_original files to .xmp_backup (OPTIMIZED - batch processing)
        # Use find with -print0 and xargs for much faster batch processing
        find "$LIBRARY_PATH" -name "*.xmp_original" -type f -print0 | \
            xargs -0 -P 8 -I {} bash -c 'mv "{}" "$(echo "{}" | sed "s/\.xmp_original$/.xmp_backup/")"'

        # Count renamed files
        BACKUP_COUNT=$(find "$LIBRARY_PATH" -name "*.xmp_backup" -type f | wc -l)

        echo ""
        echo "Renaming complete!"
        echo "Renamed $BACKUP_COUNT files from .xmp_original to .xmp_backup"
        echo ""
        echo "Backup files are now named: *.xmp_backup (consistent with config-backup folder naming)"

        exit 0
    fi

    # Wait before next check
    sleep $CHECK_INTERVAL
done
