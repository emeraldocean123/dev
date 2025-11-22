# Immich Port Change from 2283 to 8080

**Date:** November 16, 2025
**Issue:** Windows blocking Immich default port due to Hyper-V/WSL2 dynamic port exclusions
**Solution:** Changed Immich port mapping from 2283 to 8080
**Status:** ✅ Resolved

## Problem Description

Immich web GUI stopped loading at `http://localhost:2283` after a system reboot. The Docker container showed as "healthy" but was not accessible.

### Symptoms
- Immich containers running and showing "healthy" status
- `docker ps` showed port mapping but connection failed
- `curl http://localhost:2283` returned connection failure
- Container logs showed server listening on `http://[::1]:2283` (IPv6 only)

## Root Cause

**Windows Hyper-V/WSL2 Dynamic Port Exclusions**

Windows reserves port ranges dynamically for Hyper-V and WSL2 services. These exclusion ranges can change between reboots or when certain services restart.

### Port Exclusion Ranges (at time of incident)
```
Start Port    End Port
----------    --------
      1808        1907
      1908        2007
      2008        2107
      2108        2207
      2208        2307      ← Port 2283 falls in this range!
      2308        2407
      2408        2507
```

**Port 2283 Status:** BLOCKED (within range 2208-2307)

### Error Message
```
Error response from daemon: ports are not available: exposing port TCP 0.0.0.0:2283 -> 127.0.0.1:0:
bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

### Why It Worked Before

When Immich was first set up, port 2283 was not in an excluded range. After a Windows update or system reboot, Hyper-V reallocated its dynamic port exclusions and included port 2283, making it unavailable for Docker.

## Investigation Steps

### 1. Container Status Check
```bash
docker ps --filter name=immich
```
**Result:** All containers running, showing as "healthy"

### 2. Port Mapping Inspection
```bash
docker inspect immich_server | grep -A20 "NetworkSettings"
```
**Finding:** `"Ports": { "2283/tcp": [] }` - Empty port mapping array

### 3. Port Accessibility Test
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:2283
```
**Result:** Connection failed (exit code 7)

### 4. Windows Port Exclusion Check
```bash
netsh interface ipv4 show excludedportrange protocol=tcp
```
**Finding:** Port 2283 in excluded range 2208-2307

### 5. Container Logs Review
```bash
docker logs immich_server --tail 50
```
**Finding:** Server listening on `http://[::1]:2283` instead of `0.0.0.0:2283`

## Solution Applied

### Step 1: Stop Immich Stack
```bash
cd /d/Immich
docker-compose down
```

### Step 2: Update Port Mapping
Modified `docker-compose.yml`:
```yaml
# Before:
ports:
  - '2283:2283'

# After:
ports:
  - '8080:2283'
```

**File:** `D:/Immich/docker-compose.yml:26`

### Step 3: Restart Immich Stack
```bash
docker-compose up -d
```

### Step 4: Verify Port 8080 is Not Excluded
Port 8080 is outside all Windows excluded ranges and is a standard web port that Hyper-V/WSL2 typically avoids.

### Step 5: Test Accessibility
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
```
**Result:** HTTP 200 ✅

## Post-Change Configuration

### Docker Port Mapping
- **External (host):** Port 8080
- **Internal (container):** Port 2283 (unchanged)
- **Mapping:** `8080:2283`

### Access URLs

#### Local Access (Windows)
- **Old:** `http://localhost:2283` ❌
- **New:** `http://localhost:8080` ✅

#### Local Network Access
- **Old:** `http://192.168.1.109:2283` ❌
- **New:** `http://192.168.1.109:8080` ✅

#### Tailscale VPN Access
- **Old:** `http://100.98.245.56:2283` ❌
- **New:** `http://100.98.245.56:8080` ✅

### iOS App Configuration
Updated server URL in Immich iOS app:
- **Old URL:** `http://192.168.1.109:2283` (local network)
- **New URL (local):** `http://192.168.1.109:8080`
- **New URL (remote):** `http://100.98.245.56:8080` (via Tailscale)

