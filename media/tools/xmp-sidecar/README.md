# XMP Sidecar Pro

**Version:** 2.6.3
**License:** MIT

Professional-grade XMP sidecar export tool for photographers, archivists, and digital asset managers. Export all metadata to portable, Adobe-standard XMP sidecar files. Fast, safe, and automation-ready.

## ✨ Features

**Core Functionality:**
- ✅ **Adobe-Standard Naming** - `filename.xmp` (not `filename.ext.xmp`)
- ✅ **Smart Batch Sizing** - Adaptive batching (50 photos, 10 videos per batch)
- ✅ **Parallel Processing** - Multi-threaded with auto-configured workers
- ✅ **Incremental Backups** - `--skip-existing` for fast incremental runs
- ✅ **Dry-Run Mode** - Test without writing files
- ✅ **Quiet Mode** - Perfect for automation/cron jobs
- ✅ **Modern Format Support** - AVIF, WebP, JXL, HEVC, and more

**Performance:**
- ✅ **~100-200 files/minute** - Optimized ExifTool batching
- ✅ **Graceful CTRL-C** - Safe interrupt with batch completion
- ✅ **Progress Tracking** - Real-time progress bars and counters

**Safety:**
- ✅ **Non-Destructive** - Only creates sidecar files
- ✅ **Comprehensive Logging** - Detailed success/error reporting
- ✅ **Exit Codes** - 0 on success, 1 on error (automation-friendly)

## 📸 Use Cases

### Professional Photography
```bash
# Daily incremental XMP backup
python xmp-sidecar-pro.py \
  --directory "/Volumes/Photos/2024" \
  --skip-existing \
  --quiet >> backup.log
```

### DAM Software Migration
```bash
# Export all metadata before switching software
python xmp-sidecar-pro.py --directory "/Import/Raw"
```

### Archive Migration
```bash
# Export all metadata before switching photo management software
python xmp-sidecar-pro.py "/Archive/Photos" --workers 12
```

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
git clone https://github.com/emeraldocean123/xmp-sidecar-pro.git
cd xmp-sidecar-pro

# Install dependencies
pip install -r requirements.txt

# Verify ExifTool is installed
exiftool -ver
```

### Basic Usage

**Export Tool:**
```bash
# Quick one-liner (interactive mode disabled)
python xmp-sidecar-pro.py /path/to/photos

# Interactive mode (recommended for first use)
python xmp-sidecar-pro.py

# Command-line mode with options
python xmp-sidecar-pro.py \
  --directory "D:\Photos" \
  --workers 12 \
  --batch-size 100

# Incremental backup (skip existing XMP files)
python xmp-sidecar-pro.py \
  --directory "D:\Photos" \
  --skip-existing

# Dry run (preview without writing files)
python xmp-sidecar-pro.py \
  --directory "D:\Photos" \
  --dry-run

# Automation mode (minimal output)
python xmp-sidecar-pro.py \
  --directory "D:\Photos" \
  --skip-existing \
  --quiet >> xmp-backup.log 2>&1
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

### Adobe-Standard Sidecar Naming

**Before (non-standard):**
```
IMG_1234.JPG      → IMG_1234.JPG.xmp
IMG_1234.CR3      → IMG_1234.CR3.xmp
```

**After (Adobe standard):**
```
IMG_1234.JPG      → IMG_1234.xmp
IMG_1234.CR3      → IMG_1234.xmp
```

**Benefits:**
- Compatible with Lightroom, Darktable, Capture One, digiKam
- Cleaner file structure
- Industry best practice
- No confusion with double extensions

### Performance Optimizations

**Smart Batch Sizing:**
- Photos: 50 files per batch (default)
- Videos: 10 files per batch (adaptive - videos are larger)
- Prevents timeouts on large 4K+ video files

**Parallel Processing:**
- Workers: CPU count (default)
- ExifTool batching minimizes startup overhead
- Single ExifTool call per batch (~50x faster than individual calls)

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
# Daily at 2 AM
python C:\Tools\xmp-sidecar-pro\xmp-sidecar-pro.py ^
  --directory "D:\Photos" ^
  --skip-existing ^
  --quiet >> "C:\Logs\xmp-backup.log" 2>&1
```

**Linux/macOS Cron:**
```bash
# Daily at 2 AM
0 2 * * * /usr/bin/python3 /home/user/xmp-sidecar-pro/xmp-sidecar-pro.py \
  --directory "/home/user/Photos" \
  --skip-existing \
  --quiet >> /var/log/xmp-backup.log 2>&1
