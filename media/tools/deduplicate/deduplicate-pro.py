#!/usr/bin/env python3
"""
Deduplicate Pro - Media Organization, Renaming & Deduplication
==============================================================

Version: 4.0.0

Description:
    Professional-grade tool to organize, rename, and deduplicate media files.
    Supports Copying or Moving files, simple or keyword-based structures,
    and robust RAW+JPG pairing.

Requirements:
    - Python 3.10+
    - pip install tqdm colorama
    - ExifTool installed and in PATH

Usage:
    python deduplicate-pro.py              # Interactive wizard
    python deduplicate-pro.py /source      # Quick mode

Changelog:
    v4.0.0 - MAJOR: Added Move vs Copy, Simple YYYY/MM structure, Make/Model naming
"""
import sys, os, shutil, hashlib, json, logging, subprocess, re, multiprocessing as mp
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import List, Optional, Set
from dataclasses import dataclass, field
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from tqdm import tqdm
    from colorama import init, Fore, Style
    init(autoreset=True)
except ImportError:
    print("Error: Missing dependencies. Run: pip install tqdm colorama")
    sys.exit(1)

__version__ = "4.0.0"

# Supported extensions
IMG_EXTS = {'.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif', '.webp', '.avif'}
RAW_EXTS = {'.arw', '.cr2', '.cr3', '.nef', '.orf', '.dng', '.rw2', '.raf', '.srw', '.raw'}
VID_EXTS = {'.mp4', '.mov', '.avi', '.mkv', '.m4v', '.webm', '.mts', '.m2ts', '.3gp', '.mpg'}
ALL_EXTS = IMG_EXTS | RAW_EXTS | VID_EXTS

FILETYPE_TO_EXT = {
    'JPEG': '.jpg', 'PNG': '.png', 'HEIC': '.heic', 'HEIF': '.heif', 'TIFF': '.tiff',
    'CR2': '.cr2', 'CR3': '.cr3', 'NEF': '.nef', 'ARW': '.arw', 'DNG': '.dng',
    'MOV': '.mov', 'MP4': '.mp4', 'AVI': '.avi', 'MKV': '.mkv'
}

SKIP_DIRS = {'.git', 'node_modules', 'venv', '__pycache__', 'AppData', 'Library',
             '.cache', 'System Volume Information', '$RECYCLE.BIN'}

def get_optimal_workers():
    cores = mp.cpu_count()
    return max(2, cores - 2) if cores > 4 else max(1, cores - 1)

MAX_WORKERS = get_optimal_workers()

SCRIPT_DIR = Path(__file__).parent.resolve()
log_dir = SCRIPT_DIR / "logs"
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"organize_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-7s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler(log_file, encoding="utf-8", mode='w'),
        logging.StreamHandler()
    ]
)
log = logging.getLogger()

@dataclass
class Media:
    path: Path
    hash: str
    size: int
    dt: datetime
    make: str = ""
    model: str = ""
    keywords: Set[str] = field(default_factory=set)
    rating: int = 0
    width: int = 0
    height: int = 0
    is_raw: bool = False
    is_video: bool = False
    xmp: Optional[Path] = None
    paired: Optional[Path] = None
    correct_ext: str = ""

    def score(self) -> float:
        s = float(self.size)
        s += self.width * self.height * 5
        s += self.rating * 5_000_000
        s += len(self.keywords) * 100_000
        if self.is_raw:
            s *= 3.0
        return s

@dataclass
class OtherFile:
    path: Path
    hash: str
    size: int
    source_root: Path

    def score(self) -> float:
        return float(self.size)

@dataclass
class Config:
    sources: List[str]
    dest: str
    orphan_dest: str
    dupe_strategy: int
    dry_run: bool
    workers: int
    action_mode: str
    struct_mode: str
    rename_files: bool

def check_dependencies():
    try:
        subprocess.run(['exiftool', '-ver'], capture_output=True, check=True)
    except:
        print("ERROR: ExifTool not found! Install and add to PATH.")
        sys.exit(1)

