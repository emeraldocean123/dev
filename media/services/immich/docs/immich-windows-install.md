# Immich Installation on Windows 11

**Date:** November 13, 2025
**Installation Method:** Docker Desktop for Windows
**Immich Version:** v2.2.3 (latest)

## Installation Overview

Immich is installed on Windows 11 using Docker Desktop with the official docker-compose configuration.

## Installation Directory

**Location:** `<Repository Root>/media/services/immich/`

**Files:**
- `docker-compose.yml` - Immich service configuration
- `.env` - Environment variables and configuration
- `example.env` - Reference configuration from Immich project

## Docker Compose Services

The installation includes 4 containers:

1. **immich_server** - Main Immich application
   - Port: 2283 (web interface)
   - Image: ghcr.io/immich-app/immich-server:v2

2. **immich_machine_learning** - AI/ML features (facial recognition, object detection)
   - Image: ghcr.io/immich-app/immich-machine-learning:v2

3. **immich_redis** - Caching and job queue
   - Image: valkey/valkey:8

4. **immich_postgres** - PostgreSQL database with vector extensions
   - Image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
   - **Critical:** Database stored on EXT4 filesystem inside WSL2 (Docker Desktop backend)

## Configuration

**Environment Variables (.env):**
- `UPLOAD_LOCATION=./library` - Photo uploads stored in `./library/` inside container
- `DB_DATA_LOCATION=./postgres` - Database stored in `./postgres/` inside container
- `TZ=America/Los_Angeles` - Pacific timezone
- `IMMICH_VERSION=v2` - Latest v2.x.x release
- `DB_PASSWORD` - Secure randomly generated password (32 characters)

**Database Security:**
- PostgreSQL password: `cVoXvs0ev2N97Wa7MlnyVS5BOmE93grW`
- Database only accessible from Docker network (not exposed externally)

## Storage Architecture

### Internal Storage (WSL2 / Docker Desktop)
- **Database:** `./postgres/` (inside Docker Desktop WSL2 backend)
- **Thumbnails/Cache:** `./library/` (inside Docker Desktop WSL2 backend)
- **ML Models:** Named volume `model-cache`

### External Library (Planned)
Once photo organization is complete, an external library will be configured:
- **Photos Location:** <External Storage Drive>:\<photo-folder-name> (to be determined)
- **Mount Point:** Will be added to docker-compose.yml as additional volume
- **Access Mode:** Read-only to protect originals
- **Format:** External library (photos stay on Windows NTFS, accessed via `/mnt/d/`)

## Access

**Web Interface:** http://localhost:2283

## Common Commands

**Start Immich:**
```bash
cd <Repository Root>/media/services/immich
docker compose up -d
```

**Stop Immich:**
```bash
cd <Repository Root>/media/services/immich
docker compose down
```

**View Logs:**
```bash
cd <Repository Root>/media/services/immich
docker compose logs -f
```

**Update Immich:**
```bash
cd <Repository Root>/media/services/immich
docker compose pull
docker compose up -d
```

**Backup Database:**
```bash
cd <Repository Root>/media/services/immich
docker compose exec -T database pg_dumpall -c -U postgres > immich-backup-$(date +%Y%m%d).sql
```

**Restore Database:**
```bash
cd <Repository Root>/media/services/immich
cat immich-backup-YYYYMMDD.sql | docker compose exec -T database psql -U postgres
```

## Hardware Acceleration

### GPU Transcoding (Future Enhancement)
The laptop has an RTX 5090 GPU. To enable hardware-accelerated video transcoding:

1. Download `hwaccel.transcoding.yml` from Immich releases
2. Uncomment the `extends` section in docker-compose.yml
3. Set service to `nvenc` for NVIDIA GPU acceleration
4. Restart containers

### ML Acceleration (Future Enhancement)
For faster facial recognition and object detection:

1. Download `hwaccel.ml.yml` from Immich releases
2. Use image tag: `ghcr.io/immich-app/immich-machine-learning:v2-cuda`
3. Uncomment the `extends` section for immich-machine-learning
4. Set service to `cuda` for NVIDIA GPU acceleration
5. Restart containers

## External Library Setup (Pending User Action)

**User's Workflow:**
1. Export photos from Mylio to new folder on D: drive
2. Clean up and organize with PhotoMove app
3. Determine final folder path (e.g., <External Storage Drive>:\Immich-Library\)

**Configuration Steps (After User Organizes Photos):**
1. Add volume mount to docker-compose.yml:
   ```yaml
   volumes:
     - ${UPLOAD_LOCATION}:/data
     - /etc/localtime:/etc/localtime:ro
     - /mnt/d/Immich-Library:/external-library:ro
   ```

2. Restart Immich: `docker compose up -d`

3. Configure in Immich web interface:
   - Settings → External Libraries → Add External Library
   - Path: `/external-library`
   - Enable: Import paths as is
   - Enable: Read-only mode
   - Click: Scan Library

## Troubleshooting

**Container won't start:**
```bash
docker compose logs [service-name]
```

**Database connection issues:**
- Ensure Docker Desktop is running
- Check database container: `docker ps | grep postgres`
- Verify .env file has correct DB_PASSWORD

**Out of space:**
- Check WSL disk usage: `docker system df`
- Clean up old images: `docker system prune`
- If needed, expand WSL VHDX (script available: `<Repository Root>/shell-management/wsl-management/expand-wsl-disk.ps1`)

## Documentation References

- Immich Official Docs: https://docs.immich.app/
- Docker Compose Install: https://docs.immich.app/install/docker-compose
- Environment Variables: https://docs.immich.app/install/environment-variables
- Hardware Acceleration: https://docs.immich.app/features/ml-hardware-acceleration
- External Libraries: https://docs.immich.app/features/libraries

## Related Files

- Photo architecture: `<Repository Root>/media/photos/photo-vault-architecture.md`
- Hardware transcoding config: `<Repository Root>/media/photos/immich-hardware-transcoding.md`
- Mylio scripts: `<Repository Root>/media/clients/mylio/`

## Notes

- Initial installation: November 13, 2025
- Docker Desktop version: 28.5.2
- Immich version: v2.2.3
- Platform: Windows 11 Pro (25H2) on Alienware 18 Area-51
- PostgreSQL on EXT4 filesystem (WSL2) - meets Immich requirements
- External library setup pending user's photo organization workflow