```

**Output Format (Quiet Mode):**
```
2025-11-20 02:00:01 - COMPLETE: 156/15432 exported, 15276 skipped, 0 errors
2025-11-21 02:00:01 - COMPLETE: 42/15474 exported, 15432 skipped, 0 errors
```

## 🔧 Configuration

### Command-Line Options

```
--directory, -d PATH      Directory containing media files
--workers, -w NUM         Number of parallel workers (default: CPU count)
--batch-size, -b NUM      Files per batch (default: 50)
--skip-existing, -s       Skip files that already have .xmp sidecars
--dry-run                 Scan only, do not write XMP files
--quiet, -q               Minimal output (for automation/cron jobs)
--naming MODE             Naming: adobe (file.xmp) or ext (file.ext.xmp)
```

### Sidecar Naming Options

**1. Adobe Standard (Default) - `--naming adobe`**
- Format: `image.xmp`
- Best for: Lightroom, Photoshop, Camera Raw
- Note: `image.JPG` and `image.RAW` will share the same sidecar

**2. Extension Preserved - `--naming ext`**
- Format: `image.jpg.xmp`
- Best for: Darktable, RawTherapee, mixed folder backups
- Note: Prevents metadata collisions if you keep RAW+JPG in the same folder

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

**Error:** Process killed during export

**Solution:**
- Reduce `--workers` (e.g., `--workers 4`)
- Reduce `--batch-size` (e.g., `--batch-size 25`)
- Process in smaller directory chunks

## 📁 Repository Structure

```
xmp-sidecar-pro/
├── README.md                      # Complete documentation
├── LICENSE                        # MIT License
├── xmp-sidecar-pro.py      # XMP sidecar export tool (v2.0.0)
├── requirements.txt               # Python dependencies
└── .gitignore                     # Git ignore rules
```

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

- **ExifTool** by Phil Harvey - The backbone of metadata extraction
- **tqdm** - Progress bar library
- **colorama** - Cross-platform colored output
- **Python** - For making this possible

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/emeraldocean123/xmp-sidecar-pro/issues)
- **Discussions:** [GitHub Discussions](https://github.com/emeraldocean123/xmp-sidecar-pro/discussions)

## 🌟 Related Projects

**Twin Tool:**
- [Metadata Scrubber Pro](https://github.com/emeraldocean123/metadata-scrubber-pro) - Strip edits & privacy leaks, keep EXIF & GPS

**Complete Workflow:**
1. Use **XMP Sidecar Pro** to export and backup all your metadata
2. Use **Metadata Scrubber Pro** to remove privacy leaks before sharing online

Together they form the only complete open-source alternative to Adobe's locked-in metadata ecosystem.

## 📈 Changelog

### v2.6.3 (2025-11-20)
- Fixed success count parsing (now correctly extracts number from ExifTool output)
- File format warnings no longer inflate error count

### v2.6.2 (2025-11-20)
- Removed Duration mapping (XMP:xmpDM:Duration requires complex structure)
- Eliminates thousands of "Improperly formed structure" warnings for videos

### v2.6.1 (2025-11-20)
- Fixed overwrite mode: existing sidecars are now deleted before re-export
- Clearer prompt: "Y=keep, N=overwrite"

### v2.6.0 (2025-11-20)
- Added QuickTime-to-XMP mappings for video metadata export
- Videos now properly export CreateDate, Make, Model, GPS, Duration, etc.
- Fixes "Nothing to write" for video files that only have QuickTime metadata

### v2.5.0 (2025-11-20)
- Cleaner error handling: "Nothing to write" now counted as "No Data" (not errors)
- Added explicit EXIF-to-XMP mappings for scrubbed photos
- Better summary display with separate No Data category

### v2.0.0 (2025-11-20)
- Initial production release
- Adobe-standard sidecar naming (`filename.xmp`)
- Smart batch sizing (adaptive for photos vs videos)
- Incremental backup support (`--skip-existing`)
- Dry-run mode for testing
- Quiet mode for automation
- Modern format support (AVIF, WebP, JXL, HEVC)
- Graceful CTRL-C handling
- Comprehensive progress tracking

## 🌟 Star History

If you find this tool useful, please star the repository!

---

**Made with ❤️ by [emeraldocean123](https://github.com/emeraldocean123)**

🤖 Built with assistance from [Claude Code](https://claude.com/claude-code)
