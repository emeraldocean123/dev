#!/usr/bin/env python3
"""
Export Metadata to XMP Sidecars - Production Ready
===================================================
Safely exports all metadata from photos and videos to XMP sidecar files.
Interactive with progress bars, phase indicators, and graceful cancellation.
Supports both Adobe (filename.xmp) and Extension (filename.ext.xmp) naming.

Version: 3.0.0 (Unified with media_common library)
License: MIT
Author: emeraldocean123
Repository: https://github.com/emeraldocean123/xmp-sidecar-pro

Usage:
    python xmp-sidecar.py /path/to/photos
    python xmp-sidecar.py --directory "C:/Photos" --naming ext
    python xmp-sidecar.py --workers 12 --batch-size 100
    python xmp-sidecar.py --dry-run --skip-existing --quiet

Requirements:
    pip install tqdm colorama
"""

__version__ = "3.0.0"
__author__ = "emeraldocean123"
__license__ = "MIT"

import os
import sys
import shutil
import subprocess
import signal
import logging
import json
import multiprocessing as mp
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import List, Tuple
import argparse
from datetime import datetime
import re

# Import shared library
sys.path.append(str(Path(__file__).parent.parent))
from lib.media_common import (
    PHOTO_EXTENSIONS, VIDEO_EXTENSIONS, SKIP_DIRS,
    WORKER_PROFILES, get_optimal_workers,
    print_phase, print_success, print_error, print_warning, print_info
)

try:
    from tqdm import tqdm
except ImportError:
    print("ERROR: tqdm not installed. Run: pip install tqdm colorama")
    sys.exit(1)

try:
    from colorama import init, Fore, Style
    init(autoreset=True)
except ImportError:
    class Fore:
        GREEN = RED = YELLOW = CYAN = MAGENTA = BLUE = WHITE = ''
    class Style:
        BRIGHT = RESET_ALL = ''

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
log_file = log_dir / f"sidecar_{timestamp}.log"

class FlushingFileHandler(logging.FileHandler):
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

def save_configuration(directory: str, workers: int, batch_size: int, skip_existing: bool, dry_run: bool, naming: str) -> str:
    """Save run configuration to JSON file."""
    config = {
        "timestamp": datetime.now().isoformat(),
        "version": __version__,
        "directory": directory,
        "workers": workers,
        "batch_size": batch_size,
        "skip_existing": skip_existing,
        "dry_run": dry_run,
        "naming_convention": naming,
        "cpu_cores": mp.cpu_count()
    }
    config_filename = f"sidecar_{timestamp}.json"
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

# =============================================================================
# CORE LOGIC
# =============================================================================

def find_media_files(directory: str, verbose: bool = True) -> Tuple[List[Path], List[Path]]:
    """Recursively find all photo and video files in directory."""
    photo_files = []
    video_files = []

    if verbose:
        print_phase("PHASE 1: Scanning Directory", f"Searching: {directory}")

    with tqdm(desc="  Scanning", unit=" files", disable=_quiet_mode,
              bar_format='{desc}: {n_fmt} found') as pbar:

        for root, dirs, files in os.walk(directory):
            if _shutdown_requested: break

            # OOM Protection: Prune junk directories in-place
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.')]

            for file in files:
                file_path = Path(root) / file
                ext = file_path.suffix.lower()

                if ext in PHOTO_EXTENSIONS:
                    photo_files.append(file_path)
                    pbar.update(1)
                elif ext in VIDEO_EXTENSIONS:
                    video_files.append(file_path)
                    pbar.update(1)

    if verbose:
        print_success(f"Found {len(photo_files):,} photos and {len(video_files):,} videos")

    return photo_files, video_files

