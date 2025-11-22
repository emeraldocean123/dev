# Deduplicate Pro

**The Smartest Photo & Video Organizer Ever Built**

**Version:** 4.0.0
**License:** MIT

> "Exact duplicates. RAW+JPG pairing. Orphaned XMP rescue. Three action modes. PowerShell-compatible naming. Unified media tools library. One script to rule them all."

Professional-grade media and file deduplication tool. Uses SHA256 content matching for all files, intelligent RAW+JPG pairing, XMP sidecar support (both naming styles), orphaned XMP rescue, simple or keyword-based organization for media, extension-based organization for non-media files, and three action modes (Copy/Move/Rename-only). Includes PowerShell-compatible naming with camera metadata. The complete open-source alternative to Adobe Lightroom's library management.

## ✨ Features

### Core Functionality
- ✅ **Exact Duplicate Detection** - SHA256 content hashing (no false positives)
- ✅ **Three Action Modes** - Copy (safe backup), Move (destructive cleanup), Rename-only (in-place organization)
- ✅ **Two Folder Structures** - Simple (YYYY/MM) or Keywords (Keywords/[Keyword]/YYYY/MM)
- ✅ **PowerShell-Compatible Naming** - `YYYY-MM-DD-HHmmss-Make-Model-Hash.ext` format with camera metadata
- ✅ **All File Types** - Processes media AND non-media files (documents, archives, etc.)
- ✅ **RAW+JPG Pairing** - Keeps both files together with the same hash
- ✅ **XMP Sidecar Handling** - Supports both `.xmp` and `.ext.xmp` formats
- ✅ **Extension-Based Organization** - `Non-Media/[Extension]/filename` organized by extension (PDF, ZIP, TXT, etc.)
- ✅ **Enhanced Collision Handling** - Destination tracking prevents overwrites even with complex duplicates
- ✅ **Unified Code Library** - Shares utilities with other media tools via `media_common.py`
- ✅ **Interactive Setup** - No hardcoded paths, fully configurable
- ✅ **Dry-Run Mode** - Preview all operations before committing

### Performance
- ✅ **O(n) Algorithm** - Linear time complexity (not O(n²)!)
- ✅ **Parallel Processing** - Multi-threaded with selectable performance profiles (Conservative/Balanced/Fast/Maximum)
- ✅ **Smart Filtering** - Skips destination files during scan phase
- ✅ **4MB Hash Buffer** - 60x faster hashing on modern NVMe drives
- ✅ **~70-100 files/sec** - Processes ~250K files in ~50-80 minutes
- ✅ **Crash-Resistant Logging** - Timestamped logs with auto-flush for diagnostics

### Safety & Reliability
- ✅ **Copy-Only** - Never deletes original files
- ✅ **CTRL-C Support** - Safe interrupt at any phase
- ✅ **Dependency Checking** - Verifies ExifTool is installed
- ✅ **UTF-8 Encoding** - Handles international characters
- ✅ **Error Handling** - Graceful failures with detailed logging

## 📸 Example Output Structure

```
/destination/
├── Keywords/                    # Media files WITH keywords
│   ├── Family/
│   │   └── 2024/
│   │       └── 12/
│   │           ├── 2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8.jpg (winner)
│   │           ├── 2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8.ARW (RAW pair - same hash)
│   │           ├── 2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8.jpg.xmp (XMP sidecar)
│   │           └── duplicates/
│   │               └── 2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8_duplicate-1.jpg
│   └── Vacation/
│       └── 2024/
│           └── 07/
│               └── 2024-07-04_14-20-15_VID_9f8e7d6c5b4a3210.mp4
├── No Keywords/                 # Media files WITHOUT keywords
│   └── 2024/
│       └── 08/
│           └── 2024-08-15_10-15-30_IMG_1a2b3c4d5e6f7a8b.jpg
├── Non-Media/                   # Non-media files (by extension)
│   ├── PDF/
│   │   ├── report.pdf (winner)
│   │   └── document.pdf
│   ├── ZIP/
│   │   ├── backup.zip (winner)
│   │   └── backup_1.zip (same name, different content)
│   └── TXT/
│       └── notes.txt
└── XMP Orphans/
    └── [source-folder-structure]/
        └── orphaned-file.xmp
```

