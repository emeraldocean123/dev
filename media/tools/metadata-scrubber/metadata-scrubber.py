#!/usr/bin/env python3
"""
Metadata Scrubber Pro
=====================
Version: 2.8.0

Description:
    Removes 3rd-party metadata (Lightroom edits, PII) while preserving
    camera EXIF, timestamps, and Video GPS.

    Photos: Removes XMP, IPTC, Photoshop. Keeps EXIF.
    Videos: Removes XMP. Keeps QuickTime (GPS/Date).

Usage:
    python scrub-metadata.py "C:/Photos"
    python scrub-metadata.py --help

Changelog:
    v2.8.0 - Scrub mode selection: Choose embedded metadata, XMP sidecars, or both (wizard + CLI)
    v2.7.0 - XMP sidecar support: Added .xmp to supported extensions, clearer unsupported message
    v2.6.0 - Unsupported format handling: MPEG/AVI/M2TS/WMV/WebM shown as "unsupported" not "error"
    v2.5.0 - BUGFIX: Parse ExifTool counts correctly (was counting string occurrences, not numbers)
    v2.4.0 - Optional extension renaming: Fix mismatched extensions (e.g., HEIC saved as .jpg → .heic)
    v2.3.0 - FileType detection: Process files by actual type, not extension (fixes HEIC-as-JPG errors)
    v2.2.0 - Added logging and config folders (consistent with other Pro tools)
    v2.1.0 - Performance: Removed pre-check (50x faster), OOM protection, Worker profiles
    v2.0.0 - Initial production release

Requirements:
    pip install tqdm colorama
"""

import os
import sys
import shutil
import signal
import subprocess
import multiprocessing as mp
import logging
import json
from pathlib import Path
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import List, Tuple
import argparse

try:
    from tqdm import tqdm
    from colorama import init, Fore, Style
    init(autoreset=True)
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install tqdm colorama")
    sys.exit(1)

__version__ = "2.8.0"


# =============================================================================
# CONFIGURATION
# =============================================================================

# Supported file extensions
PHOTO_EXTENSIONS = {
    '.jpg', '.jpeg', '.png', '.tiff', '.tif', '.heic', '.heif',
    '.dng', '.cr2', '.cr3', '.nef', '.arw', '.orf', '.rw2', '.raw',
    '.avif', '.webp', '.jxl',
    '.xmp'  # XMP sidecar files (can be scrubbed like photos)
}
VIDEO_EXTENSIONS = {
    '.mp4', '.mov', '.avi', '.mkv', '.m4v', '.mpg', '.mpeg',
    '.wmv', '.flv', '.webm', '.3gp', '.mts', '.m2ts', '.hevc', '.ts'
}

# ExifTool FileType values for categorization
VIDEO_FILETYPES = {'MOV', 'MP4', 'AVI', 'MKV', 'M4V', 'WEBM', 'MTS', 'M2TS', '3GP', 'MPG', 'MPEG', 'HEVC', 'TS', 'WMV', 'FLV'}
PHOTO_FILETYPES = {'JPEG', 'PNG', 'HEIC', 'HEIF', 'TIFF', 'WEBP', 'AVIF', 'JXL', 'GIF', 'BMP', 'CR2', 'CR3', 'NEF', 'ARW', 'ORF', 'DNG', 'RW2', 'RAF', 'SRW', 'RAW', 'XMP'}

# Video formats ExifTool cannot write to (metadata only via XMP sidecar)
UNSUPPORTED_VIDEO_FILETYPES = {'MPEG', 'AVI', 'M2TS', 'WMV', 'WEBM', 'FLV'}
UNSUPPORTED_VIDEO_EXTENSIONS = {'.mpeg', '.mpg', '.avi', '.m2ts', '.mts', '.wmv', '.webm', '.flv'}

