#!/bin/bash

# =============================================================================
# Setup script to install git hooks for WordUpX
# Run this once after cloning the repo: ./utils/scripts/setup-hooks.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Copy pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ pre-commit hook installed"

# Copy pre-push hook
cp "$SCRIPT_DIR/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"
echo "✓ pre-push hook installed"

echo ""
echo "Done. Hooks are installed in .git/hooks/"
echo "To skip hooks temporarily: git commit --no-verify / git push --no-verify"