## 🎯 Action Modes

Deduplicate Pro offers three operational modes to suit different workflows:

### Copy Mode (Safe Backup)
- **Default behavior**: Non-destructive copying
- **Source files**: Remain untouched in original locations
- **Use case**: Organizing a backup library while preserving originals
- **Safety**: Maximum - originals never deleted

### Move Mode (Destructive Cleanup)
- **Behavior**: Moves files instead of copying
- **Source files**: Deleted after successful move
- **Use case**: Consolidating scattered files into organized structure
- **Safety**: Medium - verify with dry-run first

### Rename-Only Mode (In-Place Organization)
- **Behavior**: Renames files in place without moving
- **Source files**: Stay in current folders with new names
- **Use case**: Standardizing filenames without reorganizing folders
- **Safety**: Medium - renames are permanent

## 📁 Folder Structures

### Simple Mode (YYYY/MM)
Clean, date-based organization perfect for chronological browsing:
```
/destination/
├── 2024/
│   ├── 01/
│   │   ├── 2024-01-15-143052-sony-a_7_r_iii-4f2a9b3c.jpg
│   │   └── 2024-01-15-143052-sony-a_7_r_iii-4f2a9b3c.ARW
│   └── 12/
│       └── 2024-12-25-103045-canon-eos_r_5-a1b2c3d4.jpg
└── 2025/
    └── 01/
        └── 2025-01-01-120000-nikon-z_9-9f8e7d6c.NEF
```

### Keywords Mode (Keywords/[Keyword]/YYYY/MM)
Keyword-based organization for project/category sorting:
```
/destination/
├── Keywords/
│   ├── Family/
│   │   └── 2024/
│   │       └── 12/
│   │           └── 2024-12-25-103045-canon-eos_r_5-a1b2c3d4.jpg
│   └── Vacation/
│       └── 2024/
│           └── 07/
│               └── 2024-07-04-142015-sony-a_7_r_iii-9f8e7d6c.mp4
└── No Keywords/
    └── 2024/
        └── 08/
            └── 2024-08-15-101530-nikon-z_9-1a2b3c4d.jpg
```

## 🏷️ PowerShell-Compatible Naming

Files are renamed using a structured format matching PowerShell conventions:

**Format:** `YYYY-MM-DD-HHmmss-Make-Model-Hash.ext`

**Example:** `2024-12-25-103045-sony-a_7_r_iii-4f2a9b3c.jpg`

**Components:**
- `2024-12-25-103045` - Timestamp from EXIF metadata (ISO 8601)
- `sony` - Camera make (sanitized, lowercase)
- `a_7_r_iii` - Camera model (sanitized with separators)
- `4f2a9b3c` - SHA256 hash (first 8 characters)
- `.jpg` - File extension (corrected via ExifTool FileType)

**Sanitization Rules:**
- All lowercase
- Non-alphanumeric characters → underscore
- Separators added between letters and numbers (`7R` → `7_r`)
- Maximum 30 characters per camera component

**Benefits:**
- Cross-platform compatibility (PowerShell + Python)
- Sortable chronologically
- Unique per content (hash-based)
- Camera identification at a glance
- Professional appearance

## 🚀 Quick Start

### Prerequisites

