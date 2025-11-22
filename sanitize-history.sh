#!/bin/bash
# Repository History Sanitization Script
# WARNING: This will DELETE your entire commit history to remove secrets

set -e

REPO_PATH="$PWD"
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_PATH="../dev-history-backup-$DATE"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Repository History Sanitization"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "WARNING: This will PERMANENTLY delete your commit history!"
echo "   (A backup will be created at: $BACKUP_PATH)"
echo ""

# Step 1: Backup current .git history
echo ""
echo "Step 1/5: Creating backup of current .git history..."
if [ -d ".git" ]; then
    cp -r .git "$BACKUP_PATH"
    echo "  ✓ Backup created: $BACKUP_PATH"
else
    echo "  ! No .git folder found - nothing to backup"
fi

# Step 2: Remove old Git history
echo ""
echo "Step 2/5: Removing old Git history (where secrets hide)..."
if [ -d ".git" ]; then
    rm -rf .git
    echo "  ✓ Old history deleted"
fi

# Step 3: Re-initialize repository
echo ""
echo "Step 3/5: Re-initializing repository with 'main' branch..."
git init -b main > /dev/null 2>&1
echo "  ✓ Fresh repository initialized"

# Step 4: Stage all sanitized files
echo ""
echo "Step 4/5: Staging all sanitized files..."
git add .
STAGED_COUNT=$(git diff --cached --name-only | wc -l)
echo "  ✓ Staged $STAGED_COUNT files"

# Step 5: Create clean initial commit
echo ""
echo "Step 5/5: Creating clean initial commit..."
git commit -m "feat: initial release of sanitized homelab platform (v2.2)

Production-ready infrastructure management platform with:
- Externalized configuration architecture (zero hardcoded secrets)
- 3-tier automated backup system (PBS, ZFS, Synology)
- Config-driven deployment scripts (PowerShell + Bash)
- Media processing tools (Immich, Mylio, video conversion)
- Network infrastructure automation (VPN, WoL, diagnostics)

This is a clean-slate commit with all sensitive data removed.
Previous commit history has been sanitized for security.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" > /dev/null 2>&1
echo "  ✓ Initial commit created"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✓ HISTORY SANITIZED SUCCESSFULLY!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next Steps:"
echo ""
echo "1. Verify the clean state:"
echo "   git log --oneline"
echo ""
echo "2. Re-connect to GitHub remote:"
echo "   git remote add origin https://github.com/emeraldocean123/dev.git"
echo ""
echo "3. Force push (⚠️ OVERWRITES remote history):"
echo "   git push -u origin main --force"
echo ""
echo "⚠️  Important Notes:"
echo "   - The force push is IRREVERSIBLE"
echo "   - Old commits with secrets will be permanently deleted from GitHub"
echo "   - Backup location: $BACKUP_PATH"
echo ""
