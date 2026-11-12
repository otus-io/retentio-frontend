
# AI agent instructions

One set of instructions is shared by Claude Code, Cursor and Codex.

| What | Where | Loaded |
|------|-------|--------|
| Always-on rules | [`AGENTS.md`](../AGENTS.md) | Every task |
| Claude Code entry point | `CLAUDE.md` (imports `AGENTS.md`) | Every task |
| Task-specific skills | `.agents/skills/<name>/SKILL.md` | On demand, by description |
| Claude Code skills path | `.claude/skills` (symlink to `.agents/skills`) | On demand |

## Always-on rules (`AGENTS.md`)

- Project conventions: commits, PRs, docs, Dart style
- Git workflow: feature branches, no direct push to `main`
- Validate and keep changes minimal: validate first/after, minimal diffs, fix prod not tests,
  100% coverage of new code
- Concise responses and cost optimization

## Skills

| Skill | Use when | Description |
|-------|----------|-------------|
| `flutter-frontend` | Editing `lib/**/*.dart`, ARB files | Riverpod, go_router, Dio, shared widgets |
| `testing` | Editing `test/**/*.dart` | Widget/model tests, blackbox principle |
| `ci-workflows` | Editing `.github/workflows/**` | GitHub Actions for this repo |

## Adding or changing instructions

1. A rule that must hold on every task goes in `AGENTS.md`.
2. Guidance for one kind of task goes in a new `.agents/skills/<name>/SKILL.md` with `name`
   (matching the folder) and `description` frontmatter. Say in the description when to use it.
3. Do not add tool-specific copies (`.cursor/rules`, `.claude/skills` files); edit the shared files.
4. Update this document and `cursor_rules_zh.md`.
