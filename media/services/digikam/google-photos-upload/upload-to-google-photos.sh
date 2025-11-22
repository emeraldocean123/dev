#!/bin/bash
# Upload photos from DigiKam export to Google Photos using rclone

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}DigiKam → Google Photos Upload Script${NC}"
echo "========================================"
echo ""

# Check if rclone is configured for Google Photos
if ! rclone listremotes | grep -q "googlephotos:"; then
    echo -e "${YELLOW}Google Photos is not configured in rclone.${NC}"
    echo ""
    echo "Please run the following command to set up Google Photos:"
    echo ""
    echo -e "${BLUE}  rclone config${NC}"
    echo ""
    echo "Configuration steps:"
    echo "  1. Type 'n' for new remote"
    echo "  2. Name: googlephotos"
    echo "  3. Storage: Choose 'Google Photos'"
    echo "  4. Follow OAuth authentication prompts"
    echo "  5. When done, run this script again"
    echo ""
    exit 1
fi

# Get source folder
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <source-folder> [album-name]${NC}"
    echo ""
    echo "Examples:"
    echo "  $0 /d/DigiKam/export"
    echo "  $0 /d/DigiKam/export \"Family Vacation 2024\""
    echo ""
    exit 1
fi

SOURCE_FOLDER="$1"
ALBUM_NAME="${2:-Uploaded from DigiKam}"

# Check if source folder exists
if [ ! -d "$SOURCE_FOLDER" ]; then
    echo -e "${YELLOW}ERROR: Folder not found: $SOURCE_FOLDER${NC}"
    exit 1
fi

# Count photos
PHOTO_COUNT=$(find "$SOURCE_FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" -o -iname "*.mov" -o -iname "*.mp4" \) | wc -l)

if [ "$PHOTO_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No photos found in: $SOURCE_FOLDER${NC}"
    exit 1
fi

echo "Source folder: $SOURCE_FOLDER"
echo "Album name: $ALBUM_NAME"
echo "Photos to upload: $PHOTO_COUNT"
echo ""
echo -e "${BLUE}Starting upload to Google Photos...${NC}"
echo ""

# Upload to Google Photos
rclone copy \
    --include "*.{jpg,jpeg,png,heic,mov,mp4,JPG,JPEG,PNG,HEIC,MOV,MP4}" \
    --progress \
    --stats 10s \
    "$SOURCE_FOLDER" \
    "googlephotos:album/$ALBUM_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Upload completed successfully!${NC}"
    echo ""
    echo "Your photos are now in Google Photos album: $ALBUM_NAME"
    echo "View at: https://photos.google.com/"
else
    echo ""
    echo -e "${YELLOW}✗ Upload failed!${NC}"
    exit 1
fi
