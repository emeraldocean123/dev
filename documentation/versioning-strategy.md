# Script Versioning Strategy

## Version Number Format

**Semantic Versioning**: `MAJOR.MINOR.PATCH`

Example: `v2.3.1`

- **MAJOR**: Breaking changes (incompatible with previous versions)
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes, performance improvements

## Implementation Methods

### Method 1: In-File Version Header (Recommended)
```python
#!/usr/bin/env python3
"""
Script Name: Photo Deduplication
Version: 2.1.0
Date: 2025-11-18
Author: [Your Name]

Changelog:
  v2.1.0 (2025-11-18) - Fixed O(n²) grouping bug, added phase labels
  v2.0.0 (2025-11-18) - Added interactive mode, perceptual hashing
  v1.0.0 (2025-11-18) - Initial release
"""

__version__ = "2.1.0"
```

**Benefits:**
- Version travels with the script
- No filename clutter
- Git can track version history
- Easy to query: `python script.py --version`

### Method 2: Git Tags (Best for GitHub)
```bash
git tag -a v2.1.0 -m "Fixed O(n²) grouping bug"
git push origin v2.1.0
```

**Benefits:**
- GitHub releases page
- Download specific versions
- Automated changelog
- No manual file management

### Method 3: Hybrid (Recommended for You!)
- **In-file version header** for quick reference
- **Git tags** for releases
- **Single filename** (no version in name)

## File Naming Convention

### ❌ OLD WAY (What you had):
```
deduplicate-and-organize.py
deduplicate-and-organize-v2.py
deduplicate-and-organize-FINAL.py
deduplicate-interactive.py
```

### ✅ NEW WAY:
```
deduplicate-photos.py  (v2.1.0 in header)
```

**Git history shows all versions:**
```bash
git log --oneline deduplicate-photos.py
v2.1.0 Fixed grouping algorithm
v2.0.0 Added interactive mode
v1.0.0 Initial release
```

## Standard Header Template

### Python Scripts
```python
#!/usr/bin/env python3
"""
[Script Name]
Version: [MAJOR.MINOR.PATCH]
Date: [YYYY-MM-DD]
Author: [Your Name]

Description:
    [One-line description]

Requirements:
    - Python 3.10+
    - pip install -r requirements.txt

Usage:
    python [script-name].py [args]

Changelog:
    v2.1.0 (2025-11-18) - [Description of changes]
    v2.0.0 (2025-11-18) - [Description of changes]
    v1.0.0 (2025-11-18) - [Initial release]
"""

__version__ = "2.1.0"
__author__ = "[Your Name]"
__date__ = "2025-11-18"
```

### PowerShell Scripts
```powershell
<#
.SYNOPSIS
    [One-line description]

.DESCRIPTION
    [Detailed description]

.PARAMETER [ParamName]
    [Description]

.EXAMPLE
    .\script-name.ps1 -Param Value

.NOTES
    Version:    2.1.0
    Date:       2025-11-18
    Author:     [Your Name]

    Changelog:
        v2.1.0 (2025-11-18) - [Description]
        v2.0.0 (2025-11-18) - [Description]
        v1.0.0 (2025-11-18) - [Initial release]
#>

[CmdletBinding()]
param()

$Version = "2.1.0"
```

### Bash Scripts
```bash
#!/bin/bash
#
# Script: [name]
# Version: 2.1.0
# Date: 2025-11-18
# Author: [Your Name]
#
# Description:
#   [One-line description]
#
# Usage:
#   ./script-name.sh [args]
#
# Changelog:
#   v2.1.0 (2025-11-18) - [Description]
#   v2.0.0 (2025-11-18) - [Description]
#   v1.0.0 (2025-11-18) - [Initial release]

VERSION="2.1.0"
```

## GitHub Repository Structure

