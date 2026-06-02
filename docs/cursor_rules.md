# Cursor Rules

Rules live in `.cursor/rules/` and activate by scope. See [Cursor Rules docs](https://docs.cursor.com/context/rules-for-ai).

| Rule | File | Scope | Description |
|------|------|-------|-------------|
| Validate & minimal changes | `validate-minimal-changes.mdc` | Always | Validate first/after, minimal diffs, fix prod not tests |
| Project conventions | `project-conventions.mdc` | Always | Commits, PRs, docs, Dart style |
| Failing tests | `failing-tests-debugging.mdc` | Always | Debug implementation before weakening tests |
| Cost optimization | `cost-optimization.mdc` | Always | Concise output, efficient tool use |
| Concise responses | `concise-responses.mdc` | Always | Short, scannable replies |
| Git workflow | `git-workflow.mdc` | Always | Feature branches, no direct push to `main` |
| Flutter frontend | `flutter-frontend.mdc` | `lib/**/*.dart` | Riverpod, go_router, Dio, shared widgets |
| Testing | `testing.mdc` | `test/**/*.dart` | Widget/model tests, blackbox principle |
| CI workflows | `ci-workflows.mdc` | `.github/workflows/**` | GitHub Actions for this repo |

Project skill (same validate workflow): `.cursor/skills/validate-minimal-changes/SKILL.md`
