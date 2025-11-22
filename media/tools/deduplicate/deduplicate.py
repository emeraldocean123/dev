#!/usr/bin/env python3
"""
Deduplicate Pro - Media Deduplication & Organization Tool
=========================================================

Version: 3.9.0

Description:
    Professional-grade tool to deduplicate photos, videos, and non-media files
    by exact content hash (SHA256). Organizes media by keyword/date with
    RAW+JPG pairing and XMP sidecar handling. Non-media files sorted by extension.

Requirements:
    - Python 3.10+
    - pip install tqdm
    - ExifTool installed and in PATH

Usage:
    python deduplicate.py              # Interactive wizard
    python deduplicate.py /source      # Quick mode (auto-organize)
    python deduplicate.py /src /dest   # Quick mode with destination

Changelog:
    v3.9.0 - EXTENSION CORRECTION: Auto-fix wrong file extensions based on actual file type
    v3.8.0 - Colorized wizard with colorama, simplified log/config folder names
    v3.7.0 - PERFORMANCE TUNING: Auto-detect optimal workers, user-selectable profiles
    v3.6.1 - Terminology cleanup, simplified wizard (removed keyword filter prompt)
    v3.6.0 - Three-category structure: Keywords/, No Keywords/, Non-Media/
    v3.5.0 - SHA256-based filenames (16 chars) for idempotent re-runs
    v3.4.2 - Destination warning, project-local logs and configs
    v3.4.1 - OOM protection: Skip junk folders (node_modules, .git, etc.)
    v3.4.0 - Performance: 4MB hash buffer (60x faster), cross-platform beep
    v3.3.0 - Non-media files organized by extension (PDF, ZIP, etc.)
    v3.2.0 - Non-media file processing with SHA256 deduplication
    v3.1.3 - Reliable mode: Individual ExifTool calls (bulletproof)
    v3.1.0 - Keyword filtering support
    v3.0.0 - Interactive wizard, keyword scoring, RAW+JPG pairing
"""
import sys
import os
import shutil
import hashlib
import json
import logging
import subprocess
import multiprocessing as mp
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import List, Optional, Set, Tuple
from dataclasses import dataclass, field
from concurrent.futures import ThreadPoolExecutor, as_completed

# Third-party imports
try:
    from tqdm import tqdm
    from colorama import init, Fore, Style
    init(autoreset=True)
except ImportError:
    print("Error: Missing dependencies. Please run: pip install tqdm colorama")
    sys.exit(1)

__version__ = "3.9.0"


# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================

# Supported file extensions
IMG_EXTS = {'.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.webp', '.avif', '.jxl'}
RAW_EXTS = {'.arw', '.cr2', '.cr3', '.nef', '.orf', '.dng', '.rw2', '.raf', '.srw', '.raw'}
VID_EXTS = {'.mp4', '.mov', '.avi', '.mkv', '.m4v', '.webm', '.mts', '.m2ts', '.3gp', '.mpg', '.mpeg', '.hevc', '.ts'}
ALL_EXTS = IMG_EXTS | RAW_EXTS | VID_EXTS

# ExifTool FileType to correct extension mapping
FILETYPE_TO_EXT = {
    'JPEG': '.jpg',
    'PNG': '.png',
    'HEIC': '.heic',
    'HEIF': '.heif',
    'TIFF': '.tiff',
    'WEBP': '.webp',
    'AVIF': '.avif',
    'JXL': '.jxl',
    'GIF': '.gif',
    'BMP': '.bmp',
    # RAW formats
    'CR2': '.cr2',
    'CR3': '.cr3',
    'NEF': '.nef',
    'ARW': '.arw',
    'ORF': '.orf',
    'DNG': '.dng',
    'RW2': '.rw2',
    'RAF': '.raf',
    'SRW': '.srw',
    'RAW': '.raw',
    # Video formats
    'MOV': '.mov',
    'MP4': '.mp4',
    'AVI': '.avi',
    'MKV': '.mkv',
    'M4V': '.m4v',
    'WEBM': '.webm',
    'MTS': '.mts',
    'M2TS': '.m2ts',
    '3GP': '.3gp',
    'MPG': '.mpg',
    'MPEG': '.mpeg',
    'HEVC': '.hevc',
    'TS': '.ts',
}

# Folder exclusions (prevents OOM from massive junk folders)
SKIP_DIRS = {
    '.git', 'node_modules', 'venv', '.venv', '__pycache__', '.idea', '.vscode',
    'AppData', 'Library', '.npm', '.cache', 'Cache', 'Caches', '.gradle',
    'target', 'build', 'dist', '.tox', '.mypy_cache', '.pytest_cache'
}

