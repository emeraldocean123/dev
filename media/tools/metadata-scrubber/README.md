# Metadata Scrubber Pro

**Strip Edits & Privacy Leaks — Keep EXIF & GPS**

**Version:** 2.8.0
**License:** MIT

Remove Lightroom edits, keywords, and location history — while preserving camera data. Safe. Fast. Open Source.

## ✨ Why This Tool Exists

Every time you export a photo, you're potentially leaking:
- **Edit History** - Every adjustment you made in Lightroom/Capture One
- **Keywords & Captions** - Tags and descriptions from your DAM
- **GPS Coordinates** - Exact location where photo was taken (if you added it)
- **Serial Numbers** - Camera and lens identification
- **Software Versions** - Your entire editing toolchain

**This tool removes all that** while preserving the EXIF data you actually want:
- ✅ Camera settings (ISO, aperture, shutter speed)
- ✅ Original capture date/time
- ✅ Camera make and model
- ✅ Lens information
- ✅ GPS data for videos (QuickTime metadata)

## 🎯 Features

### Core Functionality
- ✅ **Safe Metadata Removal** - Removes XMP/IPTC/Photoshop while preserving EXIF
- ✅ **Smart Video Handling** - Preserves GPS coordinates and dates for videos
- ✅ **Copy-to-Target Mode** - Preserves original files (recommended)
- ✅ **In-Place Mode** - Direct modification option
- ✅ **Incremental Processing** - Automatically detects already-clean files
- ✅ **Dry-Run Mode** - Preview without modifying files
- ✅ **Quiet Mode** - Perfect for automation/cron jobs
- ✅ **Modern Format Support** - AVIF, WebP, JXL, HEVC, and more

### Performance
- ✅ **Turbo Batch Processing** - 50x faster than individual file calls
- ✅ **Worker Profiles** - Conservative / Balanced / Fast / Maximum
- ✅ **OOM Protection** - Skips junk folders (node_modules, .git, AppData)
- ✅ **Smart Incremental** - Detects unchanged files during batch (no pre-check needed)

### Safety
- ✅ **Backup Files** - Keeps `.exiftool_original` backups by default
- ✅ **Non-Destructive Default** - Copy mode preserves originals
- ✅ **Exit Codes** - 0 on success, 1 on error (automation-friendly)
- ✅ **Graceful CTRL-C** - Safe interrupt with batch completion

## 🚀 Quick Start

### Prerequisites

