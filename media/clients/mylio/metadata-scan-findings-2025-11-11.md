# Mylio Metadata Scan Findings
**Date**: November 11, 2025
**Author**: Claude Code
**Purpose**: Document metadata landscape before cleanup operation

## Executive Summary

Scanned Mylio photo library to understand metadata structure before implementing XMP sidecar export and embedded metadata cleanup.

**Key Statistics:**
- **Total Files**: 75,792 media files (photos and videos)
- **Existing XMP Sidecars**: 4,184 files (5.5% of library)
- **Sample Scanned**: 1,000 random files for embedded metadata analysis

**Findings:**
- Mylio uses 9 custom fields in `MY:*` namespace for organization
- 51% of XMP sidecars contain keywords (2,131 / 4,184)
- Embedded metadata contains bloat from multiple editing software programs
- All Mylio XMP sidecars include document IDs for file tracking

---

## 1. XMP Sidecar Scan Results
**Files Scanned**: 4,184 XMP sidecars
**Processing Time**: 10 seconds
**Report**: `xmp-sidecar-scan-2025-11-11-104834.txt`

### 1.1 XML Namespaces Found (8 total)

| Namespace | URI | Occurrences | Purpose |
|-----------|-----|-------------|---------|
| `MY:` | `http://ns.mylollc.com/MyloEdit/` | 4,184 | **Mylio proprietary fields** |
| `xmpMM:` | `http://ns.adobe.com/xap/1.0/mm/` | 4,184 | Document management/tracking |
| `exif:` | `http://ns.adobe.com/exif/1.0/` | 4,184 | Camera EXIF data |
| `xmp:` | `http://ns.adobe.com/xap/1.0/` | 4,184 | Core XMP metadata |
| `photoshop:` | `http://ns.adobe.com/photoshop/1.0/` | 4,184 | Location/creation date |
| `tiff:` | `http://ns.adobe.com/tiff/1.0/` | 3,122 | Image orientation |
| `dc:` | `http://purl.org/dc/elements/1.1/` | 2,131 | Keywords (Dublin Core) |
| `Iptc4xmpExt:` | `http://iptc.org/std/Iptc4xmpExt/2008-02-29/` | 1,629 | IPTC extended fields |

### 1.2 Mylio-Specific Fields (MY:* namespace)

| Field | Count | Sample Value | Purpose |
|-------|-------|--------------|---------|
| `MY:flag` | 4,184 | `false` | Flag/favorite status |
| `MY:MetadataDate` | 4,184 | `2025-11-11T03:50:06.743Z` | Last edited timestamp |
| `MY:processVersion` | 4,184 | `1` | Processing version |
| `MY:Undated` | 4,184 | `false` | Whether photo is undated |
| `MY:Season` | 25 | `0` | Season designation |
| `MY:Year` | 25 | `0` | Year override |
| `MY:DateRangeStart` | 19 | `1940-01-01T00:00:00.000` | Date range start (for undated) |
| `MY:DateRangeEnd` | 19 | `1949-12-31T23:59:59.999` | Date range end (for undated) |
| `MY:DateRangeScope` | 19 | *(empty)* | Date range scope |

**Note**: DateRange fields are used for old photos (1940s) where exact date is unknown.

### 1.3 Universal XMP Fields (in all 4,184 files)

- `xmpMM:DocumentID` - UUID for file tracking
- `xmpMM:InstanceID` - Instance identifier
- `xmpMM:OriginalDocumentID` - Original document UUID
- `xmp:ModifyDate` - Last modified date
- `xmp:CreateDate` - Creation date
- `xmp:MetadataDate` - Metadata last edited
- `exif:DateTimeOriginal` - Original capture date
- `exif:SubSecTime*` - Subsecond timestamps
- `photoshop:DateCreated` - Photo creation date

### 1.4 Keyword Statistics

- **Files with keywords**: 2,131 / 4,184 (51%)
- **Unique keywords**: 209 total

