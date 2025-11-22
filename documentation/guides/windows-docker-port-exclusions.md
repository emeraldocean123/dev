# Windows Docker Port Exclusions - Hyper-V/WSL2 Issue

**Date Created:** November 16, 2025
**Last Updated:** November 16, 2025
**Applies To:** Windows 11 with Docker Desktop (WSL2 backend)
**Issue:** Dynamic port exclusions by Hyper-V block Docker container ports

## Overview

Windows Hyper-V and WSL2 dynamically reserve port ranges for internal services.
These reservations can change between reboots or service restarts, causing Docker
containers to fail binding to ports that previously worked.

## Problem Description

Docker containers may fail to start or become inaccessible when their port
mappings conflict with Windows' dynamically allocated port exclusion ranges.

### Common Error Message

<!-- markdownlint-disable-next-line MD013 -->
```text
Error response from daemon: ports are not available:
exposing port TCP 0.0.0.0:XXXX -> 127.0.0.1:0:
bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

## Why This Happens

### Hyper-V Dynamic Port Allocation

Windows Hyper-V and WSL2 reserve port ranges for:

- Virtual machine networking
- Container networking (Docker, WSL2 distributions)
- Hyper-V internal services
- Network address translation (NAT)
- Virtual switch operations

These reservations are **dynamic** and can change when:

- Windows Updates are installed
- System reboots occur
- Hyper-V services restart
- Docker Desktop restarts
- WSL2 distributions start/stop

### Port Exclusion Ranges (Example)

Typical exclusion ranges on Windows 11:

```text
Protocol tcp Port Exclusion Ranges

Start Port    End Port
----------    --------
      1808        1907
      1908        2007
      2008        2107
      2108        2207
      2208        2307      ← Immich 2283 was blocked here
      2308        2407
      2408        2507
      5357        5357
      50000       50059     * (Administered)
```

**Note:** These ranges vary by system and can change over time.

## Checking Port Exclusions

### Command to Check Exclusions

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

### Check Specific Port

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp |
    findstr /C:"2283"
```

### Parse Exclusions (Git Bash)

```bash
netsh interface ipv4 show excludedportrange protocol=tcp |
    awk '/Start Port/,/^$/ {print}'
```

## Affected Services

### Known Incidents

| Service | Original Port | Blocked Range | New Port | Date |
|---------|--------------|---------------|----------|------|
| Immich | 2283 | 2208-2307 | 8080 | 2025-11-16 |

### At-Risk Ports

Ports commonly in exclusion ranges:

- **1800-2599:** Frequently reserved by Hyper-V
- **2200-2500:** High-risk range
- **5000-5500:** Sometimes reserved
- **49152-65535:** Ephemeral port range (avoid for services)

## Safe Port Recommendations

### Recommended Port Ranges for Docker Services

**Generally Safe Ports:**

- **3000-3999:** Development servers (Node.js, React, etc.)
- **8000-8999:** Alternative web services
  - 8080 (alternative HTTP)
  - 8443 (alternative HTTPS)
  - 8888 (Jupyter, etc.)
- **9000-9999:** Application servers
  - 9090 (Prometheus)
  - 9000 (Portainer)
- **Standard service ports:**
  - 80, 443 (web, if not used by Windows)
  - 3306 (MySQL/MariaDB)
  - 5432 (PostgreSQL)
  - 6379 (Redis)
  - 27017 (MongoDB)

**Avoid:**

- 1800-2599 (Hyper-V favorites)
- 5000-5500 (sometimes reserved)
- 49152-65535 (ephemeral range)

## Solutions

### Solution 1: Change Port Mapping (Recommended)

Change the host port while keeping container port unchanged.

**Example (docker-compose.yml):**

```yaml
services:
  app:
    ports:
      - '8080:2283'  # Host:Container
```

**Steps:**

1. Stop container: `docker-compose down`
2. Edit docker-compose.yml
3. Change host port (left side) to safe port
4. Restart: `docker-compose up -d`
5. Update client configurations

### Solution 2: Reserve Port Range (Advanced)

Reserve specific ports to prevent Hyper-V from using them.

**PowerShell (Run as Administrator):**

```powershell
# Reserve port 2283
netsh int ipv4 add excludedportrange protocol=tcp startport=2283 numberofports=1
```

**Verification:**

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

**Drawbacks:**

- Requires administrator privileges
- May not survive Windows updates
- Can conflict with Hyper-V if it needs those ports
- Not recommended for production

### Solution 3: Disable Hyper-V (Not Recommended)

Disabling Hyper-V removes the exclusions but breaks Docker Desktop (WSL2
backend) and other virtualization features.

**Not recommended** - defeats the purpose of using Docker Desktop.

## Diagnosis Workflow

### When Docker Container Won't Start

#### Step 1: Check Container Logs

