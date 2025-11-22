# Media Tools Suite

> **Architecture Update (November 2025):** All media tools now utilize a unified core library (`lib/media_common.py`) for consistent performance, logging, and safety features.

Professional-grade Python tools for photo and video management with PowerShell menu integration.

## 🏗️ Unified Architecture

The Media Tools Suite follows a layered architecture for maintainability and extensibility:

| Layer | Component | Purpose |
|-------|-----------|---------|
| **Interface** | `homelab-menu-integration.ps1` | User-friendly menu system for PowerShell automation |
| **Orchestration** | `media-manager.py` (v1.0.0) | Central CLI engine for workflow automation |
| **Specialized Tools** | `deduplicate-pro.py`, `metadata-scrubber.py`, etc. | Domain-specific heavy lifting |
| **Core Library** | `lib/media_common.py` (v1.0.0) | Shared utilities, logging, ExifTool interface |

## 📦 Core Components

### CLI Automation Engine
- **`media-manager.py`** (v1.0.0) - Main CLI entry point for automation and scripting
  - Multiple operation modes: `rename`, `organize`, `deduplicate`, `all`
  - Action types: `copy` (safe), `move` (destructive), `rename_only` (in-place)
  - Folder structures: `simple` (YYYY/MM), `keywords` (Keywords/[Keyword]/YYYY/MM)
  - PowerShell-compatible naming: `YYYY-MM-DD-HHmmss-Make-Model-Hash.ext`

### Shared Core Library
- **`lib/media_common.py`** (v1.0.0) - Foundation for all media tools
  - File extension constants (PHOTO/VIDEO/RAW_EXTENSIONS)
  - Worker pool management (auto-detection, profiles)
  - ExifTool interface (metadata extraction, batch mode)
  - Logging utilities (FlushingFileHandler, crash-resistant)
  - UI helpers (colorized output, phase indicators)
  - Filename sanitization (cross-platform, PowerShell-compatible)

### PowerShell Integration
- **`homelab-menu-integration.ps1`** - Example menu system for homelab automation
  - Interactive workflows with dry-run preview
  - Five operation modes with user-friendly prompts
  - Safe defaults (copy mode, confirmation required)

## 🛠️ Specialized Tools

All tools share the unified core library for consistency and reliability.

### Media Deduplication
- **`deduplicate/deduplicate-pro.py`** (v4.0.0)
  - Advanced duplicate detection with perceptual hashing
  - Smart winner selection (resolution, RAW priority, ratings, keywords)
  - Three duplicate strategies: folder, alongside, skip
  - PowerShell-compatible naming format
  - Safe collision handling with destination tracking
  - **Usage:**
    ```bash
    python deduplicate-pro.py /source --dest /output --mode organize --structure simple --action copy --execute
    ```

### Metadata Management
- **`metadata-scrubber/metadata-scrubber.py`** (v3.0.0)
  - Batch metadata scrubbing (XMP, IPTC, Photoshop)
  - Safe mode with dry-run preview
  - Worker pool for performance
  - Comprehensive logging
  - **Usage:**
    ```bash
    python metadata-scrubber.py /path/to/photos --execute
    ```

### XMP Sidecar Export
- **`xmp-sidecar/xmp-sidecar.py`** (v3.0.0)
  - Export metadata to XMP sidecar files
  - Two naming conventions: Adobe (file.xmp) or Extension (file.ext.xmp)
  - Batch processing with progress bars
  - EXIF → XMP and QuickTime → XMP mapping
  - **Usage:**
    ```bash
    python xmp-sidecar.py /photos --naming adobe --skip-existing
    ```

### Timestamp Synchronization
- **`timestamp-sync/sync_timestamps.py`** (v2.0.0)
  - Bidirectional sync between file system and EXIF metadata
  - 50-100x faster than PowerShell (batch mode)
  - Intelligent date selection (prefers non-suspicious timestamps)
  - **Usage:**
    ```bash
    python sync_timestamps.py /photos --dry-run
    ```

## 📋 Quick Start

### 1. Verify Dependencies
```bash
python media-manager.py --help
```

This will check for:
- ExifTool (required for all metadata operations)
- Python packages: `tqdm`, `colorama`

### 2. Run a Test Operation (Dry-Run)
```bash
# Test rename operation
python media-manager.py /test/folder --mode rename --action move

# Test organize operation
python media-manager.py /source --dest /output --mode organize --structure simple --action copy
```

### 3. Execute with Confirmation
Once you've verified the dry-run output looks correct:
```bash
# Add --execute flag to apply changes
python media-manager.py /source --dest /output --mode organize --structure simple --action copy --execute
```

### 4. PowerShell Menu Integration
```powershell
# Run the interactive menu
.\homelab-menu-integration.ps1

# Or integrate into your existing homelab.ps1 menu
# See homelab-menu-integration.ps1 for examples
```

## 🔍 Common Workflows

### Workflow 1: Organize Photos by Date
```bash
# Copy files into YYYY/MM structure with PowerShell naming
python media-manager.py "/path/to/photos" --dest "/organized" --mode organize --structure simple --action copy --execute
```

### Workflow 2: Organize by Keywords
```bash
# Group photos by XMP/IPTC keywords
python media-manager.py "/path/to/photos" --dest "/organized" --mode organize --structure keywords --action copy --execute
```

### Workflow 3: Full Cleanup (Move + Dedupe + Rename)
```bash
# DESTRUCTIVE: Move files, deduplicate, and rename
python media-manager.py "/source" --dest "/clean" --mode all --action move --rename --execute
```

