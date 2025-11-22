# Mylio Album Migration to DigiKam Tags

**Date:** November 16, 2025
**Purpose:** Migrate Mylio album assignments to DigiKam tags
**Albums:** Follett (39,335 photos), Joseph (1,872 photos), Nok (3,254 photos)

---

## Migration Overview

Mylio stores album assignments in its proprietary database (`~/.Mylio_Catalog/Mylo.mylodb`), not in image files. DigiKam reads tags from EXIF/IPTC/XMP metadata embedded in files.

**Solution:** Export Mylio album data as EXIF keywords, then import into DigiKam.

---

## Option 1: Mylio Manual Keyword Export (Recommended)

**Research Result:** Mylio does NOT have an automatic "export album names as keywords" feature. Album data is stored only in Mylio's database.

**Workaround:** Manually add album names as keywords in Mylio, then save metadata to files.

### Step 1: Add Album Names as Keywords (For Each Album)

**For "Follett" album (39,335 photos):**

1. Open Mylio
2. Navigate to **Albums → Follett**
3. Select all photos: **Ctrl+A** (Windows) or **Cmd+A** (Mac)
4. Open **Info Panel** (click Info icon in right sidebar)
5. Scroll to **Keywords** section
6. Type **"Follett"** in "Quick add keywords" field
7. Press **comma (,)** to apply keyword to all selected photos
8. Wait for Mylio to process all 39,335 photos

**Repeat for "Joseph" album (1,872 photos):**
- Select all → Add keyword "Joseph" → Apply

**Repeat for "Nok" album (3,254 photos):**
- Select all → Add keyword "Nok" → Apply

### Step 2: Save Metadata to Files

After adding keywords to all three albums:

1. Go to **Photo menu → Save Metadata to File**
2. Or export photos with metadata included
3. Mylio will write keywords to XMP sidecars (RAW) or embedded in JPEG/TIFF

### Step 3: Verify Metadata Writing

```bash
# Check if album keywords were written to files
exiftool -Keywords -Subject "/d/Immich/library/library/admin/2024/12/<sample-photo>.jpg"
```

**Expected output:**
```
Keywords: Follett
Subject: Follett
```

### Step 4: Import into DigiKam

1. Close DigiKam (if running)
2. In DigiKam: **Settings → Configure digiKam → Metadata**
3. Ensure **"Read from sidecar files"** is enabled
4. Go to photo library folder
5. Right-click folder → **"Reread metadata from image"**
6. DigiKam will import keywords as tags

**Estimated time:** 30-60 minutes (depending on Mylio processing speed)

---

## Option 2: Manual Tag Setup in DigiKam

If Mylio export isn't available, manually create tags and assign photos:

### Step 1: Create Tag Structure

1. Open DigiKam
2. Go to **Tags** panel (left sidebar)
3. Right-click → **New Tag**
4. Create tags:
   - **People/Follett**
   - **People/Joseph**
   - **People/Nok**

### Step 2: Create "Untagged" Saved Search

1. Go to **Search → Advanced Search**
2. Create search:
   - Name: **"Untagged (People)"**
   - Criteria: **Tags → Does not contain → People**
3. Save search
4. This will show all photos NOT tagged with Follett/Joseph/Nok

### Step 3: Assign Tags (Keyboard Shortcuts)

1. **Settings → Configure Keyboard Shortcuts → Tags**
2. Assign shortcuts:
   - **F1** → Assign tag "People/Follett"
   - **F2** → Assign tag "People/Joseph"
   - **F3** → Assign tag "People/Nok"

3. Workflow:
   - Select photos in "Untagged (People)" search
   - Press **F1/F2/F3** to assign tag
   - Photo disappears from "Untagged" list

---

## Option 3: Database Export Script (Advanced)

**Status:** Mylio database uses custom binary format (TrevVer) - file paths not easily accessible.

**Alternative:** Create PowerShell script to:
1. Export Mylio database to CSV (if Mylio supports)
2. Write album names as EXIF keywords using ExifTool
3. Import into DigiKam

**Script location:** `~/Documents/dev/photos/mylio/export-mylio-albums.ps1` (TBD)

---

## Mylio Database Information

**Database location:** `~/.Mylio_Catalog/Mylo.mylodb` (364 MB SQLite with WAL)

**Relevant tables:**
- **Album** - Album definitions (Follett, Joseph, Nok)
- **MediaAlbumLink** - Photo-to-album assignments
- **Media** - Photo metadata (binary format)
- **Resource** - File references (binary TrevVer format)

**Album counts (from database):**
```sql
SELECT a.Name, COUNT(*) FROM MediaAlbumLink mal
JOIN Album a ON mal.TargetResourceHash = a.UniqueHash
GROUP BY a.Name;

-- Results:
-- Follett: 39,335 photos
-- Joseph: 1,872 photos
-- Nok: 3,254 photos
```

---

## DigiKam Tag Configuration

### Tag Hierarchy

```
Tags/
└── People/
    ├── Follett (39,335 photos from Mylio)
    ├── Joseph (1,872 photos from Mylio)
    └── Nok (3,254 photos from Mylio)
```

### Saved Search: "Untagged (People)"

**Purpose:** Show photos NOT assigned to any person tag (inverse view)

**Search criteria:**
- **Tags → Does not contain → People**

