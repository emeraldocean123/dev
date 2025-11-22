#!/bin/bash
# Comprehensive Lint Check for ~/Documents/git folder
# Checks naming conventions, file organization, and encoding

set -euo pipefail

echo "========================================="
echo "  Git Folder Comprehensive Lint Check"
echo "========================================="
echo ""

cd ~/Documents/git

ISSUES=0
WARNINGS=0

# Check 1: Root folder organization
echo "=== Root Folder Check (~/Documents/git/) ==="
ROOT_FILES=$(find . -maxdepth 1 -type f ! -name ".gitignore" ! -name "lint-check.sh" 2>/dev/null || true)

if [[ -n "$ROOT_FILES" ]]; then
    echo "⚠️  Files found in root (should be in subdirectories):"
    echo "$ROOT_FILES" | while read -r file; do
        echo "    $file"
        ((WARNINGS++)) || true
    done
else
    echo "✅ Root folder clean (no loose files)"
fi

echo ""

# Check 2: Naming conventions (kebab-case)
echo "=== Naming Convention Check (kebab-case) ==="

NON_KEBAB=()
while IFS= read -r -d '' file; do
    basename=$(basename "$file")
    
    # Skip certain files
    [[ "$basename" == "README.md" ]] && continue
    [[ "$basename" == "CLAUDE.md" ]] && continue
    [[ "$basename" == ".gitignore" ]] && continue
    [[ "$basename" == *".PowerShell_profile.ps1" ]] && continue
    
    # Check if kebab-case
    if [[ ! "$basename" =~ ^[a-z0-9\-\.]+$ ]]; then
        NON_KEBAB+=("$file")
    fi
done < <(find . -type f ! -path "*/.git/*" -print0 2>/dev/null)

if [[ ${#NON_KEBAB[@]} -gt 0 ]]; then
    echo "⚠️  Non-kebab-case files found:"
    for file in "${NON_KEBAB[@]}"; do
        echo "    $file"
        ((WARNINGS++)) || true
    done
else
    echo "✅ All files follow kebab-case naming"
fi

echo ""

# Check 3: UTF-8 BOM for PowerShell 5 compatibility
echo "=== Encoding Check (UTF-8 BOM Requirements) ==="

cd dev 2>/dev/null && bash lib/check-file-encoding.sh || {
    echo "⚠️  Could not run encoding check in dev/"
    ((WARNINGS++)) || true
}
cd ~/Documents/git

echo ""

# Check 4: Git repository status
echo "=== Git Repository Status ==="

for repo in dev media-deduplicator; do
    if [[ -d "$repo/.git" ]]; then
        echo "Repository: $repo"
        cd "$repo"
        
        # Check for uncommitted changes
        if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
            echo "  ⚠️  Uncommitted changes detected"
            ((WARNINGS++)) || true
        else
            echo "  ✅ Clean working tree"
        fi
        
        # Check for unpushed commits
        UNPUSHED=$(git log --branches --not --remotes 2>/dev/null | wc -l)
        if [[ $UNPUSHED -gt 0 ]]; then
            echo "  ℹ️  $UNPUSHED unpushed commit(s)"
        fi
        
        cd ~/Documents/git
    else
        echo "⚠️  $repo is not a git repository"
        ((WARNINGS++)) || true
    fi
done

echo ""

# Summary
echo "========================================="
echo "  Lint Check Summary"
echo "========================================="
echo "Issues (Critical): $ISSUES"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ISSUES -eq 0 && $WARNINGS -eq 0 ]]; then
    echo "✅ All checks passed!"
    exit 0
elif [[ $ISSUES -eq 0 ]]; then
    echo "✅ No critical issues, but $WARNINGS warning(s) to review"
    exit 0
else
    echo "❌ Found $ISSUES critical issue(s)"
    exit 1
fi