# ExifTool FileType to correct extension mapping (for renaming)
FILETYPE_TO_EXT = {
    'JPEG': '.jpg', 'PNG': '.png', 'HEIC': '.heic', 'HEIF': '.heif',
    'TIFF': '.tiff', 'WEBP': '.webp', 'AVIF': '.avif', 'JXL': '.jxl',
    'GIF': '.gif', 'BMP': '.bmp', 'XMP': '.xmp',
    'CR2': '.cr2', 'CR3': '.cr3', 'NEF': '.nef', 'ARW': '.arw',
    'ORF': '.orf', 'DNG': '.dng', 'RW2': '.rw2', 'RAF': '.raf', 'SRW': '.srw', 'RAW': '.raw',
    'MOV': '.mov', 'MP4': '.mp4', 'AVI': '.avi', 'MKV': '.mkv', 'M4V': '.m4v',
    'WEBM': '.webm', 'MTS': '.mts', 'M2TS': '.m2ts', '3GP': '.3gp',
    'MPG': '.mpg', 'MPEG': '.mpeg', 'HEVC': '.hevc', 'TS': '.ts', 'WMV': '.wmv', 'FLV': '.flv',
}

# Folder exclusions (OOM Protection)
SKIP_DIRS = {
    '.git', 'node_modules', 'venv', '.venv', '__pycache__', '.idea', '.vscode',
    'AppData', 'Library', '.npm', '.cache', 'Cache', 'Caches', '.gradle',
    'target', 'build', 'dist', '.tox', '.mypy_cache', '.pytest_cache'
}

# Worker profiles
WORKER_PROFILES = {
    'conservative': {'workers': 2, 'desc': 'Low CPU usage (2 workers)'},
    'balanced': {'workers': max(4, mp.cpu_count() // 2), 'desc': f'Balanced ({max(4, mp.cpu_count() // 2)} workers)'},
    'fast': {'workers': max(1, mp.cpu_count() - 2), 'desc': f'Fast ({max(1, mp.cpu_count() - 2)} workers)'},
    'maximum': {'workers': mp.cpu_count(), 'desc': f'Maximum ({mp.cpu_count()} workers)'},
}

# Global flags
_shutdown_requested = False
_quiet_mode = False

# =============================================================================
# LOGGING & CONFIG SETUP
# =============================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
log_dir = SCRIPT_DIR / "logs"
log_dir.mkdir(exist_ok=True)
config_dir = SCRIPT_DIR / "configs"
config_dir.mkdir(exist_ok=True)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
log_file = log_dir / f"scrubber_{timestamp}.log"

class FlushingFileHandler(logging.FileHandler):
    """File handler that flushes after every write."""
    def emit(self, record):
        super().emit(record)
        self.flush()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-7s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        FlushingFileHandler(log_file, encoding="utf-8", mode='w'),
        logging.StreamHandler()
    ]
)
log = logging.getLogger()

def save_configuration(source: str, target: str, workers: int, dry_run: bool, keep_backups: bool) -> str:
    """Save run configuration to JSON file."""
    config = {
        "timestamp": datetime.now().isoformat(),
        "version": __version__,
        "source": source,
        "target": target,
        "in_place": target is None,
        "workers": workers,
        "dry_run": dry_run,
        "keep_backups": keep_backups,
        "cpu_cores": mp.cpu_count()
    }
    config_filename = f"scrubber_{timestamp}.json"
    config_path = config_dir / config_filename
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)
    return config_filename


# =============================================================================
# UTILITIES
# =============================================================================

def signal_handler(signum, frame):
    global _shutdown_requested
    if not _shutdown_requested:
        _shutdown_requested = True
        if not _quiet_mode:
            print(f"\n\n{Fore.YELLOW}Stopping... Finishing current batches (Ctrl+C again to force){Style.RESET_ALL}")
    else:
        sys.exit(1)

def print_phase(phase: str, message: str = ""):
    if _quiet_mode: return
    print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{Style.BRIGHT}  {phase}{Style.RESET_ALL}")
    if message: print(f"{Fore.WHITE}  {message}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")