**Top 20 Keywords**:
1. `Family` (1,243 files)
2. `!Shared-Family` (1,144 files) ← DigiKam origin
3. `!Shared-Nok-No Exif` (486 files) ← DigiKam origin
4. `!Private-Nok-No Exif` (477 files) ← DigiKam origin
5. `2015` (202 files)
6. `2009` (199 files)
7. `iPhone 4S` (189 files)
8. `2012` (176 files)
9. `2009_08` (171 files)
10. `2015_07` (169 files)
11. `iPhone 6 Plus` (151 files)
12. `No Model Info` (122 files)
13. `2022` (105 files)
14. `Joseph` (103 files)
15. `!Private-Joseph` (103 files) ← DigiKam origin
16. `!Shared-Family-No Exif` (98 files) ← DigiKam origin
17. `DSC-P10` (95 files)
18. `iPhone 6` (82 files)
19. `iPhone 13 Pro` (80 files)
20. `Canon IXY DIGITAL 820 IS` (79 files)

**DigiKam Keywords Identified**:
- Prefix pattern: `!Shared-*`, `!Private-*`
- Total: ~2,300 files affected in XMP sidecars
- **Decision**: DELETE from both embedded IPTC and XMP sidecars ⚠️
- **Note**: DigiKam originally wrote to embedded IPTC, Mylio copied to XMP sidecars

---

## 2. Embedded Metadata Scan Results
**Files Scanned**: 1,000 random sample
**Processing Time**: 3 minutes 41 seconds
**Report**: `embedded-metadata-scan-2025-11-11-095123.txt`

### 2.1 Metadata Groups Found (18 total)

| Group | Occurrences | Purpose | Keep/Remove |
|-------|-------------|---------|-------------|
| `EXIF` | 31,681 | Camera-generated data | **KEEP** |
| `QuickTime` | 18,023 | Video metadata | **KEEP** |
| `File` | 15,005 | File system info | **KEEP** |
| `Composite` | 11,611 | Calculated fields | **KEEP** |
| `MakerNotes` | 9,363 | Camera-specific data | **KEEP** |
| `ICC_Profile` | 6,334 | Color profiles | **KEEP** |
| `XMP` | 2,098 | Embedded XMP | **ANALYZE** |
| `MPF` | 1,211 | Multi-picture format | **KEEP** |
| `ExifTool` | 1,183 | ExifTool processing | **KEEP** |
| `JFIF` | 559 | JPEG metadata | **KEEP** |
| `APP10` | 180 | JPEG APP segments | **KEEP** |
| `IPTC` | 96 | Keywords/captions | **KEEP** (Mylio data) |
| `PrintIM` | 76 | Printer metadata | **KEEP** |
| `RIFF` | 61 | AVI metadata | **KEEP** |
| `PNG` | 52 | PNG metadata | **KEEP** |
| `Photoshop` | 29 | **Photoshop edits** | **REMOVE** ⚠️ |
| `JPEG` | 17 | JPEG comments | **KEEP** |
| `APP4` | 1 | JPEG APP4 segment | **KEEP** |

### 2.2 Software Tags Found (Editing Bloat)

**iOS Versions** (523 occurrences):
- iOS 5.1.1 through 18.6.2
- **Decision**: KEEP (camera/phone software is legitimate)

**Editing Software** (to remove):

| Software | Count | Tag | Action |
|----------|-------|-----|--------|
| Picasa | 16 | `EXIF:Software` | **REMOVE** ⚠️ |
| Microsoft Windows Photo Viewer | 16 | `EXIF:Software` | **REMOVE** ⚠️ |
| digiKam 7.3.0 / 7.8.0 | 3 | `EXIF:ProcessingSoftware` | **REMOVE** ⚠️ |
| Adobe Photoshop Elements 3.0 | 1 | `EXIF:Software` | **REMOVE** ⚠️ |
| ProCamera (various versions) | 4 | `EXIF:Software` | **KEEP** (camera app) |
| Google+ iOS | 2 | `EXIF:Software` | **REMOVE** ⚠️ |

**Camera Software** (to keep):
- COOLPIX S4000V1.2
- DSC-HX20V v1.00
- Digital Camera FinePix S602 ZOOM Ver1.00
- MediaTek Camera Application
- Photos 1.0
- ProCamera (camera app)

### 2.3 ICC Profile Creators

