# Retentio Frontend: agent instructions

Shared instructions for AI coding agents (Claude Code, Cursor, Codex). Everything in this file
applies to every task. `CLAUDE.md` imports this file.

## Skills (read on demand)

Task-specific guidance lives in `.agents/skills/<name>/SKILL.md`. Read the matching skill before
working in its area:

| Skill | Read it when |
|-------|--------------|
| `flutter-frontend` | Writing or editing `lib/**/*.dart` or `lib/l10n/app_*.arb` |
| `testing` | Writing, editing or running tests under `test/` |
| `ci-workflows` | Reading or editing `.github/workflows/` |

`.claude/skills` is a symlink to `.agents/skills`, so every tool reads the same files.

## Retentio Frontend Project Conventions

### Project Overview

Retentio Frontend is a Flutter app (Riverpod, go_router, Dio) for vocabulary learning.

### Commit & PR Conventions

- Commit/PR title: `<type>(<scope>): <subject>` in imperative mood, under 50 chars
- Types: feat, fix, docs, style, refactor, perf, test, chore
- Scopes: auth, deck, card, fact, media, api, frontend, ci
- Keep PRs under 200 lines, commits under 100 lines
- Squash and merge for feature branches

### Code Style

- **Dart**: Follow Effective Dart, run `dart format`, lines ≤120 chars, functions ≤50 lines
- Prefer clear naming over comments; add comments only for complex logic

### Documentation

- All user-facing docs must have English and Chinese versions (e.g., `foo.md` + `foo_zh.md`)
- Keep `docs/api_progress_tracker.md` updated when adding/changing API usage

### Key Principles

- Never modify production code to make tests pass — tests expose bugs for developers to fix
- CI must pass before merge: `dart format`, `flutter analyze`, `flutter test`

## Git Workflow

### Branch Protection

- **Never push directly to `main`** — all changes must go through a pull request
- GitHub branch protection enforces this remotely
- If you need to commit, always create a feature branch first

### Branch Naming

- Use descriptive branch names: `<scope>-<feature>` (e.g., `frontend-auth-flow`, `deck-card-ui`)
- Keep branch names lowercase with hyphens

### Workflow

1. Create a feature branch from `main`: `git checkout -b <branch-name>`
2. Make commits on the feature branch (pre-commit hook runs checks)
3. Push the branch: `git push -u origin <branch-name>`
4. Create a PR against `main`
5. Squash and merge after review and CI passes

### Hooks

- **pre-commit**: Runs formatting, linting, and tests for changed files
- Install hooks: `./utils/scripts/setup-hooks.sh`

## Validate and keep changes minimal

**Mandatory on every prompt.** Merge of project validate workflow and [Karpathy behavioral guidelines](https://github.com/multica-ai/andrej-karpathy-skills).

### Think before coding

- Read relevant current code; do not rely on stale findings or assumptions.
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — do not pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- For review findings or bug reports: verify each item against current code. Fix only still-valid items; skip others with a brief reason.

### On every prompt

1. **Validate first** — Confirm the problem exists in current code before editing.
2. **Minimal diff** — Smallest correct change. No drive-by refactors, formatting sweeps, renames, or unrelated edits. Match local conventions in touched files.
3. **Simplicity** — No features, abstractions, configurability, or error handling beyond what the request needs. No helpers for single-use code.
4. **Surgical edits** — Every changed line should trace to the user's request. Do not delete unrelated pre-existing dead code (mention it if useful). Remove only orphans your change created (unused imports, vars, functions).
5. **Do not change tests to pass** — Fix production code when behavior is wrong. Edit tests only when the test is wrong or the user asked for test changes.
6. **Flutter tests** — Placement and patterns: the `testing` and `flutter-frontend` skills.
7. **Validate after** — Run relevant checks for the change scope: `dart format`, `flutter analyze`, `flutter test`. If a check fails, fix within the same scope; do not expand to “clean up” nearby code.
8. **100% coverage on new code** — For all new code changes, test coverage must be 100%. Cover every new or changed executable line, branch, and error path in the change set. Do not finish until coverage of the diff is complete. Do not require raising coverage of untouched pre-existing code.

**Question-only or review-only:** answer without editing unless the user asked for code changes.

### When tests fail

1. **Investigate the implementation first.** Reproduce the failure, read the code under test, and determine whether the bug is in production logic (wrong behavior, missing edge case, etc.).
2. **Fix the real issue** in production code when you find one.
3. **Only then** consider changing the test — wrong expectations, wrong assertion target, or a legitimately changed API/contract.

Do not relax or rewrite a test solely to make it pass without understanding the cause.

### Multi-step tasks

State a brief plan with verifiable success criteria, e.g.:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Bug fix: reproduce (test or steps), then fix. Refactor: tests pass before and after.

### Quick checklist

```
[ ] Verified against current code (assumptions stated if needed)
[ ] Only still-valid issues addressed (skips explained)
[ ] Minimal, surgical diff — no unrelated changes
[ ] Failures fixed in prod code, not by weakening tests
[ ] Post-change validation run or N/A explained
[ ] New/changed code has 100% test coverage
```

## Concise responses

- Default to **short answers**: lead with the outcome or decision, then minimal supporting detail only when needed.
- Prefer bullets over long paragraphs; skip preamble (“Certainly!”, “In summary…”).
- Avoid repeating the question, restating obvious context, or filler transitions.
- Expand only when the task is inherently complex, ambiguous, or the user asks for depth.

## Cost Optimization

### Thinking Discipline

- Keep internal reasoning minimal — don't deliberate over straightforward tasks
- For simple edits (rename, add a line, fix a typo), act immediately with zero deliberation
- Never restate the user's request back to yourself before acting
- Don't enumerate multiple approaches when the right one is obvious — just do it

### Output Discipline

- Be concise — avoid boilerplate comments, redundant docstrings, and filler text in generated code
- When generating tests, produce one focused test file per prompt; don't pad with obvious/trivial test cases
- When generating docs, write tight prose; skip sections that add no information (e.g., empty "Notes" headers)
- Never repeat large code blocks back to the user just to show what was changed — describe the change briefly
- Skip unnecessary preamble ("Sure!", "Great question!", "Let me...") — get straight to the action or answer
- After making an edit, confirm in one short sentence; don't recap what the code does

### Tool Call Efficiency

- Don't re-read files that are already in context (open tabs, recently read, or attached by the user)
- Batch independent tool calls into a single round-trip instead of sequential calls
- Use targeted reads (offset + limit) for large files instead of reading the entire file
- Prefer Grep/Glob over broad semantic search when you know the symbol or filename
- Don't explore the codebase when the user already told you the file or location

### Conversation Efficiency

- Ask clarifying questions upfront if the request is ambiguous — one round of questions is cheaper than re-generating
- When the user points to a specific file/function, go straight to it — don't scan the whole codebase first
- If a task has multiple parts (e.g., "add tests and docs"), confirm scope before generating everything

### Generation Guidelines

- For docs: generate English first, then Chinese in one pass —
  don't split across conversations
- For tests: follow existing test patterns (see the `testing` skill) instead of inventing new structures each time
- For boilerplate (handlers, models): use the codebase's existing patterns as a template — don't over-engineer
