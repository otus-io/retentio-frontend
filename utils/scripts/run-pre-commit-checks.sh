#!/bin/bash
# =============================================================================
# Run all pre-commit checks manually (same as the git pre-commit hook).
# Usage: from repo root, run: ./utils/scripts/run-pre-commit-checks.sh
# Or: bash utils/scripts/run-pre-commit-checks.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

FAILED=0

# -----------------------------------------------------------------------------
# YAML lint (tracked files only; excludes git-ignored e.g. node_modules)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ YAML Checks ━━━${NC}"
echo "📋 Linting YAML files..."
if command -v yamllint &> /dev/null; then
    YAML_FAILED=0
    YAML_LIST=$(git ls-files -- '*.yml' '*.yaml' 2>/dev/null | grep -v 'backend-api/docs/swagger.yaml' | grep -v '^\.cursor/rules/' || true)
    for file in $YAML_LIST; do
        if [ -f "$file" ] && ! yamllint -d "{extends: default, rules: {line-length: {max: 200}, truthy: disable}}" "$file" 2>&1; then
            YAML_FAILED=1
        elif [ -f "$file" ]; then
            echo -e "${GREEN}  ✓ $file${NC}"
        fi
    done
    if [ "$YAML_FAILED" -ne 0 ]; then
        echo -e "${RED}  ✗ YAML lint issues found${NC}"
        FAILED=1
    else
        echo -e "${GREEN}  ✓ All YAML files OK${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ yamllint not found — skipping (install: pip install yamllint)${NC}"
fi
echo ""

# -----------------------------------------------------------------------------
# Markdown lint (tracked files only; excludes git-ignored e.g. node_modules)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Markdown Checks ━━━${NC}"
echo "📋 Linting Markdown files..."
MD_FILES=$(git ls-files -- '*.md' '*.mdc' 2>/dev/null | grep -v '^\.cursor/rules/' | tr '\n' ' ')
if [ -n "$MD_FILES" ]; then
    if command -v markdownlint &> /dev/null; then
        if markdownlint --config .markdownlint.json $MD_FILES 2>&1; then
            echo -e "${GREEN}  ✓ Markdown lint OK${NC}"
        else
            echo -e "${RED}  ✗ Markdown lint issues found${NC}"
            FAILED=1
        fi
    elif command -v markdownlint-cli2 &> /dev/null; then
        if markdownlint-cli2 $MD_FILES 2>&1; then
            echo -e "${GREEN}  ✓ Markdown lint OK${NC}"
        else
            echo -e "${RED}  ✗ Markdown lint issues found${NC}"
            FAILED=1
        fi
    else
        echo -e "${YELLOW}  ⚠ markdownlint not found — skipping (install: npm install -g markdownlint-cli)${NC}"
    fi
else
    echo -e "${GREEN}  ✓ No markdown files to lint${NC}"
fi
echo ""

# -----------------------------------------------------------------------------
# Backend
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Backend Checks ━━━${NC}"
echo "📝 Generating Swagger docs..."
if (cd backend-api && make swagger-prod); then
    echo -e "${GREEN}  ✓ Swagger docs generated${NC}"
else
    echo -e "${RED}  ✗ Swagger doc generation failed${NC}"
    FAILED=1
fi

echo "🔧 Checking Go formatting..."
UNFORMATTED=$(gofmt -l backend-api/ 2>/dev/null || true)
if [ -z "$UNFORMATTED" ]; then
    echo -e "${GREEN}  ✓ Go formatting OK${NC}"
else
    echo -e "${RED}  ✗ Go formatting issues found:${NC}"
    echo "$UNFORMATTED"
    echo "  Run: gofmt -w backend-api/"
    FAILED=1
fi

echo "🔎 Running go vet..."
if (cd backend-api && go vet ./...); then
    echo -e "${GREEN}  ✓ go vet OK${NC}"
else
    echo -e "${RED}  ✗ go vet found issues${NC}"
    FAILED=1
fi

echo "🔎 Running golangci-lint..."
if command -v golangci-lint &> /dev/null; then
    if (cd backend-api && GOFLAGS="-buildvcs=false" golangci-lint run ./...); then
        echo -e "${GREEN}  ✓ golangci-lint OK${NC}"
    else
        echo -e "${RED}  ✗ golangci-lint found issues${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}  ⚠ golangci-lint not found — skipping${NC}"
fi

echo "🔨 Checking Go build..."
if (cd backend-api && go build -o /tmp/wordupx-api-check .); then
    echo -e "${GREEN}  ✓ Go build OK${NC}"
else
    echo -e "${RED}  ✗ Go build failed${NC}"
    FAILED=1
fi

echo "🧪 Running Go unit tests..."
if (cd backend-api && go test ./tests/unit/... 2>&1); then
    echo -e "${GREEN}  ✓ Go unit tests passed${NC}"
else
    echo -e "${RED}  ✗ Go unit tests failed${NC}"
    FAILED=1
fi

echo "🧪 Running Go integration tests..."
if (cd backend-api && go test ./tests/integration/... 2>&1); then
    echo -e "${GREEN}  ✓ Go integration tests passed${NC}"
else
    echo -e "${RED}  ✗ Go integration tests failed${NC}"
    FAILED=1
fi
echo ""

# -----------------------------------------------------------------------------
# Frontend (Flutter)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Frontend Checks ━━━${NC}"
echo "🔧 Checking Dart formatting..."
if (cd frontend && dart format --set-exit-if-changed .); then
    echo -e "${GREEN}  ✓ Dart formatting OK${NC}"
else
    echo -e "${RED}  ✗ Dart formatting issues found${NC}"
    echo "  Run: cd frontend && dart format ."
    FAILED=1
fi

echo "🔎 Running flutter analyze..."
if (cd frontend && flutter analyze --no-pub); then
    echo -e "${GREEN}  ✓ Flutter analysis OK${NC}"
else
    echo -e "${RED}  ✗ Flutter analysis found issues${NC}"
    FAILED=1
fi

echo "🧪 Running Flutter tests..."
if (cd frontend && flutter test); then
    echo -e "${GREEN}  ✓ Flutter tests passed${NC}"
else
    echo -e "${RED}  ✗ Flutter tests failed${NC}"
    FAILED=1
fi
echo ""

# -----------------------------------------------------------------------------
# Webapp
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━ Webapp Checks ━━━${NC}"
echo "🔧 Checking TypeScript types..."
if (cd webapp && npx tsc --noEmit); then
    echo -e "${GREEN}  ✓ TypeScript OK${NC}"
else
    echo -e "${RED}  ✗ TypeScript errors found${NC}"
    FAILED=1
fi

echo "🧪 Running webapp tests..."
if (cd webapp && npm run test:run); then
    echo -e "${GREEN}  ✓ Webapp tests passed${NC}"
else
    echo -e "${RED}  ✗ Webapp tests failed${NC}"
    FAILED=1
fi
echo ""

# -----------------------------------------------------------------------------
# Result
# -----------------------------------------------------------------------------
if [ "$FAILED" -ne 0 ]; then
    echo -e "${RED}━━━ Checks FAILED ━━━${NC}"
    echo -e "${RED}Fix the issues above before committing.${NC}"
    exit 1
fi
echo -e "${GREEN}━━━ All checks passed ✓ ━━━${NC}"
exit 0
