#!/bin/bash
set -e

# =============================================================================
# Setup script to install git hooks for Retentio Frontend
# Run this once after cloning the repo: ./utils/setup-hooks.sh
# Re-run after utils/pre-commit changes to refresh the installed hook.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Delegate to utils/pre-commit so hook logic stays in one place.
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
set -e
REPO_ROOT="$(git rev-parse --show-toplevel)"
exec "$REPO_ROOT/utils/pre-commit"
EOF
chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ pre-commit hook installed (delegates to utils/pre-commit)"

echo ""
echo "Done. Hooks are installed in .git/hooks/"
echo "To skip hooks temporarily: git commit --no-verify"
