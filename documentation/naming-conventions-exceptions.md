# Naming Conventions - Acceptable Exceptions

**Last Updated:** November 19, 2025

## Standard Convention

All files in the repository use **kebab-case** naming:
- All lowercase letters
- Words separated by hyphens (-)
- Acronyms lowercase: hdr, pbs, lxc, usb, vpn
- Dates in YYYY-MM-DD format

**Examples:**
- ✅ `check-caldigit.ps1` (kebab-case)
- ✅ `backup-audit-2025-10-19.md` (kebab-case with date)
- ✅ `convert-hdr-to-sdr.ps1` (kebab-case with acronym)

## Acceptable Exceptions

The following file types are exempt from kebab-case requirements for legitimate reasons:

### 1. System and Convention Files

**Pattern:** Standard naming conventions from tools/platforms
- `README.md` - Universal documentation standard
- `CLAUDE.md` - Claude Code configuration file
- `.gitignore` - Git standard
- `.markdownlintignore` - Linter configuration

**Reason:** These files have established naming conventions that should not be changed.

### 2. Configuration Files

**Pattern:** `*.json`, `*.jsonc`, `config.*`
- `settings.local.json`
- `config.jsonc`
- `daemon.json`
- `package.json`

**Reason:** Configuration files often use camelCase or dot notation based on the tool's requirements. Changing them may break integrations.

### 3. Documentation with Proper Nouns

**Pattern:** Markdown files containing brand/product names
- `CODEX.md` - AI service name
- `GEMINI.md` - AI service name
- `DigiKam-*` - Product name (proper noun)
- `XNView-*` - Product name (proper noun)

**Reason:** Proper nouns and brand names maintain their original capitalization for clarity and recognition.

### 4. Log Files with Timestamps

**Pattern:** `*-YYYYMMDD-HHMMSS.log`, `*-YYYY-MM-DD.txt`
- `backup-rename-20251115-000252.log`
- `xmp-sanitization-20251114-182240.log`
- `powershell-lint-20251116-130144.txt`

**Reason:** Log files with timestamps use numeric date formats for sortability. The base filename follows kebab-case, but the timestamp portion uses compact formats.

### 5. Archive Files

**Pattern:** `*.zip`, generated artifacts
- `dev-repo.zip` - Generated build artifact (should be in .gitignore)

**Reason:** Generated files that should be excluded from version control anyway.

### 6. Python Files with Underscores

**Pattern:** `*_*.py`
- `test_config.py`
- `mylio_db_tool.py`
- `sync_timestamps.py`

**Reason:** Python convention uses snake_case for module names. This is the standard for Python ecosystem.

### 7. Special System Files

**Pattern:** System-specific file names
- `Microsoft.PowerShell_profile.ps1` - PowerShell system file

**Reason:** Must match exact system expectations for automatic loading.

## Non-Exceptions (Should be Fixed)

These patterns appear in the repository but should eventually conform to kebab-case:

### Documentation Files
- Markdown files without proper nouns should use kebab-case
- Example: `setup-automated-backup.md` (correct) vs `Setup-Automated-Backup.md` (should be fixed)

### Script Files
- All `.ps1` and `.sh` files should strictly use kebab-case
- Example: `check-caldigit.ps1` (correct) vs `Check-Caldigit.ps1` (should be fixed)

## Lint Check Integration

The lint check script (`dev/documentation/maintenance/lint-check.sh`) automatically identifies non-kebab-case files. When reviewing results:

1. **Check against this exception list first**
2. **If file matches an exception pattern → Acceptable, no action needed**
3. **If file doesn't match → Consider renaming or adding to exceptions**

## Adding New Exceptions

Before adding a new exception:

1. **Question:** Can this file be renamed to kebab-case without breaking functionality?
2. **Question:** Is this a universal standard (like README.md)?
3. **Question:** Would renaming harm clarity (like proper nouns)?

If all answers are "no", the file should be renamed. Only add exceptions when technically necessary or when clarity demands it.

## Future Improvements

- Automated exception validation in lint script
- Pre-commit hooks to enforce naming on new files
- Gradual migration of legacy files that don't fit exceptions