def export_metadata_batch(files: List[Path], skip_existing: bool = False,
                          dry_run: bool = False, naming: str = 'adobe') -> Tuple[int, int, int, int, List[str]]:
    """
    Export metadata for a batch of files.
    naming: 'adobe' (file.xmp) or 'ext' (file.ext.xmp)
    Returns: (success, skipped, no_data, errors, error_messages)
    """
    if not files or _shutdown_requested:
        return 0, 0, 0, 0, []

    skipped_count = 0
    files_to_process = []

    for file in files:
        # Determine sidecar path based on naming convention
        if naming == 'ext':
            # file.ext.xmp (e.g. image.jpg.xmp)
            sidecar = file.parent / f"{file.name}.xmp"
        else:
            # file.xmp (e.g. image.xmp) - Adobe standard
            sidecar = file.with_suffix('.xmp')

        if sidecar.exists():
            if skip_existing:
                skipped_count += 1
                continue
            else:
                # Delete existing sidecar so ExifTool can create fresh one
                try:
                    sidecar.unlink()
                except Exception:
                    pass  # If delete fails, ExifTool will report the error
        files_to_process.append(file)

    if not files_to_process:
        return 0, skipped_count, 0, 0, []

    if dry_run:
        return len(files_to_process), skipped_count, 0, 0, []

    try:
        # Build ExifTool command based on naming convention
        # -o %d%f.xmp    -> filename.xmp
        # -o %d%f.%e.xmp -> filename.ext.xmp

        out_fmt = '%d%f.xmp' if naming == 'adobe' else '%d%f.%e.xmp'
        cmd = ['exiftool', '-o', out_fmt, '-tagsFromFile', '@']

        # Copy all existing XMP/IPTC data
        cmd.append('-all:all')

        # Explicitly map EXIF to XMP (for photos with only EXIF data)
        exif_to_xmp_mappings = [
            '-XMP:DateTimeOriginal<EXIF:DateTimeOriginal',
            '-XMP:CreateDate<EXIF:CreateDate',
            '-XMP:ModifyDate<EXIF:ModifyDate',
            '-XMP:Make<EXIF:Make',
            '-XMP:Model<EXIF:Model',
            '-XMP:LensModel<EXIF:LensModel',
            '-XMP:LensMake<EXIF:LensMake',
            '-XMP:FocalLength<EXIF:FocalLength',
            '-XMP:FNumber<EXIF:FNumber',
            '-XMP:ExposureTime<EXIF:ExposureTime',
            '-XMP:ISO<EXIF:ISO',
            '-XMP:ExposureProgram<EXIF:ExposureProgram',
            '-XMP:MeteringMode<EXIF:MeteringMode',
            '-XMP:Flash<EXIF:Flash',
            '-XMP:WhiteBalance<EXIF:WhiteBalance',
            '-XMP:Orientation<EXIF:Orientation',
            '-XMP:ImageWidth<EXIF:ImageWidth',
            '-XMP:ImageHeight<EXIF:ImageHeight',
            '-XMP:GPSLatitude<EXIF:GPSLatitude',
            '-XMP:GPSLongitude<EXIF:GPSLongitude',
            '-XMP:GPSAltitude<EXIF:GPSAltitude',
        ]
        cmd.extend(exif_to_xmp_mappings)

        # Explicitly map QuickTime to XMP (for videos)
        # Note: Duration excluded - XMP:xmpDM:Duration requires complex structure
        quicktime_to_xmp_mappings = [
            '-XMP:CreateDate<QuickTime:CreateDate',
            '-XMP:ModifyDate<QuickTime:ModifyDate',
            '-XMP:DateTimeOriginal<QuickTime:CreateDate',
            '-XMP:Make<QuickTime:Make',
            '-XMP:Model<QuickTime:Model',
            '-XMP:GPSLatitude<QuickTime:GPSLatitude',
            '-XMP:GPSLongitude<QuickTime:GPSLongitude',
            '-XMP:GPSAltitude<QuickTime:GPSAltitude',
            '-XMP:VideoFrameRate<QuickTime:VideoFrameRate',
            '-XMP:ImageWidth<QuickTime:ImageWidth',
            '-XMP:ImageHeight<QuickTime:ImageHeight',
            '-XMP:Rotation<QuickTime:Rotation',
            '-XMP:CompressorName<QuickTime:CompressorName',
        ]
        cmd.extend(quicktime_to_xmp_mappings)

        for file in files_to_process:
            cmd.append(str(file))

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

        # Parse success count (ExifTool says "X image files created")
        success_match = re.search(r'(\d+) image files? created', result.stdout)
        success_count = int(success_match.group(1)) if success_match else 0

        # Count "Nothing to write" as no_data, not errors
        no_data_count = result.stderr.count('Nothing to write') if result.stderr else 0

        # Warnings don't prevent sidecar creation - don't count as errors
        warning_count = result.stderr.count('Warning:') if result.stderr else 0

        # Real errors = total - success - no_data (warnings are info, not errors)
        error_count = max(0, len(files_to_process) - success_count - no_data_count)

        error_messages = []
        if result.stderr:
            # Filter out "Nothing to write" and show first few warnings/errors
            lines = [l for l in result.stderr.strip().split('\n')
                     if 'Nothing to write' not in l and l.strip()]
            if lines:
                error_messages.append(lines[0][:200])

        return success_count, skipped_count, no_data_count, error_count, error_messages

    except subprocess.TimeoutExpired:
        return 0, skipped_count, 0, len(files_to_process), ["Batch timeout"]
    except Exception as e:
        return 0, skipped_count, 0, len(files_to_process), [str(e)]

