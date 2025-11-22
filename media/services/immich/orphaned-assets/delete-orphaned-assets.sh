#!/bin/bash
# Delete orphaned assets from Immich database
# USAGE: bash delete-orphaned-assets.sh <orphaned-assets-file>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing orphaned assets file${NC}"
    echo "Usage: bash delete-orphaned-assets.sh <orphaned-assets-file>"
    echo ""
    echo "Example:"
    echo "  bash delete-orphaned-assets.sh D:/Immich/tools/logs/orphaned-assets-20251115-120000.txt"
    exit 1
fi

ORPHANED_FILE="$1"

if [ ! -f "$ORPHANED_FILE" ]; then
    echo -e "${RED}Error: File not found: $ORPHANED_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Immich Orphaned Assets Deletion Tool${NC}"
echo "======================================"
echo ""

# Count orphaned assets (skip header lines)
TOTAL_ORPHANED=$(grep -v "^Orphaned Assets Report\|^====\|^$" "$ORPHANED_FILE" | wc -l)

if [ $TOTAL_ORPHANED -eq 0 ]; then
    echo -e "${GREEN}No orphaned assets to delete!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found $TOTAL_ORPHANED orphaned assets to delete${NC}"
echo ""
echo "WARNING: This will permanently delete these database entries!"
echo "Make sure you have a backup of your database before proceeding."
echo ""
echo -n "Type 'DELETE' to confirm deletion: "
read -r CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo -e "${RED}Deletion cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting deletion...${NC}"

# Database connection details
DB_CONTAINER="immich_postgres"
DB_NAME="immich"
DB_USER="postgres"

# Process each orphaned asset
DELETED=0
FAILED=0

while IFS='|' read -r id path type isOffline createdAt; do
    # Skip header lines and empty lines
    if [[ "$id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        # Delete from database
        DELETE_QUERY="DELETE FROM asset WHERE id = '$id';"

        if docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "$DELETE_QUERY" > /dev/null 2>&1; then
            DELETED=$((DELETED + 1))
            echo -ne "\rDeleted: $DELETED / $TOTAL_ORPHANED"
        else
            FAILED=$((FAILED + 1))
            echo ""
            echo -e "${RED}Failed to delete: $id ($path)${NC}"
        fi
    fi
done < "$ORPHANED_FILE"

echo ""
echo ""
echo -e "${GREEN}Deletion complete!${NC}"
echo ""
echo "Summary:"
echo "  Total orphaned assets: $TOTAL_ORPHANED"
echo "  Successfully deleted:  $DELETED"
echo "  Failed to delete:      $FAILED"
echo ""

if [ $DELETED -gt 0 ]; then
    echo -e "${YELLOW}Recommendation:${NC}"
    echo "  1. Restart Immich containers to clear caches:"
    echo "     cd /d/Immich && docker compose restart"
    echo ""
    echo "  2. Verify in Immich web UI that orphaned assets are gone"
    echo ""
fi