| Creator | Count | Action |
|---------|-------|--------|
| Apple Computer Inc. | 223 | **KEEP** |
| Hewlett-Packard | 9 | **KEEP** |
| Little CMS | 1 | **KEEP** |
| Unknown (hand) | 2 | **KEEP** |

---

## 3. Metadata Preservation Strategy

### 3.1 KEEP - Camera & Device Metadata

**Why**: Original capture data is irreplaceable and valuable for photo history.

- **EXIF Group**: All camera settings (aperture, shutter, ISO, focal length, etc.)
- **MakerNotes**: Camera-specific proprietary data
- **QuickTime**: Video container metadata
- **File**: Basic file system information
- **Composite**: Calculated fields (e.g., `Megapixels`, `ShutterSpeed`, `Aperture`)
- **ICC_Profile**: Color space profiles
- **MPF**: Multi-picture format data
- **PrintIM**: Print image matching
- **JFIF**: JPEG file interchange format
- **GPS Data**: Location coordinates
- **iOS/Android Software Tags**: Phone OS version is part of device signature

### 3.2 KEEP - Mylio Organizational Data

**Why**: Mylio's data structure must be preserved to maintain library organization.

**In XMP Sidecars**:
- `MY:*` namespace (all 9 fields)
- `xmpMM:DocumentID` / `xmpMM:InstanceID` / `xmpMM:OriginalDocumentID`
- `dc:subject` keywords (EXCEPT DigiKam `!Shared-*` and `!Private-*` patterns)
- `xmp:MetadataDate` / `xmp:CreateDate` / `xmp:ModifyDate`
- `photoshop:Country` / `photoshop:State` / `photoshop:City`
- GPS coordinates in `exif:GPS*`

**In Embedded IPTC**:
- Keywords (EXCEPT DigiKam `!Shared-*` and `!Private-*` patterns)
- Captions
- Copyright
- Ratings

### 3.3 KEEP - ExifTool Processing Stamps

**Why**: Track what's been processed by our scripts.

- `ExifTool:ExifToolVersion`
- `ExifTool:ProcessingTimestamp`
- Processing history in comments

### 3.4 REMOVE - Editing Software Bloat ⚠️

**Why**: These tags add no value and clutter metadata. They indicate the file was edited/viewed by software we no longer use.

**Software to Remove**:
- Picasa (16 files)
- Microsoft Windows Photo Viewer (16 files)
- digiKam (3 files in `ProcessingSoftware`)
- Adobe Photoshop Elements (1 file)
- Google+ iOS (2 files)

**Tags to Remove**:
1. **DigiKam Keywords** (embedded IPTC + XMP sidecars):
   - `!Shared-Family` (~1,144 files)
   - `!Shared-Nok-No Exif` (~486 files)
   - `!Private-Nok-No Exif` (~477 files)
   - `!Private-Joseph` (~103 files)
   - `!Shared-Family-No Exif` (~98 files)

2. **Software Tags**:
   - `EXIF:Software` when value = editing software
   - `EXIF:ProcessingSoftware` when value = editing software
   - `Photoshop:*` embedded tags (keep in XMP sidecars, remove from embedded)

**How to Remove**:
```powershell
# Remove DigiKam keywords from both embedded IPTC and XMP sidecars
exiftool -IPTC:Keywords-="!Shared-Family" `
         -IPTC:Keywords-="!Shared-Nok-No Exif" `
         -IPTC:Keywords-="!Private-Nok-No Exif" `
         -IPTC:Keywords-="!Private-Joseph" `
         -IPTC:Keywords-="!Shared-Family-No Exif" `
         -XMP:Subject-="!Shared-Family" `
         -XMP:Subject-="!Shared-Nok-No Exif" `
         -XMP:Subject-="!Private-Nok-No Exif" `
         -XMP:Subject-="!Private-Joseph" `
         -XMP:Subject-="!Shared-Family-No Exif" `
         -P -overwrite_original FILE.jpg

# Remove editing software tags
exiftool -Software="" -ProcessingSoftware="" -Photoshop:all="" `
         -P -overwrite_original FILE.jpg
