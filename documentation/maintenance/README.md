# Repository Maintenance & Hygiene Tools

This directory contains the "Engine Room" of the `dev` repository. These tools ensure cross-platform compatibility (Windows/Linux), enforce coding standards, and keep the repository clean.

## 🛠️ Core Tools

### 1. `lint-repository.ps1`
**Purpose:** Primary health check script for repository hygiene.

**Usage:**
```powershell
./lint-repository.ps1
```

**Checks:**
- ❌ **Hardcoded Paths:** Detects absolute paths like `C:\Users\josep` or `/home/josep` that break portability
- ❌ **CRLF in Bash:** Ensures `.sh` files use LF line endings (critical for Linux)
- ❌ **BOM in Bash:** Detects UTF-8 BOM headers that break Bash shebangs (`#!/bin/bash`)
- ❌ **Empty Directories:** Identifies stale folder structures

### 2. `fix-bash-line-endings.ps1`
**Purpose:** Automated repair tool for line ending issues.

**Usage:**
```powershell
./fix-bash-line-endings.ps1
```

**Action:** Recursively finds all `.sh` files and converts line endings from Windows (`\r\n`) to Linux (`\n`). Writes files as UTF-8 without BOM for maximum Linux compatibility.

### 3. `apply-standards.ps1`
**Purpose:** Standardizes PowerShell scripts with correct library imports and location headers.

**Usage:**
```powershell
./apply-standards.ps1
```

**Action:**
- Calculates correct relative paths to `lib/Utils.ps1`
- Injects import blocks where missing
- Updates `# Location:` headers to match actual file paths
- Skips scripts with `[CmdletBinding()]` to preserve parameter parsing

## 📂 Special Cases

### Proxmox Automation (`infrastructure/proxmox/`)
Scripts for LXC and Proxmox management.

**Requirement:** Must always use **LF** line endings
**Validation:** Verified by `lint-repository.ps1`

### Shell Utilities (`shell-management/utils/`)
**Special Case - winfetch.ps1:**
- This file **MUST** be saved with **UTF-8 with BOM** encoding
- Required for legacy PowerShell 5.1 Unicode character support
- PowerShell 7 handles both, but PS5 needs the BOM

## 🔄 Maintenance Workflow

### Pre-Commit Checks (Recommended)
```powershell
cd ~/Documents/git/dev
./documentation/maintenance/lint-repository.ps1
```

If issues are found:
```powershell
# Fix bash line endings
./documentation/maintenance/fix-bash-line-endings.ps1

# Re-check
./documentation/maintenance/lint-repository.ps1
```

### Manual Standardization
Run after adding new PowerShell scripts:
```powershell
./documentation/maintenance/apply-standards.ps1
```

## 📋 Maintenance Schedule

**Before Every Commit:**
- Run `lint-repository.ps1` to catch cross-platform issues

**Weekly:**
- Review audit output for new hardcoded paths
- Check for empty directories from file moves

**After Repository Reorganization:**
- Run `apply-standards.ps1` to fix location headers
- Run `lint-repository.ps1` to verify all paths are correct

## 🐛 Troubleshooting

### "Could not read" warnings for `.sh` files
**Cause:** PowerShell's `Get-Content -Raw` may fail on files with certain line endings
**Solution:** This is expected behavior - the script still checks what it can read

### Hardcoded paths in documentation
**Expected:** Documentation files (`*.md`) often contain environment-specific paths for installation guides
**Action:** Only fix hardcoded paths in executable scripts (`.ps1`, `.sh`, `.py`)

### winfetch.ps1 breaks in PowerShell 5
**Symptom:** Unicode box-drawing characters display incorrectly or cause parse errors
**Solution:** Ensure file is saved with UTF-8 with BOM encoding:
```powershell
$content = Get-Content winfetch.ps1 -Raw
$utf8BOM = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText('winfetch.ps1', $content, $utf8BOM)
```

## 🔗 Related Documentation

- Repository organization: `../audits/`
- Bash scripts for Proxmox: `../../infrastructure/proxmox/`
- Shell configuration: `../../shell-management/`
