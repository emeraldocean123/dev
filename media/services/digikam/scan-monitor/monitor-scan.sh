#!/bin/bash
# Monitor DigiKam scanning progress

echo "DigiKam Scan Progress Monitor"
echo "=============================="
echo "Target: 82,345 total files"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    # Get current count
    COUNT=$(docker exec -i digikam-mariadb mariadb -u root -pDigiKam2025Root! -sN << 'EOF'
USE `digikam-core`;
SELECT COUNT(*) FROM Images;
EOF
)

    # Calculate percentage
    PERCENT=$(echo "scale=2; ($COUNT / 82345) * 100" | bc)

    # Clear previous line and show progress
    echo -ne "\rImages scanned: $COUNT / 82,345 ($PERCENT%)    "

    # Wait 5 seconds before next check
    sleep 5
done