## Files Modified

### docker-compose.yml
**Location:** `D:/Immich/docker-compose.yml`
**Line:** 26
**Change:**
```diff
     ports:
-      - '2283:2283'
+      - '8080:2283'
```

## Verification

### Container Status
```bash
docker ps --filter name=immich_server --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
**Output:**
```
NAMES             STATUS                       PORTS
immich_server     Up 5 minutes (healthy)       0.0.0.0:8080->2283/tcp, [::]:8080->2283/tcp
```

### Web Access Test
```bash
curl http://localhost:8080
```
**Result:** HTTP 200 - Immich web interface loads successfully

### Port Mapping Verification
```bash
docker port immich_server
```
**Output:**
```
2283/tcp -> 0.0.0.0:8080
2283/tcp -> [::]:8080
```

## Why Port 8080 is Safe

1. **Standard web port:** Commonly used for alternative HTTP services
2. **Outside exclusion ranges:** Not in any Hyper-V/WSL2 reserved ranges
3. **Well-known:** Less likely to be dynamically reserved by Windows
4. **Widely compatible:** Works with all browsers and mobile apps

## Prevention

### Understanding Dynamic Port Exclusions

Windows Hyper-V and WSL2 dynamically reserve port ranges for:
- Virtual machine networking
- Container networking
- Hyper-V services
- WSL2 distributions

These ranges can change on:
- Windows Updates
- System reboots
- Hyper-V service restarts
- Docker Desktop restarts

### Recommended Port Ranges for Docker Services

**Safe Ports (unlikely to be reserved):**
- 8080 (alternative HTTP)
- 8443 (alternative HTTPS)
- 9000-9999 (application servers)
- 3000-3999 (development servers)

**Avoid:**
- 1800-2599 (frequently in Hyper-V ranges)
- Dynamic/ephemeral ranges (49152-65535)

## Rollback Procedure

If needed, revert to original port:

### 1. Check if port 2283 is available
```bash
netsh interface ipv4 show excludedportrange protocol=tcp | grep -A2 -B2 "2283"
```

### 2. Update docker-compose.yml
```yaml
ports:
  - '2283:2283'
```

### 3. Restart stack
```bash
cd /d/Immich
docker-compose down && docker-compose up -d
```

## Related Issues

### MariaDB Status
**Port:** 3306 (MySQL/MariaDB default)
**Status:** ✅ Not affected
**Reason:** Port 3306 is outside all Windows exclusion ranges

## Related Documentation

- `~/Documents/dev/photos/photo-vault-architecture.md` - Photo storage architecture
- `~/Documents/dev/photos/immich-hardware-transcoding.md` - Immich GPU acceleration
- `~/Documents/dev/network/network-devices.md` - Network device inventory

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Port (host) | 2283 | 8080 |
| Port (container) | 2283 | 2283 (unchanged) |
| Local URL | http://localhost:2283 | http://localhost:8080 |
| Network URL | http://192.168.1.109:2283 | http://192.168.1.109:8080 |
| Tailscale URL | http://100.98.245.56:2283 | http://100.98.245.56:8080 |
| Status | Blocked by Windows | ✅ Working |
| iOS App | Needs update | Updated to new port |

## Lessons Learned

1. **Windows port exclusions are dynamic** - They can change without warning
2. **Use standard alternative ports** - Ports like 8080, 8443 are safer
3. **Check exclusions when Docker ports fail** - Use `netsh interface ipv4 show excludedportrange`
4. **Docker health status ≠ port accessibility** - Container can be "healthy" but inaccessible

## Future Recommendations

1. **Document all service ports** - Keep track of which ports are used
2. **Monitor port exclusions** - Check after Windows updates
3. **Use port ranges 8000-8999** - Generally safe from Hyper-V reservations
4. **Test after reboots** - Verify services are accessible
