🌐 [English](PRE_COMMIT_HOOK.md) | [中文](PRE_COMMIT_HOOK_zh.md)

---

# Pre-commit Hook

This **Retentio Flutter** repo includes a Git **pre-commit** hook that runs Dart/Flutter checks on every commit (and optional YAML/Markdown lint when those files are staged), so issues are caught before CI.

## What It Checks

### Always (every commit)

| Check | Command | Purpose |
|-------|---------|---------|
| Dart format | `dart format --set-exit-if-changed .` | Consistent formatting |
| Flutter analyze | `flutter analyze --no-pub` | Static analysis |
| Flutter tests | `flutter test` | Full test suite |

Runs from the **repository root** (where `pubspec.yaml` lives).

### Only when you stage matching files

**YAML** (`.yml` / `.yaml` in the commit):

| Check | Command | Purpose |
|-------|---------|---------|
| YAML lint | `yamllint` | Syntax and style |

**Markdown** (`.md` / `.mdc` in the commit):

| Check | Command | Purpose |
|-------|---------|---------|
| Markdown lint | `markdownlint` or `markdownlint-cli2` | Lint per `.markdownlint.json` |

If `yamllint` or `markdownlint` is not installed, that part is **skipped** with a warning (`pip install yamllint`, or `npm install -g markdownlint-cli` for the CLI).

## Installation

After cloning, run once from the repo root:

```bash
./utils/setup-hooks.sh
```

### Manual installation

```bash
cp utils/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Run checks without committing

Same checks as the hook, without `git commit`:

```bash
./utils/run-pre-commit-checks.sh
```

## Usage

The hook runs on every `git commit` from this repo.

```bash
git commit -m "feat(deck): add card sorting"
```

If something fails, fix it, then:

```bash
dart format .
git add .
git commit -m "feat(deck): add card sorting"
```

### Skipping the hook

Not recommended:

```bash
git commit --no-verify -m "wip: work in progress"
```

## Troubleshooting

### `flutter: command not found`

Add Flutter to your `PATH`, for example:

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

### Hook not running

```bash
ls -la .git/hooks/pre-commit
```

If missing or stale:

```bash
./utils/setup-hooks.sh
```

## Platform Compatibility

| OS | Works? | Notes |
|---|---|---|
| Linux | Yes | Fully compatible |
| macOS | Yes | Fully compatible |
| Windows + Git Bash | Yes | Git for Windows runs hooks via Git Bash |
| Windows (cmd / PowerShell) | No | Use **Git Bash** for this Bash hook |

## Editing the Hook

Source (tracked in git): `utils/pre-commit`.

1. Edit `utils/pre-commit`
2. Run `./utils/setup-hooks.sh` to refresh `.git/hooks/pre-commit`
3. Commit the change so others get it
