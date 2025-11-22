#!/usr/bin/env python3
"""
Media Tools Common Library
==========================
Version: 1.0.0

Shared utilities for all media processing tools:
- deduplicate-pro.py
- metadata-scrubber.py
- xmp-sidecar.py
- timestamp-sync.py

Usage:
    from media.tools.lib.media_common import *
"""

__version__ = "1.0.0"

import os
import sys
import logging
import subprocess
import json
import re
import multiprocessing as mp
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Set

# =============================================================================
# FILE EXTENSION CONSTANTS (Unified across all tools)
# =============================================================================

PHOTO_EXTENSIONS = {
    '.jpg', '.jpeg', '.png', '.tiff', '.tif', '.heic', '.heif',
    '.dng', '.cr2', '.cr3', '.nef', '.arw', '.orf', '.rw2', '.raw',
    '.avif', '.webp', '.jxl', '.raf', '.srw'
}

VIDEO_EXTENSIONS = {
    '.mp4', '.mov', '.avi', '.mkv', '.m4v', '.mpg', '.mpeg',
    '.wmv', '.flv', '.webm', '.3gp', '.mts', '.m2ts', '.hevc', '.ts'
}

RAW_EXTENSIONS = {
    '.arw', '.cr2', '.cr3', '.nef', '.orf', '.dng', '.rw2',
    '.raf', '.srw', '.raw'
}

ALL_MEDIA_EXTENSIONS = PHOTO_EXTENSIONS | VIDEO_EXTENSIONS

# ExifTool FileType to Extension Mapping
FILETYPE_TO_EXT = {
    'JPEG': '.jpg', 'PNG': '.png', 'HEIC': '.heic', 'HEIF': '.heif',
    'TIFF': '.tiff', 'WEBP': '.webp', 'AVIF': '.avif', 'JXL': '.jxl',
    'GIF': '.gif', 'BMP': '.bmp', 'XMP': '.xmp',
    'CR2': '.cr2', 'CR3': '.cr3', 'NEF': '.nef', 'ARW': '.arw',
    'ORF': '.orf', 'DNG': '.dng', 'RW2': '.rw2', 'RAF': '.raf',
    'SRW': '.srw', 'RAW': '.raw',
    'MOV': '.mov', 'MP4': '.mp4', 'AVI': '.avi', 'MKV': '.mkv',
    'M4V': '.m4v', 'WEBM': '.webm', 'MTS': '.mts', 'M2TS': '.m2ts',
    '3GP': '.3gp', 'MPG': '.mpg', 'MPEG': '.mpeg', 'HEVC': '.hevc',
    'TS': '.ts', 'WMV': '.wmv', 'FLV': '.flv',
}

# Folders to skip (Memory Protection)
SKIP_DIRS = {
    '.git', 'node_modules', 'venv', '.venv', '__pycache__', '.idea',
    '.vscode', 'AppData', 'Library', '.npm', '.cache', 'Cache', 'Caches',
    '.gradle', 'target', 'build', 'dist', '.tox', '.mypy_cache',
    '.pytest_cache', 'System Volume Information', '$RECYCLE.BIN'
}

# =============================================================================
# WORKER POOL MANAGEMENT (Performance optimization)
# =============================================================================

WORKER_PROFILES = {
    'conservative': {'workers': 2, 'desc': 'Low CPU (2 workers)'},
    'balanced': {'workers': max(4, mp.cpu_count() // 2), 'desc': f'Balanced ({max(4, mp.cpu_count() // 2)} workers)'},
    'fast': {'workers': max(1, mp.cpu_count() - 2), 'desc': f'Fast ({max(1, mp.cpu_count() - 2)} workers)'},
    'maximum': {'workers': mp.cpu_count(), 'desc': f'Maximum ({mp.cpu_count()} workers)'},
}

def get_optimal_workers() -> int:
    """Auto-detect optimal worker count based on CPU cores."""
    cores = mp.cpu_count()
    return max(2, cores - 2) if cores > 4 else max(1, cores - 1)

# =============================================================================
# LOGGING UTILITIES (Consistent logging across tools)
# =============================================================================

class FlushingFileHandler(logging.FileHandler):
    """File handler that flushes after every write for real-time logs."""
    def emit(self, record):
        super().emit(record)
        self.flush()

def setup_logging(tool_name: str, log_dir: Path) -> Path:
    """
    Setup standardized logging for media tools.

    Args:
        tool_name: Name of the tool (e.g., 'deduplicate', 'scrubber')
        log_dir: Directory to store logs

    Returns:
        Path to the log file
    """
    log_dir.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{tool_name}_{timestamp}.log"

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s | %(levelname)-7s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=[
            FlushingFileHandler(log_file, encoding="utf-8", mode='w'),
            logging.StreamHandler()
        ]
    )

    return log_file

# =============================================================================
# EXIFTOOL INTERFACE (Unified metadata access)
# =============================================================================

def check_exiftool() -> bool:
    """Verify ExifTool is installed and accessible."""
    try:
        subprocess.run(['exiftool', '-ver'], capture_output=True, check=True)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False

def get_exiftool_path() -> str:
    """Locate ExifTool executable (Windows + Unix)."""
    # Common Windows paths
    windows_paths = [
        r"D:\Files\Programs-Portable\ExifTool\exiftool.exe",
        r"C:\Windows\exiftool.exe",
        r"C:\Program Files\ExifTool\exiftool.exe"
    ]

    for p in windows_paths:
        if os.path.exists(p):
            return p

    # Fallback to PATH
    return "exiftool"

def get_metadata(file_path: Path, is_video: bool = False) -> Dict:
    """
    Extract metadata from a media file using ExifTool.

    Args:
        file_path: Path to media file
        is_video: Whether file is a video (disables -fast2 for full scan)

    Returns:
        Dictionary of metadata tags and values
    """
    try:
        cmd = [
            get_exiftool_path(),
            '-j', '-G', '-q',
            '-FileType', '-DateTimeOriginal', '-CreateDate',
            '-QuickTime:CreationDate', '-Subject', '-Keywords',
            '-Rating', '-ImageWidth', '-ImageHeight',
            '-Make', '-Model'
        ]

        if not is_video:
            cmd.append('-fast2')

        cmd.append(str(file_path))

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
            timeout=30
        )

        if result.returncode == 0 and result.stdout:
            return json.loads(result.stdout)[0]
    except Exception as e:
        logging.error(f"Failed to read metadata from {file_path}: {e}")

    return {}