```

---

## 4. XMP Sidecar Export/Merge Strategy

### 4.1 For Files WITH Existing Mylio XMP (4,184 files)

1. **Read existing XMP** - Parse current Mylio sidecar
2. **Preserve all MY:* fields** - Never overwrite Mylio data
3. **Preserve xmpMM:* IDs** - Document tracking must remain intact
4. **Preserve dc:subject keywords** - Keep all keywords (including DigiKam ones)
5. **Merge additional EXIF** - Add camera/GPS data not already in XMP
6. **Add ImageDataMD5** - Calculate and embed file hash for permanent linking
7. **Update xmp:MetadataDate** - Timestamp the merge operation

### 4.2 For Files WITHOUT XMP (estimated ~71,608 files)

1. **Export all embedded metadata** - Use ExifTool to create new sidecar
2. **Add ImageDataMD5** - Calculate file hash
3. **Structure as Mylio-compatible XMP** - Use standard namespaces
4. **Create side-by-side** - `photo.jpg` → `photo.jpg.xmp` in same directory

**ExifTool Export Command**:
```powershell
# Export all metadata to XMP sidecar
exiftool -o %f.xmp -all:all -tagsfromfile @ -ImageDataMD5 FILE.jpg

# Alternatively, export specific groups only
exiftool -o %f.xmp `
  -EXIF:all -GPS:all -IPTC:all -XMP:all -MakerNotes:all `
  -tagsfromfile @ -ImageDataMD5 FILE.jpg
```

---

## 5. Embedded Metadata Cleanup Strategy

**IMPORTANT**: Only execute AFTER XMP export is complete and verified.

### 5.1 Remove DigiKam Keywords

**Remove from both embedded IPTC and XMP sidecars:**

```powershell
# Identify files with DigiKam keywords
exiftool -if '$Keywords =~ /^!Shared-|^!Private-/' -r D:\Mylio > files-with-digikam-keywords.txt

# Remove DigiKam keywords from embedded IPTC
exiftool -IPTC:Keywords-="!Shared-Family" `
         -IPTC:Keywords-="!Shared-Nok-No Exif" `
         -IPTC:Keywords-="!Private-Nok-No Exif" `
         -IPTC:Keywords-="!Private-Joseph" `
         -IPTC:Keywords-="!Shared-Family-No Exif" `
         -P -overwrite_original -r D:\Mylio

# Remove DigiKam keywords from XMP sidecars
exiftool -XMP:Subject-="!Shared-Family" `
         -XMP:Subject-="!Shared-Nok-No Exif" `
         -XMP:Subject-="!Private-Nok-No Exif" `
         -XMP:Subject-="!Private-Joseph" `
         -XMP:Subject-="!Shared-Family-No Exif" `
         -P -overwrite_original -ext xmp -r D:\Mylio
```

### 5.2 Remove Editing Software Tags

```powershell
# Identify files with editing software tags
exiftool -if '$Software =~ /Picasa|Windows Photo Viewer|digiKam|Photoshop|Google/' `
  -r D:\Mylio > files-with-editing-software.txt

# Remove editing software tags
exiftool -Software="" -ProcessingSoftware="" -Photoshop:all="" `
  -P -overwrite_original -r D:\Mylio
