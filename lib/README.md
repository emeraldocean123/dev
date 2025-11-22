# Shared Utilities Library

Centralized library of common functions used across homelab scripts to reduce code duplication and ensure consistency.

## Files

### Utils.ps1

Shared PowerShell utilities for all homelab management scripts.

**Functions:**

- **Write-Console** - Cross-platform colored console output
  ```powershell
  Write-Console "Success!" -ForegroundColor Green
  Write-Console "Error occurred" -ForegroundColor Red
  Write-Console "Processing..." -ForegroundColor Yellow -NoNewline
  ```

- **Assert-Admin** - Ensure script runs with Administrator privileges
  ```powershell
  Assert-Admin  # Exits if not running as Admin
  ```

- **Test-CommandExists** - Check if command is available
  ```powershell
  if (Test-CommandExists 'git') {
      Write-Console "Git is installed" -ForegroundColor Green
  }
  ```

- **Backup-File** - Create timestamped file backups
  ```powershell
  Backup-File -FilePath "C:\config.json"
  # Creates: C:\config.json.backup.20251118-223000
  ```

## Usage

To use these utilities in your scripts:

```powershell
# Method 1: Dot source (simple scripts)
. "$PSScriptRoot\..\lib\Utils.ps1"

# Method 2: Import as module (advanced scripts)
Import-Module "$PSScriptRoot\..\lib\Utils.ps1" -Force

# Method 3: Auto-discover (for nested scripts)
$utilsPath = Get-ChildItem -Path $PSScriptRoot\..\ -Recurse -Filter "Utils.ps1" | Select-Object -First 1
if ($utilsPath) { . $utilsPath.FullName }
```

## Benefits

- **Reduced Code Duplication**: ~20 lines of `Write-Console` logic removed from each script
- **Consistency**: All scripts use the same logging format
- **Maintainability**: Change logging format once, applies everywhere
- **Error Handling**: Centralized error handling and fallbacks
- **Type Safety**: Proper parameter validation and type checking

## Migration

Scripts previously defining their own `Write-Console` function have been updated to use this shared library. Old implementations removed to reduce codebase bloat.

**Before:**
```powershell
# 20+ lines of Write-Console function definition
# ... rest of script
```

**After:**
```powershell
. "$PSScriptRoot\..\lib\Utils.ps1"
# ... rest of script
```

## Naming Convention

All shared utilities follow kebab-case for file names and PascalCase for function names (PowerShell convention).
