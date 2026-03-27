#!/bin/bash

# =============================================================================
# Standalone script to run the same checks as the pre-commit hook.
# Run from repo root: ./utils/run-pre-commit-checks.sh
# Use this to verify everything before committing without doing a commit.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ ! -f "$REPO_ROOT/pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found at repo root $REPO_ROOT${NC}"
    exit 1
fi

echo "🔍 Running pre-commit checks (standalone)..."
echo "   Repo root: $REPO_ROOT"
echo ""

FAILED=0

# -----------------------------------------------------------------------------
# Dart format (run first so analyze/tests see formatted code)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Dart format ━━━${NC}"
echo "🔧 Running dart format . ..."
if (cd "$REPO_ROOT" && dart format .); then
    echo -e "${GREEN}  ✓ dart format completed${NC}"
else
    echo -e "${RED}  ✗ dart format failed${NC}"
    FAILED=1
fi
echo ""

# -----------------------------------------------------------------------------
# Flutter analyze
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Dart / Flutter ━━━${NC}"
echo "🔎 Running flutter analyze..."
if (cd "$REPO_ROOT" && flutter analyze --no-pub); then
    echo -e "${GREEN}  ✓ Flutter analysis OK${NC}"
else
    echo -e "${RED}  ✗ Flutter analysis found issues${NC}"
    FAILED=1
fi

# -----------------------------------------------------------------------------
# Flutter test
# -----------------------------------------------------------------------------
echo "🧪 Running Flutter tests..."
if (cd "$REPO_ROOT" && flutter test); then
    echo -e "${GREEN}  ✓ Flutter tests passed${NC}"
else
    echo -e "${RED}  ✗ Flutter tests failed${NC}"
    FAILED=1
fi

echo ""

if [ $FAILED -ne 0 ]; then
    echo -e "${RED}━━━ Pre-commit checks FAILED ━━━${NC}"
    echo -e "${RED}Fix the issues above before committing.${NC}"
    exit 1
fi

echo -e "${GREEN}━━━ All pre-commit checks passed ✓ ━━━${NC}"
exit 0