# =============================================================================
# FILENAME UTILITIES (Sanitization and formatting)
# =============================================================================

def safe_filename(name: str, max_length: int = 255) -> str:
    """
    Sanitize filename for cross-platform compatibility.

    Args:
        name: Original filename
        max_length: Maximum filename length (default 255)

    Returns:
        Sanitized filename safe for all filesystems
    """
    # Remove/replace problematic characters
    name = "".join(c if c.isalnum() or c in (' ', '-', '_', '.') else "_" for c in name)
    # Remove leading/trailing whitespace and dots
    name = name.strip('. ')
    # Limit length
    return name[:max_length]

def sanitize_camera_str(s: str) -> str:
    """
    Sanitize camera make/model for filename use.
    Matches PowerShell naming convention.

    Args:
        s: Camera make or model string

    Returns:
        Sanitized string suitable for filenames

    Example:
        'Sony ILCE-7RM3' → 'sony_ilce_7_rm_3'
    """
    if not s:
        return ""

    s = s.lower()
    # Replace non-alphanumeric with underscore
    s = re.sub(r'[^\w\d]+', '_', s)
    # Add separator between letters and numbers
    s = re.sub(r'([a-z])(\d)', r'\1_\2', s)
    s = re.sub(r'(\d)([a-z])', r'\1_\2', s)
    # Clean up underscores
    s = s.strip('_')

    return s[:30]

# =============================================================================
# UI HELPERS (Colorized output for better UX)
# =============================================================================

try:
    from colorama import init, Fore, Style
    init(autoreset=True)
    COLORS_AVAILABLE = True
except ImportError:
    # Fallback if colorama not installed
    class Fore:
        GREEN = RED = YELLOW = CYAN = MAGENTA = BLUE = WHITE = ''
    class Style:
        BRIGHT = RESET_ALL = ''
    COLORS_AVAILABLE = False

def print_phase(phase: str, message: str = ""):
    """Print a section header with visual separation."""
    print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{Style.BRIGHT}  {phase}{Style.RESET_ALL}")
    if message:
        print(f"{Fore.WHITE}  {message}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")

def print_success(message: str):
    """Print success message in green."""
    print(f"{Fore.GREEN}✓ {message}{Style.RESET_ALL}")

def print_error(message: str):
    """Print error message in red."""
    print(f"{Fore.RED}✗ {message}{Style.RESET_ALL}")

def print_warning(message: str):
    """Print warning message in yellow."""
    print(f"{Fore.YELLOW}⚠ {message}{Style.RESET_ALL}")

# =============================================================================
# DEPENDENCY CHECKER
# =============================================================================

def check_dependencies() -> bool:
    """
    Verify all required dependencies are installed.

    Returns:
        True if all dependencies available, False otherwise
    """
    errors = []

    # Check ExifTool
    if not check_exiftool():
        errors.append("ExifTool not found - please install and add to PATH")

    # Check Python packages
    try:
        import tqdm
    except ImportError:
        errors.append("tqdm not installed - run: pip install tqdm")

    try:
        import colorama
    except ImportError:
        errors.append("colorama not installed - run: pip install colorama")

    if errors:
        for error in errors:
            print_error(error)
        return False

    return True

# =============================================================================
# MODULE INFO
# =============================================================================

def get_module_info():
    """Return module information for debugging."""
    return {
        'version': __version__,
        'photo_extensions': len(PHOTO_EXTENSIONS),
        'video_extensions': len(VIDEO_EXTENSIONS),
        'raw_extensions': len(RAW_EXTENSIONS),
        'skip_dirs': len(SKIP_DIRS),
        'optimal_workers': get_optimal_workers(),
        'exiftool_available': check_exiftool(),
        'colors_available': COLORS_AVAILABLE,
    }
