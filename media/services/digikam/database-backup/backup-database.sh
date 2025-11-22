#!/bin/bash
# Backup DigiKam MariaDB database

BACKUP_DIR="/d/DigiKam/backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/digikam-backup-$DATE.sql.gz"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}DigiKam Database Backup${NC}"
echo "========================================"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if container is running
if ! docker ps | grep -q digikam-mariadb; then
    echo -e "${YELLOW}ERROR: digikam-mariadb container is not running${NC}"
    exit 1
fi

echo "Starting backup..."
echo "Backup file: $BACKUP_FILE"

# Perform backup
docker exec digikam-mariadb mariadb-dump \
  -u root \
  -pDigiKam2025Root! \
  --single-transaction \
  --quick \
  --lock-tables=false \
  digikam | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    FILESIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}Backup completed successfully!${NC}"
    echo "File size: $FILESIZE"
    echo "Location: $BACKUP_FILE"
else
    echo -e "${YELLOW}Backup failed!${NC}"
    exit 1
fi

# Keep only last 7 backups
echo ""
echo "Cleaning up old backups (keeping last 7)..."
ls -t "$BACKUP_DIR"/digikam-backup-*.sql.gz | tail -n +8 | while read file; do
    echo "Deleting: $file"
    rm "$file"
done

echo ""
echo "Backup retention:"
ls -lh "$BACKUP_DIR"/digikam-backup-*.sql.gz 2>/dev/null | wc -l | xargs echo "Total backups:"

echo ""
echo "========================================"
echo -e "${GREEN}Done!${NC}"