# Worker profiles for different system capabilities
WORKER_PROFILES = {
    'conservative': {'workers': 2, 'desc': 'Low CPU usage (2 workers) - for older systems or background tasks'},
    'balanced': {'workers': max(4, mp.cpu_count() // 2), 'desc': f'Balanced ({max(4, mp.cpu_count() // 2)} workers) - good for most systems'},
    'fast': {'workers': max(1, mp.cpu_count() - 2), 'desc': f'Fast ({max(1, mp.cpu_count() - 2)} workers) - leaves 2 cores free'},
    'maximum': {'workers': mp.cpu_count(), 'desc': f'Maximum ({mp.cpu_count()} workers) - uses all cores'},
}

def get_optimal_workers() -> int:
    """Auto-detect optimal worker count based on CPU cores."""
    cores = mp.cpu_count()
    if cores <= 4:
        return max(2, cores - 1)  # Leave 1 core free on low-end systems
    elif cores <= 8:
        return cores - 2  # Leave 2 cores free
    else:
        return cores - 2  # High-end: still leave 2 cores for system responsiveness

# Default worker count (can be overridden in wizard)
MAX_WORKERS = get_optimal_workers()

# Timestamped Logging Setup (preserve logs for crash analysis)
# Use script directory for logs (not home directory)
SCRIPT_DIR = Path(__file__).parent.resolve()
log_dir = SCRIPT_DIR / "logs"
log_dir.mkdir(exist_ok=True)
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
log_file = log_dir / f"deduplicate_{timestamp}.log"

# Configuration directory for saving run configs
config_dir = SCRIPT_DIR / "configs"
config_dir.mkdir(exist_ok=True)

class FlushingFileHandler(logging.FileHandler):
    """File handler that flushes after every write (critical for crash diagnosis)."""
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
log.info(f"📋 Log file: logs/{log_file.name}")

# =============================================================================
# DATA STRUCTURES
# =============================================================================

@dataclass
class Media:
    path: Path
    hash: str
    size: int
    dt: datetime
    keywords: Set[str] = field(default_factory=set)
    rating: int = 0
    width: int = 0
    height: int = 0
    is_raw: bool = False
    is_video: bool = False
    xmp: Optional[Path] = None
    paired: Optional[Path] = None  # For RAW+JPG linking
    correct_ext: str = ""  # Corrected extension based on actual file type

    def score(self) -> float:
        """Calculate a score to determine the 'winner' among duplicates."""
        s = float(self.size)
        s += self.width * self.height * 5
        s += self.rating * 5_000_000
        s += len(self.keywords) * 100_000  # Bonus for having metadata
        if self.is_raw:
            s *= 3.0  # Prefer RAW over JPG if content is identical
        return s

@dataclass
class OtherFile:
    """Represents a non-media file."""
    path: Path
    hash: str
    size: int
    source_root: Path  # Kept for reference, though we sort by extension now

    def score(self) -> float:
        """Simple scoring: prefer larger files."""
        return float(self.size)

# =============================================================================
# UTILITIES
# =============================================================================

def check_dependencies():
    """Verify ExifTool is available."""
    try:
        subprocess.run(['exiftool', '-ver'], capture_output=True, text=True, timeout=5, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("ERROR: ExifTool not found! Please install it and add to PATH.")
        print("  Windows: https://exiftool.org/ (rename to exiftool.exe)")
        print("  Mac: brew install exiftool")
        print("  Linux: sudo apt install libimage-exiftool-perl")
        sys.exit(1)

def safe_filename(name: str) -> str:
    """Sanitize directory/filenames."""
    return "".join(c if c.isalnum() or c in (' ', '-', '_') else "_" for c in name).strip()

def victory_beep():
    """Cross-platform completion beep."""
    try:
        if sys.platform == "win32":
            import winsound
            winsound.Beep(800, 500)  # 800Hz for 500ms
        else:
            # Linux/Mac console beep
            print('\a', end='', flush=True)
    except:
        pass

def check_destination_files(dest_path: Path) -> Tuple[int, float]:
    """
    Check if destination has existing files.
    Returns (file_count, size_in_GB).
    """
    if not dest_path.exists():
        return 0, 0.0

    try:
        files = list(dest_path.rglob('*'))
        file_list = [f for f in files if f.is_file()]
        count = len(file_list)
        if count == 0:
            return 0, 0.0

        total_size = sum(f.stat().st_size for f in file_list)
        size_gb = total_size / (1024**3)
        return count, size_gb
    except Exception:
        return 0, 0.0

def save_configuration(sources: List[str], dest: str, orphan: str, strategy: int,
                       dry_run: bool, kw_filter: Optional[Set[str]], workers: int) -> str:
    """
    Save run configuration to JSON file with timestamp.
    Returns the saved config filename.
    """
    import json

    config = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "version": __version__,
        "sources": sources,
        "destination": dest,
        "orphan_directory": orphan,
        "duplicate_strategy": strategy,
        "duplicate_strategy_name": ["Separate folder", "Alongside", "Skip"][strategy-1],
        "dry_run": dry_run,
        "keyword_filter": list(sorted(kw_filter)) if kw_filter else None,
        "workers": workers,
        "cpu_cores": mp.cpu_count()
    }

    config_filename = f"config_{timestamp}.json"
    config_path = config_dir / config_filename

    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)

    return config_filename

def print_phase(phase: str, message: str = ""):
    """Print a colorized phase header."""
    print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{Style.BRIGHT}  {phase}{Style.RESET_ALL}")
    if message:
        print(f"{Fore.WHITE}  {message}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")


def get_directories() -> Tuple[List[str], str, str, int, bool, Optional[Set[str]], int]:
    """Interactive wizard for user configuration. Returns (sources, dest, orphan, strategy, dry_run, kw_filter, workers)."""
    try:
        print(f"\n{Fore.MAGENTA}{Style.BRIGHT}Deduplicate Pro v{__version__}{Style.RESET_ALL}")
        print(f"{Fore.WHITE}Organize & deduplicate photos, videos, and files by content hash.{Style.RESET_ALL}")
        print(f"{Fore.WHITE}Detected {mp.cpu_count()} CPU cores{Style.RESET_ALL}\n")

        # Sources
        sources = []
        print(f"{Fore.YELLOW}Source Directories:{Style.RESET_ALL}")
        print(f"  (Enter one per line, empty line to finish)")
        while True:
            src = input(f"{Fore.CYAN}  Source #{len(sources)+1}: {Style.RESET_ALL}").strip()
            if not src:
                break
            if Path(src).exists():
                sources.append(src)
                print(f"{Fore.GREEN}    Added: {src}{Style.RESET_ALL}")
            else:
                print(f"{Fore.RED}    Directory not found: {src}{Style.RESET_ALL}")
                if input(f"{Fore.YELLOW}    Add anyway? (y/n): {Style.RESET_ALL}").lower() != 'y':
                    continue
                sources.append(src)

        if not sources:
            print(f"{Fore.RED}ERROR: No sources provided. Exiting.{Style.RESET_ALL}")
            sys.exit(1)

        # Destination
        while True:
            dest = input(f"\n{Fore.CYAN}Destination Directory: {Style.RESET_ALL}").strip()
            if dest:
                dest_path = Path(dest)
                if dest_path.exists():
                    file_count, size_gb = check_destination_files(dest_path)
                    if file_count > 0:
                        print(f"{Fore.YELLOW}  Warning: Contains {file_count:,} files ({size_gb:.2f} GB){Style.RESET_ALL}")
                        proceed = input(f"{Fore.CYAN}  Continue anyway? (y/n): {Style.RESET_ALL}").lower()
                        if proceed == 'y':
                            break
                    else:
                        print(f"{Fore.GREEN}  Directory exists (empty){Style.RESET_ALL}")
                        break
                else:
                    print(f"{Fore.GREEN}  Will create directory{Style.RESET_ALL}")
                    break

        # XMP Orphans
        orphan = input(f"\n{Fore.CYAN}Orphaned XMP directory [Enter for 'XMP_Orphans']: {Style.RESET_ALL}").strip()
        if not orphan:
            orphan = str(Path(dest) / "XMP_Orphans")

        # Strategy
        print(f"\n{Fore.YELLOW}Duplicate Handling:{Style.RESET_ALL}")
        print("  1. Separate folder (duplicates/)")
        print("  2. Alongside winner (_duplicate-1, etc.)")
        print("  3. Skip duplicates (keep winner only)")
        strat_in = input(f"{Fore.CYAN}Choose [1]: {Style.RESET_ALL}").strip() or "1"
        strategy = int(strat_in) if strat_in in ('1', '2', '3') else 1

        # Dry Run
        dry = input(f"\n{Fore.CYAN}Dry Run (simulation)? (y/N): {Style.RESET_ALL}").lower() == 'y'

        # Worker count selection
        print(f"\n{Fore.YELLOW}Performance Profile:{Style.RESET_ALL}")
        print(f"  1. Conservative - 2 workers (background tasks)")
        print(f"  2. Balanced     - {WORKER_PROFILES['balanced']['workers']} workers (recommended)")
        print(f"  3. Fast         - {WORKER_PROFILES['fast']['workers']} workers (leaves 2 cores free)")
        print(f"  4. Maximum      - {WORKER_PROFILES['maximum']['workers']} workers (all cores)")
        profile_in = input(f"{Fore.CYAN}Choose [3]: {Style.RESET_ALL}").strip() or "3"

        if profile_in == '1':
            workers = WORKER_PROFILES['conservative']['workers']
        elif profile_in == '2':
            workers = WORKER_PROFILES['balanced']['workers']
        elif profile_in == '4':
            workers = WORKER_PROFILES['maximum']['workers']
        else:
            workers = WORKER_PROFILES['fast']['workers']

        # Keywords - always organize by ALL keywords (no filtering)
        kw_filter = None

        # Summary
        print_phase("CONFIGURATION SUMMARY")
        print(f"  {Fore.WHITE}Sources ({len(sources)}):{Style.RESET_ALL}")
        for s in sources:
            print(f"    - {s}")
        print(f"  {Fore.WHITE}Destination:{Style.RESET_ALL} {dest}")
        print(f"  {Fore.WHITE}Orphaned XMPs:{Style.RESET_ALL} {orphan}")
        print(f"  {Fore.WHITE}Duplicates:{Style.RESET_ALL} {['Separate folder', 'Alongside', 'Skip'][strategy-1]}")
        print(f"  {Fore.WHITE}Dry Run:{Style.RESET_ALL} {'Yes' if dry else 'No'}")
        print(f"  {Fore.WHITE}Workers:{Style.RESET_ALL} {workers}")
        print()
        print(f"  {Fore.WHITE}Output filename format:{Style.RESET_ALL}")
        print(f"    2024-12-25_10-30-45_IMG_a1b2c3d4e5f6a7b8.jpg")
        print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
        print()

        if input("Proceed with this configuration? (y/n): ").lower() != 'y':
            print("Cancelled.")
            sys.exit(0)

        # Save configuration for record keeping
        config_filename = save_configuration(sources, dest, orphan, strategy, dry, kw_filter, workers)
        print()
        print(f"Configuration saved: configs/{config_filename}")
        print()

        return sources, dest, orphan, strategy, dry, kw_filter, workers

    except KeyboardInterrupt:
        print("\n\nConfiguration cancelled by user.")
        sys.exit(0)

# =============================================================================
# METADATA ENGINE (Individual ExifTool Calls)
# =============================================================================

def get_metadata_single(path: Path, is_video: bool = False) -> dict:
    """
    Run a single ExifTool subprocess call.
    RELIABLE MODE: No batch processing, no threading issues.
    """
    try:
        cmd = ['exiftool', '-j', '-G', '-q',
               '-FileType',  # For extension correction
               '-DateTimeOriginal', '-CreateDate', '-QuickTime:CreationDate', '-QuickTime:CreateDate',
               '-Subject', '-Keywords', '-Rating', '-ImageWidth', '-ImageHeight']

        if not is_video:
            cmd.append('-fast2')

        cmd.append(str(path))

        res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8',
                           errors='replace', timeout=30)
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            return data[0] if data else {}
    except Exception as e:
        log.debug(f"ExifTool error on {path.name}: {e}")
    return {}

