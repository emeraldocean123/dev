# Home Directory Audit - November 19, 2025

Comprehensive audit of `~/` (home directory) to identify configuration files that can be version-controlled in the git repository.

## Current State

### Already Version-Controlled ✓

**AI Configuration Files:**
- `~/CLAUDE.md` → symlink to `~/Documents/git/dev/ai-configs/CLAUDE.md`
- `~/CODEX.md` → symlink to `~/Documents/git/dev/ai-configs/CODEX.md`
- `~/GEMINI.md` → symlink to `~/Documents/git/dev/ai-configs/GEMINI.md`
- `~/.claude/CLAUDE.md` → symlink to `~/Documents/git/dev/ai-configs/CLAUDE.md`
- `~/.gemini/GEMINI.md` → symlink to `~/Documents/git/dev/ai-configs/GEMINI.md`

**Shell Configuration:**
- `~/.bash_aliases` → symlink to `~/Documents/git/dev/configs/Shell/.bash_aliases`

### Candidates for Version Control

**HIGH PRIORITY - Shell Configs (Currently NOT symlinked):**
- `~/.bashrc` (3KB) - Bash shell configuration
- `~/.bash_profile` (96B) - Bash profile loader
- `~/.gitconfig` (142B) - Git global configuration

**MEDIUM PRIORITY - SSH Config:**
- `~/.ssh/config` (empty file, but should be version-controlled)
- Note: SSH keys should NOT be version-controlled (security risk)

**LOW PRIORITY - Application Configs:**
- `~/.config/fastfetch/config.jsonc` - Fastfetch configuration
- `~/.config/git/ignore` - Git global ignore patterns
- `~/.docker/config.json` - Docker configuration (may contain sensitive data)
- `~/.vscode/argv.json` - VSCode command-line arguments

### Should NOT Be Version-Controlled

**Security Sensitive:**
- `~/.ssh/id_ed25519_unified` (private SSH key)
- `~/.ssh/id_ed25519_unified.ppk` (private key in PuTTY format)
- `~/.claude/.credentials.json` (Claude credentials)
- `~/.gemini/oauth_creds.json` (Gemini OAuth credentials)
- `~/.codex/auth.json` (Codex authentication)

**Temporary/Generated:**
- `~/.bash_history` (command history)
- `~/.ps_history` (PowerShell history)
- `~/.ssh/known_hosts` (dynamic list of known SSH hosts)
- `~/.vscode/cli/tunnel-service.log` (log files)
- `~/.codex/history.jsonl` (Codex history)

**System Files:**
- `NTUSER.DAT` (Windows registry hive)
- `ntuser.dat.LOG*` (Windows registry transaction logs)

## Recommendations

### 1. Version Control Shell Configs

The following files should be moved to git repository and symlinked:

**Location:** `~/Documents/git/dev/shell-management/bash-configs/`

Files to version-control:
- `.bashrc` (currently 3KB, contains bash configuration)
- `.bash_profile` (currently 96B, contains profile loader)
- `.gitconfig` (currently 142B, contains git global settings)

**Action:**
```bash
# Create repository directory (already exists)
mkdir -p ~/Documents/git/dev/shell-management/bash-configs/

# Move files to repository
cp ~/.bashrc ~/Documents/git/dev/shell-management/bash-configs/.bashrc
cp ~/.bash_profile ~/Documents/git/dev/shell-management/bash-configs/.bash_profile
cp ~/.gitconfig ~/Documents/git/dev/shell-management/bash-configs/.gitconfig

# Create symlinks
rm -f ~/.bashrc ~/.bash_profile ~/.gitconfig
ln -s ~/Documents/git/dev/shell-management/bash-configs/.bashrc ~/.bashrc
ln -s ~/Documents/git/dev/shell-management/bash-configs/.bash_profile ~/.bash_profile
ln -s ~/Documents/git/dev/shell-management/bash-configs/.gitconfig ~/.gitconfig
```

**Note:** `.bashrc` and `.bash_profile` are currently NOT symlinked but should be for consistency.

### 2. Version Control SSH Config

**Location:** `~/Documents/git/dev/shell-management/ssh-configs/`

**Action:**
```bash
# SSH config already exists as empty file in repository
# Verify symlink exists
ls -la ~/.ssh/config
```

**Status:** ✓ Already done (symlink exists)

### 3. Version Control Application Configs

**Location:** `~/Documents/git/dev/configs/`

Create subfolders for different applications:
```
~/Documents/git/dev/configs/
├── fastfetch/
│   └── config.jsonc
├── git/
│   └── ignore
└── vscode/
    └── argv.json (if desired)
```

## Summary

### Current Symlink Status

| File | Status | Action Needed |
|------|--------|---------------|
| `~/CLAUDE.md` | ✓ Symlinked | None |
| `~/CODEX.md` | ✓ Symlinked | None |
| `~/GEMINI.md` | ✓ Symlinked | None |
| `~/.claude/CLAUDE.md` | ✓ Symlinked | None |
| `~/.gemini/GEMINI.md` | ✓ Symlinked | None |
| `~/.bash_aliases` | ✓ Symlinked | None |
| `~/.bashrc` | ✗ Regular File | **Convert to symlink** |
| `~/.bash_profile` | ✗ Regular File | **Convert to symlink** |
| `~/.gitconfig` | ✗ Regular File | **Convert to symlink** |
| `~/.ssh/config` | ✓ Symlinked | None |

### Next Steps

1. **High Priority:** Convert `.bashrc`, `.bash_profile`, and `.gitconfig` to symlinks
2. **Medium Priority:** Version control `~/.config/fastfetch/config.jsonc`
3. **Low Priority:** Consider version-controlling VSCode and Docker configs (check for sensitive data first)

## Notes

- **Backup First:** Always backup files before converting to symlinks
- **Test After:** Verify shells work correctly after symlinking
- **Security:** Never version-control private keys, credentials, or auth tokens
- **History Files:** Keep `.bash_history` and `.ps_history` local (not version-controlled)

## Folder Structure After Implementation

```
~/Documents/git/dev/
├── ai-configs/
│   ├── CLAUDE.md (source)
│   ├── CODEX.md (source)
│   └── GEMINI.md (source)
├── configs/
│   ├── fastfetch/
│   ├── git/
│   └── vscode/
└── shell-management/
    ├── bash-configs/
    │   ├── .bashrc (source)
    │   ├── .bash_profile (source)
    │   └── .gitconfig (source)
    └── ssh-configs/
        └── config (source)
```

All files in `~/` become symlinks pointing to repository sources.
