🌐 [English](CURSOR_RULES.md) | [中文](CURSOR_RULES_zh.md)

---

# Cursor Rules

This project uses [Cursor Rules](https://docs.cursor.com/context/rules-for-ai) to provide persistent AI guidance. Rules are stored in `.cursor/rules/` and automatically activate based on context.

## Rules Overview

| Rule | File | Scope | Description |
|------|------|-------|-------------|
| Project Conventions | `project-conventions.mdc` | Always active | Project-wide standards for commits, PRs, docs, and code style |
| Go Backend | `go-backend.mdc` | `api/**/*.go` | Go coding patterns, Redis, JWT, middleware, Swagger |
| Flutter Frontend | `flutter-frontend.mdc` | `frontend/lib/**/*.dart` | Riverpod, go_router, Dio, model and screen patterns |
| Testing | `testing.mdc` | `frontend/test/**/*.dart` | Blackbox testing principles and Flutter test conventions |
| CI/CD Workflows | `ci-workflows.mdc` | `.github/workflows/**` | GitHub Actions workflow conventions |

## How Rules Work

- **Always active** rules apply to every AI conversation regardless of which files are open.
- **File-scoped** rules activate automatically when you open or edit files matching the glob pattern.
- Rules are read-only guidance for the AI — they don't modify your code or enforce linting.

## Rule Details

### Project Conventions (Always Active)

Core standards that apply everywhere:

- **Commit format**: `<type>(<scope>): <subject>` (e.g., `feat(deck): add card sorting`)
- **PR size**: Under 200 lines of code changes, 3 commits or fewer
- **Code style**: Go follows Effective Go + `gofmt`; Dart follows Effective Dart + `dart format`
- **Documentation**: All user-facing docs must have English and Chinese versions
- **Testing principle**: Never modify production code to make tests pass — tests expose bugs

### Go Backend

Activated when editing files in `api/`:

- Architecture overview: gorilla/mux router, Redis storage, JWT auth
- Middleware chain: CorsMiddleware → JwtAuthMiddleware → Handlers
- Error handling patterns using `common.SendErrorResponse`
- Redis key patterns and data access conventions
- Swagger annotation requirements

### Flutter Frontend

Activated when editing files in `frontend/lib/`:

- State management with Riverpod (ProviderScope, StateNotifier, ConsumerWidget)
- Routing with go_router
- HTTP calls via Dio with interceptors
- Model conventions: `fromJson`/`toJson` with null and type safety
- Screen organization: each feature has its own `providers/` and `widgets/`

### Testing

Activated when editing files in `frontend/test/`:

- **Blackbox testing principle**: Tests are written to expose bugs, not to pass
- Never modify test data to work around production code bugs
- Widget test pattern with ProviderScope wrapping
- Model test pattern for null/edge case handling
- Test report format and location (`docs/frontend/test-reports/`)

### CI/CD Workflows

Activated when editing files in `.github/workflows/`:

- Backend CI: Go 1.23, Redis service, build + vet + format + test
- Frontend CI: Flutter stable, format + analyze + test
- PR review: Claude AI auto-review
- Deploy: SSH deploy on push to main

## Adding New Rules

1. Create a `.mdc` file in `.cursor/rules/`
2. Add YAML frontmatter with `description`, `globs` (optional), and `alwaysApply`
3. Keep rules concise (under 50 lines) and actionable
4. Update this document when adding or changing rules