def print_success(msg):
    if not _quiet_mode: print(f"{Fore.GREEN}  {msg}{Style.RESET_ALL}")

def print_error(msg):
    if not _quiet_mode: print(f"{Fore.RED}  {msg}{Style.RESET_ALL}")

def print_warning(msg):
    if not _quiet_mode: print(f"{Fore.YELLOW}  {msg}{Style.RESET_ALL}")

def print_info(msg):
    if not _quiet_mode: print(f"{Fore.BLUE}  {msg}{Style.RESET_ALL}")

def get_optimal_workers() -> int:
    """Auto-detect optimal worker count based on CPU cores."""
    cores = mp.cpu_count()
    if cores <= 4:
        return max(1, cores - 1)
    return max(2, cores - 2)


# =============================================================================
# CORE LOGIC
# =============================================================================

def find_media_files(directory: str, scrub_mode: str = 'both') -> Tuple[List[Path], List[Path]]:
    """Scan directory using os.walk with OOM protection.

    scrub_mode: 'embedded' (photos/videos only), 'xmp' (sidecars only), 'both' (all)

    Note: Supports both .xmp and .ext.xmp sidecar naming conventions.
    Python's Path.suffix returns '.xmp' for both 'photo.xmp' and 'photo.jpg.xmp'.
    """
    photo_files = []
    video_files = []

    mode_desc = {'embedded': 'embedded metadata', 'xmp': 'XMP sidecars', 'both': 'all files'}
    if not _quiet_mode:
        print_phase("PHASE 1: Scanning Directory", f"Searching: {directory} ({mode_desc.get(scrub_mode, 'all files')})")

    base_path = Path(directory)

    # Determine which extensions to look for based on mode
    if scrub_mode == 'xmp':
        target_photo_ext = {'.xmp'}
        target_video_ext = set()
    elif scrub_mode == 'embedded':
        target_photo_ext = PHOTO_EXTENSIONS - {'.xmp'}
        target_video_ext = VIDEO_EXTENSIONS
    else:  # 'both'
        target_photo_ext = PHOTO_EXTENSIONS
        target_video_ext = VIDEO_EXTENSIONS

    with tqdm(desc="  Scanning", unit=" files", disable=_quiet_mode,
              bar_format='{desc}: {n_fmt} found') as pbar:

        for root, dirs, files in os.walk(base_path):
            if _shutdown_requested: break

            # Prune junk directories in-place (OOM protection)
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.')]

            for file in files:
                fpath = Path(root) / file
                ext = fpath.suffix.lower()

                if ext in target_photo_ext:
                    photo_files.append(fpath)
                    pbar.update(1)
                elif ext in target_video_ext:
                    video_files.append(fpath)
                    pbar.update(1)

    if not _quiet_mode:
        if scrub_mode == 'xmp':
            print_success(f"Found {len(photo_files):,} XMP sidecar files")
        else:
            print_success(f"Found {len(photo_files):,} photos and {len(video_files):,} videos")

    return photo_files, video_files


def copy_files(files: List[Path], source: Path, target: Path):
    """Copy files to target directory preserving structure."""
    if not _quiet_mode:
        print_phase("PHASE 2: Copying Files", f"Target: {target}")

    with tqdm(total=len(files), desc="  Copying", unit=" file", disable=_quiet_mode) as pbar:
        for f in files:
            if _shutdown_requested: break

            rel_path = f.relative_to(source)
            dest = target / rel_path
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            pbar.update(1)


def parse_exiftool_count(output: str, pattern: str) -> int:
    """Parse count from ExifTool output like '5 image files updated'."""
    import re
    match = re.search(rf'(\d+)\s+{pattern}', output)
    return int(match.group(1)) if match else 0


