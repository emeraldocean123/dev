#!/usr/bin/env python3
"""
Media Manager - Unified Media Processing Engine
===============================================
Version: 1.0.0

Description:
    The central engine for the Homelab Media Suite.
    Performs Renaming, Organizing, and Deduplication in a single efficient pass.
    Designed to be called by PowerShell/Bash scripts or the Homelab Menu.

Dependencies:
    media_common.py (Shared Library)

Usage:
    # Rename only (in-place)
    python media-manager.py /source --mode rename --dry-run

    # Organize by Date (Copy)
    python media-manager.py /source /dest --mode organize --structure simple

    # Full Processing (Move + Dedupe + Rename + Organize)
    python media-manager.py /source /dest --mode all --action move --execute
"""

import sys
import os
import argparse
import shutil
import hashlib
import logging
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import List, Dict, Optional, Set
from concurrent.futures import ThreadPoolExecutor, as_completed

# Import shared library
try:
    # Adjust path to find lib if running from different directories
    sys.path.insert(0, str(Path(__file__).parent))
    from lib.media_common import (
        get_metadata, safe_filename, sanitize_camera_str,
        print_phase, print_success, print_warning, print_error,
        setup_logging, get_optimal_workers,
        ALL_MEDIA_EXTENSIONS, VIDEO_EXTENSIONS, RAW_EXTENSIONS,
        FILETYPE_TO_EXT, SKIP_DIRS
    )
    try:
        from tqdm import tqdm
    except ImportError:
        print_warning("tqdm not installed - progress bars disabled")
        def tqdm(iterable, **kwargs):
            return iterable
except ImportError as e:
    print(f"CRITICAL ERROR: Could not import dependencies: {e}")
    print(f"Make sure media_common.py is in: {Path(__file__).parent / 'lib'}")
    sys.exit(1)

__version__ = "1.0.0"

# =============================================================================
# DATA CLASSES
# =============================================================================

class MediaFile:
    """Represents a single media file with metadata and hash."""
    def __init__(self, path: Path):
        self.path = path
        self.hash: str = ""
        self.size: int = path.stat().st_size
        self.dt: datetime = datetime.fromtimestamp(path.stat().st_mtime)
        self.make: str = ""
        self.model: str = ""
        self.is_video: bool = path.suffix.lower() in VIDEO_EXTENSIONS
        self.is_raw: bool = path.suffix.lower() in RAW_EXTENSIONS
        self.keywords: Set[str] = set()
        self.rating: int = 0
        self.width: int = 0
        self.height: int = 0
        self.correct_ext: str = path.suffix.lower()
        self.xmp_path: Optional[Path] = None
        self.paired_path: Optional[Path] = None  # For RAW+JPG

    def process(self):
        """Calculates hash and extracts metadata."""
        # 1. Calculate Hash (4MB chunks)
        h = hashlib.sha256()
        with open(self.path, "rb") as f:
            while chunk := f.read(4 * 1024 * 1024):
                h.update(chunk)
        self.hash = h.hexdigest()

        # 2. Extract Metadata
        meta = get_metadata(self.path, self.is_video)

        # Date Logic (prioritize EXIF over filesystem)
        date_tags = [
            'EXIF:DateTimeOriginal',
            'XMP:DateTimeOriginal',
            'QuickTime:CreationDate',
            'EXIF:CreateDate',
            'CreateDate'
        ]
        for tag in date_tags:
            if val := meta.get(tag):
                try:
                    # Clean timezone/UTC markers
                    clean_val = str(val).split('+')[0].replace('Z', '').strip()
                    self.dt = datetime.strptime(clean_val, "%Y:%m:%d %H:%M:%S")
                    break
                except (ValueError, TypeError):
                    continue

        # Camera Data
        self.make = sanitize_camera_str(meta.get('EXIF:Make', '') or meta.get('Make', ''))
        self.model = sanitize_camera_str(meta.get('EXIF:Model', '') or meta.get('Model', ''))

        # Keywords
        if keywords := meta.get('XMP:Subject') or meta.get('IPTC:Keywords'):
            if isinstance(keywords, list):
                self.keywords = set(keywords)
            elif isinstance(keywords, str):
                self.keywords = {keywords}

        # Rating
        if rating := meta.get('XMP:Rating'):
            try:
                self.rating = int(rating)
            except (ValueError, TypeError):
                pass

        # Dimensions
        try:
            self.width = int(meta.get('EXIF:ImageWidth', 0) or meta.get('ImageWidth', 0))
            self.height = int(meta.get('EXIF:ImageHeight', 0) or meta.get('ImageHeight', 0))
        except (ValueError, TypeError):
            pass

        # Extension Correction (use FileType for accurate extension)
        if ftype := meta.get('File:FileType'):
            self.correct_ext = FILETYPE_TO_EXT.get(ftype, self.path.suffix.lower())

        # Check for XMP Sidecar (both .xmp and .ext.xmp formats)
        xmp_cand = self.path.with_suffix('.xmp')
        if not xmp_cand.exists():
            xmp_cand = Path(str(self.path) + ".xmp")
        if xmp_cand.exists():
            self.xmp_path = xmp_cand

    def get_score(self) -> float:
        """Score for deduplication winner selection (higher is better)."""
        score = float(self.size)
        score += (self.width * self.height) * 5  # Prioritize higher resolution
        score += self.rating * 1000  # Rating has high weight
        if self.is_raw:
            score *= 3.0  # Prefer RAW as source of truth
        if self.keywords:
            score += len(self.keywords) * 100  # Bonus for keyword richness
        return score

