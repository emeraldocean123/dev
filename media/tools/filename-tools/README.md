# Filename Tools

Photo filename correction utilities.

## Purpose

Fixes problematic photo filenames (special chars, spaces, date formats).

## Scripts

- **fix-filenames.ps1** - Adds separators to date-based filenames (YYYYMMDD -> YYYY-MM-DD)
- **replace-spaces-with-hyphens.ps1** - Replaces spaces in filenames with hyphens

## Usage

```powershell
.\fix-filenames.ps1 [directory]
.\replace-spaces-with-hyphens.ps1 -Path "D:\Photos" -Recurse -WhatIf
```

## Location

**Path:** `~/Documents/dev/photos/filename-tools`
**Category:** `photos`