def detect_file_types(files: List[Path]) -> dict:
    """
    Detect actual file types for a batch using ExifTool.
    Returns: {path: actual_filetype} mapping
    """
    if not files:
        return {}

    try:
        cmd = ['exiftool', '-FileType', '-j', '-q'] + [str(f) for f in files]
        result = subprocess.run(cmd, capture_output=True, text=True,
                               timeout=120, encoding='utf-8', errors='replace')
        if result.returncode == 0 and result.stdout:
            import json
            data = json.loads(result.stdout)
            return {Path(item.get('SourceFile', '')): item.get('FileType', '') for item in data}
    except Exception:
        pass
    return {}


def scrub_batch(files: List[Path], is_video: bool, dry_run: bool, keep_backups: bool, fix_extensions: bool = False) -> Tuple[int, int, int, int, int, List[str]]:
    """
    Process a batch of files with ExifTool.
    Detects actual file types to handle mismatched extensions correctly.
    Optionally renames files to correct extensions.
    Returns: (updated_count, unchanged_count, error_count, renamed_count, unsupported_count, error_msgs)
    """
    if not files:
        return 0, 0, 0, 0, 0, []

    if dry_run:
        return len(files), 0, 0, 0, 0, []

    try:
        # Detect actual file types to handle mismatched extensions
        type_map = detect_file_types(files)

        # Split into actual photos vs actual videos based on FileType
        actual_photos = []
        actual_videos = []
        unsupported_files = []  # Files ExifTool cannot write to
        files_to_rename = []  # (old_path, new_path, actual_type)

        for f in files:
            actual_type = type_map.get(f, '')
            current_ext = f.suffix.lower()
            correct_ext = FILETYPE_TO_EXT.get(actual_type, current_ext)

            # Check for unsupported formats first
            if actual_type in UNSUPPORTED_VIDEO_FILETYPES or current_ext in UNSUPPORTED_VIDEO_EXTENSIONS:
                unsupported_files.append(f)
                continue

            # Track files needing rename
            if fix_extensions and correct_ext != current_ext and actual_type:
                new_path = f.with_suffix(correct_ext)
                files_to_rename.append((f, new_path, actual_type))

            if actual_type in VIDEO_FILETYPES:
                actual_videos.append(f)
                # Log type correction to file only (prevents tqdm staircase)
                if not is_video:
                    msg = f"Type fix: {f.name} has photo ext but is {actual_type}, processing as video"
                    for h in log.handlers:
                        if isinstance(h, FlushingFileHandler):
                            record = logging.LogRecord('root', logging.INFO, '', 0, msg, (), None)
                            h.handle(record)
            elif actual_type in PHOTO_FILETYPES:
                actual_photos.append(f)
                # Log type correction to file only
                if is_video:
                    msg = f"Type fix: {f.name} has video ext but is {actual_type}, processing as photo"
                    for h in log.handlers:
                        if isinstance(h, FlushingFileHandler):
                            record = logging.LogRecord('root', logging.INFO, '', 0, msg, (), None)
                            h.handle(record)
            else:
                # Unknown type - use original categorization
                if is_video:
                    actual_videos.append(f)
                else:
                    actual_photos.append(f)

        total_updated = 0
        total_unchanged = 0
        total_errors = 0
        err_msgs = []

        # Process actual photos
        if actual_photos:
            cmd = ['exiftool', '-XMP:All=', '-IPTC:All=', '-Photoshop:All=']
            cmd.append('-overwrite_original_in_place' if keep_backups else '-overwrite_original')
            cmd.extend([str(f) for f in actual_photos])
            result = subprocess.run(cmd, capture_output=True, text=True,
                                   timeout=600, encoding='utf-8', errors='replace')
            total_updated += parse_exiftool_count(result.stdout, "image files updated")
            total_unchanged += parse_exiftool_count(result.stdout, "image files unchanged")

        # Process actual videos
        if actual_videos:
            cmd = ['exiftool', '-XMP:All=']
            cmd.append('-overwrite_original_in_place' if keep_backups else '-overwrite_original')
            cmd.extend([str(f) for f in actual_videos])
            result = subprocess.run(cmd, capture_output=True, text=True,
                                   timeout=600, encoding='utf-8', errors='replace')
            total_updated += parse_exiftool_count(result.stdout, "image files updated")
            total_unchanged += parse_exiftool_count(result.stdout, "image files unchanged")

        # Calculate errors (exclude unsupported files from error count)
        total_processed = total_updated + total_unchanged
        total_unsupported = len(unsupported_files)
        total_errors = max(0, len(files) - total_processed - total_unsupported)

        # Rename files with wrong extensions (after scrubbing completes)
        total_renamed = 0
        for old_path, new_path, actual_type in files_to_rename:
            try:
                if old_path.exists() and not new_path.exists():
                    old_path.rename(new_path)
                    total_renamed += 1
                    # Log to file only (prevents tqdm staircase)
                    msg = f"Renamed: {old_path.name} → {new_path.name} ({actual_type})"
                    for h in log.handlers:
                        if isinstance(h, FlushingFileHandler):
                            record = logging.LogRecord('root', logging.INFO, '', 0, msg, (), None)
                            h.handle(record)
            except Exception:
                pass

        return total_updated, total_unchanged, total_errors, total_renamed, total_unsupported, err_msgs

    except subprocess.TimeoutExpired:
        return 0, 0, len(files), 0, 0, ["Batch timeout (600s)"]
    except Exception as e:
        return 0, 0, len(files), 0, 0, [str(e)[:200]]


