#!/bin/bash
# Simple XMP Sanitization using ExifTool's built-in recursive processing
# This is the FASTEST approach - single ExifTool command processes all files

LIBRARY_PATH="/d/Immich/library/library"

echo "XMP Sanitization (Simple Fast Mode)"
echo "===================================="
echo ""
echo "Processing all XMP files in: $LIBRARY_PATH"
echo ""
echo "This will:"
echo "  - Keep only Immich-compatible metadata"
echo "  - Overwrite files in-place (NO backups created)"
echo "  - Process all XMP files in a single ExifTool run"
echo ""
echo "Starting sanitization..."
echo ""

# Run ExifTool once on the entire directory tree
# -all= removes all metadata
# -tagsFromFile @ copies back only the tags we specify
# -overwrite_original = no backup files created
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
  -overwrite_original \
  -ext xmp \
  -r \
  -progress \
  "$LIBRARY_PATH"

echo ""
echo "Sanitization complete!"
echo ""