def chunk_list(items: List, chunk_size: int) -> List[List]:
    return [items[i:i + chunk_size] for i in range(0, len(items), chunk_size)]

def export_metadata(directory: str, workers: int, batch_size: int,
                    skip_existing: bool = False, dry_run: bool = False,
                    naming: str = 'adobe', verbose: bool = True):
    """Main export function."""

    config_filename = save_configuration(directory, workers, batch_size, skip_existing, dry_run, naming)
    log.info(f"Config saved: configs/{config_filename}")
    log.info(f"Log file: logs/{log_file.name}")
    log.info(f"Naming: {naming} ({'filename.xmp' if naming == 'adobe' else 'filename.ext.xmp'})")
    log.info(f"Directory: {directory}")
    log.info(f"Workers: {workers}")

    # Phase 1: Scan
    photo_files, video_files = find_media_files(directory, verbose)
    all_files = photo_files + video_files

    if not all_files:
        print_error("No media files found!")
        return False

    # Phase 2: Export
    mode_str = "DRY RUN" if dry_run else f"Workers: {workers}"
    if not _quiet_mode:
        print_phase("PHASE 2: Exporting Metadata", mode_str)

    photo_batches = chunk_list(photo_files, batch_size)
    video_batches = chunk_list(video_files, min(10, batch_size))
    all_batches = photo_batches + video_batches

    if verbose:
        print_info(f"Batching: {len(photo_batches)} photo batches, {len(video_batches)} video batches")
        if skip_existing: print_info("Skip existing: ON")
        print()

    total_success = 0
    total_skipped = 0
    total_no_data = 0
    total_errors = 0
    all_errors = []

    with ProcessPoolExecutor(max_workers=workers) as executor:
        future_to_batch = {
            executor.submit(export_metadata_batch, batch, skip_existing, dry_run, naming): i
            for i, batch in enumerate(all_batches, 1)
        }

        with tqdm(total=len(all_files), desc="  Exporting", unit=" file", disable=_quiet_mode) as pbar:
            for future in as_completed(future_to_batch):
                if _shutdown_requested:
                    executor.shutdown(wait=False, cancel_futures=True)
                    break

                try:
                    suc, skip, no_data, err, msgs = future.result()
                    total_success += suc
                    total_skipped += skip
                    total_no_data += no_data
                    total_errors += err
                    if msgs: all_errors.extend(msgs)

                    pbar.update(suc + skip + no_data + err)
                    pbar.set_postfix(ok=total_success, skip=total_skipped, empty=total_no_data, err=total_errors)

                except Exception as e:
                    batch_idx = future_to_batch[future]
                    all_errors.append(f"Batch {batch_idx} failed: {e}")

    # Phase 3: Summary
    log.info(f"COMPLETE: {total_success:,} exported, {total_skipped:,} skipped, {total_no_data:,} no data, {total_errors:,} errors")

    if _quiet_mode:
        if _shutdown_requested: return False
        print(f"COMPLETE: {total_success}/{len(all_files)} exported, {total_skipped} skipped, {total_no_data} no data, {total_errors} errors")
        return total_errors == 0

    print_phase("SUMMARY")
    print(f"  Total Files:  {len(all_files):,}")
    print(f"  {Fore.GREEN}Exported:     {total_success:,}{Style.RESET_ALL}")
    print(f"  {Fore.YELLOW}Skipped:      {total_skipped:,} (existing){Style.RESET_ALL}")
    if total_no_data > 0:
        print(f"  {Fore.MAGENTA}No Data:      {total_no_data:,} (no metadata to export){Style.RESET_ALL}")

    if total_errors > 0:
        print(f"  {Fore.RED}Errors:       {total_errors:,}{Style.RESET_ALL}")
        for e in all_errors[:3]:
            print(f"    - {e}")
    else:
        print(f"  {Fore.GREEN}Errors:       0{Style.RESET_ALL}")

    if not dry_run and not _shutdown_requested:
        print()
        print_success("Mission Complete.")
    return True

