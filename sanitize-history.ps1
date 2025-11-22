# sanitize-history.ps1
# Repository History Sanitization Script
#
# ⚠️ WARNING: This will DELETE your entire commit history to remove secrets.
# This is the "nuclear option" - it resets your repo to "Day 1" but keeps all current code.
#
# What this does:
# 1. Backs up current .git history (safety net)
# 2. Deletes the .git folder (removes all commit history)
# 3. Re-initializes as a fresh repository
# 4. Creates a single clean "Initial Release" commit
#
# After running this:
# - You'll need to force push to GitHub
# - All old commits (with hardcoded secrets) will be gone
# - You'll have a clean history starting today

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoPath = Get-Location
$date = Get-Date -Format "yyyy-MM-dd-HHmmss"
$backupPath = Join-Path $repoPath.Parent.FullName "dev-history-backup-$date"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Repository History Sanitization" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This will PERMANENTLY delete your commit history!" -ForegroundColor Yellow
Write-Host "   (A backup will be created at: $backupPath)" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Type 'SANITIZE' to proceed (or Ctrl+C to cancel)"

if ($confirmation -ne "SANITIZE") {
    Write-Host "❌ Cancelled. No changes made." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 1/5: Creating backup of current .git history..." -ForegroundColor Cyan
try {
    $gitPath = Join-Path $repoPath ".git"
    if (Test-Path $gitPath) {
        Copy-Item -Path $gitPath -Destination $backupPath -Recurse -Force
        Write-Host "  ✅ Backup created: $backupPath" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No .git folder found - nothing to backup" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Backup failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2/5: Removing old Git history (where secrets hide)..." -ForegroundColor Yellow
try {
    if (Test-Path $gitPath) {
        Remove-Item -Path $gitPath -Recurse -Force
        Write-Host "  ✅ Old history deleted" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ Failed to delete .git: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3/5: Re-initializing repository with 'main' branch..." -ForegroundColor Cyan
try {
    git init -b main | Out-Null
    Write-Host "  ✅ Fresh repository initialized" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Git init failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 4/5: Staging all sanitized files..." -ForegroundColor Cyan
try {
    git add .
    $stagedFiles = (git diff --cached --name-only).Count
    Write-Host "  ✅ Staged $stagedFiles files" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Git add failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 5/5: Creating clean initial commit..." -ForegroundColor Cyan
try {
    $commitMessage = @"
feat: initial release of sanitized homelab platform (v2.2)

Production-ready infrastructure management platform with:
- Externalized configuration architecture (zero hardcoded secrets)
- 3-tier automated backup system (PBS, ZFS, Synology)
- Config-driven deployment scripts (PowerShell + Bash)
- Media processing tools (Immich, Mylio, video conversion)
- Network infrastructure automation (VPN, WoL, diagnostics)

This is a clean-slate commit with all sensitive data removed.
Previous commit history has been sanitized for security.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
"@

    git commit -m $commitMessage | Out-Null
    Write-Host "  ✅ Initial commit created" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Git commit failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ HISTORY SANITIZED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Verify the clean state:" -ForegroundColor White
Write-Host "   git log --oneline" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Re-connect to GitHub remote:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/emeraldocean123/dev.git" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Force push (⚠️  OVERWRITES remote history):" -ForegroundColor White
Write-Host "   git push -u origin main --force" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "   - The force push is IRREVERSIBLE" -ForegroundColor Yellow
Write-Host "   - Old commits with secrets will be permanently deleted from GitHub" -ForegroundColor Yellow
Write-Host "   - Backup location: $backupPath" -ForegroundColor Yellow
Write-Host ""
