#!/bin/bash
# Remove ALL keywords from XMP and metadata using single ExifTool instance
# Memory efficient - spawns only ONE ExifTool process for entire library

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration
LIBRARY_PATH="/d/Immich/library/library"
LOG_DIR="/d/Immich/tools/logs"
LOG_FILE="$LOG_DIR/keyword-removal-$(date +%Y%m%d-%H%M%S).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to validate ExifTool is available
check_exiftool() {
    if ! command -v exiftool &> /dev/null; then
        log "ERROR: ExifTool not found. Please install ExifTool first."
        exit 1
    fi
}

# Function to validate library path exists
check_library_path() {
    if [ ! -d "$LIBRARY_PATH" ]; then
        log "ERROR: Library path not found: $LIBRARY_PATH"
        exit 1
    fi
}

# Main execution
main() {
    log "========================================"
    log "Keyword Removal Tool"
    log "========================================"
    log ""
    log "Started: $(date)"
    log "Library: $LIBRARY_PATH"
    log "Log file: $LOG_FILE"
    log ""

    # Validation
    check_exiftool
    check_library_path

    log "This will:"
    log "  - Remove ALL keywords from images and XMP sidecars"
    log "  - Remove TagsList, HierarchicalSubject, Keywords, Subject, etc."
    log "  - Overwrite files in-place (NO backups created)"
    log "  - Process entire library in a single ExifTool run"
    log ""
    log "Starting keyword removal..."
    log ""

    # Run ExifTool once on the entire directory tree
    # This removes ALL keyword-related tags from both:
    # - Image files (EXIF/IPTC/XMP embedded metadata)
    # - XMP sidecar files
    #
    # Tags being removed:
    # - Keywords (standard IPTC keyword field)
    # - TagsList (Lightroom tags)
    # - HierarchicalSubject (hierarchical keywords like "Merlinda's Travel Drive For Safety Committee")
    # - Subject (Dublin Core subject field)
    # - LastKeywordXMP, LastKeywordIPTC (Lightroom cache)
    # - CatalogSets (Catalog/collection references)
    #
    # Options:
    # -r = recursive
    # -progress = show progress bar
    # -overwrite_original = no backup files created

    exiftool \
      -Keywords= \
      -TagsList= \
      -HierarchicalSubject= \
      -Subject= \
      -LastKeywordXMP= \
      -LastKeywordIPTC= \
      -CatalogSets= \
      -overwrite_original  \
      -r \
      -progress \
      -ext jpg \
      -ext jpeg \
      -ext png \
      -ext heic \
      -ext dng \
      -ext nef \
      -ext cr2 \
      -ext arw \
      -ext xmp \
      "$LIBRARY_PATH" 2>&1 | tee -a "$LOG_FILE"

    EXIFTOOL_EXIT_CODE=${PIPESTATUS[0]}

    log ""
    log "========================================"
    if [ $EXIFTOOL_EXIT_CODE -eq 0 ]; then
        log "Keyword removal completed successfully!"
    else
        log "WARNING: ExifTool exited with code $EXIFTOOL_EXIT_CODE"
        log "Check the log file for details: $LOG_FILE"
    fi
    log "========================================"
    log ""
    log "Finished: $(date)"
    log ""
    log "NOTE: No backup files created (-overwrite_original flag used)"
    log "Changes are permanent and cannot be restored."
    log ""
}

# Run main function
main