**Usage:**
1. Click "Untagged (People)" saved search
2. See all photos without person tags
3. Assign tags (F1/F2/F3)
4. Photo disappears from list

---

## Metadata Writing Configuration

**DigiKam settings (already configured):**

```ini
[Metadata Settings]
Read Metadata From Files With ExifTool=false     # Use Exiv2 for reading
Write Metadata To Files With ExifTool=true      # Use ExifTool for writing
Metadata Writing Mode=2                          # Write to both DB + files
Use XMP Sidecar For Reading=true                # Read XMP sidecars (RAW)
```

**What gets written:**
- Tags → `Xmp.dc.subject`, `Iptc.Application2.Keywords`
- Ratings → `Xmp.xmp.Rating`, `Exif.Image.Rating`
- Color Labels → XMP
- Pick Labels → XMP
- Face Tags → `Xmp.digiKam.TagsList`
- GPS → `Exif.GPSInfo.*`
- Comments → EXIF/XMP
- Date/Time → EXIF

---

## Immich Compatibility

After migration, Immich can read DigiKam tags:

**Metadata refresh in Immich:**
1. Per-photo: **Photo options → Refresh metadata**
2. Bulk: **Administration → Jobs → Metadata Extraction**

**Result:**
- Tags appear in Immich
- Ratings synchronized
- GPS locations on map

---

## Recommended Workflow

1. **Option 1 (Easiest):** Enable Mylio metadata writing → Export albums as keywords
2. **Option 2 (Manual):** Create DigiKam tags → Use keyboard shortcuts + "Untagged" search
3. **Option 3 (Future):** Develop export script if Mylio API/export feature unavailable

**Current status:** Testing Option 1 (Mylio export feature)

---

## Files and Locations

### Mylio Database
- **Location:** `C:/Users/josep/.Mylio_Catalog/Mylo.mylodb`
- **Size:** 364 MB (SQLite with WAL)
- **Format:** Proprietary TrevVer binary format

### DigiKam Database
- **Location:** `D:/Immich/library/library/digikam4.db` (automatic backups land in `D:/Immich/backup/db/`)
- **Format:** SQLite with WAL mode
- **Tags stored in:** Tags table (hierarchical structure)

### Photo Library
- **Location:** `D:/Immich/library/library/admin/` (82,345 images)
- **Metadata:** EXIF/IPTC/XMP embedded in files + XMP sidecars for RAW

---

## DigiKam XMP Sidecar Limitation (IMPORTANT!)

**Issue Discovered:** DigiKam does NOT read XMP sidecars for video and HEIF files during metadata sync.

### What Works:
- ✅ JPEG files: Keywords imported from embedded metadata AND XMP sidecars
- ✅ RAW files: Keywords imported from XMP sidecars
- ✅ TIFF/PNG files: Keywords imported from embedded metadata

### What Doesn't Work:
- ❌ Video files (.mov, .mp4): XMP sidecars ignored during sync
- ❌ HEIF files (.heic): XMP sidecars ignored during sync (likely)

### Root Cause:
DigiKam's metadata sync only reads XMP sidecars for **RAW image files**, not for videos or HEIF files. This is a known DigiKam limitation.

### XMP Format Analysis:
Total XMP files analyzed: **44,461**

Two XMP keyword formats found (both valid and compatible):
1. **`<rdf:Bag>` format** - Used for JPEG and video files (unordered list)
2. **`<rdf:Seq>` format** - Used for HEIF files (ordered sequence)

Both formats use standard XMP Dublin Core (`dc:subject`) and are compatible with DigiKam and Immich.

### Solution: Automated Import Script

**Script:** `~/Documents/dev/photos/import-xmp-keywords-to-digikam.ps1`

**What it does:**
1. Scans all XMP files in library (single ExifTool call for speed)
2. Extracts keywords from XMP sidecars
3. Imports keywords directly into DigiKam's database
4. Creates automatic database backup before making changes

**Usage:**
```powershell
# Preview what would be imported (dry run)
cd ~/Documents/dev/photos
.\import-xmp-keywords-to-digikam.ps1 -DryRun

# Import keywords into DigiKam database
.\import-xmp-keywords-to-digikam.ps1
```

**Performance:** Optimized with single ExifTool call for bulk operations (processes all 44,461 XMP files in one pass).

---

## Migration Status

✅ **Completed Steps:**
1. Mylio "Save Metadata to File" executed (wrote keywords to XMP sidecars)
2. XMP format verified (standard Dublin Core format)
3. DigiKam imported JPEG keywords successfully
4. Created hierarchical tag structure (People/Follett, People/Joseph, People/Nok)
5. Identified DigiKam limitation with video/HEIF XMP sidecars
6. Created automated import script

❌ **Remaining:**
1. Close DigiKam (required for database safety)
2. Run `import-xmp-keywords-to-digikam.ps1` to import video/HEIF keywords
3. Reopen DigiKam and verify all files appear in tag searches

---

## Next Steps

1. Close DigiKam
2. Run import script: `.\import-xmp-keywords-to-digikam.ps1 -DryRun` (preview)
3. Run import script: `.\import-xmp-keywords-to-digikam.ps1` (actual import)
4. Open DigiKam and search for tags (videos/HEIF should now appear)
5. Optional: Set up keyboard shortcuts (F1/F2/F3) for quick tagging of any remaining untagged files
