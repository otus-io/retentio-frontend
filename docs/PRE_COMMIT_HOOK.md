🌐 [English](PRE_COMMIT_HOOK.md) | [中文](PRE_COMMIT_HOOK_zh.md)

---

# Pre-commit Hook

This project includes a pre-commit hook that runs format checks and tests before every commit, catching issues early before they reach CI.

## What It Checks

The hook only runs checks relevant to the files you're committing:

### YAML (`.yml` / `.yaml` files changed)

| Check | Command | Purpose |
|-------|---------|---------|
| YAML lint | `yamllint` | Validate YAML syntax and formatting |

> If `yamllint` is not installed, the check is skipped with a warning. Install with: `pip install yamllint`

### Backend (`api/` files changed)

| Check | Command | Purpose |
|-------|---------|---------|
| Swagger docs | `make swagger-prod` | Regenerate and stage API docs |
| Go format | `gofmt -l` | Ensure consistent formatting |
| Go vet | `go vet ./...` | Catch common mistakes |
| Go build | `go build` | Verify compilation |
| Go tests | `go test ./tests/unit/...` | Run unit tests |

### Flutter app (repository root — `lib/`, `test/`, `pubspec.yaml`, etc.)

| Check | Command | Purpose |
|-------|---------|---------|
| Dart format | `dart format --set-exit-if-changed .` | Ensure consistent formatting |
| Flutter analyze | `flutter analyze --no-pub` | Static analysis for errors |
| Flutter tests | `flutter test` | Run all tests |

If your commit only touches docs or config files, all checks are skipped automatically.

## Installation

Run the setup script once after cloning the repo:

```bash
./utils/setup-hooks.sh
```

That's it. The hook is now active for all future commits.

### Manual Installation

If you prefer to install manually:

```bash
cp utils/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Run checks without committing

To run the same frontend checks (format, analyze, tests) without committing:

```bash
./utils/run-pre-commit-checks.sh
```

Run it from the repo root. The script is standalone and does not require git.

## Usage

The hook runs automatically on every `git commit`. No extra steps needed.

```bash
# Normal commit — hook runs automatically
git commit -m "feat(deck): add card sorting"

# If checks fail, fix the issues and try again
dart format .
git add .
git commit -m "feat(deck): add card sorting"
```

### Skipping the Hook

In rare cases where you need to bypass the hook (not recommended):

```bash
git commit --no-verify -m "wip: work in progress"
```

## Troubleshooting

### `flutter: command not found`

Make sure Flutter is in your PATH:

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it permanent.

### `gofmt: command not found`

Make sure Go is installed and in your PATH:

```bash
export PATH="$PATH:/usr/local/go/bin"
```

### Hook not running

Verify the hook is installed and executable:

```bash
ls -la .git/hooks/pre-commit
```

If missing, re-run the setup script:

```bash
./utils/setup-hooks.sh
```

## Platform Compatibility

| OS | Works? | Notes |
|---|---|---|
| Linux | Yes | Fully compatible |
| macOS | Yes | Fully compatible |
| Windows + Git Bash | Yes | Git for Windows includes Git Bash, which runs the hook automatically |
| Windows (cmd / PowerShell) | No | Bash script — use Git Bash instead |

> **Note**: If you're on Windows, make sure you're using [Git for Windows](https://gitforwindows.org/) which includes Git Bash. Git hooks run through Git Bash automatically, so no extra setup is needed.

## Editing the Hook

The hook source file is tracked in git at:

```
utils/pre-commit
```

To modify the hook:

1. Edit `utils/pre-commit`
2. Re-run `./utils/setup-hooks.sh` to install the updated version
3. Commit the updated source file so the team gets the change
