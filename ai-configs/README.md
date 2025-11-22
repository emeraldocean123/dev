# AI Assistant Configuration Files

Version-controlled configuration files for various AI coding assistants.

## Files

- **CLAUDE.md** - Configuration for Claude Code (Anthropic)
- **CODEX.md** - Configuration for GitHub Copilot/Codex
- **GEMINI.md** - Configuration for Google Gemini

## Setup

These files are symlinked from multiple locations to this repository:

**Home Directory:**
```
~/CLAUDE.md  -> ~/Documents/git/dev/ai-configs/CLAUDE.md
~/CODEX.md   -> ~/Documents/git/dev/ai-configs/CODEX.md
~/GEMINI.md  -> ~/Documents/git/dev/ai-configs/GEMINI.md
```

**AI Assistant Config Folders:**
```
~/.claude/CLAUDE.md  -> ~/Documents/git/dev/ai-configs/CLAUDE.md
~/.gemini/GEMINI.md  -> ~/Documents/git/dev/ai-configs/GEMINI.md
```

**Last Synchronized:** November 19, 2025

## Purpose

Version controlling AI assistant configurations allows:
- **History tracking** - See how configurations evolve over time
- **Sync across machines** - Same AI behavior on different systems
- **Backup** - Never lose important AI customizations
- **Experimentation** - Try changes and revert if needed

## Usage

Edit files in this directory (not the symlinks in home directory). Changes are:
1. Tracked in git
2. Immediately available to AI assistants (through symlinks)
3. Synced across any system with this repository

## Location

- **Repository**: `~/Documents/git/dev/ai-configs/`
- **Symlinks**: `~/` (home directory)
- **Category**: ai-configs