def extract_meta_and_hash(path: Path) -> Optional[Media]:
    """Worker function: Hashes file and extracts metadata."""
    try:
        ext = path.suffix.lower()
        is_video = ext in VID_EXTS
        is_raw = ext in RAW_EXTS

        # 1. Hash file (SHA256) - 4MB buffer for optimal performance on modern NVMe
        h = hashlib.sha256()
        with open(path, "rb") as f:
            while chunk := f.read(4 * 1024 * 1024):  # 4MB chunks
                h.update(chunk)
        file_hash = h.hexdigest()

        # 2. Get metadata (INDIVIDUAL CALL - RELIABLE)
        data = get_metadata_single(path, is_video)

        # Parse Date (prefer CreationDate with TZ info for videos over CreateDate UTC)
        dt = datetime.fromtimestamp(path.stat().st_mtime)  # Fallback to file mtime
        for tag in ['EXIF:DateTimeOriginal', 'XMP:DateTimeOriginal', 'QuickTime:CreationDate',
                    'QuickTime:CreateDate', 'Composite:DateTimeOriginal', 'EXIF:CreateDate']:
            if val := data.get(tag):
                try:
                    clean_val = val.split('+')[0].replace('Z', '').strip()
                    dt = datetime.strptime(clean_val, "%Y:%m:%d %H:%M:%S")
                    break
                except ValueError:
                    continue

        # Parse Keywords
        keywords = set()
        for tag in ['XMP:Subject', 'IPTC:Keywords', 'XMP:Keywords']:
            val = data.get(tag)
            if isinstance(val, list):
                keywords.update(str(v).strip() for v in val)
            elif isinstance(val, str):
                keywords.update(v.strip() for v in val.replace(';', ',').split(','))

        # Parse Others
        rating = int(data.get('XMP:Rating', 0) or 0)
        w = int(data.get('EXIF:ImageWidth', 0) or 0)
        h_dim = int(data.get('EXIF:ImageHeight', 0) or 0)

        # Determine correct extension from actual file type
        file_type = data.get('File:FileType', '')
        correct_ext = FILETYPE_TO_EXT.get(file_type, ext)  # Fallback to original ext
        if correct_ext != ext:
            # Log to file ONLY to prevent breaking the progress bar
            msg = f"Extension fix: {path.name} is {file_type}, will use {correct_ext}"
            for h in log.handlers:
                if isinstance(h, FlushingFileHandler):
                    record = logging.LogRecord('root', logging.INFO, '', 0, msg, (), None)
                    h.handle(record)

        # Check for XMP Sidecar
        xmp_path = path.with_suffix('.xmp')
        if not xmp_path.exists():
            xmp_path = Path(str(path) + ".xmp")
        has_xmp = xmp_path if xmp_path.exists() else None

        return Media(
            path=path,
            hash=file_hash,
            size=path.stat().st_size,
            dt=dt,
            keywords={k for k in keywords if k},
            rating=rating,
            width=w,
            height=h_dim,
            is_raw=is_raw,
            is_video=is_video,
            xmp=has_xmp,
            correct_ext=correct_ext
        )

    except Exception as e:
        log.error(f"Error processing {path.name}: {e}")
        return None

