#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

run_backend_unit() {
  echo "=== Backend: unit tests ==="
  cd "$REPO_ROOT/backend-api"
  go test ./tests/unit/... -count=1 -v
}

run_backend_integration() {
  echo "=== Backend: integration tests ==="
  cd "$REPO_ROOT/backend-api"
  go test ./tests/integration/... -count=1 -v
}

run_frontend() {
  echo "=== Frontend: Flutter tests ==="
  cd "$REPO_ROOT/frontend"
  flutter test --no-pub
}

case "${1:-all}" in
  unit)
    run_backend_unit
    ;;
  integration)
    run_backend_integration
    ;;
  frontend)
    run_frontend
    ;;
  backend)
    run_backend_unit
    echo ""
    run_backend_integration
    ;;
  all)
    run_backend_unit
    echo ""
    run_backend_integration
    echo ""
    run_frontend
    ;;
  *)
    echo "Usage: $0 [unit|integration|frontend|backend|all]"
    echo ""
    echo "  unit          Backend unit tests only"
    echo "  integration   Backend integration tests only (requires Redis)"
    echo "  frontend      Flutter tests only"
    echo "  backend       All backend tests"
    echo "  all           Everything (default)"
    exit 1
    ;;
esac
