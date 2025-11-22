#!/usr/bin/env python3
"""
Metadata Scrubber Pro
=====================
Version: 3.0.0

Description:
    Removes 3rd-party metadata (Lightroom edits, PII) while preserving
    camera EXIF, timestamps, and Video GPS.

    Photos: Removes XMP, IPTC, Photoshop. Keeps EXIF.
    Videos: Removes XMP. Keeps QuickTime (GPS/Date).

Usage:
    python metadata-scrubber.py "C:/Photos"
    python metadata-scrubber.py --help

Changelog:
    v3.0.0 - Code unification: Refactored to use media_common.py shared library (~135 lines removed)
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
import re
from pathlib import Path
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import List, Tuple
import argparse

# Import shared library
try:
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from lib.media_common import (
        PHOTO_EXTENSIONS, VIDEO_EXTENSIONS, FILETYPE_TO_EXT, SKIP_DIRS,
        WORKER_PROFILES, get_optimal_workers, setup_logging,
        print_phase, print_success, print_error, print_warning, print_info,
        check_exiftool
    )
    try:
        from tqdm import tqdm
    except ImportError:
        print("ERROR: Missing tqdm. Run: pip install tqdm")
        sys.exit(1)
except ImportError as e:
    print(f"ERROR: Could not import dependencies: {e}")
    print(f"Make sure media_common.py is in: {Path(__file__).parent.parent / 'lib'}")
    sys.exit(1)

__version__ = "3.0.0"


# =============================================================================
# CONFIGURATION
# =============================================================================

# ExifTool FileType values for categorization
VIDEO_FILETYPES = {'MOV', 'MP4', 'AVI', 'MKV', 'M4V', 'WEBM', 'MTS', 'M2TS', '3GP', 'MPG', 'MPEG', 'HEVC', 'TS', 'WMV', 'FLV'}
PHOTO_FILETYPES = {'JPEG', 'PNG', 'HEIC', 'HEIF', 'TIFF', 'WEBP', 'AVIF', 'JXL', 'GIF', 'BMP', 'CR2', 'CR3', 'NEF', 'ARW', 'ORF', 'DNG', 'RW2', 'RAF', 'SRW', 'RAW', 'XMP'}

# Video formats ExifTool cannot write to (metadata only via XMP sidecar)
UNSUPPORTED_VIDEO_FILETYPES = {'MPEG', 'AVI', 'M2TS', 'WMV', 'WEBM', 'FLV'}
UNSUPPORTED_VIDEO_EXTENSIONS = {'.mpeg', '.mpg', '.avi', '.m2ts', '.mts', '.wmv', '.webm', '.flv'}

# Global flags
_shutdown_requested = False
_quiet_mode = False

# =============================================================================
# LOGGING & CONFIG SETUP
# =============================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
config_dir = SCRIPT_DIR / "configs"
config_dir.mkdir(exist_ok=True)

# Use media_common setup_logging
log_file = setup_logging("scrubber", SCRIPT_DIR / "logs")
log = logging.getLogger()

def save_configuration(source: str, target: str, workers: int, dry_run: bool, keep_backups: bool, scrub_mode: str, fix_extensions: bool) -> str:
    """Save run configuration to JSON file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    config = {
        "timestamp": datetime.now().isoformat(),
        "version": __version__,
        "source": source,
        "target": target,
        "in_place": target is None,
        "workers": workers,
        "dry_run": dry_run,
        "keep_backups": keep_backups,
        "scrub_mode": scrub_mode,
        "fix_extensions": fix_extensions,
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
            print_warning("\nStopping... Finishing current batches (Ctrl+C again to force)")
    else:
        sys.exit(1)


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
        # Add .xmp to photo extensions for unified handling
        target_photo_ext = PHOTO_EXTENSIONS | {'.xmp'}
        target_video_ext = VIDEO_EXTENSIONS

    with tqdm(desc="  Scanning", unit=" files", disable=_quiet_mode,
              bar_format='{desc}: {n_fmt} found') as pbar:

        for root, dirs, files in os.walk(base_path):
            if _shutdown_requested:
                break

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
            if _shutdown_requested:
                break

            rel_path = f.relative_to(source)
            dest = target / rel_path
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            pbar.update(1)


def parse_exiftool_count(output: str, pattern: str) -> int:
    """Parse count from ExifTool output like '5 image files updated'."""
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
                    logging.info(f"Type fix: {f.name} has photo ext but is {actual_type}, processing as video")
            elif actual_type in PHOTO_FILETYPES:
                actual_photos.append(f)
                # Log type correction to file only
                if is_video:
                    logging.info(f"Type fix: {f.name} has video ext but is {actual_type}, processing as photo")
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
                    logging.info(f"Renamed: {old_path.name} → {new_path.name} ({actual_type})")
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
    config_filename = save_configuration(source, target, workers, dry_run, keep_backups, scrub_mode, fix_extensions)
    log.info(f"Fix extensions: {fix_extensions}")
    log.info(f"Scrub mode: {scrub_mode}")
    log.info(f"Log file: {log_file}")
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
    print_success(f"Scrubbed:     {stats['updated']:,}")
    print_warning(f"Unchanged:    {stats['unchanged']:,} (already clean)")
    if stats['renamed'] > 0:
        print_info(f"Renamed:      {stats['renamed']:,} (extension fixes)")
    if stats['unsupported'] > 0:
        print_warning(f"Unsupported:  {stats['unsupported']:,} (unsupported format - use XMP sidecar)")
        if scrub_mode == 'embedded':
            print_info("  Note: To scrub these files, create XMP sidecars and use 'XMP sidecars' or 'Both' mode")

    if stats['errors'] > 0:
        print_error(f"Errors:       {stats['errors']:,}")
        shown = min(3, len(all_errors))
        if shown > 0:
            print(f"    (showing {shown} of {stats['errors']:,} errors)")
            for e in all_errors[:3]:
                print(f"    - {e}")
    else:
        print_success("Errors:       0")

    # Log final stats
    log.info(f"COMPLETE: {stats['updated']:,} scrubbed, {stats['unchanged']:,} unchanged, {stats['renamed']:,} renamed, {stats['unsupported']:,} unsupported, {stats['errors']:,} errors")

    if not dry_run and not _shutdown_requested:
        print()
        print_success("Mission Complete.")


def main_interactive():
    """Interactive wizard mode."""
    try:
        from colorama import Fore, Style
    except ImportError:
        class Fore:
            MAGENTA = CYAN = YELLOW = WHITE = ''
        class Style:
            BRIGHT = RESET_ALL = ''

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
    parser.add_argument("--fix-extensions", action="store_true", help="Rename files with wrong extensions")
    parser.add_argument("--scrub-mode", choices=['embedded', 'xmp', 'both'], default='both',
                        help="What to scrub: embedded (photos/videos), xmp (sidecars), both (default)")

    args = parser.parse_args()

    global _quiet_mode
    _quiet_mode = args.quiet

    # Check ExifTool
    if not check_exiftool():
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
            run_scrubber(args.source, args.target, workers, args.dry_run, not args.no_backups,
                        fix_extensions=args.fix_extensions, scrub_mode=scrub_mode)
        elif args.in_place:
            run_scrubber(args.source, None, workers, args.dry_run, not args.no_backups,
                        fix_extensions=args.fix_extensions, scrub_mode=scrub_mode)
        else:
            # Default: create 'cleaned' subfolder
            tgt = str(Path(args.source) / "cleaned")
            run_scrubber(args.source, tgt, workers, args.dry_run, not args.no_backups,
                        fix_extensions=args.fix_extensions, scrub_mode=scrub_mode)


if __name__ == "__main__":
    mp.freeze_support()
    main()