def hash_other_file(path: Path, source_root: Path) -> Optional[OtherFile]:
    """Worker function: Hashes non-media file."""
    try:
        # SHA256 hash - 4MB buffer for optimal performance
        h = hashlib.sha256()
        with open(path, "rb") as f:
            while chunk := f.read(4 * 1024 * 1024):  # 4MB chunks
                h.update(chunk)
        file_hash = h.hexdigest()

        return OtherFile(
            path=path,
            hash=file_hash,
            size=path.stat().st_size,
            source_root=source_root
        )

    except Exception as e:
        log.error(f"Error hashing {path.name}: {e}")
        return None

# =============================================================================
# PROCESSING PHASES
# =============================================================================

def link_raw_jpg_pairs(media_list: List[Media]):
    """Links RAW and JPG files if they share a folder and filename stem."""
    lookup = defaultdict(list)
    for m in media_list:
        lookup[(m.path.parent, m.path.stem)].append(m)

    count = 0
    for key, group in lookup.items():
        if len(group) >= 2:
            raw = next((x for x in group if x.is_raw), None)
            jpg = next((x for x in group if not x.is_raw and not x.is_video), None)
            if raw and jpg:
                raw.paired = jpg.path
                jpg.paired = raw.path
                count += 1
    log.info(f"  Linked {count} RAW+JPG pairs")