# =============================================================================
# ENGINE
# =============================================================================

class MediaEngine:
    """Main processing engine for media files."""

    def __init__(self, args):
        self.args = args
        self.log_file = setup_logging("media_manager", Path(__file__).parent / "logs")
        self.files: List[MediaFile] = []
        self.used_destinations: Set[Path] = set()

        print_success(f"Log file: {self.log_file}")

    def scan(self):
        """Phase 1: Scan source directories for media files."""
        print_phase("Phase 1: Scanning Sources")
        logging.info("=== Phase 1: Scanning Sources ===")

        paths = []
        for src in self.args.sources:
            src_path = Path(src).resolve()
            if not src_path.exists():
                print_warning(f"Source not found: {src}")
                logging.warning(f"Source not found: {src}")
                continue

            logging.info(f"Scanning: {src_path}")
            for root, dirs, filenames in os.walk(src_path):
                # Skip junk folders
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

                for name in filenames:
                    p = Path(root) / name
                    if p.suffix.lower() in ALL_MEDIA_EXTENSIONS:
                        paths.append(p)

        print_success(f"Found {len(paths):,} media files.")
        logging.info(f"Found {len(paths):,} media files")

        if not paths:
            print_error("No media files found!")
            sys.exit(1)

    def process(self):
        """Phase 2: Process metadata and compute hashes."""
        print_phase("Phase 2: Processing Metadata & Hashing")
        logging.info("=== Phase 2: Processing Metadata ===")

        # Collect all paths first from scan
        paths = []
        for src in self.args.sources:
            src_path = Path(src).resolve()
            if not src_path.exists():
                continue
            for root, dirs, filenames in os.walk(src_path):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                for name in filenames:
                    p = Path(root) / name
                    if p.suffix.lower() in ALL_MEDIA_EXTENSIONS:
                        paths.append(p)

        workers = get_optimal_workers()
        logging.info(f"Using {workers} workers")

        with ThreadPoolExecutor(max_workers=workers) as ex:
            futures = {ex.submit(self._process_file_wrapper, p): p for p in paths}
            for fut in tqdm(as_completed(futures), total=len(paths), desc="Processing"):
                if res := fut.result():
                    self.files.append(res)

        print_success(f"Processed {len(self.files):,} files successfully")
        logging.info(f"Processed {len(self.files):,} files")

    @staticmethod
    def _process_file_wrapper(path: Path) -> Optional[MediaFile]:
        """Wrapper for parallel processing with error handling."""
        try:
            mf = MediaFile(path)
            mf.process()
            return mf
        except Exception as e:
            logging.error(f"Failed to process {path}: {e}")
            return None

    def execute(self):
        """Main execution logic."""
        # Phase 1 & 2: Scan and Process
        self.process()

        # Phase 3: Group by Hash (Deduplication context)
        print_phase("Phase 3: Grouping Duplicates")
        hash_groups = defaultdict(list)
        for f in self.files:
            hash_groups[f.hash].append(f)

        unique_hashes = len(hash_groups)
        total_files = len(self.files)
        duplicates = total_files - unique_hashes

        print_success(f"Unique files: {unique_hashes:,}")
        if duplicates > 0:
            print_warning(f"Duplicates found: {duplicates:,}")
        logging.info(f"Unique: {unique_hashes}, Duplicates: {duplicates}")

        # Phase 4: Execute Actions
        print_phase(f"Phase 4: Executing Actions ({self.args.mode.upper()})")
        logging.info(f"=== Phase 4: {self.args.mode.upper()} Mode ===")

        if self.args.dry_run:
            print_warning("DRY-RUN MODE: No files will be modified")
            logging.info("DRY-RUN MODE ENABLED")

        # Sort groups by date for deterministic processing
        sorted_groups = sorted(hash_groups.values(), key=lambda g: g[0].dt)

        actions_count = 0
        for group in tqdm(sorted_groups, desc="Organizing"):
            # 1. Select Winner (Best file from duplicate group)
            winner = max(group, key=lambda x: x.get_score())
            losers = [f for f in group if f != winner]

            # 2. Handle Winner
            if self._handle_file(winner, is_duplicate=False):
                actions_count += 1

            # 3. Handle Duplicates
            if self.args.mode in ['deduplicate', 'all']:
                for dup in losers:
                    if self._handle_file(dup, is_duplicate=True, winner=winner):
                        actions_count += 1
            elif self.args.mode in ['organize']:
                # In organize mode, treat all files equally
                for dup in losers:
                    if self._handle_file(dup, is_duplicate=False):
                        actions_count += 1

        # Summary
        print_phase("Summary")
        print_success(f"Files processed: {actions_count:,}")
        if self.args.dry_run:
            print_warning("This was a DRY-RUN. Use --execute to apply changes.")
        else:
            print_success("Operation completed successfully!")

        logging.info(f"Total actions: {actions_count}")

    def _handle_file(self, file: MediaFile, is_duplicate: bool, winner: Optional[MediaFile] = None) -> bool:
        """Determines destination and performs copy/move/rename."""

        # A. Determine Filename
        if self.args.rename or self.args.mode in ['rename', 'all']:
            # Format: YYYY-MM-DD-HHmmss-Make-Model-Hash.ext
            date_str = file.dt.strftime("%Y-%m-%d-%H%M%S")
            hash_short = file.hash[:8]

            parts = [date_str]
            if file.make:
                parts.append(file.make)
            if file.model:
                parts.append(file.model)
            parts.append(hash_short)

            final_name = "-".join(parts) + file.correct_ext
        else:
            final_name = file.path.name

        # B. Determine Folder Structure
        if is_duplicate and self.args.dupe_strategy == 'skip':
            logging.info(f"Skipping duplicate: {file.path}")
            return False  # Skip duplicates completely

        if self.args.mode == 'rename':
            # In-place rename: Keep same folder
            dest_folder = file.path.parent
        else:
            # Organize mode: Use destination root
            dest_root = Path(self.args.dest)
            year = file.dt.strftime("%Y")
            month = file.dt.strftime("%m")

            if self.args.structure == 'simple':
                base_folder = dest_root / year / month
            else:  # keywords mode
                if file.keywords:
                    # Use first keyword alphabetically
                    kw = safe_filename(sorted(file.keywords)[0])
                    base_folder = dest_root / "Keywords" / kw / year / month
                else:
                    base_folder = dest_root / "No Keywords" / year / month

            # Handle duplicates
            if is_duplicate:
                if self.args.dupe_strategy == 'folder':
                    dest_folder = base_folder / "Duplicates"
                elif self.args.dupe_strategy == 'alongside':
                    dest_folder = base_folder
                    # Append -duplicate suffix
                    stem = Path(final_name).stem
                    ext = Path(final_name).suffix
                    final_name = f"{stem}-duplicate{ext}"
                else:
                    dest_folder = base_folder
            else:
                dest_folder = base_folder

        # C. Handle Collisions (Safety)
        dest_path = dest_folder / final_name

        # Check if destination already used or exists
        counter = 1
        original_stem = dest_path.stem
        original_ext = dest_path.suffix
        while dest_path in self.used_destinations or (dest_path.exists() and not self.args.dry_run):
            # If renaming in-place and name matches, it's fine
            if self.args.action == 'move' and dest_path.resolve() == file.path.resolve():
                break
            dest_path = dest_folder / f"{original_stem}_{counter}{original_ext}"
            counter += 1

        self.used_destinations.add(dest_path)

        # D. Perform Action
        if self.args.dry_run:
            # Just log
            logging.info(f"WOULD {self.args.action.upper()}: {file.path} -> {dest_path}")
            return True
        else:
            dest_folder.mkdir(parents=True, exist_ok=True)

            try:
                if self.args.action == 'move':
                    if file.path.resolve() != dest_path.resolve():
                        shutil.move(str(file.path), str(dest_path))
                        logging.info(f"MOVED: {file.path} -> {dest_path}")
                elif self.args.action == 'copy':
                    shutil.copy2(str(file.path), str(dest_path))
                    logging.info(f"COPIED: {file.path} -> {dest_path}")

                # Handle XMP Sidecar
                if file.xmp_path:
                    xmp_dest = dest_path.with_suffix('.xmp')
                    if self.args.action == 'move':
                        shutil.move(str(file.xmp_path), str(xmp_dest))
                    else:
                        shutil.copy2(str(file.xmp_path), str(xmp_dest))

                return True
            except Exception as e:
                logging.error(f"Failed to {self.args.action} {file.path}: {e}")
                print_error(f"Failed: {file.path.name}")
                return False

