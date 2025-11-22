# Immich Control Scripts

Scripts for controlling the Immich photo management service running in LXC container 1001 (192.168.1.51).

## Scripts

### start-immich.ps1
Starts the Immich Docker containers via SSH.

**Usage:**
```powershell
.\start-immich.ps1
```

Connects to the Immich LXC container and runs `docker compose up -d` to start all services.

### stop-immich.ps1
Stops the Immich Docker containers via SSH.

**Usage:**
```powershell
.\stop-immich.ps1
```

Connects to the Immich LXC container and runs `docker compose down` to stop all services.

### pause-immich-jobs.ps1
Pauses Immich background jobs (machine learning, thumbnail generation, etc.).

**Usage:**
```powershell
.\pause-immich-jobs.ps1
```

Uses Immich API to pause all job queues. Useful before performing maintenance or large imports.

### resume-immich-jobs.ps1
Resumes Immich background jobs after they've been paused.

**Usage:**
```powershell
.\resume-immich-jobs.ps1
```

Uses Immich API to resume all job queues. Pair with `pause-immich-jobs.ps1`.

## Requirements

- SSH access to Immich LXC container (192.168.1.51)
- SSH key configured in `~/.ssh/config` (host: immich)
- Docker Compose installed on Immich container
- Immich API key (for pause/resume scripts)

## Related

All scripts work with the Immich instance running at: https://photos.follett.family (192.168.1.51)