def get_user_input(prompt: str, default: str = None) -> str:
    if default: prompt = f"{prompt} [{default}]: "
    else: prompt = f"{prompt}: "
    response = input(f"{Fore.CYAN}{prompt}{Style.RESET_ALL}").strip()
    return response if response else default

def interactive_mode():
    print(f"\n{Fore.MAGENTA}{Style.BRIGHT}XMP Sidecar Pro v{__version__}{Style.RESET_ALL}")
    print(f"{Fore.WHITE}Detected {mp.cpu_count()} CPU cores{Style.RESET_ALL}\n")

    # 1. Directory
    while True:
        directory = get_user_input("Source Directory")
        if directory and os.path.isdir(directory): break
        print_error("Invalid directory.")

    # 2. Naming
    print(f"\n{Fore.YELLOW}Naming Convention:{Style.RESET_ALL}")
    print("  1. Adobe Standard (image.xmp) - Best Compatibility")
    print("  2. Extension Preserved (image.jpg.xmp) - Safer for collisions")
    naming_in = get_user_input("Choose", "1")
    naming = 'ext' if naming_in == '2' else 'adobe'

    # 3. Performance
    print(f"\n{Fore.YELLOW}Performance Profile:{Style.RESET_ALL}")
    print(f"  1. Conservative - 2 workers")
    print(f"  2. Balanced     - {WORKER_PROFILES['balanced']['workers']} workers")
    print(f"  3. Fast         - {WORKER_PROFILES['fast']['workers']} workers")
    print(f"  4. Maximum      - {WORKER_PROFILES['maximum']['workers']} workers")
    prof = get_user_input("Choose", "3")

    if prof == '1': workers = WORKER_PROFILES['conservative']['workers']
    elif prof == '2': workers = WORKER_PROFILES['balanced']['workers']
    elif prof == '4': workers = WORKER_PROFILES['maximum']['workers']
    else: workers = WORKER_PROFILES['fast']['workers']

    # 4. Options
    skip = get_user_input("\nSkip existing sidecars? Y=keep, N=overwrite (Y/n)", "y").lower() == 'y'
    dry = get_user_input("Dry run? (y/N)", "n").lower() == 'y'

    print()
    export_metadata(directory, workers, 50, skip, dry, naming)

def main():
    signal.signal(signal.SIGINT, signal_handler)

    # Convenience: if single argument is a directory, use it directly
    if len(sys.argv) == 2 and os.path.isdir(sys.argv[1]):
        directory = sys.argv[1]
        workers = get_optimal_workers()

        global _quiet_mode
        _quiet_mode = False

        if shutil.which('exiftool') is None:
            print("ERROR: ExifTool not found.")
            sys.exit(1)

        export_metadata(directory, workers, 50, skip_existing=True, dry_run=False, naming='adobe')
        return

    parser = argparse.ArgumentParser(description='XMP Sidecar Pro - Export metadata to XMP sidecars')
    parser.add_argument('directory', nargs='?', help='Source directory')
    parser.add_argument('--workers', '-w', type=int, help='Worker threads')
    parser.add_argument('--batch-size', '-b', type=int, default=50, help='Batch size')
    parser.add_argument('--skip-existing', '-s', action='store_true', help='Skip existing XMPs')
    parser.add_argument('--dry-run', action='store_true', help='Simulate')
    parser.add_argument('--quiet', '-q', action='store_true', help='Minimal output')
    parser.add_argument('--naming', choices=['adobe', 'ext'], default='adobe',
                        help='Naming: adobe (file.xmp) or ext (file.ext.xmp)')

    args = parser.parse_args()

    _quiet_mode = args.quiet

    if shutil.which('exiftool') is None:
        print("ERROR: ExifTool not found.")
        sys.exit(1)

    if not args.directory:
        try:
            interactive_mode()
        except KeyboardInterrupt:
            print("\nCancelled.")
    else:
        workers = args.workers or get_optimal_workers()
        export_metadata(args.directory, workers, args.batch_size,
                       args.skip_existing, args.dry_run, args.naming)

if __name__ == '__main__':
    mp.freeze_support()
    main()