# =============================================================================
# CLI SETUP
# =============================================================================

def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Media Manager - Unified Tool for Homelab Media Suite",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Rename files in-place (dry-run)
  python media-manager.py /source --mode rename --dry-run

  # Organize to YYYY/MM structure (copy)
  python media-manager.py /source --dest /organized --mode organize --structure simple --execute

  # Full workflow (move + dedupe + rename)
  python media-manager.py /source --dest /organized --mode all --action move --execute
        """
    )

    # Inputs
    parser.add_argument("sources", nargs='+', help="Source directories to process")
    parser.add_argument("--dest", help="Destination root (required for organize/deduplicate/all modes)")

    # Modes
    parser.add_argument("--mode",
                        choices=['rename', 'organize', 'deduplicate', 'all'],
                        required=True,
                        help="Operation mode: rename (in-place), organize (structure), deduplicate (remove dupes), all (complete workflow)")

    # Behavior
    parser.add_argument("--action",
                        choices=['copy', 'move'],
                        default='copy',
                        help="Action type: copy (safe, default) or move (destructive)")

    parser.add_argument("--structure",
                        choices=['simple', 'keywords'],
                        default='simple',
                        help="Folder structure: simple (YYYY/MM) or keywords (Keywords/[Keyword]/YYYY/MM)")

    parser.add_argument("--dupe-strategy",
                        choices=['folder', 'alongside', 'skip'],
                        default='folder',
                        help="Duplicate handling: folder (Duplicates/ subfolder), alongside (same folder with suffix), skip (ignore dupes)")

    parser.add_argument("--rename",
                        action="store_true",
                        help="Force rename using PowerShell-compatible format (YYYY-MM-DD-HHmmss-Make-Model-Hash.ext)")

    # Safety
    parser.add_argument("--execute",
                        action="store_true",
                        help="Actually perform actions (default is dry-run mode)")

    parser.add_argument("--version", action="version", version=f"Media Manager v{__version__}")

    return parser.parse_args()

# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    args = parse_arguments()

    # Validation
    if args.mode in ['organize', 'deduplicate', 'all'] and not args.dest:
        print_error(f"ERROR: --dest is required for mode '{args.mode}'")
        sys.exit(1)

    args.dry_run = not args.execute

    # Configuration Summary
    print_phase("MEDIA MANAGER CONFIGURATION")
    print(f"Mode:           {args.mode.upper()}")
    print(f"Action:         {args.action.upper()}")
    print(f"Structure:      {args.structure}")
    print(f"Duplicates:     {args.dupe_strategy}")
    print(f"Rename:         {args.rename}")
    print(f"Dry Run:        {args.dry_run}")
    if args.dest:
        print(f"Destination:    {args.dest}")
    print()

    # Execute
    engine = MediaEngine(args)
    engine.execute()

    print_success("Media Manager completed!")