```

### 5.3 Preserve Camera Software

**DO NOT remove** software tags matching:
- iOS version numbers (5.1.1 - 18.6.2)
- Android version strings
- Camera firmware versions (e.g., `DSC-HX20V v1.00`)
- Camera app names (e.g., `ProCamera`, `MediaTek Camera Application`)

### 5.4 Validation

After cleanup:
1. Verify XMP sidecars are intact
2. Spot-check random files for proper metadata removal
3. Confirm camera EXIF data is still present
4. Test file loading in Mylio (should see XMP keywords/ratings)

---

## 6. Next Steps

### Immediate (Step 3 - Document Findings) ✅
- [x] Created this documentation

### Pending (Step 4 - Wait for Timestamp Sync)
- [ ] Monitor timestamp sync completion (currently at ~51%, ETA 4.5 hours)
- [ ] After sync complete: Run full embedded metadata scan (all 75,792 files)
- [ ] Document any additional software tags found in full scan

### Pending (Step 5 - Create Scripts)
- [ ] Create XMP merge script for existing 4,184 Mylio sidecars
- [ ] Create XMP export script for remaining ~71,608 files
- [ ] Create embedded metadata cleanup script (remove editing software tags)
- [ ] Add ImageDataMD5 hash to all files and sidecars
- [ ] Test scripts on small sample (100 files) before full execution

---

## 7. Risk Assessment

### Low Risk Operations ✅
- Reading/analyzing metadata (no changes)
- Creating XMP sidecars (non-destructive, creates new files)
- Adding ImageDataMD5 hash (reversible)

### Medium Risk Operations ⚠️
- Merging metadata into existing Mylio XMP (could overwrite if not careful)
  - **Mitigation**: Backup all 4,184 XMP files before merge
- Removing embedded editing software tags (destructive)
  - **Mitigation**: Export to XMP first, test on small sample

### High Risk Operations 🚨
- None planned (all operations are either non-destructive or have backups)

---

## 8. Timeline Estimate

| Task | Estimated Time | Notes |
|------|----------------|-------|
| Timestamp sync completion | 4.5 hours | Currently running (51% complete) |
| Full metadata scan (75,792 files) | 4-5 hours | After timestamp sync |
| XMP merge script development | 2-3 hours | For 4,184 existing sidecars |
| XMP export script development | 2-3 hours | For ~71,608 new sidecars |
| Cleanup script development | 1-2 hours | Remove editing software tags |
| Testing on sample (100 files) | 30 minutes | Validation before full run |
| Full XMP export/merge | 8-10 hours | All 75,792 files |
| Full cleanup execution | 2-3 hours | Remove editing tags |
| Validation | 1 hour | Spot-check results |
| **Total** | **25-32 hours** | Spread over 2-3 days |

---

## 9. Backup Strategy

Before any destructive operations:

1. **XMP Sidecars**: Copy all 4,184 existing XMP files to backup location
2. **Test Sample**: Copy 100 random files to test directory
3. **Mylio Database**: Mylio maintains its own database (not at risk)
4. **File System**: Timestamp sync uses `-P` flag (preserves file modification dates)

**Backup Command**:
```powershell
# Backup all existing XMP sidecars
$xmpFiles = Get-ChildItem -Path "D:\Mylio" -Recurse -Filter "*.xmp"
$xmpFiles | ForEach-Object {
    $relativePath = $_.FullName.Replace("D:\Mylio\", "")
    $backupPath = "D:\Mylio-XMP-Backup\$relativePath"
    $backupDir = Split-Path $backupPath -Parent
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item $_.FullName $backupPath -Force
}
```

---

## 10. Success Criteria

### After XMP Export/Merge
- [ ] All 75,792 files have corresponding .xmp sidecars
- [ ] Existing 4,184 Mylio XMP files retain all MY:* fields
- [ ] All XMP files contain ImageDataMD5 hash
- [ ] Keywords from embedded IPTC are present in dc:subject
- [ ] Camera EXIF data is present in xmp sidecars
- [ ] GPS coordinates are preserved

### After Embedded Cleanup
- [ ] Editing software tags removed (Picasa, Windows Photo Viewer, digiKam, Photoshop, Google+)
- [ ] Camera software tags retained (iOS versions, camera firmware)
- [ ] Camera EXIF data intact (aperture, shutter, ISO, etc.)
- [ ] MakerNotes preserved
- [ ] ICC profiles preserved
- [ ] Mylio can still read all files and displays keywords/ratings from XMP

---

## References

- **Scan Reports**:
  - `embedded-metadata-scan-2025-11-11-095123.txt` (1,000 file sample)
  - `xmp-sidecar-scan-2025-11-11-104834.txt` (4,184 XMP files)

- **Scripts**:
  - `scan-embedded-metadata.ps1` - Full metadata scanner
  - `scan-xmp-sidecars.ps1` - XMP structure analyzer
  - `sync-timestamps-bidirectional.ps1` - Timestamp synchronization (currently running)

- **Documentation**:
  - XMP Specification: https://www.adobe.com/devnet/xmp.html
  - ExifTool Documentation: https://exiftool.org/
  - Mylio XMP Namespace: `http://ns.mylollc.com/MyloEdit/`