def safe_filename(name: str) -> str:
    return "".join(c if c.isalnum() or c in (' ', '-', '_') else "_" for c in name).strip()

def sanitize_camera_str(s: str) -> str:
    if not s: return ""
    s = s.lower()
    s = re.sub(r'[^\w\d]+', '_', s)
    s = re.sub(r'([a-z])(\d)', r'\1_\2', s)
    s = re.sub(r'(\d)([a-z])', r'\1_\2', s)
    s = s.strip('_')
    return s[:30]

def print_phase(phase: str, message: str = ""):
    print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{Style.BRIGHT}  {phase}{Style.RESET_ALL}")
    if message: print(f"{Fore.WHITE}  {message}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")

def get_configuration() -> Config:
    try:
        print(f"\n{Fore.MAGENTA}{Style.BRIGHT}Deduplicate Pro v{__version__}{Style.RESET_ALL}\n")

        sources = []
        print(f"{Fore.YELLOW}1. Source Directories:{Style.RESET_ALL}")
        while True:
            src = input(f"{Fore.CYAN}   Add Path (Enter to finish): {Style.RESET_ALL}").strip()
            if not src: break
            if Path(src).exists():
                sources.append(src)
                print(f"{Fore.GREEN}     Added: {src}{Style.RESET_ALL}")
            else:
                print(f"{Fore.RED}     Not found: {src}{Style.RESET_ALL}")
        if not sources: sys.exit(1)

        print(f"\n{Fore.YELLOW}2. Action Mode:{Style.RESET_ALL}")
        print("   1. Copy (Safe)")
        print("   2. Move (Destructive)")
        print("   3. Rename Only (In-place)")
        act_in = input(f"{Fore.CYAN}   Choose [1]: {Style.RESET_ALL}").strip() or "1"
        action_mode = {'1': 'copy', '2': 'move', '3': 'rename_only'}.get(act_in, 'copy')

        dest = ""
        orphan_dest = ""
        struct_mode = "simple"
        dupe_strategy = 1

        if action_mode != 'rename_only':
            while True:
                dest = input(f"\n{Fore.CYAN}3. Destination: {Style.RESET_ALL}").strip()
                if dest: break
            orphan_dest = str(Path(dest) / "XMP_Orphans")

            print(f"\n{Fore.YELLOW}4. Structure:{Style.RESET_ALL}")
            print("   1. Simple (YYYY/MM)")
            print("   2. Advanced (Keywords/YYYY/MM)")
            struc_in = input(f"{Fore.CYAN}   Choose [1]: {Style.RESET_ALL}").strip() or "1"
            struct_mode = 'simple' if struc_in == '1' else 'keywords'

            print(f"\n{Fore.YELLOW}5. Duplicates:{Style.RESET_ALL}")
            print("   1. Separate folder")
            print("   2. Alongside")
            print("   3. Skip")
            strat_in = input(f"{Fore.CYAN}   Choose [1]: {Style.RESET_ALL}").strip() or "1"
            dupe_strategy = int(strat_in) if strat_in in ('1', '2', '3') else 1

        print(f"\n{Fore.YELLOW}6. Filenames:{Style.RESET_ALL}")
        print("   1. Rename (YYYY-MM-DD-HHmmss-Make-Model-Hash)")
        print("   2. Keep original")
        ren_in = input(f"{Fore.CYAN}   Choose [1]: {Style.RESET_ALL}").strip() or "1"
        rename_files = (ren_in == '1')

        dry_run = input(f"\n{Fore.CYAN}7. Dry Run? (y/N): {Style.RESET_ALL}").lower() == 'y'

        return Config(sources, dest, orphan_dest, dupe_strategy, dry_run, MAX_WORKERS,
                     action_mode, struct_mode, rename_files)
    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(0)

def get_metadata_single(path: Path, is_video: bool = False) -> dict:
    try:
        cmd = ['exiftool', '-j', '-G', '-q', '-FileType', '-DateTimeOriginal',
               '-CreateDate', '-QuickTime:CreationDate', '-Subject', '-Keywords',
               '-Rating', '-ImageWidth', '-ImageHeight', '-Make', '-Model']
        if not is_video: cmd.append('-fast2')
        cmd.append(str(path))

        res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8',
                           errors='replace', timeout=30)
        if res.returncode == 0 and res.stdout:
            return json.loads(res.stdout)[0]
    except: pass
    return {}

