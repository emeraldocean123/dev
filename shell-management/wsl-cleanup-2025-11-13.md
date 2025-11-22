# WSL Cleanup - November 13, 2025

## Summary

Cleaned up WSL distributions and Windows Terminal profiles after successful Immich installation with Docker Desktop.

## Actions Taken

### 1. Removed Debian-CasaOS WSL Distribution

**Reason:** CasaOS was no longer needed after successfully installing Immich via Docker Desktop for Windows.

**Steps:**
```bash
wsl --terminate Debian-CasaOS
wsl --unregister Debian-CasaOS
```

**Result:**
- Debian-CasaOS WSL distribution removed
- Freed ~2 GB on C: drive
- CasaOS installation (which did complete successfully) was removed

### 2. Cleaned Windows Terminal Profiles

**Issue:** Windows Terminal had duplicate Debian profiles:
1. Custom Debian profile (manual, with custom icon) - **Kept**
2. Auto-generated Debian profile (from WSL) - **Removed**
3. Debian-CasaOS profile - **Removed**

**File:** `C:\Users\josep\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

**Changes:**
- Removed auto-generated duplicate Debian profile (GUID: `{75f9d99c-a71c-51d4-89bc-2ca201acaf93}`)
- Removed Debian-CasaOS profile (GUID: `{8397bc92-fb47-5573-b9e2-3b7b7d1fdf85}`)
- Kept custom Debian profile (GUID: `{fc594fcd-196a-468f-b16e-449aa09be599}`)

**Note:** `disabledProfileSources` includes `"Windows.Terminal.Wsl"` to prevent future auto-generation of WSL profiles.

### 3. Removed Unused Files

**Deleted:**
- `D:\WSL\Exports\debian-13-rootfs.tar.xz` (196 MB) - Unused Debian Trixie rootfs
- `~/Documents/dev/shell-management/create-debian-casaos.ps1` - Obsolete CasaOS setup script

**Kept:**
- `D:\WSL\Exports\debian-export.tar` (2.0 GB) - Backup of original Debian WSL (before move to D: drive)

## Final WSL State

**Active Distributions:**
```
NAME              STATE      VERSION  LOCATION
Debian            Running    2        D:\WSL\Debian\
docker-desktop    Running    2        (Docker Desktop managed)
```

**Removed:**
- Debian-CasaOS ✓

## Windows Terminal Profiles

**Active Profiles:**
1. PowerShell 7 (default)
2. **Debian** (custom, on D: drive)
3. Git Bash
4. PowerShell 5
5. Command Prompt
6. Azure Cloud Shell

**Removed Profiles:**
- Duplicate auto-generated Debian ✓
- Debian-CasaOS ✓

## Docker Desktop WSL Backend

**Important:** The `docker-desktop` WSL distribution is automatically created and managed by Docker Desktop for Windows. This is normal and required for Docker to function. Do not remove it.

**Purpose:** Docker Desktop uses WSL2 as its backend, which provides:
- Linux kernel for Docker containers
- Better performance than Hyper-V backend
- EXT4 filesystem for PostgreSQL (required by Immich)

## Space Freed

- **C: drive:** ~2 GB (Debian-CasaOS VHDX removed)
- **D: drive:** 196 MB (debian-13-rootfs.tar.xz removed)
- **Total:** ~2.2 GB freed

## Notes

1. **Debian WSL** is your primary Linux environment (located on D:\WSL\Debian\)
2. **docker-desktop** is managed by Docker Desktop - required for Immich
3. Windows Terminal now shows only one Debian profile (no duplicates)
4. Original Debian backup (debian-export.tar) kept for safety
5. CasaOS installation was functional but no longer needed

## Related Documentation

- WSL migration: `~/Documents/dev/shell-management/move-wsl-to-d-drive.ps1`
- Immich installation: `~/Documents/dev/photos/immich-windows-install.md`
- Shell configs: `~/Documents/dev/shell-management/shell-configs.md`

## Verification Commands

```bash
# List WSL distributions
wsl --list --verbose

# Check Windows Terminal profiles (should show no duplicates)
# Open Windows Terminal → Settings → Profiles

# Verify Debian works
wsl -d Debian whoami

# Verify Docker Desktop
docker --version
docker ps
```

## Future Recommendations

1. Keep `debian-export.tar` as backup for at least 30 days
2. Monitor Docker Desktop WSL usage via `docker system df`
3. If C: drive space becomes critical, consider expanding Docker Desktop VHDX limit
4. Windows Terminal auto-generation is disabled - manual profile management only