def organize_media(groups: List[List[Media]], dest_root: Path, strategy: int,
                  dry_run: bool, kw_filter: Optional[Set[str]]):
    """Organizes files into destination structure."""

    for group in tqdm(groups, desc="Phase 4: Organizing"):
        # Pick winner
        winner = max(group, key=lambda x: x.score())

        # Determine folder structure
        year = winner.dt.strftime("%Y")
        month = winner.dt.strftime("%m")

        # Apply keyword filtering if enabled
        if kw_filter:
            matching_keywords = [kw for kw in winner.keywords if kw.lower() in kw_filter]
            if matching_keywords:
                kw_folder = "-".join(sorted(matching_keywords)[:4])
                kw_folder = safe_filename(kw_folder)
                target_dir = dest_root / "Keywords" / kw_folder / year / month
            else:
                # No matching keywords
                target_dir = dest_root / "No Keywords" / year / month
        else:
            if winner.keywords:
                kw_folder = "-".join(sorted(winner.keywords)[:4])
                kw_folder = safe_filename(kw_folder)
                target_dir = dest_root / "Keywords" / kw_folder / year / month
            else:
                # No keywords at all
                target_dir = dest_root / "No Keywords" / year / month

        # Determine filename (use corrected extension based on actual file type)
        f_uid = winner.hash[:16]  # First 16 chars of SHA256 (safe for 100M+ files)
        f_type = "VID" if winner.is_video else "IMG"
        f_date = winner.dt.strftime("%Y-%m-%d_%H-%M-%S")
        f_ext = winner.correct_ext or winner.path.suffix.lower()
        f_name = f"{f_date}_{f_type}_{f_uid}{f_ext}"

        dest_path = target_dir / f_name

        # Copy winner
        if not dry_run:
            target_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(winner.path, dest_path)
            if winner.xmp:
                shutil.copy2(winner.xmp, dest_path.with_suffix(dest_path.suffix + '.xmp'))

            # Copy paired file
            if winner.paired:
                pair_name = f"{f_date}_{f_type}_{f_uid}{winner.paired.suffix.lower()}"
                shutil.copy2(winner.paired, target_dir / pair_name)

        # Handle duplicates
        duplicates = [m for m in group if m != winner]
        if not duplicates:
            continue

        for i, dup in enumerate(duplicates, 1):
            if strategy == 3:  # Skip
                continue

            dup_ext = dup.correct_ext or dup.path.suffix.lower()
            dup_name = f"{dest_path.stem}_duplicate-{i}{dup_ext}"

            if strategy == 1:  # Separate folder
                dup_dir = target_dir / "duplicates"
                dup_dest = dup_dir / dup_name
                if not dry_run:
                    dup_dir.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(dup.path, dup_dest)
                    if dup.xmp:
                        shutil.copy2(dup.xmp, dup_dest.with_suffix(dup_dest.suffix + '.xmp'))

            elif strategy == 2:  # Alongside
                dup_dest = target_dir / dup_name
                if not dry_run:
                    shutil.copy2(dup.path, dup_dest)
                    if dup.xmp:
                        shutil.copy2(dup.xmp, dup_dest.with_suffix(dup_dest.suffix + '.xmp'))

