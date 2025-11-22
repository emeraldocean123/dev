# Microsoft Edge Tab Organization

**Last Updated:** October 17, 2025
**Status:** Policy enabled, feature not yet available in UI

## Overview

Microsoft Edge's Tab Organization feature provides automatic suggestions to group and organize open tabs based on content similarity. This feature can be enabled via Registry policies.

## Registry Configuration

### Location
```
HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge
```

### Key Details
- **Name:** `TabServicesEnabled`
- **Type:** `REG_DWORD`
- **Values:**
  - `1` = Enabled (allows tab organization feature)
  - `0` = Disabled (blocks tab organization feature)
  - Not set = Feature availability depends on Edge defaults

## Current Status

**Policy Status:** Enabled (`TabServicesEnabled = 1`)
**Edge Version:** 141.0.3537.85 (October 2025)
**UI Availability:** Not showing in Settings
**Likely Cause:** Gradual rollout - feature not available for all accounts/regions yet

## Files

### Registry Files (`~/Documents/dev/reg/`)

**1. Enable-Edge-Tab-Organization.reg**
- Enables the Tab Organization feature
- Creates policy: `TabServicesEnabled = 1`
- Shows "Managed by your organization" message in Edge

**2. Remove-Edge-Tab-Organization.reg**
- Removes all Edge policies (entire registry key)
- Removes "Managed by your organization" message
- Restores default Edge behavior

### Scripts (`~/Documents/dev/sh/`)

**1. remove-edge-tab-organization.sh**
- Bash script to remove Edge Tab Organization policy
- Works in Git Bash on Windows
- Removes the registry key via PowerShell
- More convenient than double-clicking .reg file

## Usage

### Enable Tab Organization

**Method 1: Using .reg file**
```bash
# Double-click the file in File Explorer
~/Documents/dev/reg/Enable-Edge-Tab-Organization.reg
```

**Method 2: Using Registry Editor**
```
1. Press Win+R, type: regedit
2. Navigate to: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge
3. Create DWORD: TabServicesEnabled = 1
```

### Disable/Remove Tab Organization

**Method 1: Using .reg file**
```bash
# Double-click the file in File Explorer
~/Documents/dev/reg/Remove-Edge-Tab-Organization.reg
```

**Method 2: Using script**
```bash
# From Git Bash
~/Documents/dev/sh/remove-edge-tab-organization.sh
```

**Method 3: Using Registry Editor**
```
1. Press Win+R, type: regedit
2. Navigate to: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft
3. Delete the "Edge" key (if you want to remove ALL Edge policies)
   OR
4. Navigate to: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge
5. Delete the "TabServicesEnabled" value (keeps Edge key for other policies)
```

## Expected Behavior

### When Enabled via Policy

**What happens:**
- `edge://policy` shows: `TabServicesEnabled = true`
- Edge displays "Managed by your organization" in Settings
- UI setting should appear in: `edge://settings/privacy` under "Services"
- Feature provides automatic tab grouping suggestions

**Current issue:**
- Policy is enabled but UI setting not appearing
- Likely due to Microsoft's gradual feature rollout
- Feature may become available in future updates

### When Removed/Disabled

**What happens:**
- "Managed by your organization" message disappears
- Policy no longer shows in `edge://policy`
- Tab Organization returns to default availability
- Manual tab groups still work (always available)

## Alternative: Manual Tab Groups

Even without automatic organization, you can manually group tabs:

1. **Right-click any tab**
2. Select **"Add tab to new group"**
3. Choose a color and name
4. Drag tabs into groups

This feature is always available regardless of policy settings.

## Verification

### Check Policy Status
```
1. Open Edge
2. Go to: edge://policy
3. Look for: TabServicesEnabled
   - Value: true (enabled)
   - Status: OK
   - Source: Platform
```

### Check Feature Availability
```
1. Open Edge
2. Go to: edge://settings/privacy
3. Scroll to "Services" section
4. Look for: "Let Microsoft Edge help keep your tabs organized"
```

### Check for Experimental Flags
```
1. Open Edge
2. Go to: edge://flags
3. Search for: "tab", "group", "organize"
4. Enable any experimental tab organization features
5. Restart Edge
```

## Notes

- The policy enables the feature at the system level but doesn't guarantee UI availability
- Microsoft may be rolling out the feature gradually by account type or region
- Edge version 141+ should support this feature, but it may not be visible yet
- The "Managed by your organization" message is normal and expected when policies are set
- Removing the policy doesn't disable manual tab grouping (always available)

## Troubleshooting

### Feature Not Showing After Enabling Policy

**Try these steps:**
1. Verify policy is applied: `edge://policy`
2. Completely restart Edge (close all windows)
3. Check Edge version (should be 141+)
4. Search `edge://flags` for experimental features
5. Wait for Microsoft to complete feature rollout

### "Managed by your organization" Message

**This is normal when:**
- Any policy is set in `HKLM\SOFTWARE\Policies\Microsoft\Edge`
- Not a sign of malware or intrusion
- Can be removed by deleting the policy

**To remove the message:**
- Use `Remove-Edge-Tab-Organization.reg`
- Or run `remove-edge-tab-organization.sh`

## References

- **Edge Policies Documentation:** https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies
- **Edge Release Notes:** https://learn.microsoft.com/en-us/deployedge/microsoft-edge-relnote-stable-channel
- **Policy Settings:** `edge://policy`
- **Flags/Experiments:** `edge://flags`

## Related Files

- Registry files: `~/Documents/dev/reg/`
- Scripts: `~/Documents/dev/sh/`
- Documentation: `~/Documents/dev/md/`

## Change Log

**October 17, 2025**
- Created `TabServicesEnabled` policy
- Enabled via Registry (value = 1)
- Created .reg files for enable/disable
- Created bash script for removal
- Feature not yet available in UI despite policy being enabled
