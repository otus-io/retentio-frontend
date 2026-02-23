#!/usr/bin/env bash
# sync-api-tracker.sh — Bidirectional sync between docs/API_PROGRESS_TRACKER.md
# and GitHub Issue #21 (wordupx/wordupx).
#
# For each endpoint, keeps the "highest" status from either source:
#   ✅ (done) > 🔧 (in progress) > ❌ (not started)
#
# Usage:
#   ./utils/scripts/sync-api-tracker.sh            # preview changes (dry run)
#   ./utils/scripts/sync-api-tracker.sh --apply     # apply changes to both local file and issue
#
# Requirements: gh (GitHub CLI, authenticated), python3

set -euo pipefail

REPO="wordupx/wordupx"
ISSUE=21
LOCAL_FILE="docs/API_PROGRESS_TRACKER.md"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_PATH="$ROOT_DIR/$LOCAL_FILE"

if [[ ! -f "$LOCAL_PATH" ]]; then
  echo "Error: $LOCAL_PATH not found. Run this script from the repo root or utils/scripts/."
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh (GitHub CLI) is required. Install it and run 'gh auth login'."
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required."
  exit 1
fi

APPLY=false
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=true
fi

# Fetch issue body
export ISSUE_BODY
ISSUE_BODY="$(gh issue view "$ISSUE" --repo "$REPO" --json body --jq '.body')"

# Run the merge logic in Python, output merged local file and merged issue body
# separated by a known delimiter
RESULT="$(python3 - "$LOCAL_PATH" <<'PYEOF'
import sys, re, json

STATUS_RANK = {"❌": 0, "🔧": 1, "✅": 2}
RANK_STATUS = {v: k for k, v in STATUS_RANK.items()}

# Regex to match a table row with a backtick-quoted endpoint and two status columns
ROW_RE = re.compile(
    r'^(\|\s*`([^`]+)`\s*\|[^|]*\|)\s*([✅🔧❌])\s*\|\s*([✅🔧❌])\s*\|'
)

def parse_statuses(text):
    """Extract endpoint -> (frontend_status, backend_status) from markdown."""
    result = {}
    for line in text.split('\n'):
        m = ROW_RE.match(line)
        if m:
            endpoint = m.group(2).strip()
            result[endpoint] = (m.group(3), m.group(4))
    return result

def higher(a, b):
    return a if STATUS_RANK.get(a, 0) >= STATUS_RANK.get(b, 0) else b

def apply_merged(text, merged):
    """Replace statuses in text with merged values, preserving structure."""
    lines = text.split('\n')
    out = []
    for line in lines:
        m = ROW_RE.match(line)
        if m:
            ep = m.group(2).strip()
            if ep in merged:
                prefix = m.group(1)
                fe, be = merged[ep]
                out.append(f"{prefix} {fe} | {be} |")
                continue
        out.append(line)
    return '\n'.join(out)

# Read inputs
local_path = sys.argv[1]
with open(local_path, 'r') as f:
    local_text = f.read()

import os
issue_body = os.environ['ISSUE_BODY']

# Parse
local_statuses = parse_statuses(local_text)
issue_statuses = parse_statuses(issue_body)

# Merge
all_endpoints = set(local_statuses) | set(issue_statuses)
merged = {}
changes = []
for ep in sorted(all_endpoints):
    l_fe, l_be = local_statuses.get(ep, ("❌", "❌"))
    i_fe, i_be = issue_statuses.get(ep, ("❌", "❌"))
    m_fe = higher(l_fe, i_fe)
    m_be = higher(l_be, i_be)
    merged[ep] = (m_fe, m_be)

    # Track what changed where
    if l_fe != m_fe or l_be != m_be:
        changes.append(f"  LOCAL  {ep}: frontend {l_fe}->{m_fe}, backend {l_be}->{m_be}")
    if i_fe != m_fe or i_be != m_be:
        changes.append(f"  ISSUE  {ep}: frontend {i_fe}->{m_fe}, backend {i_be}->{m_be}")

# Apply merged statuses to the local file (source of truth for structure).
# Use the local file as the template for BOTH outputs, so new rows in the
# local file automatically appear in the issue body.
merged_local = apply_merged(local_text, merged)
merged_issue = merged_local  # issue mirrors local structure with merged statuses

# Output as JSON so the shell script can parse it
output = {
    "merged_local": merged_local,
    "merged_issue": merged_issue,
    "changes": changes,
}
print(json.dumps(output))
PYEOF
)"

# Parse the JSON output
CHANGES="$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('\n'.join(d['changes']) if d['changes'] else '(no changes needed)')")"
NUM_CHANGES="$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['changes']))")"

echo "=== API Tracker Sync ==="
echo "  Local file: $LOCAL_FILE"
echo "  GitHub issue: $REPO#$ISSUE"
echo ""
echo "Changes to apply:"
echo "$CHANGES"
echo ""

if [[ "$NUM_CHANGES" == "0" ]]; then
  echo "Already in sync. Nothing to do."
  exit 0
fi

if [[ "$APPLY" == false ]]; then
  echo "Dry run complete. Run with --apply to write changes:"
  echo "  ./utils/scripts/sync-api-tracker.sh --apply"
  exit 0
fi

# Write merged local file
echo "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
with open('$LOCAL_PATH', 'w') as f:
    f.write(d['merged_local'])
"
echo "Updated $LOCAL_FILE"

# Update GitHub issue body
MERGED_ISSUE_BODY="$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['merged_issue'])")"
gh issue edit "$ISSUE" --repo "$REPO" --body "$MERGED_ISSUE_BODY"
echo "Updated GitHub issue $REPO#$ISSUE"

echo ""
echo "Sync complete."