```
joseph-follett-scripts/
├── README.md
├── LICENSE
├── .gitignore
│
├── network/
│   ├── README.md
│   ├── network-status.ps1           (v1.2.3)
│   └── test-connectivity.ps1        (v1.0.0)
│
├── photos/
│   ├── README.md
│   ├── deduplicate-photos.py        (v2.1.0)
│   ├── requirements.txt
│   └── video-processing/
│       └── convert-hdr-to-sdr.ps1   (v1.1.0)
│
├── hardware/
│   ├── README.md
│   ├── check-caldigit.ps1           (v2.0.1)
│   └── test-bluetooth.ps1           (v1.0.0)
│
├── proxmox/
│   ├── README.md
│   ├── lxc-setup.sh                 (v3.0.0)
│   ├── lxc-utils.sh                 (v2.1.0)
│   └── proxmox-setup-repos.sh       (v1.5.0)
│
└── backup/
    ├── README.md
    ├── zfs-replicate-pbs.sh         (v2.2.0)
    └── services/
        └── synology-auto-backup.service
```

## Version Increment Rules

### When to Bump MAJOR (x.0.0):
- Breaking changes to script arguments
- Removed features
- Incompatible with previous versions
- Example: Changed from positional args to flags

### When to Bump MINOR (0.x.0):
- New features added
- New command-line options (backward compatible)
- Performance improvements (like your O(n²) fix)
- Example: Added interactive mode

### When to Bump PATCH (0.0.x):
- Bug fixes
- Documentation updates
- Code cleanup (no functional changes)
- Example: Fixed UTF-8 encoding bug

## Git Workflow

### Initial Setup
```bash
cd ~/Documents/dev
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo, then:
git remote add origin https://github.com/yourusername/scripts.git
git push -u origin main
```

### Making Changes
```bash
# 1. Make your changes
# 2. Update version in script header
# 3. Update changelog in header
# 4. Commit
git add deduplicate-photos.py
git commit -m "v2.1.0: Fixed O(n²) grouping algorithm"

# 5. Tag the release
git tag -a v2.1.0 -m "Performance fix: 27,500x faster grouping"
git push origin main --tags
```

### GitHub Releases
After pushing tags, create releases on GitHub:
1. Go to repository → Releases → Create new release
2. Select tag (v2.1.0)
3. Add release notes (copy from changelog)
4. Attach any binaries/docs
5. Publish

## Example: Your Current Photo Script

### Current State (Messy):
```
deduplicate-and-organize.py        (v1.0?)
deduplicate-and-organize-v2.py     (v2.0?)
deduplicate-and-organize-FINAL.py  (v2.0.1?)
deduplicate-interactive.py         (v2.1.0?)
```

### Clean State (After versioning):
```
deduplicate-photos.py              (v2.1.0)
```

**Git history:**
```
v2.1.0 - Fixed O(n²) algorithm, added phase labels
v2.0.0 - Added interactive mode, perceptual hashing
v1.0.0 - Initial release
```

## Implementing This Strategy

### Step 1: Clean Up Current Scripts
1. Choose best version (Interactive = v2.1.0)
2. Rename to canonical name (deduplicate-photos.py)
3. Add version header
4. Archive old versions

### Step 2: Set Up Git Repo
1. Initialize git in ~/Documents/dev
2. Create .gitignore
3. Initial commit with all current scripts
4. Tag current versions

### Step 3: Create GitHub Repo
1. Create repo on GitHub
2. Push local repo
3. Create initial releases for all scripts

### Step 4: Document Everything
1. Main README.md (overview of all scripts)
2. Per-category READMEs (network/, photos/, etc.)
3. Usage examples
4. Installation instructions

## Benefits

✅ **Single source of truth** - One file, many versions in git
✅ **Easy rollback** - `git checkout v2.0.0`
✅ **Clear history** - See what changed when
✅ **Professional** - Industry standard versioning
✅ **Shareable** - Others can use your scripts
✅ **Backup** - GitHub = cloud backup

## Next Steps (After Photo Script Finishes)

1. Create versioning plan for all scripts
2. Set up git repository structure
3. Add version headers to all scripts
4. Create GitHub repository
5. Write documentation
6. Tag initial releases

Sound good?
