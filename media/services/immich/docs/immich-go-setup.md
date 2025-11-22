# Immich-Go Setup and Usage

**Installed:** November 8, 2025
**Version:** v0.29.0
**Location:** `D:\Files\Programs-Portable\immich-go\immich-go.exe`
**Added to PATH:** Yes (User PATH)

## What is Immich-Go?

Immich-Go is a command-line tool for bulk uploading photos and videos to your Immich server. It preserves all EXIF metadata (GPS, dates, camera info), handles duplicates intelligently, and can process Google Photos takeouts.

## Installation

✓ **Already installed** at: `D:\Files\Programs-Portable\immich-go\`
✓ **Added to PATH** - can run `immich-go` from any terminal

## Setup

### 1. Get your Immich API Key

1. Open Immich web interface: http://192.168.1.51:2283
2. Go to **Account Settings** (top right profile icon)
3. Click **API Keys**
4. Click **New API Key**
5. Give it a name (e.g., "Immich-Go Windows Upload")
6. Copy the generated key (starts with `pKEy...`)

**Save this key securely** - you'll use it for all uploads

### 2. Test Connection

```powershell
immich-go version
```

Should show: `immich-go version 0.29.0`

### 3. Upload Photos from D:\Mylio

**Basic upload (dry-run first):**
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -dry-run D:\Mylio
```

**Actual upload:**
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY D:\Mylio
```

**Upload with progress:**
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -progress D:\Mylio
```

## Common Commands

### Upload a specific folder
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY "D:\Mylio\Photos\2024"
```

### Upload and create an album
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -create-album "Family Photos 2024" "D:\Mylio\Photos\2024"
```

### Skip duplicates
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -skip-duplicate D:\Mylio
```

### Google Photos Takeout
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -google-photos "D:\Google Takeout"
```

## Important Notes

**Metadata Preservation:**
- ✓ EXIF data (GPS, camera, lens info)
- ✓ Original file dates and times
- ✓ Geolocation tags
- ✓ All metadata is preserved

**Upload Behavior:**
- Immich-Go detects duplicates by file hash
- Existing photos won't be re-uploaded
- Use `-skip-duplicate` to skip duplicate warnings
- Use `-dry-run` to preview what will be uploaded

**Performance:**
- Direct Windows → Immich server (192.168.1.51)
- Uses your 10G network connection
- Typical speed: 100-200 MB/s (depends on photo size)
- 842GB of photos will take approximately 1-2 hours

## Recommended Workflow

### First Time Upload (Full Mylio Library)

1. **Test with one folder first:**
   ```powershell
   immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -dry-run "D:\Mylio\Photos\2024\(11) November"
   ```

2. **Upload the test folder:**
   ```powershell
   immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY "D:\Mylio\Photos\2024\(11) November"
   ```

3. **Verify in Immich web interface** that photos uploaded correctly

4. **Upload entire library:**
   ```powershell
   immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -progress D:\Mylio
   ```

### Ongoing Uploads (New Photos)

Upload new photos periodically:
```powershell
immich-go upload -server http://192.168.1.51:2283 -key YOUR_API_KEY -skip-duplicate D:\Mylio
```

Immich-Go will automatically skip photos that are already uploaded.

## Troubleshooting

**Issue: Command not found**
- Restart PowerShell to refresh PATH
- Or use full path: `D:\Files\Programs-Portable\immich-go\immich-go.exe`

**Issue: Connection refused**
- Verify Immich is running: http://192.168.1.51:2283
- Check LXC 1001 (immich) is online: `ssh immich`

**Issue: API key invalid**
- Regenerate API key in Immich web interface
- Make sure to copy the entire key

**Issue: Slow uploads**
- Check network connection to immich server
- Verify 10G network link is active
- Large video files (4K, HDR) take longer

## Links

- **Immich-Go GitHub:** https://github.com/simulot/immich-go
- **Immich Server:** http://192.168.1.51:2283
- **Immich Documentation:** https://immich.app/docs

## Your Setup

- **Immich Server:** 192.168.1.51:2283 (LXC 1001 on intel-1250p)
- **Photo Library:** D:\Mylio (842GB, 1,153 videos)
- **Network:** 10G direct to Proxmox host
- **Immich-Go Location:** D:\Files\Programs-Portable\immich-go\