### Workflow 4: In-Place Rename Only
```bash
# Rename files in current location (no move)
python media-manager.py "/photos" --mode rename --action move --execute
```

### Workflow 5: Deduplicate Only
```bash
# Find and handle duplicates
python media-manager.py "/source" --dest "/output" --mode deduplicate --action copy --dupe-strategy folder --execute
```

## 🧪 Verification Checklist

Before using on your live photo library:

- [ ] **Dependencies**: Run `python media-manager.py --help` - confirms ExifTool detected
- [ ] **Logging**: Run a small test with dry-run - check `lib/logs/` for log file creation
- [ ] **PowerShell**: If using menus, test option calls Python script correctly
- [ ] **Dry-Run Test**: Run `--mode organize --action copy` on small test folder (no `--execute`)
- [ ] **Verify Output**: Check dry-run output matches expectations before using `--execute`

## 📁 Directory Structure

```
media/tools/
├── lib/
│   ├── media_common.py (v1.0.0)     # Shared core library
│   └── logs/                         # Auto-generated logs
├── deduplicate/
│   ├── deduplicate-pro.py (v4.0.0)  # Deduplication tool
│   └── README.md                     # Detailed dedupe docs
├── metadata-scrubber/
│   └── metadata-scrubber.py (v3.0.0)
├── xmp-sidecar/
│   └── xmp-sidecar.py (v3.0.0)
├── timestamp-sync/
│   └── sync_timestamps.py (v2.0.0)
├── media-manager.py (v1.0.0)        # CLI automation engine
├── homelab-menu-integration.ps1     # PowerShell menu examples
└── README.md                         # This file
```

## 🔧 Configuration

### Worker Pool Profiles

All tools support worker pool configuration for performance tuning:

- **Conservative**: 2 workers (low CPU usage)
- **Balanced**: ~50% CPU cores (default for most operations)
- **Fast**: CPU cores - 2 (high performance)
- **Maximum**: All CPU cores (maximum throughput)

Example:
```bash
python xmp-sidecar.py /photos --workers 12
```

### Duplicate Handling Strategies

When using `--mode deduplicate` or `--mode all`:

- **folder**: Move duplicates to `Duplicates/` subfolder (recommended)
- **alongside**: Keep duplicates with `-duplicate` suffix in same folder
- **skip**: Ignore duplicates completely

Example:
```bash
python media-manager.py /source --dest /output --mode deduplicate --dupe-strategy folder --execute
```

## 📊 Code Metrics

Total code reduction from unification: **120 lines eliminated**

| Tool | Version | Lines | Reduction |
|------|---------|-------|-----------|
| media_common.py | v1.0.0 | 333 | +333 (new) |
| deduplicate-pro.py | v4.0.0 | 405 | - |
| metadata-scrubber.py | v3.0.0 | 595 | -68 |
| xmp-sidecar.py | v3.0.0 | 485 | -40 |
| sync_timestamps.py | v2.0.0 | 323 | -12 |
| media-manager.py | v1.0.0 | 506 | +506 (new) |
| homelab-menu-integration.ps1 | - | 253 | +253 (new) |

## 🚨 Safety Features

All tools implement multiple safety layers:

1. **Dry-Run Mode**: Preview changes before execution (default behavior)
2. **Logging**: FlushingFileHandler ensures logs survive crashes
3. **Memory Protection**: SKIP_DIRS prevents processing system folders
4. **Collision Handling**: Destination tracking prevents file overwrites
5. **Error Handling**: Graceful degradation with detailed error messages
6. **Confirmation Required**: PowerShell menus require explicit confirmation

## 📚 Additional Tools & Documentation

### Video Processing
- **video/** - Video conversion and HDR processing scripts

### Configuration Utilities
- **codec-tools/** - Video codec configuration and testing
- **exiftool-management/** - ExifTool installation and configuration
- **file-association-tools/** - Windows file association management

### Documentation
- **photo-vault-architecture.md** - Complete photo storage architecture
- **auto-rotation-configuration.md** - Auto-rotation setup for Windows
- **heic-viewing-solution.md** - HEIC image format support
- **icaros-configuration.md** - Thumbnail generation configuration

### Archive
- **archive/** - Historical development files and superseded tools

## 🔗 Related Services

Application-specific tools and configurations:

- **Immich** → `~/Documents/git/dev/media/services/immich/`
- **DigiKam** → `~/Documents/git/dev/media/services/digikam/`

## 📝 License

MIT License - See individual tool files for details.

## 🤝 Contributing

This is a personal homelab project, but improvements are welcome:

1. Test changes on small datasets first
2. Follow existing code style (unified library imports)
3. Update version numbers in docstrings
4. Run verification checklist before committing

## 🐛 Troubleshooting

### "ExifTool not found"
Install ExifTool and ensure it's in your PATH:
- Windows: `D:\Files\Programs-Portable\ExifTool\exiftool.exe`
- Or install system-wide and add to PATH

### "ModuleNotFoundError: No module named 'tqdm'"
Install required Python packages:
```bash
pip install tqdm colorama
```

### "Nothing to write" warnings in XMP export
Normal for files with no metadata - not an error. Use `--skip-existing` to avoid reprocessing.

### PowerShell execution policy
If scripts won't run, update execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

**Last Updated:** November 21, 2025
**Architecture Status:** 🟢 Production Ready