def run_scrubber(source: str, target: str, workers: int, dry_run: bool = False,
                 keep_backups: bool = True, batch_size: int = 50, fix_extensions: bool = False,
                 scrub_mode: str = 'both'):
    """Main scrubbing workflow."""
    src_path = Path(source)

    # Save configuration and log startup
    config_filename = save_configuration(source, target, workers, dry_run, keep_backups)
    log.info(f"Fix extensions: {fix_extensions}")
    log.info(f"Scrub mode: {scrub_mode}")
    log.info(f"Log file: logs/{log_file.name}")
    log.info(f"Config saved: configs/{config_filename}")
    log.info(f"Source: {source}")
    log.info(f"Target: {target or 'IN-PLACE'}")
    log.info(f"Workers: {workers}")

    # Phase 1: Scan
    photos, videos = find_media_files(source, scrub_mode)
    all_files = photos + videos

    if not all_files:
        print_error("No media files found.")
        return

    # Phase 2: Copy (if target specified)
    work_files = all_files
    phase_num = 2

    if target:
        tgt_path = Path(target)
        copy_files(all_files, src_path, tgt_path)
        # Re-map paths to target
        work_files = [tgt_path / f.relative_to(src_path) for f in all_files]
        phase_num = 3

    # Phase 3: Scrub
    mode_str = "DRY RUN" if dry_run else f"Workers: {workers}"
    print_phase(f"PHASE {phase_num}: Scrubbing Metadata", mode_str)

    # Build batches
    chunks = []

    # Photo batches
    photo_work = work_files[:len(photos)]
    for i in range(0, len(photo_work), batch_size):
        chunk = photo_work[i:i + batch_size]
        if chunk:
            chunks.append((chunk, False))  # False = photo

    # Video batches (smaller batch size for stability)
    video_work = work_files[len(photos):]
    video_batch_size = 10
    for i in range(0, len(video_work), video_batch_size):
        chunk = video_work[i:i + video_batch_size]
        if chunk:
            chunks.append((chunk, True))  # True = video

    stats = {'updated': 0, 'unchanged': 0, 'errors': 0, 'renamed': 0, 'unsupported': 0}
    all_errors = []

    with ProcessPoolExecutor(max_workers=workers) as pool:
        futures = {
            pool.submit(scrub_batch, c[0], c[1], dry_run, keep_backups, fix_extensions): c
            for c in chunks
        }

        with tqdm(total=len(work_files), desc="  Scrubbing", unit=" file", disable=_quiet_mode) as pbar:
            for fut in as_completed(futures):
                if _shutdown_requested:
                    pool.shutdown(wait=False, cancel_futures=True)
                    break

                up, un, err, ren, unsup, msgs = fut.result()
                stats['updated'] += up
                stats['unchanged'] += un
                stats['errors'] += err
                stats['renamed'] += ren
                stats['unsupported'] += unsup
                if msgs:
                    all_errors.extend(msgs)

                pbar.update(up + un + err + unsup)
                pbar.set_postfix(
                    scrubbed=stats['updated'],
                    clean=stats['unchanged'],
                    err=stats['errors']
                )

    # Summary
    print_phase("SUMMARY")
    print(f"  Total Files:  {len(work_files):,}")
    print(f"  {Fore.GREEN}Scrubbed:     {stats['updated']:,}{Style.RESET_ALL}")
    print(f"  {Fore.YELLOW}Unchanged:    {stats['unchanged']:,} (already clean){Style.RESET_ALL}")
    if stats['renamed'] > 0:
        print(f"  {Fore.CYAN}Renamed:      {stats['renamed']:,} (extension fixes){Style.RESET_ALL}")
    if stats['unsupported'] > 0:
        print(f"  {Fore.MAGENTA}Unsupported:  {stats['unsupported']:,} (unsupported format - use XMP sidecar){Style.RESET_ALL}")
        if scrub_mode == 'embedded':
            print(f"  {Fore.MAGENTA}  Note: To scrub these files, create XMP sidecars and use 'XMP sidecars' or 'Both' mode{Style.RESET_ALL}")

    if stats['errors'] > 0:
        print(f"  {Fore.RED}Errors:       {stats['errors']:,}{Style.RESET_ALL}")
        shown = min(3, len(all_errors))
        if shown > 0:
            print(f"    (showing {shown} of {stats['errors']:,} errors)")
            for e in all_errors[:3]:
                print(f"    - {e}")
    else:
        print(f"  {Fore.GREEN}Errors:       0{Style.RESET_ALL}")

    # Log final stats
    log.info(f"COMPLETE: {stats['updated']:,} scrubbed, {stats['unchanged']:,} unchanged, {stats['renamed']:,} renamed, {stats['unsupported']:,} unsupported, {stats['errors']:,} errors")

    if not dry_run and not _shutdown_requested:
        print()
        print_success("Mission Complete.")