def extract_meta_and_hash(path: Path) -> Optional[Media]:
    try:
        ext = path.suffix.lower()
        is_video = ext in VID_EXTS
        is_raw = ext in RAW_EXTS

        h = hashlib.sha256()
        with open(path, "rb") as f:
            while chunk := f.read(4 * 1024 * 1024):
                h.update(chunk)
        file_hash = h.hexdigest()

        data = get_metadata_single(path, is_video)

        dt = datetime.fromtimestamp(path.stat().st_mtime)
        for tag in ['EXIF:DateTimeOriginal', 'XMP:DateTimeOriginal', 'QuickTime:CreationDate']:
            if val := data.get(tag):
                try:
                    clean_val = val.split('+')[0].replace('Z', '').strip()
                    dt = datetime.strptime(clean_val, "%Y:%m:%d %H:%M:%S")
                    break
                except ValueError: continue

        keywords = set()
        for tag in ['XMP:Subject', 'IPTC:Keywords', 'XMP:Keywords']:
            val = data.get(tag)
            if isinstance(val, list):
                keywords.update(str(v).strip() for v in val)
            elif isinstance(val, str):
                keywords.update(v.strip() for v in val.replace(';', ',').split(','))

        make = sanitize_camera_str(data.get('EXIF:Make', '') or data.get('Make', ''))
        model = sanitize_camera_str(data.get('EXIF:Model', '') or data.get('Model', ''))
        correct_ext = FILETYPE_TO_EXT.get(data.get('File:FileType', ''), ext)

        xmp_path = path.with_suffix('.xmp')
        if not xmp_path.exists(): xmp_path = Path(str(path) + ".xmp")

        return Media(path, file_hash, path.stat().st_size, dt, make, model,
                    {k for k in keywords if k}, int(data.get('XMP:Rating', 0) or 0),
                    int(data.get('EXIF:ImageWidth', 0) or 0), int(data.get('EXIF:ImageHeight', 0) or 0),
                    is_raw, is_video, xmp_path if xmp_path.exists() else None, None, correct_ext)
    except Exception as e:
        log.error(f"Error processing {path}: {e}")
        return None

def perform_file_action(src: Path, dest: Path, action: str, dry_run: bool):
    if dry_run: return
    dest.parent.mkdir(parents=True, exist_ok=True)
    if action == 'move': shutil.move(src, dest)
    else: shutil.copy2(src, dest)

