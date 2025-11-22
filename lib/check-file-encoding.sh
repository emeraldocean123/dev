#!/bin/bash
# Encoding Check Script
# Verifies UTF-8 BOM requirements for PowerShell scripts

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "Checking file encodings in dev repository..."
echo ""

# Track issues
ISSUES=0

# Files that explicitly require UTF-8 with BOM (PowerShell 5 compatibility)
BOM_REQUIRED_FILES=(
    "shell-management/utils/winfetch.ps1"
)

echo "=== Critical: Files Requiring UTF-8 with BOM ==="
for file in "${BOM_REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ MISSING: $file"
        ((ISSUES++))
        continue
    fi
    
    encoding=$(file -b "$file")
    if [[ "$encoding" == *"UTF-8 (with BOM)"* ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (Current: $encoding)"
        echo "   Fix: Must be UTF-8 with BOM for PowerShell 5 compatibility"
        ((ISSUES++))
    fi
done

echo ""
echo "=== Checking for Problematic Encodings ==="

WARNED=0

# Check all .ps1 files for incompatible encodings
while IFS= read -r -d '' file; do
    encoding=$(file -b "$file")
    
    # UTF-16 is problematic for cross-platform scripts
    if [[ "$encoding" == *"UTF-16"* ]]; then
        echo "❌ $file: UTF-16 encoding detected (should be UTF-8)"
        ((ISSUES++))
    fi
    
    # ISO-8859 can cause issues with special characters
    if [[ "$encoding" == *"ISO-8859"* ]]; then
        echo "⚠️  $file: ISO-8859 encoding (recommend UTF-8)"
        ((WARNED++))
    fi
done < <(find . -name "*.ps1" -type f -print0 | grep -zv ".git")

echo ""
if [[ $ISSUES -eq 0 ]]; then
    echo "✅ All critical encoding checks passed!"
    if [[ $WARNED -gt 0 ]]; then
        echo "⚠️  $WARNED warning(s) - non-critical but should be reviewed"
    fi
    exit 0
else
    echo "❌ Found $ISSUES critical encoding issue(s)"
    if [[ $WARNED -gt 0 ]]; then
        echo "⚠️  Plus $WARNED warning(s)"
    fi
    exit 1
fi