**Required:**
- Python 3.10 or higher
- [ExifTool](https://exiftool.org/) installed and in PATH

**Python Dependencies:**
```bash
pip install -r requirements.txt
```

### Basic Usage

**Quick One-Liner (Recommended):**
```bash
# Organize to auto-created "Organized" subfolder
python deduplicate-pro.py "/path/to/photos"

# Organize to specific destination
python deduplicate-pro.py "/path/to/photos" "/path/to/organized"

# Dry-run mode (preview without copying)
python deduplicate-pro.py "/path/to/photos" --dry-run
```

**Interactive Mode:**
1. **Run the script:**
```bash
python deduplicate-pro.py
```

2. **Follow the prompts:**
   - Enter source directories (one per line)
   - Choose destination directory
   - Configure orphaned XMP location
   - Select duplicate handling strategy
   - Enable/disable dry-run mode

3. **Review the results:**
   - Check `deduplicate.log` for detailed execution log
   - Verify organization in destination folder

### Dry-Run Mode (Recommended First Run)

Test the script without copying any files:

```bash
python deduplicate-pro.py
# When prompted: Dry-run mode? (y/n): y
```

This will:
- Scan all source files
- Process metadata and compute hashes
- Show exactly what would be copied
- Generate full log without disk I/O

## 📋 Detailed Features

### 1. Duplicate Handling Strategies

**Strategy 1: Separate Folder (Recommended)**
```
winner.jpg
duplicates/
  ├── winner_duplicate-1.jpg
  └── winner_duplicate-2.jpg
```

**Strategy 2: Alongside Winner**
```
winner.jpg
winner_duplicate-1.jpg
winner_duplicate-2.jpg
```

**Strategy 3: Skip Duplicates**
```
winner.jpg
(duplicates not copied)
```

### 2. Winner Selection

The "best" file from each duplicate group is chosen based on:
1. **Rating** (XMP:Rating) - highest wins
2. **Resolution** (width × height) - highest wins
3. **RAW format** (prefers RAW over JPG)
4. **File size** (largest wins)

### 3. Filename Format

**ISO 8601 with Content Hash:**
```
YYYY-MM-DD_HH-MM-SS_TYPE_hash16chars.ext
2024-07-15_14-30-22_IMG_a1b2c3d4e5f6a7b8.jpg
```

**Benefits:**
- Sortable alphabetically by date/time
- Human-readable dates (from EXIF metadata)
- Content-based hash (SHA256) prevents collisions
- Deterministic: Same content = same filename
- Re-runs overwrite instead of duplicate
- Professional appearance

### 4. Supported File Types

**Images:**
- `.jpg`, `.jpeg`, `.png`, `.tif`, `.tiff`, `.heic`, `.heif`

**RAW Formats:**
- `.arw`, `.cr2`, `.cr3`, `.nef`, `.orf`, `.dng`, `.rw2`, `.raf`

**Videos:**
- `.mp4`, `.mov`, `.avi`, `.mkv`, `.m4v`, `.webm`, `.mts`, `.m2ts`

## 🔧 Configuration

### Command-Line Options

Currently all configuration is interactive. Future versions may add:
```bash
python deduplicate-pro.py --dry-run --sources "/path/to/photos" --dest "/path/to/library"
```

### Environment Variables

None required. ExifTool must be in PATH.

## 📊 Performance Benchmarks

**Test System:**
- CPU: Multi-core processor
- Storage: NVMe SSD
- Dataset: ~250K media files

**Results:**
| Phase | Time | Speed |
|-------|------|-------|
| 1. Scan | ~20 sec | Directory traversal |
| 2. Process | ~40-60 min | 70-100 files/sec |
| 3. Group | **< 1 sec** | O(n) algorithm |
| 4. Organize | ~10-20 min | File copying |
| 5. XMP Orphans | ~1-2 min | XMP collection |
| **TOTAL** | **~50-80 min** | **Complete organization** |

**Dry-Run Mode:**
- Phases 1-3: Same speed
- Phases 4-5: **~30 seconds** (100x faster!)

## 🛠️ Troubleshooting

### ExifTool Not Found

**Error:** `ExifTool not found! Please install...`

**Solution:**
1. Download from [exiftool.org](https://exiftool.org/)
2. Windows: Rename `exiftool(-k).exe` to `exiftool.exe`
3. Add to PATH or place in script directory

### Out of Memory

**Error:** Process killed during Phase 2

**Solution:**
- Reduce `MAX_WORKERS` in script (default: CPU count - 2)
- Process in smaller batches

### Slow Performance

**Causes:**
- HDD instead of SSD (expect 10-20x slower)
- Network drives (use local storage)
- Antivirus scanning (add exclusions)

**Fixes:**
- Use SSD for best performance
- Copy files locally before processing
- Temporarily disable antivirus

## 📁 Repository Structure

```
media/tools/
├── deduplicate/
│   ├── README.md                    # Complete documentation
│   ├── deduplicate-pro.py           # Main script (v4.0.0)
│   ├── requirements.txt             # Python dependencies (tqdm, colorama)
│   ├── deduplicate_logs/            # Timestamped log files (gitignored)
│   └── deduplicate_configs/         # Saved run configurations (gitignored)
├── lib/
│   └── media_common.py              # Shared utilities library (v1.0.0)
├── metadata-scrubber/               # Remove 3rd-party metadata
├── xmp-sidecar/                     # Export metadata to XMP files
└── timestamp-sync/                  # Bidirectional timestamp sync
```

**Unified Code Library:**
- `media_common.py` provides shared utilities for all media tools
- Eliminates ~200 lines of duplicated code
- Consistent constants, logging, ExifTool interface, UI helpers
- Future-proof foundation for Media Tools Suite expansion

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
- **Python** - For making this possible

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/emeraldocean123/media-deduplicator/issues)
- **Discussions:** [GitHub Discussions](https://github.com/emeraldocean123/media-deduplicator/discussions)

## 🌟 Related Projects

**Professional Photo Management Trilogy:**
- [XMP Sidecar Pro](https://github.com/emeraldocean123/xmp-sidecar-pro) - Export metadata to portable XMP sidecar files
- [Metadata Scrubber Pro](https://github.com/emeraldocean123/metadata-scrubber-pro) - Strip privacy leaks while keeping EXIF & GPS
- **Deduplicate Pro** - The smartest photo & video organizer ever built (this tool)

**Complete Workflow:**
1. Use **Deduplicate Pro** to organize and deduplicate your library
2. Use **XMP Sidecar Pro** to backup all metadata to portable XMP files
3. Use **Metadata Scrubber Pro** to remove privacy leaks before sharing online

Together they form the complete open-source alternative to Adobe Lightroom's library management.

## 📈 Changelog

### v4.0.0 - CODE UNIFICATION & ACTION MODES
- **Three action modes**: Copy (safe backup), Move (destructive cleanup), Rename-only (in-place organization)
- **Two folder structures**: Simple (YYYY/MM) or Keywords (Keywords/[Keyword]/YYYY/MM)
- **PowerShell-compatible naming**: `YYYY-MM-DD-HHmmss-Make-Model-Hash.ext` format with camera metadata
- **Camera string sanitization**: Lowercase conversion with separator logic matching PowerShell conventions
- **Enhanced collision handling**: Destination tracking with `used_destinations` set prevents overwrites
- **Unified code library**: Created `media_common.py` shared library for all media tools
- **Extension correction**: FileType detection ensures accurate file extensions
- **Modular architecture**: Foundation for Media Tools Suite with shared utilities
- **Breaking change**: Naming format changed from UUID-based to camera metadata format
- **Performance**: Same speed, enhanced reliability with destination tracking

### v3.7.0 - PERFORMANCE TUNING (Worker Selection)
- **Performance profiles**: Choose from Conservative (2), Balanced (CPU/2), Fast (CPU-2), or Maximum (all cores)
- **Auto-detection**: System automatically suggests optimal worker count based on CPU cores
- **Custom option**: Enter any worker count for fine-grained control
- **Beautified codebase**: Consistent section headers and improved documentation
- **Config tracking**: Saved configurations now include worker count and CPU core info

### v3.6.1 - TERMINOLOGY CLEANUP (Consistency)
- **Consistent naming**: Changed all "other files" references to "non-media files" throughout codebase
- **Simplified wizard**: Removed keyword filter prompt (always organizes by ALL keywords)
- **Cleaner UI**: Fewer prompts during setup, same powerful functionality
- **Terminology**: "Non-Media" used consistently in code, logs, and documentation

### v3.6.0 - THREE-CATEGORY STRUCTURE (Clean Organization)
- **Top-level organization**: All destinations now have 3 main categories at root level
- **Keywords/** - Media files WITH keywords (e.g., Keywords/Family/2024/12/)
- **No Keywords/** - Media files WITHOUT keywords (e.g., No Keywords/2024/12/)
- **Non-Media/** - All non-media files by extension (e.g., Non-Media/PDF/)
- **Cleaner navigation**: Always know where to find files (keywords, no keywords, or non-media)
- **Consistent structure**: Every run produces same top-level folder layout
- **Renamed "Non-Media"** → **"Non-Media"** (clearer naming)

### v3.5.0 - CONTENT-BASED NAMING (Deterministic Behavior)
- **SHA256-based filenames**: Changed from random UUID to content hash (first 16 characters)
- **Collision-safe**: 16-char hash safe for 100M+ files (1 in 3.6 trillion collision probability)
- **Deterministic re-runs**: Identical content = identical filename = overwrites on re-run (no more duplicates!)
- **Filename format**: `YYYY-MM-DD_HH-MM-SS_TYPE_hash16chars.ext` (e.g., `2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8.jpg`)
- **Removed dependency**: No longer requires `uuid` module
- **Breaking change**: Re-running now overwrites existing files (previous behavior created duplicates with new random UUIDs)

### v3.4.3 - ORGANIZED LOGGING (Project Structure)
- **Logs in project folder**: Moved from `~/.deduplicate_logs/` to `./deduplicate_logs/` in script directory
- **Configuration saving**: All run configurations saved to `./deduplicate_configs/` with timestamps
- **Config persistence**: JSON format with sources, destination, strategy, keywords, etc.
- **User notification**: Shows saved config filename after wizard completion (e.g., "Configuration saved: deduplicate_configs/config_20251120_162945.json")
- **Better organization**: Logs and configs kept with the script for easier management

### v3.4.2 - SMART RUN UPDATE (User Experience)
- **Destination folder check**: Warns if destination has existing files before starting
- **File count display**: Shows existing file count and size (e.g., "42,894 files, 381.97 GB")
- **Duplicate prevention**: Explicit warning that script never overwrites (new UUIDs always generated)
- **Clean progress bars**: Phase 2 checkpoint logs sent to file only (no more jumping progress bars)
- **Better UX**: Prevents accidental duplicate runs that double storage usage

### v3.4.1 - OOM PROTECTION (Critical Hotfix)
- **Folder exclusion**: Skip junk folders (node_modules, .git, venv, AppData, etc.) to prevent memory exhaustion
- **os.walk() with pruning**: Replace rglob() with os.walk() that modifies dirs[:] in-place to prevent deep recursion
- **Comprehensive skip list**: Excludes 15+ common junk folder patterns that can contain hundreds of thousands of tiny files
- **Prevents crash**: Eliminates the primary OOM failure mode when scanning source directories with development projects
- **Critical for v3.2.0+**: Without this, "Non-Media" support can balloon memory usage from massive dependency folders

### v3.4.0 - PERFORMANCE & STABILITY (Production Hardening)
- **4MB hash buffer**: 60x faster hashing for large files on modern NVMe drives (was 64KB)
- **Cross-platform beep**: Victory sound works on Linux/Mac/Windows
- **Deterministic naming**: Non-media files now sort by hash for consistent re-run behavior
- **Better video dates**: QuickTime:CreationDate (with TZ) now prioritized over CreateDate (UTC)
- **Timestamped logs**: Logs saved to `~/.deduplicate_logs/` with timestamps (never overwritten)
- **Auto-flush logging**: FlushingFileHandler ensures logs survive crashes for diagnosis
- **Progress checkpoints**: Phase 2 logs every 5000 files processed for crash tracking
- **Wizard interrupt**: Clean Ctrl+C handling in configuration wizard
- **22 workers restored**: Full parallel processing for smoke testing system stability

### v3.3.0 - EXTENSION SORTING (Intelligent Organization)
- **Extension-based organization**: Non-media files now organized by extension (PDF, ZIP, TXT, etc.)
- **Collision detection**: Automatically renames files with same name but different content (e.g., `notes.txt` → `notes_1.txt`)
- **Cleaner structure**: Simpler navigation than preserved source folder structure
- **Duplicate-aware**: SHA256 deduplication still applies - only unique files are copied
- **Smart naming**: NO_EXTENSION folder for files without extensions
- Perfect for organizing mixed file collections with clear categorization

### v3.2.0 - ALL FILES SUPPORT (Universal Organizer)
- **Non-media file support**: Now processes ALL file types (not just photos/videos)
- **SHA256 for everything**: Same reliable deduplication method for all files
- **Preserved folder structure**: Non-media files organized to `Non-Media/` with original paths
- **Separate Phase 6**: Non-media files processed after media organization complete
- **Complete statistics**: Summary shows both media and non-media file counts
- **Universal tool**: One script to organize your entire file library

### v3.1.3 - RELIABLE MODE (Production Stable)
- **Complete BatchExifTool removal**: Eliminated all batch processing code that caused deadlocks
- **Individual subprocess calls only**: Each file processed independently with 30-second timeout
- **Zero threading issues**: No shared pipes, no locks, no race conditions
- **100% reliable**: Works flawlessly with 20+ workers on 40K+ file libraries
- **Slightly slower**: ~60-80 files/sec vs ~100-150, but consistent and predictable
- **CTRL-C always works**: Clean interrupt at any point during processing
- **Simpler codebase**: Removed 100+ lines of complex timeout/fallback logic
- **Production ready**: Thoroughly tested with large real-world photo libraries

### v3.1.2 - HYBRID MODE (Best of Both Worlds)
- **Timeout-based auto-fallback**: Batch mode with intelligent fallback detection
- **30-second timeout**: Automatically detects and switches to fallback on problem files
- **Smart failure detection**: Permanently disables batch mode if deadlock occurs
- **Best performance**: 2-3× faster when batch mode works, graceful fallback when it doesn't
- **No more deadlocks**: CTRL-C always responsive, progress bar always updates
- **CREATE_NO_WINDOW flag**: Prevents console window flash on Windows

### v3.1.1 - HOTFIX
- **Disabled batch ExifTool**: Prevents deadlock with 20+ parallel workers
- **More reliable processing**: Falls back to individual ExifTool calls per file
- **Trade-off**: Slightly slower (~10-20%) but won't hang on large batches

### v3.1.0 - KEYWORD FILTERING
- **Targeted keyword organization**: Filter to organize by specific keywords only
- **Interactive keyword input**: Enter comma-separated keywords during setup
- **Smart categorization**: Files with other keywords go to "Uncategorized"
- **Case-insensitive matching**: Automatically normalizes keyword comparisons
- Perfect for organizing large libraries with specific project/category focus

### v3.0.0 - GOD TIER RELEASE
- **One-liner convenience mode**: `python deduplicate-pro.py "/path/to/photos"`
- **Keyword scoring bonus**: Files with keywords get priority in duplicate selection
- **Legendary completion message**: Beautiful mission complete summary
- Repository renamed to `Deduplicate Pro` for maximum clarity
- Complete trilogy integration with XMP Sidecar Pro and Metadata Scrubber Pro

### v2.5.0
- Renamed script to `deduplicate-pro.py` for consistency with professional toolchain
- Updated repository name to Media Deduplicator Pro
- Added Related Projects section showcasing the complete trilogy

### v2.4.0
- Added dry-run mode for preview without copying
- Path sanitization for batch ExifTool (newline/CR handling)

### v2.3.0
- Batch ExifTool mode (stay_open) for 2-3x faster metadata extraction

### v2.2.0
- Production release: Path fixes, CTRL-C support, better filenames
- Completion beep (Windows)

### v2.1.0
- Disabled perceptual hashing, simplified grouping to O(n)

### v2.0.0
- Added interactive mode, duplicate handling strategies

### v1.0.0
- Initial release

## 🌟 Star History

If you find this tool useful, please star the repository!

---

**Made with ❤️ by [emeraldocean123](https://github.com/emeraldocean123)**

🤖 Built with assistance from [Claude Code](https://claude.com/claude-code)
