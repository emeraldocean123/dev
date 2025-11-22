#!/usr/bin/env python3
"""
AI Config Synchronizer
======================
Syncs shared documentation from CLAUDE.md (master) to other AI config files,
while preserving each file's unique header and configuration section.

Structure: [Header] -> [Config Section] -> [Shared Environment Docs]
"""

import re
from pathlib import Path

# Configuration
BASE_DIR = Path(__file__).parent.resolve()
MASTER_FILE = BASE_DIR / "CLAUDE.md"
TARGETS = [BASE_DIR / "CODEX.md", BASE_DIR / "GEMINI.md", BASE_DIR / "AGENTS.md"]

# Marker where shared content begins
SHARED_START = "## Environment Overview"

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def get_shared_content(content):
    """Extract shared documentation starting from Environment Overview."""
    if SHARED_START not in content:
        raise ValueError(f"Master file missing '{SHARED_START}'")

    # Get everything from Environment Overview onwards
    idx = content.index(SHARED_START)
    return content[idx:]

def get_unique_prefix(content):
    """Extract the unique header and config section (everything before shared content)."""
    if SHARED_START not in content:
        # No shared content marker, return first 10 lines as fallback
        return "\n".join(content.splitlines()[:10])

    idx = content.index(SHARED_START)
    prefix = content[:idx].rstrip()
    return prefix

def main():
    print(f"Syncing AI Configs from master: {MASTER_FILE.name}")

    if not MASTER_FILE.exists():
        print(f"Error: Master file not found at {MASTER_FILE}")
        return

    master_content = read_file(MASTER_FILE)
    shared_content = get_shared_content(master_content)

    for target in TARGETS:
        if not target.exists():
            print(f"Skipping missing target: {target.name}")
            continue

        print(f"  -> Updating {target.name}...")

        # Get target's unique prefix (header + config)
        target_content = read_file(target)
        unique_prefix = get_unique_prefix(target_content)

        # Assemble: Unique Prefix + Shared Content
        new_content = f"{unique_prefix}\n\n{shared_content}"

        write_file(target, new_content)
        print(f"     Synced")

    print("Done!")

if __name__ == "__main__":
    main()
