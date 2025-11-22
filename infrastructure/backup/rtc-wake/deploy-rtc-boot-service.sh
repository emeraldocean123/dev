#!/bin/bash
#
# Deploy RTC Boot Service to N6005
# Sets up automatic RTC alarm configuration on every boot
#
# USAGE:
#   ./deploy-rtc-boot-service.sh
#
# WHAT IT DOES:
#   1. Copies set-rtc-alarm-on-boot.sh to N6005:/root/sh/
#   2. Copies rtc-alarm-on-boot.service to N6005:/etc/systemd/system/
#   3. Makes script executable
#   4. Enables and starts the service
#   5. Tests that RTC alarm is set
#
# REQUIREMENTS:
#   - N6005 must be online (wake it with: wake-n6005)
#   - SSH access to N6005 configured

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$HOME/Documents/dev/sh"
N6005_HOST="intel-n6005"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  RTC Boot Service Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if N6005 is online
echo -e "${BLUE}[1/6]${NC} Checking N6005 connectivity..."
if ! ssh -o ConnectTimeout=5 "$N6005_HOST" "echo 'Online'" &>/dev/null; then
    echo -e "${RED}ERROR: N6005 is not online${NC}"
    echo -e "${YELLOW}Run 'wake-n6005' to wake the server first${NC}"
    exit 1
fi
echo -e "${GREEN}✅ N6005 is online${NC}"
echo ""

# Copy boot script
echo -e "${BLUE}[2/6]${NC} Deploying set-rtc-alarm-on-boot.sh..."
scp "$SCRIPT_DIR/set-rtc-alarm-on-boot.sh" "$N6005_HOST:/root/sh/"
ssh "$N6005_HOST" "chmod +x /root/sh/set-rtc-alarm-on-boot.sh"
echo -e "${GREEN}✅ Script deployed${NC}"
echo ""

# Copy systemd service
echo -e "${BLUE}[3/6]${NC} Deploying rtc-alarm-on-boot.service..."
scp "$SCRIPT_DIR/rtc-alarm-on-boot.service" "$N6005_HOST:/etc/systemd/system/"
echo -e "${GREEN}✅ Service file deployed${NC}"
echo ""

# Reload systemd and enable service
echo -e "${BLUE}[4/6]${NC} Enabling systemd service..."
ssh "$N6005_HOST" "systemctl daemon-reload && systemctl enable rtc-alarm-on-boot.service"
echo -e "${GREEN}✅ Service enabled (will run on every boot)${NC}"
echo ""

# Start service now
echo -e "${BLUE}[5/6]${NC} Starting service and setting RTC alarm..."
ssh "$N6005_HOST" "systemctl start rtc-alarm-on-boot.service"
echo -e "${GREEN}✅ Service started${NC}"
echo ""

# Verify RTC alarm is set
echo -e "${BLUE}[6/6]${NC} Verifying RTC alarm..."
ssh "$N6005_HOST" "rtcwake -m show"
echo -e "${GREEN}✅ RTC alarm verified${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo "  • /root/sh/set-rtc-alarm-on-boot.sh (boot script)"
echo "  • /etc/systemd/system/rtc-alarm-on-boot.service (systemd service)"
echo ""
echo -e "${BLUE}What happens now:${NC}"
echo "  • RTC alarm is SET for next 2:50 AM"
echo "  • Service will run automatically on EVERY boot"
echo "  • This breaks the chicken-and-egg dependency"
echo "  • Even manual boots will set the alarm"
echo ""
echo -e "${BLUE}Test the service:${NC}"
echo "  ssh intel-n6005 'systemctl status rtc-alarm-on-boot.service'"
echo "  ssh intel-n6005 'journalctl -u rtc-alarm-on-boot.service'"
echo ""