```bash
docker logs <container_name>
```

#### Step 2: Check Docker Error

```bash
docker-compose up
# Look for "ports are not available" error
```

#### Step 3: Check Windows Exclusions

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

#### Step 4: Identify Conflicting Range

Find if your port falls within any Start-End range.

#### Step 5: Choose New Port

Select port from safe ranges (8000-8999 recommended).

#### Step 6: Update Configuration

Modify docker-compose.yml or docker run command.

#### Step 7: Restart Container

```bash
docker-compose down && docker-compose up -d
```

#### Step 8: Verify Access

```bash
curl http://localhost:<new-port>
```

## Prevention Strategies

### 1. Use Safe Port Ranges

Always choose ports from 8000-8999 or 9000-9999 for new services.

### 2. Document Port Assignments

Keep a port mapping document:

```text
Service          Port    Protocol    Notes
-------------    ----    --------    -----
Immich           8080    HTTP        Changed from 2283
MariaDB          3306    TCP         Safe (standard port)
Portainer        9000    HTTP        Safe range
```

### 3. Test After System Changes

After Windows updates or reboots:

1. Verify all containers start successfully
2. Test port accessibility
3. Check for new exclusion ranges

### 4. Use Health Checks

Add health checks to docker-compose.yml:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:2283"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### 5. Monitor Port Exclusions

Create a script to check exclusions:

```powershell
# check-port-exclusions.ps1
$ports = @(8080, 3306, 9000)  # Your service ports

foreach ($port in $ports) {
    $excluded = netsh interface ipv4 show excludedportrange protocol=tcp |
                Select-String "^\s+(\d+)\s+(\d+)" |
                ForEach-Object {
                    if ([int]$_.Matches.Groups[1].Value -le $port -and
                        [int]$_.Matches.Groups[2].Value -ge $port) {
                        return $true
                    }
                }

    if ($excluded) {
        Write-Host "⚠️ Port $port is EXCLUDED!" -ForegroundColor Red
    } else {
        Write-Host "✅ Port $port is available" -ForegroundColor Green
    }
}
```

## Case Studies

### Case 1: Immich Port Blockage

**Date:** November 16, 2025

**Symptoms:**

- Immich stopped loading at localhost:2283
- Container showed "healthy" status
- curl returned connection failure

**Diagnosis:**

- Checked exclusions: `netsh interface ipv4 show excludedportrange protocol=tcp`
- Found port 2283 in range 2208-2307

**Resolution:**

- Changed port mapping from `2283:2283` to `8080:2283`
- Updated iOS app configuration
- Service restored successfully

**Files Modified:**

- `D:/Immich/docker-compose.yml`

**Lessons:**

- Standard service ports (2283 for Immich) can be blocked
- Port 8080 is generally safe from exclusions
- Container health != port accessibility

## Related Tools

### Check Port Availability (PowerShell)

```powershell
Test-NetConnection -ComputerName localhost -Port 8080
```

### Check Port Usage (CMD)

```cmd
netstat -ano | findstr :8080
```

### Check if Process Listening (PowerShell)

```powershell
Get-NetTCPConnection -LocalPort 8080
```

## References

- Microsoft Docs: [Troubleshoot port exhaustion issues][ms-ports]
- Docker Desktop Issues: [Windows port reservation][docker-for-win]
- Hyper-V Networking: [Dynamic port range][hyperv-range]

[ms-ports]: https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/port-exhaustion-issues
[docker-for-win]: https://github.com/docker/for-win/issues/3171
[hyperv-range]: https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/default-dynamic-port-range-tcpip-chang

## Summary

| Aspect | Details |
|--------|---------|
| **Root Cause** | Hyper-V/WSL2 dynamic port exclusions |
| **Affected Systems** | Windows 10/11 with Docker Desktop (WSL2 backend) |
| **Symptoms** | Docker cannot bind ports ("access permissions" error) |
| **Diagnosis** | `netsh interface ipv4 show excludedportrange protocol=tcp` |
| **Solution** | Change to safe port range (8000-8999) |
| **Prevention** | Safe port ranges + documentation + post-update tests |
| **Safe Ports** | 3306, 8000-8999, 9000-9999 |
| **Risky Ports** | 1800-2599, 49152-65535 |

## Quick Reference Commands

```powershell
# Check exclusions
netsh interface ipv4 show excludedportrange protocol=tcp

# Check specific port range
netsh interface ipv4 show excludedportrange protocol=tcp | findstr "2283"

# Reserve a port (requires admin)
netsh int ipv4 add excludedportrange protocol=tcp startport=8080 numberofports=1

# Test port connectivity
Test-NetConnection -ComputerName localhost -Port 8080

# Check what's using a port
netstat -ano | findstr :8080

# Get process by PID
tasklist | findstr <PID>
```
