# Upload DigiKam Photos to Google Photos

Complete guide for uploading organized photos from DigiKam to Google Photos for sharing.

## Setup (One-time)

### Step 1: Configure rclone for Google Photos

Run this command:

```bash
rclone config
```

Follow these steps:

1. **Choose**: `n` (new remote)
2. **Name**: `googlephotos`
3. **Storage type**: Type number for "Google Photos" (usually around #17-20)
4. **Client ID**: Press Enter (leave blank for default)
5. **Client Secret**: Press Enter (leave blank)
6. **Scope**: Choose `1` (read/write access)
7. **Root folder ID**: Press Enter (leave blank)
8. **Service Account**: Press Enter (leave blank)
9. **Auto config**: Choose `Y` (yes)
   - Browser window will open for Google authentication
   - Sign in with your Google account
   - Grant permissions to rclone
10. **Confirm**: `y` (yes, this is OK)
11. **Quit**: `q` (quit config)

### Step 2: Verify Configuration

```bash
rclone listremotes
```

You should see:
```
googlephotos:
```

---

## Workflow: DigiKam → Google Photos

### Step 1: Export from DigiKam

1. **In DigiKam**, select photos/albums you want to share
2. **File → Export → Export to Local Storage**
3. **Export settings**:
   - Destination: `D:\DigiKam\export\` (or any folder)
   - Include metadata: ✓ (recommended)
   - Resize (optional): Set max dimension if you want smaller files
4. Click **Export**

### Step 2: Upload to Google Photos

```bash
cd /d/DigiKam
bash upload-to-google-photos.sh /d/DigiKam/export "Album Name"
```

**Examples:**

```bash
# Upload with custom album name
bash upload-to-google-photos.sh /d/DigiKam/export "Family Vacation 2024"

# Upload with default album name
bash upload-to-google-photos.sh /d/DigiKam/export
```

### Step 3: Share the Album

1. Go to https://photos.google.com/
2. Find your album
3. Click **Share** button
4. Get shareable link
5. Send link to friends/family

---

## Common Scenarios

### Share a Tagged Collection

**DigiKam workflow:**
1. Filter by tag (e.g., "Family > Wedding")
2. Select all matching photos (`Ctrl+A`)
3. Export to `D:\DigiKam\export\wedding`
4. Run upload script:
   ```bash
   bash upload-to-google-photos.sh /d/DigiKam/export/wedding "Sarah's Wedding 2024"
   ```

### Share Best Photos (5-star rated)

**DigiKam workflow:**
1. Use filter bar → select 5-star rating
2. Select all (`Ctrl+A`)
3. Export to `D:\DigiKam\export\favorites`
4. Upload:
   ```bash
   bash upload-to-google-photos.sh /d/DigiKam/export/favorites "My Best Photos"
   ```

### Share Event Photos

**DigiKam workflow:**
1. Use calendar view to select date range
2. Select photos from the event
3. Export to `D:\DigiKam\export\event`
4. Upload:
   ```bash
   bash upload-to-google-photos.sh /d/DigiKam/export/event "Birthday Party Oct 2024"
   ```

---

## Advanced Options

### Upload with Progress Tracking

The script shows upload progress by default:
- Transfer speed
- Files uploaded / total files
- Estimated time remaining

### Automatic Album Creation

rclone automatically creates albums in Google Photos if they don't exist.

### Supported File Formats

The script uploads:
- **Photos**: JPG, JPEG, PNG, HEIC
- **Videos**: MOV, MP4

### Skip XMP Sidecar Files

The script automatically skips `.xmp` files - only uploads actual photos/videos.

---

## Tips for Sharing

### Optimize for Sharing (Smaller Files)

When exporting from DigiKam:
1. **File → Export → Export to Local Storage**
2. Enable **"Resize images"**
3. Set max dimension: `2048px` (good for web sharing)
4. Quality: `85%` (balance quality/size)

This creates smaller files that upload faster and load faster for recipients.

### Create Shared Albums Directly in Google Photos

After uploading:
1. Open Google Photos
2. Find your album
3. Click **Share** → **Create shared album**
4. Recipients can add their own photos to the album

### Privacy Settings

Google Photos sharing options:
- **Link sharing**: Anyone with link can view
- **Collaborate**: Recipients can add photos
- **Download**: Allow/prevent downloading

---

## Troubleshooting

### Error: "googlephotos: not found in config"

**Fix**: Run `rclone config` and set up Google Photos (see Step 1 above)

### Error: "Failed to create file system"

**Fix**: Your rclone authentication may have expired. Run:
```bash
rclone config reconnect googlephotos:
```

### Photos Not Appearing in Google Photos

**Wait**: Google Photos may take 5-10 minutes to process uploads
**Check**: Go to https://photos.google.com/ → Albums → Find your album

### Duplicates in Google Photos

Google Photos detects duplicates automatically. If you upload the same photo twice:
- It won't create a duplicate in your library
- It will just add it to the new album

---

## Your Complete Workflow

```
┌─────────────┐
│  DigiKam    │ 1. Organize, tag, rate photos
│  (Desktop)  │    (writes to XMP sidecars)
└──────┬──────┘
       │
       │ 2. Export selected photos
       ↓
┌─────────────┐
│   Export    │ 3. Temporary folder
│   Folder    │    D:\DigiKam\export\
└──────┬──────┘
       │
       │ 4. Upload via rclone
       ↓
┌─────────────┐
│   Google    │ 5. Share link with others
│   Photos    │    (web viewing, no install needed)
└─────────────┘
       │
       │ 6. Meanwhile...
       ↓
┌─────────────┐
│   Immich    │ Personal viewing/mobile access
│ (Self-host) │ (reads same XMP sidecars)
└─────────────┘
```

**Best of both worlds:**
- ✅ **DigiKam**: Professional organization
- ✅ **Immich**: Personal viewing/mobile
- ✅ **Google Photos**: Easy sharing with non-technical users
- ✅ **XMP sidecars**: Keep everything in sync

---

## Clean Up After Uploading

After successful upload, you can delete the export folder:

```bash
rm -rf /d/DigiKam/export/*
```

Or keep it as a local copy for offline sharing.
