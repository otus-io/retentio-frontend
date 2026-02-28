#!/bin/bash
# Fix yamllint document-start and trailing-spaces in .github workflows.
# Run from repo root: ./utils/scripts/fix-yaml-lint.sh
set -e
cd "$(dirname "$0")/../.."

for f in .github/workflows/backend-api-deploy.yml .github/workflows/frontend.yml .github/workflows/pr-review.yml; do
  [ -f "$f" ] || continue
  # Add --- at start if missing
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "---" | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    echo "Added document start to $f"
  fi
  # Remove trailing spaces (portable: write to tmp then mv)
  sed 's/[[:space:]]*$//' "$f" > "$f.tmp2" && mv "$f.tmp2" "$f" && echo "Stripped trailing spaces in $f"
done
echo "Done."