def main_interactive():
    """Interactive wizard mode."""
    print(f"\n{Fore.MAGENTA}{Style.BRIGHT}Metadata Scrubber Pro v{__version__}{Style.RESET_ALL}")
    print(f"{Fore.WHITE}Removes edit history & PII. Keeps EXIF & Video GPS.{Style.RESET_ALL}")
    print(f"{Fore.WHITE}Detected {mp.cpu_count()} CPU cores{Style.RESET_ALL}\n")

    # 1. Source
    while True:
        src = input(f"{Fore.CYAN}Source Directory: {Style.RESET_ALL}").strip()
        if os.path.isdir(src):
            break
        print_error("Invalid directory.")

    # 2. Mode
    print(f"\n{Fore.YELLOW}Mode:{Style.RESET_ALL}")
    print("  1. Copy to new folder (Safer)")
    print("  2. Modify in-place (Destructive)")
    mode = input(f"{Fore.CYAN}Choose [1]: {Style.RESET_ALL}").strip() or "1"

    target = None
    if mode == "1":
        while True:
            target = input(f"{Fore.CYAN}Target Directory: {Style.RESET_ALL}").strip()
            if target:
                break

    # 3. Scrub target
    print(f"\n{Fore.YELLOW}What to Scrub:{Style.RESET_ALL}")
    print("  1. Embedded metadata only (photos/videos)")
    print("  2. XMP sidecar files only (.xmp)")
    print("  3. Both embedded and XMP sidecars")
    scrub_choice = input(f"{Fore.CYAN}Choose [3]: {Style.RESET_ALL}").strip() or "3"

    if scrub_choice == '1':
        scrub_mode = 'embedded'
    elif scrub_choice == '2':
        scrub_mode = 'xmp'
    else:
        scrub_mode = 'both'

    # 4. Performance
    print(f"\n{Fore.YELLOW}Performance Profile:{Style.RESET_ALL}")
    print(f"  1. Conservative - 2 workers (background tasks)")
    print(f"  2. Balanced     - {WORKER_PROFILES['balanced']['workers']} workers (recommended)")
    print(f"  3. Fast         - {WORKER_PROFILES['fast']['workers']} workers (leaves 2 cores free)")
    print(f"  4. Maximum      - {WORKER_PROFILES['maximum']['workers']} workers (all cores)")
    prof = input(f"{Fore.CYAN}Choose [3]: {Style.RESET_ALL}").strip() or "3"

    if prof == '1':
        workers = WORKER_PROFILES['conservative']['workers']
    elif prof == '2':
        workers = WORKER_PROFILES['balanced']['workers']
    elif prof == '4':
        workers = WORKER_PROFILES['maximum']['workers']
    else:
        workers = WORKER_PROFILES['fast']['workers']

    # 5. Fix extensions
    print(f"\n{Fore.YELLOW}Fix Extensions:{Style.RESET_ALL}")
    print("  Rename files with wrong extensions (e.g., HEIC files with .jpg → .heic)")
    fix_ext = input(f"{Fore.CYAN}Fix mismatched extensions? (y/N): {Style.RESET_ALL}").lower() == 'y'

    # 6. Dry run
    dry_run = input(f"\n{Fore.CYAN}Dry Run (simulation)? (y/N): {Style.RESET_ALL}").lower() == 'y'

    # Run
    print()
    run_scrubber(src, target, workers, dry_run=dry_run, keep_backups=True, fix_extensions=fix_ext, scrub_mode=scrub_mode)


