---
name: ci-workflows
description: CI/CD workflow conventions for GitHub Actions in retentio-frontend. Use when reading or editing .github/workflows files or reasoning about CI checks.
---

# CI/CD Workflow Conventions

## Existing Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `frontend.yml` | Push/PR to main, app paths (`lib/**`, `test/**`, platforms, `pubspec.*`) | Flutter format, analyze, test |
| `pr-review.yml` | PR opened/sync | PR description auto-fill, Claude Code review |
| `android-release.yml` | Push to main changing `pubspec.yaml` / manual | New pubspec version → signed APK, tag `v<version>`, GitHub Release asset `retentio.apk` |

## Frontend CI Requirements

- Flutter stable channel
- Must pass: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`
- Test failures should be documented, not hidden

## Rules

- Never skip CI checks or add `[skip ci]` without team agreement
