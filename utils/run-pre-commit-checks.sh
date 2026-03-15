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
FRONTEND_DIR="$REPO_ROOT/frontend"

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Error: frontend directory not found at $FRONTEND_DIR${NC}"
    exit 1
fi

echo "🔍 Running pre-commit checks (standalone)..."
echo "   Repo root: $REPO_ROOT"
echo ""

FAILED=0

# -----------------------------------------------------------------------------
# Dart format
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Frontend Checks ━━━${NC}"
echo "🔧 Checking Dart formatting..."
if (cd "$FRONTEND_DIR" && dart format --set-exit-if-changed .); then
    echo -e "${GREEN}  ✓ Dart formatting OK${NC}"
else
    echo -e "${RED}  ✗ Dart formatting issues found${NC}"
    echo "  Run: cd frontend && dart format ."
    FAILED=1
fi

# -----------------------------------------------------------------------------
# Flutter analyze
# -----------------------------------------------------------------------------
echo "🔎 Running flutter analyze..."
if (cd "$FRONTEND_DIR" && flutter analyze --no-pub); then
    echo -e "${GREEN}  ✓ Flutter analysis OK${NC}"
else
    echo -e "${RED}  ✗ Flutter analysis found issues${NC}"
    FAILED=1
fi

# -----------------------------------------------------------------------------
# Flutter test
# -----------------------------------------------------------------------------
echo "🧪 Running Flutter tests..."
if (cd "$FRONTEND_DIR" && flutter test); then
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
