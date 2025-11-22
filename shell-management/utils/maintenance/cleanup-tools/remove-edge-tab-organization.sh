#!/bin/bash
#
# Remove Edge Tab Organization Policy
# Removes the TabServicesEnabled registry policy from Edge
# This eliminates the "Managed by your organization" message
#
# USAGE:
#   ./remove-edge-tab-organization.sh
#
# WHAT IT DOES:
#   - Removes HKLM\SOFTWARE\Policies\Microsoft\Edge registry key
#   - Removes "Managed by your organization" message from Edge
#   - Requires administrator privileges (will prompt for UAC)
#
# DEPLOYMENT:
#   Windows: ~/Documents/dev/sh/remove-edge-tab-organization.sh
#
# NOTE:
#   This removes the ENTIRE Edge policy key. If you have other Edge policies
#   you want to keep, edit the script to only remove TabServicesEnabled value.

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Remove Edge Tab Organization Policy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check current status
echo -e "${BLUE}[1/3]${NC} Checking current policy status..."

if powershell.exe -NoProfile -Command "Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'" | grep -q "True"; then
    echo -e "${YELLOW}  Edge policies key exists${NC}"

    # Check if TabServicesEnabled is set
    if powershell.exe -NoProfile -Command "Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'TabServicesEnabled' -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "TabServicesEnabled"; then
        echo -e "${YELLOW}  TabServicesEnabled policy is currently set${NC}"
    else
        echo -e "${GREEN}  TabServicesEnabled policy is not set${NC}"
        echo ""
        echo -e "${GREEN}No policy to remove. Exiting.${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}  No Edge policies found${NC}"
    echo ""
    echo -e "${GREEN}No policy to remove. Exiting.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[2/3]${NC} Removing Edge Tab Organization policy..."

# Remove the registry key (requires admin)
# Using PowerShell with UAC elevation
powershell.exe -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -Command \"Remove-Item -Path ''HKLM:\SOFTWARE\Policies\Microsoft\Edge'' -Recurse -Force -ErrorAction SilentlyContinue; if (-not (Test-Path ''HKLM:\SOFTWARE\Policies\Microsoft\Edge'')) { Write-Host ''Registry key removed successfully'' -ForegroundColor Green } else { Write-Host ''Failed to remove registry key'' -ForegroundColor Red }; Write-Host ''''; Write-Host ''Press any key to close...''; \\\$null = \\\$Host.UI.RawUI.ReadKey(''NoEcho,IncludeKeyDown'')\"' -Verb RunAs"

# Wait for user to complete the admin operation
echo -e "${YELLOW}  Waiting for admin operation to complete...${NC}"
sleep 3

echo ""
echo -e "${BLUE}[3/3]${NC} Verifying removal..."

# Check if the key was removed
if powershell.exe -NoProfile -Command "Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'" | grep -q "False"; then
    echo -e "${GREEN}✅ Policy removed successfully${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Removal Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}What changed:${NC}"
    echo "  • Edge Tab Organization policy removed"
    echo "  • \"Managed by your organization\" message will disappear"
    echo "  • Edge will use default settings"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Restart Microsoft Edge completely"
    echo "  2. Check edge://policy (should show no policies)"
    echo "  3. \"Managed by your organization\" message should be gone"
    echo ""
else
    echo -e "${YELLOW}⚠ Policy key still exists${NC}"
    echo ""
    echo -e "${YELLOW}Possible reasons:${NC}"
    echo "  • UAC prompt was cancelled"
    echo "  • You don't have administrator privileges"
    echo "  • The registry key is locked by another process"
    echo ""
    echo -e "${BLUE}Try again:${NC}"
    echo "  • Run this script again and approve the UAC prompt"
    echo "  • Or use: Remove-Edge-Tab-Organization.reg"
    echo ""
fi

exit 0
