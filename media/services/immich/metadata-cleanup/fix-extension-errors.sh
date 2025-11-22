#!/bin/bash
# Remove keywords from the 10 files with corrected extensions
# These files had mismatched extensions (JPEG files with .heic, HEIC files with .jpg)

set -euo pipefail

LIBRARY_PATH="/d/Immich/library/library/admin"
LOG_DIR="/d/Immich/tools/logs"
LOG_FILE="$LOG_DIR/keyword-removal-fixed-extensions-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "========================================"
log "Keyword Removal - Fixed Extensions"
log "========================================"
log ""
log "Started: $(date)"
log ""

# Process the 8 files that were .heic but are actually .jpg (now renamed)
log "Processing 8 JPEG files (formerly .heic)..."
exiftool \
  -Keywords= \
  -TagsList= \
  -HierarchicalSubject= \
  -Subject= \
  -LastKeywordXMP= \
  -LastKeywordIPTC= \
  -CatalogSets= \
  -overwrite_original \
  -progress \
  "$LIBRARY_PATH/2018/12/2018-12-02-08-42-42-IMAGE-98f7fb16-e1a1-4217-8c01-631b04330f9c.jpg" \
  "$LIBRARY_PATH/2018/12/2018-12-02-08-43-29-IMAGE-5b7769c7-a78a-4628-b1fc-9eee43135dba.jpg" \
  "$LIBRARY_PATH/2018/12/2018-12-05-11-44-00-IMAGE-eaf9fb66-15e4-4411-a6d3-36fc7d472e0b.jpg" \
  "$LIBRARY_PATH/2020/01/2020-01-22-12-15-03-IMAGE-5251fae8-586e-4151-8afc-8c046aab242b.jpg" \
  "$LIBRARY_PATH/2020/01/2020-01-26-10-10-36-IMAGE-b5c20342-8b3f-4767-9182-68defd446604.jpg" \
  "$LIBRARY_PATH/2020/02/2020-02-24-11-35-26-IMAGE-e5439619-64c6-4ad0-8877-9fb0ae17a000.jpg" \
  "$LIBRARY_PATH/2020/05/2020-05-24-01-18-17-IMAGE-7ddb728c-b476-407f-aa56-7807abd75d03.jpg" \
  "$LIBRARY_PATH/2020/05/2020-05-24-01-18-43-IMAGE-05ddfefb-dc6c-4c64-90ab-c19d88dcd947.jpg" \
  2>&1 | tee -a "$LOG_FILE"

JPEG_EXIT_CODE=${PIPESTATUS[0]}

log ""
log "Processing 2 HEIC files (formerly .jpg)..."
exiftool \
  -Keywords= \
  -TagsList= \
  -HierarchicalSubject= \
  -Subject= \
  -LastKeywordXMP= \
  -LastKeywordIPTC= \
  -CatalogSets= \
  -overwrite_original \
  -progress \
  "$LIBRARY_PATH/2025/06/2025-06-07-06-00-00-IMAGE-a45bfdad-ffe9-4ba6-b6b7-1ecca22573b8.heic" \
  "$LIBRARY_PATH/2025/06/2025-06-19-12-53-00-IMAGE-dde3fb2d-6057-48c4-800a-e4d501f0133d.heic" \
  2>&1 | tee -a "$LOG_FILE"

HEIC_EXIT_CODE=${PIPESTATUS[0]}

log ""
log "========================================"
if [ $JPEG_EXIT_CODE -eq 0 ] && [ $HEIC_EXIT_CODE -eq 0 ]; then
    log "All files processed successfully!"
else
    log "WARNING: Some files may have errors"
    log "JPEG exit code: $JPEG_EXIT_CODE"
    log "HEIC exit code: $HEIC_EXIT_CODE"
fi
log "========================================"
log ""
log "Finished: $(date)"
log ""
log "NOTE: No backup files created (-overwrite_original flag used)"
log "Changes are permanent and cannot be restored."
log ""
