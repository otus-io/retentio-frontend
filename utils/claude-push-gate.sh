#!/bin/bash

# =============================================================================
# Claude Code PreToolUse hook: blocks `git push` until HEAD has been reviewed.
# The agent runs /code-review and /security-review, fixes valid findings, commits,
# then marks HEAD reviewed with: utils/claude-push-gate.sh --mark
# The git pre-push hook skips its own reviews for marked commits.
# =============================================================================

REVIEWED_DIR="$(git rev-parse --git-path ai-reviewed)"
HEAD_SHA="$(git rev-parse HEAD)"

if [ "$1" = "--mark" ]; then
    mkdir -p "$REVIEWED_DIR" && touch "$REVIEWED_DIR/$HEAD_SHA" && echo "Marked $HEAD_SHA as reviewed"
    exit $?
fi

if ! command -v jq &> /dev/null; then
    echo "jq is required by utils/claude-push-gate.sh; install it before running Bash commands." >&2
    exit 2
fi

COMMAND="$(jq -r '.tool_input.command // empty')"
# `git push` at the start of a command segment (string start, newline, ; & | or a subshell),
# optionally after VAR=value prefixes and git global options such as -C <dir>.
SEP=$'(^|[;&|(\n])[[:space:]]*'
ENV_VARS='([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
GIT_OPTS='(-[Cc][[:space:]]+[^[:space:]]+[[:space:]]+)*'
PUSH_RE="${SEP}${ENV_VARS}git[[:space:]]+${GIT_OPTS}push([[:space:];&|)]|$)"
if ! [[ "$COMMAND" =~ $PUSH_RE ]]; then
    exit 0
fi
if [ -f "$REVIEWED_DIR/$HEAD_SHA" ]; then
    exit 0
fi

REASON="HEAD $HEAD_SHA has not been reviewed. Before pushing: run /code-review and /security-review on this \
branch, verify each finding against the code, fix the valid ones and commit (explain skipped ones to the user), \
then run utils/claude-push-gate.sh --mark and push again. Any new commit needs a new review."
jq -n --arg reason "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $reason}}'