def main():
    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(
        description="Metadata Scrubber Pro - Remove edit history while preserving EXIF"
    )
    parser.add_argument("source", nargs="?", help="Source directory")
    parser.add_argument("--target", help="Target directory (copy mode)")
    parser.add_argument("--in-place", action="store_true", help="Modify source files directly")
    parser.add_argument("--dry-run", action="store_true", help="Simulate only")
    parser.add_argument("--workers", type=int, help="Parallel workers")
    parser.add_argument("--quiet", action="store_true", help="Suppress output")
    parser.add_argument("--no-backups", action="store_true", help="Don't create .original files")
    parser.add_argument("--scrub-mode", choices=['embedded', 'xmp', 'both'], default='both',
                        help="What to scrub: embedded (photos/videos), xmp (sidecars), both (default)")

    args = parser.parse_args()

    global _quiet_mode
    _quiet_mode = args.quiet

    # Check ExifTool
    if shutil.which('exiftool') is None:
        print("ERROR: ExifTool not found in PATH.")
        sys.exit(1)

    # Mode selection
    if not args.source:
        try:
            main_interactive()
        except KeyboardInterrupt:
            print("\nCancelled.")
    else:
        # CLI mode
        workers = args.workers or get_optimal_workers()

        scrub_mode = args.scrub_mode.replace('-', '_')  # Handle 'xmp' vs potential 'xmp-sidecar'
        if args.target:
            run_scrubber(args.source, args.target, workers, args.dry_run, not args.no_backups, scrub_mode=scrub_mode)
        elif args.in_place:
            run_scrubber(args.source, None, workers, args.dry_run, not args.no_backups, scrub_mode=scrub_mode)
        else:
            # Default: create 'cleaned' subfolder
            tgt = str(Path(args.source) / "cleaned")
            run_scrubber(args.source, tgt, workers, args.dry_run, not args.no_backups, scrub_mode=scrub_mode)


if __name__ == "__main__":
    mp.freeze_support()
    main()
