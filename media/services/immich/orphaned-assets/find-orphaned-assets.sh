#!/bin/bash
# Find orphaned assets in Immich database (files that no longer exist on disk)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Immich Orphaned Assets Scanner${NC}"
echo "================================"
echo ""

# Database connection details
DB_CONTAINER="immich_postgres"
DB_NAME="immich"
DB_USER="postgres"

# Output file
OUTPUT_FILE="/tmp/orphaned-assets-$(date +%Y%m%d-%H%M%S).txt"
OUTPUT_FILE_WINDOWS="D:/Immich/tools/logs/orphaned-assets-$(date +%Y%m%d-%H%M%S).txt"

echo "Querying database for all assets..."
echo ""

# Query to get all assets with their file paths
# The 'assets' table contains:
# - id: UUID of the asset
# - originalPath: Full path to the file on disk
# - type: IMAGE or VIDEO
# - isOffline: boolean flag (though this may not be set for upload libraries)

QUERY="
SELECT
    id,
    \"originalPath\",
    type,
    \"isOffline\",
    \"createdAt\"
FROM asset
WHERE \"deletedAt\" IS NULL
ORDER BY \"originalPath\";
"

echo "Running database query..."
ASSETS=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -A -F '|' -c "$QUERY")

if [ -z "$ASSETS" ]; then
    echo -e "${RED}Error: No assets found in database${NC}"
    exit 1
fi

TOTAL_ASSETS=$(echo "$ASSETS" | wc -l)
echo -e "${GREEN}Found $TOTAL_ASSETS assets in database${NC}"
echo ""

# Initialize counters
CHECKED=0
ORPHANED=0
EXISTS=0

# Create output file
echo "Orphaned Assets Report - $(date)" > "$OUTPUT_FILE"
echo "======================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Checking file existence on disk...${NC}"
echo ""

# Process each asset
while IFS='|' read -r id path type isOffline createdAt; do
    CHECKED=$((CHECKED + 1))

    # Show progress every 100 files
    if [ $((CHECKED % 100)) -eq 0 ]; then
        echo -ne "\rChecked: $CHECKED / $TOTAL_ASSETS (Orphaned: $ORPHANED, Exists: $EXISTS)"
    fi

    # Check if file exists on disk
    # Convert Unix path to Windows path if needed (Docker on Windows)
    if [ ! -f "$path" ]; then
        ORPHANED=$((ORPHANED + 1))
        echo "$id|$path|$type|$isOffline|$createdAt" >> "$OUTPUT_FILE"
    else
        EXISTS=$((EXISTS + 1))
    fi
done <<< "$ASSETS"

echo -ne "\rChecked: $CHECKED / $TOTAL_ASSETS (Orphaned: $ORPHANED, Exists: $EXISTS)\n"
echo ""

# Copy to Windows-accessible location
cp "$OUTPUT_FILE" "$OUTPUT_FILE_WINDOWS" 2>/dev/null || true

echo -e "${GREEN}Scan complete!${NC}"
echo ""
echo "Summary:"
echo "  Total assets in database: $TOTAL_ASSETS"
echo "  Files exist on disk:      $EXISTS"
echo "  Orphaned entries:         $ORPHANED"
echo ""

if [ $ORPHANED -gt 0 ]; then
    echo -e "${YELLOW}Orphaned assets saved to:${NC}"
    echo "  $OUTPUT_FILE_WINDOWS"
    echo ""
    echo "First 10 orphaned assets:"
    echo "-------------------------"
    head -n 13 "$OUTPUT_FILE" | tail -n 10
    echo ""
    echo -e "${YELLOW}To delete these orphaned entries, use the companion script:${NC}"
    echo "  bash ~/Documents/dev/applications/immich/scripts/delete-orphaned-assets.sh $OUTPUT_FILE_WINDOWS"
else
    echo -e "${GREEN}No orphaned assets found!${NC}"
fi

echo ""