def organize_other_files(groups: List[List[OtherFile]], dest_root: Path, strategy: int, dry_run: bool):
    """Organizes non-media files by sorting them into folders based on their EXTENSION."""

    other_root = dest_root / "Non-Media"

    # Track destinations used in this run to handle filename collisions
    # (e.g., distinct files named 'readme.txt' from different source folders)
    used_destinations = set()

    for group in tqdm(groups, desc="Phase 6: Organizing Other"):
        # Pick winner (largest file)
        winner = max(group, key=lambda x: x.score())

        # Determine extension folder (e.g., "PDF", "ZIP", "NO_EXT")
        ext = winner.path.suffix.lstrip('.').upper()
        if not ext:
            ext = "NO_EXTENSION"

        ext = safe_filename(ext)
        target_dir = other_root / ext

        # Determine initial target path
        target_name = winner.path.name
        target_path = target_dir / target_name

        # Handle filename collisions for *different content*
        # If a file with this name already exists (and it's not the same hash, because we are in unique hash groups),
        # we must rename the new incoming file.
        counter = 1
        base_stem = target_path.stem
        base_suffix = target_path.suffix

        # Check both the filesystem (if not dry run) and our internal tracking set
        while target_path in used_destinations or (target_path.exists() and not dry_run):
            target_name = f"{base_stem}_{counter}{base_suffix}"
            target_path = target_dir / target_name
            counter += 1

        used_destinations.add(target_path)

        # Copy winner
        if not dry_run:
            target_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(winner.path, target_path)

        # Handle duplicates (same content)
        duplicates = [f for f in group if f != winner]
        if not duplicates:
            continue

        for i, dup in enumerate(duplicates, 1):
            if strategy == 3:  # Skip
                continue

            dup_name = f"{target_path.stem}_duplicate-{i}{target_path.suffix}"

            if strategy == 1:  # Separate folder
                dup_dir = target_path.parent / "duplicates"
                dup_dest = dup_dir / dup_name
                if not dry_run:
                    dup_dir.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(dup.path, dup_dest)

            elif strategy == 2:  # Alongside
                dup_dest = target_path.parent / dup_name
                if not dry_run:
                    shutil.copy2(dup.path, dup_dest)

def handle_orphans(sources: List[str], orphan_dest: Path, dry_run: bool):
    """Finds XMP files that have no corresponding media file."""
    log.info("=" * 70)
    log.info("PHASE 5/6: Collecting orphaned XMP sidecars")
    log.info(f"  Destination: {orphan_dest}")

    orphan_count = 0
    for src in sources:
        src_path = Path(src)
        if not src_path.exists():
            continue

        for xmp in src_path.rglob("*.xmp"):
            stem = xmp.stem.split(".")[0]
            has_media = any((xmp.with_name(stem + ext)).exists() for ext in ALL_EXTS)

            if not has_media:
                try:
                    rel_path = xmp.relative_to(src_path)
                except ValueError:
                    rel_path = xmp.name

                target = orphan_dest / rel_path
                if not dry_run:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(xmp, target)
                orphan_count += 1

    log.info(f"Phase 5 complete: {orphan_count} orphaned XMP files collected")

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

