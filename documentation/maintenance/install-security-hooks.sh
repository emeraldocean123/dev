#!/bin/bash
# File: documentation/maintenance/install-security-hooks.sh
# Description: Installs a pre-commit hook to prevent committing sensitive IPs or MACs
# Usage: ./install-security-hooks.sh (run from repository root)

set -e

HOOK_PATH=".git/hooks/pre-commit"

echo ""
echo "🔒 Installing Security Pre-Commit Hook..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ ERROR: Not in a git repository root. Please run from repository root."
    exit 1
fi

# Create the pre-commit hook
cat > "$HOOK_PATH" << 'EOF'
#!/bin/bash
# Pre-commit security scan
# Prevents accidental commits of sensitive data

echo "🔍 Running security scan on staged changes..."

# 1. Check for Hardcoded IPs (192.168.x.x)
if git diff --cached --diff-filter=ACM | grep -E "[^0-9]192\.168\.[0-9]{1,3}\.[0-9]{1,3}[^0-9]" | grep -v "aa:bb:cc:dd:ee"; then
    echo ""
    echo "❌ SECURITY ERROR: Potential hardcoded local IP address detected in staged changes."
    echo ""
    echo "   Action Required:"
    echo "   1. Move sensitive IPs to .config/homelab.settings.json"
    echo "   2. Use placeholder values (e.g., 192.168.1.XXX) in documentation"
    echo "   3. Use --no-verify to bypass if this is intentional documentation"
    echo ""
    exit 1
fi

# 2. Check for Hardcoded MAC Addresses (excluding placeholders)
if git diff --cached --diff-filter=ACM | grep -iE "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})" | grep -v "aa:bb:cc:dd:ee" | grep -v "00:00:00:00:00:00" | grep -v "fingerprint"; then
    echo ""
    echo "❌ SECURITY ERROR: Potential real MAC address detected in staged changes."
    echo ""
    echo "   Action Required:"
    echo "   1. Replace with placeholder pattern (aa:bb:cc:dd:ee:XX)"
    echo "   2. Move real MACs to .config/homelab.settings.json"
    echo "   3. Use --no-verify to bypass if this is a PBS fingerprint or similar"
    echo ""
    exit 1
fi

# 3. Check for accidentally staged .config/homelab.settings.json
if git diff --cached --name-only | grep -q "^.config/homelab.settings.json$"; then
    echo ""
    echo "❌ SECURITY ERROR: Real configuration file is staged for commit!"
    echo ""
    echo "   This file contains secrets and should NEVER be committed."
    echo "   Run: git reset .config/homelab.settings.json"
    echo ""
    exit 1
fi

echo "✅ Security scan passed - no sensitive data detected"
exit 0
EOF

# Make the hook executable
chmod +x "$HOOK_PATH"

echo "✅ Security hook installed successfully!"
echo ""
echo "Location: $HOOK_PATH"
echo ""
echo "What this hook does:"
echo "  1. Scans staged changes for hardcoded IPs (192.168.x.x)"
echo "  2. Scans for real MAC addresses (excludes placeholders)"
echo "  3. Blocks commits of .config/homelab.settings.json"
echo ""
echo "To bypass (use with caution): git commit --no-verify"
echo ""