def organize_media(groups: List[List[Media]], cfg: Config):
    dest_root = Path(cfg.dest) if cfg.dest else None
    used_destinations = set()

    for group in tqdm(groups, desc="Phase 4: Organizing"):
        winner = max(group, key=lambda x: x.score())
        f_ext = winner.correct_ext or winner.path.suffix.lower()

        if cfg.rename_files:
            parts = [winner.dt.strftime("%Y-%m-%d-%H%M%S")]
            if winner.make: parts.append(winner.make)
            if winner.model: parts.append(winner.model)
            parts.append(winner.hash[:8])
            f_name = "-".join(parts) + f_ext
        else:
            f_name = winner.path.name

        if cfg.action_mode == 'rename_only':
            target_dir = winner.path.parent
        else:
            year = winner.dt.strftime("%Y")
            month = winner.dt.strftime("%m")

            if cfg.struct_mode == 'simple':
                target_dir = dest_root / year / month
            else:
                if winner.keywords:
                    kw_folder = safe_filename("-".join(sorted(winner.keywords)[:4]))
                    target_dir = dest_root / "Keywords" / kw_folder / year / month
                else:
                    target_dir = dest_root / "No Keywords" / year / month

        target_path = target_dir / f_name
        counter = 1
        while target_path in used_destinations or (target_path.exists() and not cfg.dry_run):
            target_path = target_dir / f"{Path(f_name).stem}_dup{counter}{f_ext}"
            counter += 1
        used_destinations.add(target_path)

        if cfg.action_mode == 'rename_only':
            if winner.path != target_path and not cfg.dry_run:
                if not target_path.exists():
                    winner.path.rename(target_path)
                    if winner.xmp:
                        winner.xmp.rename(target_path.with_name(target_path.stem + ".xmp"))
        else:
            perform_file_action(winner.path, target_path, cfg.action_mode, cfg.dry_run)
            if winner.xmp:
                perform_file_action(winner.xmp, target_path.with_name(target_path.stem + ".xmp"),
                                  cfg.action_mode, cfg.dry_run)
            if winner.paired:
                pair_name = target_path.stem + winner.paired.suffix.lower()
                perform_file_action(winner.paired, target_dir / pair_name, cfg.action_mode, cfg.dry_run)

        duplicates = [m for m in group if m != winner]
        if duplicates and cfg.action_mode != 'rename_only' and cfg.dupe_strategy != 3:
            for i, dup in enumerate(duplicates, 1):
                dup_ext = dup.correct_ext or dup.path.suffix.lower()
                dup_name = f"{target_path.stem}_duplicate-{i}{dup_ext}"
                dup_dir = target_dir / "duplicates" if cfg.dupe_strategy == 1 else target_dir
                dup_dest = dup_dir / dup_name

                counter = 1
                while dup_dest in used_destinations or (dup_dest.exists() and not cfg.dry_run):
                    dup_dest = dup_dir / f"{target_path.stem}_duplicate-{i}-{counter}{dup_ext}"
                    counter += 1
                used_destinations.add(dup_dest)

                perform_file_action(dup.path, dup_dest, cfg.action_mode, cfg.dry_run)

def main():
    check_dependencies()
    cfg = get_configuration()

    log.info("="*50)
    log.info(f"MODE: {cfg.action_mode.upper()} | STRUCTURE: {cfg.struct_mode.upper()}")
    log.info(f"RENAME: {cfg.rename_files} | DRY RUN: {cfg.dry_run}")
    log.info("="*50)

    print_phase("Phase 1: Scanning")
    media_files = []
    for src in cfg.sources:
        for root, dirs, files in os.walk(src):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            root_p = Path(root)
            if cfg.dest and str(Path(cfg.dest).resolve()) in str(root_p.resolve()): continue
            for f in files:
                fp = root_p / f
                if fp.suffix.lower() in ALL_EXTS: media_files.append(fp)

    print_phase("Phase 2: Metadata & Hashing")
    media_list = []
    with ThreadPoolExecutor(max_workers=cfg.workers) as ex:
        futures = [ex.submit(extract_meta_and_hash, f) for f in media_files]
        for fut in tqdm(as_completed(futures), total=len(media_files)):
            if res := fut.result(): media_list.append(res)

    print_phase("Phase 3: Grouping")
    lookup = defaultdict(list)
    for m in media_list: lookup[(m.path.parent, m.path.stem)].append(m)
    for grp in lookup.values():
        if len(grp) >= 2:
            raw = next((x for x in grp if x.is_raw), None)
            jpg = next((x for x in grp if not x.is_raw and not x.is_video), None)
            if raw and jpg: raw.paired = jpg.path; jpg.paired = raw.path

    hash_map = defaultdict(list)
    for m in media_list: hash_map[m.hash].append(m)
    organize_media(list(hash_map.values()), cfg)

    if cfg.action_mode != 'rename_only':
        print_phase("Phase 5: XMP Orphans")
        dest_orph = Path(cfg.orphan_dest)
        for src in cfg.sources:
            for xmp in Path(src).rglob("*.xmp"):
                if not any((xmp.with_name(xmp.stem + ext)).exists() for ext in ALL_EXTS):
                    perform_file_action(xmp, dest_orph / xmp.name, cfg.action_mode, cfg.dry_run)

    print_phase("COMPLETE")
    print(f"Log: {log_file}")

if __name__ == "__main__":
    mp.freeze_support()
    main()