def main():
    global MAX_WORKERS
    check_dependencies()

    # Configuration
    if len(sys.argv) > 1 and Path(sys.argv[1]).exists():
        # Quick mode - use auto-detected workers
        src_dirs = [sys.argv[1]]
        dest_root = sys.argv[2] if len(sys.argv) > 2 else str(Path(sys.argv[1]) / "Organized")
        orphan_dir = str(Path(dest_root) / "XMP_Orphans")
        strategy = 2
        dry_run = "--dry-run" in sys.argv
        kw_filter = None
        workers = get_optimal_workers()
        log.info(f"Quick mode: {src_dirs[0]} → {dest_root}")
    else:
        src_dirs, dest_root, orphan_dir, strategy, dry_run, kw_filter, workers = get_directories()

    # Apply user-selected worker count
    MAX_WORKERS = workers

    dest_path = Path(dest_root)
    dest_abs = dest_path.resolve()

    # Phase 1: Scan MEDIA files
    log.info("=" * 70)
    log.info("Photo/Video/File Deduplication - Interactive Mode")
    log.info(f"Version: {__version__}")
    log.info("=" * 70)
    log.info("PHASE 1/6: Scanning source directories for media files")

    media_files = []
    other_files = []

    for src in src_dirs:
        p = Path(src)
        if p.exists():
            log.info(f"  Scanning: {src}")
            src_media = []
            src_other = []

            # Use os.walk() instead of rglob() to skip junk folders (prevents OOM)
            for root, dirs, files in os.walk(p):
                # Modify dirs in-place to skip excluded folders (prevents deep recursion)
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.')]

                root_path = Path(root)

                # Skip if we are inside the destination folder
                try:
                    if root_path.resolve().is_relative_to(dest_abs):
                        dirs.clear()  # Stop recursing into this tree
                        continue
                except (ValueError, AttributeError):
                    if str(dest_abs) in str(root_path.resolve()):
                        dirs.clear()
                        continue

                # Process files in this directory
                for file in files:
                    f = root_path / file

                    # Categorize by extension
                    if f.suffix.lower() in ALL_EXTS:
                        src_media.append(f)
                    else:
                        src_other.append((f, p))  # Store with source root

            log.info(f"    Found {len(src_media):,} media files, {len(src_other):,} non-media files")
            media_files.extend(src_media)
            other_files.extend(src_other)

    log.info(f"Phase 1 complete: {len(media_files):,} media files, {len(other_files):,} non-media files")
    log.info("")

    # Phase 2: Process MEDIA files
    log.info("=" * 70)
    log.info("PHASE 2/6: Processing media files (metadata, hashing)")
    log.info(f"Using {MAX_WORKERS} parallel workers...")
    log.info("  RELIABLE MODE: Individual ExifTool calls (no batch threading)")

    media_list = []
    try:
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            futures = [executor.submit(extract_meta_and_hash, f) for f in media_files]
            log.info(f"  ✓ Submitted {len(futures):,} tasks to thread pool")
            log.info(f"  Processing with {MAX_WORKERS} workers...")

            processed = 0
            for fut in tqdm(as_completed(futures), total=len(media_files), desc="Phase 2: Processing"):
                res = fut.result()
                if res:
                    media_list.append(res)
                processed += 1

                # Log progress every 5000 files for crash diagnosis (file only - keeps progress bar clean)
                if processed % 5000 == 0:
                    msg = f"  → Progress: {processed:,}/{len(media_files):,} files processed ({len(media_list):,} successful)"
                    # Send to file handler ONLY (keeps console clean for tqdm progress bar)
                    for h in log.handlers:
                        if isinstance(h, FlushingFileHandler):
                            # Manually create a record so it formats correctly with timestamp
                            record = logging.LogRecord('root', logging.INFO, '', 0, msg, (), None)
                            h.handle(record)

    except KeyboardInterrupt:
        log.warning("Interrupted by user")
        sys.exit(1)

    log.info(f"Phase 2 complete: {len(media_list):,} files successfully processed")
    log.info(f"  Final success rate: {len(media_list)}/{processed} ({100*len(media_list)/max(1,processed):.1f}%)")
    log.info("")

    # Phase 3: Deduplicate & Pair MEDIA
    log.info("=" * 70)
    log.info("PHASE 3/6: Finding RAW+JPG pairs and grouping duplicates")
    log.info("  Finding RAW+JPG pairs...")
    link_raw_jpg_pairs(media_list)

    log.info("  Grouping duplicates by exact content hash (SHA256)...")
    hash_groups = defaultdict(list)
    for m in media_list:
        hash_groups[m.hash].append(m)

    media_groups = list(hash_groups.values())
    media_unique = [g for g in media_groups if len(g) == 1]
    media_dupes = [g for g in media_groups if len(g) > 1]

    log.info(f"  Found {len(media_unique):,} unique media files")
    log.info(f"  Found {len(media_dupes):,} duplicate groups ({sum(len(g) for g in media_dupes):,} total files)")
    log.info(f"Phase 3 complete")
    log.info("")

    # Phase 4: Organize MEDIA
    log.info("=" * 70)
    log.info("PHASE 4/6: Copying and organizing media files")
    log.info(f"  Destination: {dest_root}")
    log.info(f"  Duplicate strategy: {['Separate folder', 'Alongside', 'Skip'][strategy-1]}")
    if dry_run:
        log.info(f"  DRY-RUN MODE: No files will be copied")

    if not dry_run:
        dest_path.mkdir(parents=True, exist_ok=True)

    organize_media(media_groups, dest_path, strategy, dry_run, kw_filter)
    log.info(f"Phase 4 complete: {len(media_groups):,} media files organized")
    log.info("")

    # Phase 5: Orphans
    handle_orphans(src_dirs, Path(orphan_dir), dry_run)
    log.info("")

    # Phase 6: Process NON-MEDIA files
    log.info("=" * 70)
    log.info("PHASE 6/6: Processing non-media files (SHA256 deduplication)")
    log.info(f"  Total non-media files to process: {len(other_files):,}")

    if other_files:
        other_list = []
        try:
            with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
                futures = [executor.submit(hash_other_file, f, src_root) for f, src_root in other_files]
                for fut in tqdm(as_completed(futures), total=len(other_files), desc="Phase 6: Hashing Other"):
                    res = fut.result()
                    if res:
                        other_list.append(res)
        except KeyboardInterrupt:
            log.warning("Interrupted by user")
            sys.exit(1)

        log.info(f"  Hashed {len(other_list):,} non-media files")

        # Group by hash
        log.info("  Grouping non-media files by content hash...")
        other_hash_groups = defaultdict(list)
        for f in other_list:
            other_hash_groups[f.hash].append(f)

        other_groups = list(other_hash_groups.values())
        # Sort for deterministic processing order (prevents rename chaos on re-runs)
        other_groups.sort(key=lambda g: g[0].hash)
        other_unique = [g for g in other_groups if len(g) == 1]
        other_dupes = [g for g in other_groups if len(g) > 1]

        log.info(f"  Found {len(other_unique):,} unique non-media files")
        log.info(f"  Found {len(other_dupes):,} duplicate groups ({sum(len(g) for g in other_dupes):,} total files)")

        # Organize non-media files
        log.info(f"  Organizing to: {dest_root}/Non-Media/[Extension]/")
        organize_other_files(other_groups, dest_path, strategy, dry_run)
        log.info(f"Phase 6 complete: {len(other_groups):,} non-media files organized")
    else:
        other_groups = []
        other_unique = []
        other_dupes = []
        log.info("  No non-media files found")
        log.info(f"Phase 6 complete")

    log.info("")

    # Summary
    log.info("=" * 70)
    log.info("FINAL SUMMARY")
    log.info("=" * 70)
    if dry_run:
        log.info("MODE: DRY-RUN (no files were copied)")
    log.info(f"Total media files scanned: {len(media_files):,}")
    log.info(f"Successfully processed media: {len(media_list):,}")
    log.info(f"Unique media files: {len(media_unique):,}")
    log.info(f"Duplicate media groups: {len(media_dupes):,}")
    log.info(f"Media files organized: {len(media_groups):,}")
    log.info("")
    log.info(f"Total non-media files scanned: {len(other_files):,}")
    log.info(f"Successfully processed non-media: {len(other_list) if other_files else 0:,}")
    log.info(f"Unique non-media files: {len(other_unique):,}")
    log.info(f"Duplicate non-media groups: {len(other_dupes):,}")
    log.info(f"Non-media files organized: {len(other_groups):,}")
    log.info("")
    log.info(f"Destination: {dest_root}")
    log.info("=" * 70)
    log.info("")
    log.info("✨ Deduplicate Pro – Mission Complete ✨")
    log.info("Your library is now perfectly organized and deduplicated.")
    log.info("Media files organized by keyword/date, non-media files by extension.")
    log.info("RAW+JPG pairs preserved, orphaned XMPs rescued.")
    log.info("You may now sleep peacefully knowing your files are safe.")

    # Victory beep (cross-platform)
    victory_beep()

if __name__ == "__main__":
    mp.freeze_support()
    try:
        main()
    except KeyboardInterrupt:
        log.warning("Interrupted by user")
        sys.exit(1)
    except Exception as e:
        log.exception(f"Fatal error: {e}")
        sys.exit(1)
