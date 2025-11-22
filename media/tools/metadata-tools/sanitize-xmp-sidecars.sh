#!/bin/bash
# Simple XMP Sanitization using ExifTool's built-in recursive processing
# This is the FASTEST approach - single ExifTool command processes all files
# Modified for PhotoMove directory

LIBRARY_PATH="/d/PhotoMove"

echo "XMP Sanitization for PhotoMove (Simple Fast Mode)"
echo "=================================================="
echo ""
echo "Processing all XMP files in: $LIBRARY_PATH"
echo ""
echo "This will:"
echo "  - Keep only Immich-compatible metadata"
echo "  - Create .xmp_original backups automatically"
echo "  - Process all 78,105 files in a single ExifTool run"
echo ""
echo "Starting sanitization..."
echo ""

# Run ExifTool once on the entire directory tree
# -all= removes all metadata
# -tagsFromFile @ copies back only the tags we specify
# -overwrite_original_in_place processes files in-place
# -ext xmp processes only .xmp files
# -r recursively processes subdirectories
# -progress shows progress

exiftool \
  -all= \
  -tagsFromFile @ \
  -Description \
  -ImageDescription \
  -Rating \
  -DateTimeOriginal \
  -SubSecDateTimeOriginal \
  -DateCreated \
  -CreateDate \
  -SubSecCreateDate \
  -CreationDate \
  -MediaCreateDate \
  -SubSecMediaCreateDate \
  -DateTimeCreated \
  -GPSLatitude \
  -GPSLongitude \
  -GPSLatitudeRef \
  -GPSLongitudeRef \
  -TagsList \
  -HierarchicalSubject \
  -Keywords \
  -ext xmp \
  -r \
  -progress \
  "$LIBRARY_PATH"

echo ""
echo "Sanitization complete!"
echo ""
echo "Backup files created with .xmp_original extension"
echo "To remove backups after verifying: find '$LIBRARY_PATH' -name '*.xmp_original' -delete"
echo ""