**Required:**
- Python 3.10 or higher
- [ExifTool](https://exiftool.org/) installed and in PATH

**Python Dependencies:**
```bash
pip install -r requirements.txt
```

### Installation

```bash
# Clone the repository
git clone https://github.com/emeraldocean123/metadata-scrubber-pro.git
cd metadata-scrubber-pro

# Install dependencies
pip install -r requirements.txt

# Verify ExifTool is installed
exiftool -ver
```

### Basic Usage

**Quick One-Liner (Recommended):**
```bash
# Creates a "cleaned" subfolder with scrubbed files
python metadata-scrubber-pro.py "D:\Photos"
```

**Interactive Mode:**
```bash
# Step-by-step prompts
python metadata-scrubber-pro.py
```

**Copy to Target (Safest - Preserves Originals):**
```bash
python metadata-scrubber-pro.py \
  --source "D:\Photos" \
  --target "D:\Photos-Clean"
```

**In-Place Modification (Use with Caution):**
```bash
python metadata-scrubber-pro.py \
  --source "D:\Photos" \
  --in-place
```

**Dry Run (Preview Without Modifying Files):**
```bash
python metadata-scrubber-pro.py \
  --source "D:\Photos" \
  --in-place \
  --dry-run
```

**Automation Mode (Minimal Output, No Backups):**
```bash
python metadata-scrubber-pro.py \
  --source "D:\Photos" \
  --in-place \
  --no-backups \
  --quiet >> scrub.log 2>&1
```

## 📋 Detailed Features

### Supported File Formats

**Photos:**
- RAW: `.dng`, `.cr2`, `.cr3`, `.nef`, `.arw`, `.orf`, `.rw2`, `.raw`
- Standard: `.jpg`, `.jpeg`, `.png`, `.tiff`, `.tif`
- Mobile: `.heic`, `.heif`
- Modern: `.avif`, `.webp`, `.jxl`

**Videos:**
- Common: `.mp4`, `.mov`, `.avi`, `.mkv`, `.m4v`
- Legacy: `.mpg`, `.mpeg`, `.wmv`, `.flv`, `.webm`
- Broadcast: `.3gp`, `.mts`, `.m2ts`
- Modern: `.hevc`, `.ts`

### What Gets Removed vs Preserved

**Photos - Removed:**
- XMP metadata (edit history, keywords, ratings)
- IPTC metadata (captions, copyright, location text)
- Photoshop metadata (layer data, actions)

**Photos - Preserved:**
- EXIF metadata (camera settings, dates, lens info)

**Videos - Removed:**
- XMP metadata only

**Videos - Preserved:**
- EXIF metadata (camera settings, dates)
- QuickTime metadata (GPS coordinates, creation dates)

### Performance Optimizations

**Turbo Batch Processing:**
- Photos: 50 files per batch
- Videos: 10 files per batch (adaptive - prevents timeouts)
- Single ExifTool call per batch (~50x faster than individual calls)
- No pre-check overhead - unchanged files detected during batch

**Worker Profiles:**
| Profile | Workers | Use Case |
|---------|---------|----------|
| Conservative | 2 | Background tasks, older systems |
| Balanced | CPU/2 | Recommended for most systems |
| Fast | CPU-2 | High performance (default) |
| Maximum | All CPU | Dedicated server, maximum speed |

**OOM Protection:**
- Skips junk folders: `node_modules`, `.git`, `AppData`, `__pycache__`, etc.
- Uses `os.walk` with pruning instead of `rglob`

**Typical Performance:**
| File Count | Estimated Time |
|------------|----------------|
| 1,000 files | ~5-10 minutes |
| 10,000 files | ~50-100 minutes |
| 100,000 files | ~8-16 hours |

*Performance varies based on storage speed, file sizes, and CPU cores.*

### Automation Examples

**Windows Task Scheduler:**
```powershell
# Daily at 3 AM
python C:\Tools\metadata-scrubber-pro\metadata-scrubber-pro.py ^
  --source "D:\Photos\Export" ^
  --in-place ^
  --no-backups ^
  --quiet >> "C:\Logs\scrub.log" 2>&1
```

**Linux/macOS Cron:**
```bash
# Daily at 3 AM
0 3 * * * /usr/bin/python3 /home/user/metadata-scrubber-pro/metadata-scrubber-pro.py \
  --source "/home/user/Photos/Export" \
  --in-place \
  --no-backups \
  --quiet >> /var/log/scrub.log 2>&1
```

**Output Format (Quiet Mode):**
```
2025-11-20 03:00:01 - COMPLETE: 234/234 scrubbed, 0 skipped, 0 errors
2025-11-21 03:00:01 - COMPLETE: 18/252 scrubbed, 234 skipped, 0 errors
```

## 🔧 Configuration

### Command-Line Options

```
--source PATH             Source directory
--target PATH             Target directory (copy mode)
--in-place                Modify files in-place (no copy)
--workers NUM             Number of parallel workers (default: auto-detect)
--dry-run                 Preview only, do not modify files
--no-backups              Do not keep .exiftool_original backup files
--quiet, -q               Minimal output (for automation/cron jobs)
--scrub-mode MODE         What to scrub: embedded, xmp, or both (default: both)
```

## 📸 Use Cases

### Pre-Publication Privacy
```bash
# Remove all edit history before posting online
python metadata-scrubber-pro.py "D:\Photos\ForInstagram"
```

### Client Delivery
```bash
# Remove your workflow details before delivering to clients
python metadata-scrubber-pro.py \
  --source "D:\Shoots\Wedding2024" \
  --target "D:\Delivery\Wedding2024"
```

### Archive Export
```bash
# Clean metadata before archiving to external drive
python metadata-scrubber-pro.py \
  --source "D:\Photos\2024" \
  --target "E:\Archive\2024-Clean"
```

### Stock Photo Prep
```bash
# Remove location data and edit history for stock submissions
python metadata-scrubber-pro.py \
  --source "D:\StockPhotos\Batch42" \
  --in-place
```

## 🛠️ Troubleshooting

### ExifTool Not Found

**Error:** `ExifTool not found! Please install...`

**Solution:**
1. Download from [exiftool.org](https://exiftool.org/)
2. **Windows:** Rename `exiftool(-k).exe` to `exiftool.exe` and add to PATH
3. **macOS:** `brew install exiftool`
4. **Linux:** `sudo apt install libimage-exiftool-perl`

### Slow Performance

**Causes:**
- HDD instead of SSD (expect 10-20x slower)
- Network drives (high latency)
- Antivirus scanning (blocks file access)

**Fixes:**
- Use local SSD for best performance
- Add script directory to antivirus exclusions
- Reduce `--workers` if system is overloaded

### Out of Memory

**Error:** Process killed during scrub

**Solution:**
- Reduce `--workers` (e.g., `--workers 4`)
- Reduce `--batch-size` (e.g., `--batch-size 25`)
- Process in smaller directory chunks

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ExifTool** by Phil Harvey - The backbone of metadata manipulation
- **tqdm** - Progress bar library
- **colorama** - Cross-platform colored output
- **Python** - For making this possible

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/emeraldocean123/metadata-scrubber-pro/issues)
- **Discussions:** [GitHub Discussions](https://github.com/emeraldocean123/metadata-scrubber-pro/discussions)

## 🌟 Related Projects

**Twin Tool:**
- [XMP Sidecar Pro](https://github.com/emeraldocean123/xmp-sidecar-pro) - Export metadata to portable XMP sidecar files

**Workflow:**
1. Use **XMP Sidecar Pro** to export and backup all your metadata
2. Use **Metadata Scrubber Pro** to remove privacy leaks before sharing

## 📈 Changelog

### v2.8.0 (2025-11-20)
- **Scrub mode selection** - Choose to scrub embedded metadata, XMP sidecars, or both (wizard + CLI)
- **Both XMP formats** - Supports `.xmp` and `.ext.xmp` sidecar naming conventions (e.g., `photo.xmp` and `photo.jpg.xmp`)
- **Unsupported format note** - When using embedded-only mode, shows hint to use XMP sidecars for unsupported formats

### v2.7.0 (2025-11-20)
- **XMP sidecar support** - Added `.xmp` to supported extensions (can scrub sidecar files)
- **Clearer messaging** - Unsupported formats now say "unsupported format - use XMP sidecar"

### v2.6.0 (2025-11-20)
- **Unsupported format handling** - MPEG/AVI/M2TS/WMV/WebM now shown as "Unsupported" (magenta) instead of errors
- **Helpful message** - Explains these formats need XMP sidecar files for metadata

### v2.5.0 (2025-11-20)
- **BUGFIX: ExifTool count parsing** - Was counting string occurrences instead of parsing actual numbers (caused 95%+ false "errors")

### v2.4.0 (2025-11-20)
- **Extension Renaming** - Optional wizard prompt to fix mismatched extensions (e.g., HEIC saved as .jpg → .heic)
- **Extension renaming logged** - All renames logged to file without breaking progress bar

### v2.3.0 (2025-11-20)
- **FileType Detection** - Process files by actual type, not extension (fixes HEIC-as-JPG errors)
- **Type fix logging** - Log type corrections to file only (prevents tqdm staircase)

### v2.2.0 (2025-11-20)
- **Logging Infrastructure** - Added `logs/` and `configs/` folders (consistent with other Pro tools)
- **Crash-safe logging** - FlushingFileHandler ensures logs survive crashes

### v2.1.0 (2025-11-20)
- **50x Performance Boost** - Removed per-file pre-check, now batches everything
- **OOM Protection** - Skips junk folders (node_modules, .git, AppData)
- **Worker Profiles** - Conservative / Balanced / Fast / Maximum options
- **Code Cleanup** - Unified styling, consistent section headers

### v2.0.0 (2025-11-20)
- Initial production release
- Smart video handling (preserves GPS/dates, removes only XMP)
- Incremental processing (`--skip-unchanged`)
- Dry-run mode for preview
- Quiet mode for automation
- Adaptive batch sizing (50 photos, 10 videos)
- Backup file handling (keeps `.exiftool_original` by default)
- Modern format support (AVIF, WebP, JXL, HEVC)
- Smart metadata detection (only processes files with removable metadata)
- Parallel processing with progress tracking
- Quick one-liner mode (`python metadata-scrubber-pro.py "path"`)

---

**Made with ❤️ by [emeraldocean123](https://github.com/emeraldocean123)**

🤖 Built with assistance from [Claude Code](https://claude.com/claude-code)
