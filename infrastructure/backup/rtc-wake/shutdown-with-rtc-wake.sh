#!/bin/bash
#
# Shutdown with RTC Wake Timer
# Configures system to wake at 2:50 AM for ZFS replication at 3:00 AM
# Sets RTC (Real-Time Clock) alarm before shutting down
#
# DEPLOYMENT:
#   Device: intel-n6005-proxmox-host (192.168.1.41)
#   Path:   /root/sh/shutdown-with-rtc-wake.sh
#   Backup: ~/Documents/dev/sh/shutdown-with-rtc-wake.sh (Windows)
#
# EXECUTION:
#   - Called by zfs-replicate-pbs.sh on intel-1250p after replication completes
#   - Can be run manually: ./shutdown-with-rtc-wake.sh
#   - Calculates next 2:50 AM wake time
#   - Sets RTC wake alarm
#   - Shuts down system immediately
#
# USAGE:
#   ssh intel-n6005
#   cd /root/sh
#   ./shutdown-with-rtc-wake.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
# NC='\033[0m'  # Unused but kept for consistency

echo -e "${BLUE}[RTC] Setting up RTC wake timer..."

# Target wake time: 2:50 AM tomorrow
TARGET_HOUR=2
TARGET_MINUTE=50

# Get current time
CURRENT_EPOCH=$(date +%s)
CURRENT_HOUR=$(date +%H)

# Calculate next 2:50 AM
if [ "$CURRENT_HOUR" -lt "$TARGET_HOUR" ]; then
    # If before 2:50 AM today, wake today at 2:50 AM
    WAKE_TIME=$(date -d "today ${TARGET_HOUR}:${TARGET_MINUTE}:00" +%s)
else
    # If after 2:50 AM, wake tomorrow at 2:50 AM
    WAKE_TIME=$(date -d "tomorrow ${TARGET_HOUR}:${TARGET_MINUTE}:00" +%s)
fi

SECONDS_UNTIL_WAKE=$((WAKE_TIME - CURRENT_EPOCH))
WAKE_DATE=$(date -d @"$WAKE_TIME")

echo -e "${GREEN}[RTC] Current time: $(date)"
echo -e "${GREEN}[RTC] Wake time: $WAKE_DATE"
echo -e "${GREEN}[RTC] Seconds until wake: $SECONDS_UNTIL_WAKE"

# Set RTC wake alarm
if rtcwake -m no -s "$SECONDS_UNTIL_WAKE"; then
    echo -e "${GREEN}[RTC] RTC wake alarm set successfully"
else
    echo -e "${YELLOW}[WARN] Failed to set RTC wake alarm"
    exit 1
fi

echo -e "${BLUE}[RTC] Shutting down in 5 seconds..."
sleep 5

shutdown -h now
