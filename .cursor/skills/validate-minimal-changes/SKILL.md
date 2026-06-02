---
name: validate-minimal-changes
description: >-
  Enforces validate-first workflow, minimal diffs, and fixing prod code not tests
  on every task. Apply on every prompt, code change, bug fix, review finding,
  refactor, or review — always before writing or editing code.
---

# Validate and keep changes minimal

**Mandatory on every prompt.** Full text lives in:

`retentio-frontend/.cursor/rules/validate-minimal-changes.mdc`

When working in this repo, follow that file (validate first, minimal surgical diffs, simplicity, do not change tests to pass, validate after with `dart format` / `flutter analyze` / `flutter test`).
