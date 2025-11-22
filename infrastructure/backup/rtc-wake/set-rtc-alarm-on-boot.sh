#!/bin/bash
#
# Set RTC Wake Alarm on Boot
# Ensures N6005 always has an RTC alarm set for next 2:50 AM
# Runs automatically on every boot via systemd service
#
# DEPLOYMENT:
#   Device: intel-n6005-proxmox-host (192.168.1.41)
#   Path:   /root/sh/set-rtc-alarm-on-boot.sh
#   Service: /etc/systemd/system/rtc-alarm-on-boot.service
#   Backup: ~/Documents/dev/sh/set-rtc-alarm-on-boot.sh (Windows)
#
# EXECUTION:
#   - Called by systemd on boot
#   - Can be run manually: ./set-rtc-alarm-on-boot.sh
#   - Idempotent - safe to run multiple times
#
# PURPOSE:
#   - Ensures RTC alarm is ALWAYS set, even after manual boots
#   - Breaks the chicken-and-egg dependency on replication script
#   - Provides automatic recovery if alarm cycle breaks

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[RTC-BOOT] Setting up RTC wake timer on boot..."

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

echo -e "${GREEN}[RTC-BOOT] Current time: $(date)"
echo -e "${GREEN}[RTC-BOOT] Wake time: $WAKE_DATE"
echo -e "${GREEN}[RTC-BOOT] Seconds until wake: $SECONDS_UNTIL_WAKE"

# Set RTC wake alarm
if rtcwake -m no -s "$SECONDS_UNTIL_WAKE"; then
    echo -e "${GREEN}[RTC-BOOT] ✅ RTC wake alarm set successfully on boot"
else
    echo -e "${YELLOW}[WARN] ⚠️  Failed to set RTC wake alarm on boot"
    exit 1
fi

echo -e "${BLUE}[RTC-BOOT] RTC alarm configured. System will wake at 2:50 AM for daily replication.${NC}"
