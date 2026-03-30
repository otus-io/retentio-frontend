🌐 [English](contributing.md) | [中文](contributing_zh.md)

---

# Code Conduct and Contribution Guidelines

This document outlines the code quality standards and Pull Request (PR) conventions for the Retentio project, inspired by Kubernetes contribution guidelines.

## Table of Contents

- [PR Submission Flow](#pr-submission-flow)
- [Code Quality Standards](#code-quality-standards)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [PR Review Process](#pr-review-process)

---

## PR Submission Flow

When submitting a PR, follow this process:

1. **Create PR** - Submit your pull request to `main`
2. **Claude Bot Review** - Wait for the automated Claude AI review comment
3. **Teammate Review** - Request a second opinion from a teammate
4. **Resolve Comments** - Address feedback from both Claude and your teammate
   - ⚠️ **Do NOT resolve comments yourself** - Let the reviewer resolve them after verification
5. **Merge** - Once approved and all comments resolved, merge the PR

---

## Code Quality Standards

### General Principles

1. **Readability**: Code should be self-documenting. Prefer clear variable/function names over comments.
2. **Simplicity**: Keep it simple. Avoid over-engineering.
3. **Testability**: Write code that is easy to test. Include unit tests for new functionality.
4. **Consistency**: Follow existing code patterns and project conventions.

### Code Style

- Follow the language-specific style guides:
  - **Go**: Follow [Effective Go](https://go.dev/doc/effective_go) and run `gofmt`
  - **Kotlin/Android**: Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
  - **Flutter/Dart**: Follow [Effective Dart](https://dart.dev/effective-dart) and run `dart format`
- Use meaningful variable and function names
- Keep functions focused on a single responsibility
- Limit function length to **50 lines** where possible
- Limit line length to **120 characters**

### Documentation

- Add comments for complex logic or non-obvious decisions
- Update README or relevant documentation when adding new features
- Include godoc/kdoc comments for public APIs

---

## Pull Request Guidelines

### PR Title Convention

PR titles **MUST** follow the format:

```
<type>(<scope>): <subject>
```

#### Types

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Code style changes (formatting, missing semicolons, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks (build process, dependencies, etc.) |

#### Scope

The scope should indicate the affected module or component:

- `auth` - Authentication related changes
- `deck` - Deck management
- `card` - Card operations
- `api` - General API changes
- `app` / `mobile` - Flutter client changes (repo root next to `pubspec.yaml`)
- `ci` - CI/CD pipeline changes

#### Subject

- Use imperative mood: "add feature" not "added feature" or "adds feature"
- Don't capitalize the first letter
- No period at the end
- Keep it under **50 characters**

#### Examples

```
feat(auth): add OAuth2 support for Google login
fix(deck): resolve null pointer when deck is empty
docs(api): update swagger documentation for card endpoints
refactor(card): simplify card validation logic
test(auth): add unit tests for token refresh
```

### PR Size Guidelines

#### Lines of Code per PR

| Size | Lines Changed | Recommendation |
|------|---------------|----------------|
| **XS** | 1-10 | Ideal for quick fixes |
| **S** | 11-50 | Good for small features or bug fixes |
| **M** | 51-200 | Acceptable for moderate features |
| **L** | 201-500 | Should be split if possible |
| **XL** | 500+ | **Must be split** into smaller PRs |

**Target**: Keep PRs under **200 lines** of actual code changes (excluding tests and generated files).

#### Why Small PRs?

- Easier to review thoroughly
- Faster review turnaround
- Lower risk of introducing bugs
- Easier to revert if needed
- Better git history

### Commits per PR

| Commits | Guideline |
|---------|-----------|
| **1-3** | Ideal |
| **4-5** | Acceptable for larger features |
| **6+** | Consider splitting into multiple PRs |

**Target**: Keep PRs to **3 commits or fewer**.

### PR Description Template

Every PR should include:

```markdown
## What type of PR is this?
<!-- feat / fix / docs / refactor / test / chore -->

## Description
<!-- Describe your changes in detail -->

## Related Issue
<!-- Link to related issue: Fixes #123 -->

## How Has This Been Tested?
<!-- Describe how you tested your changes -->

## Checklist
- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my code
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing unit tests pass locally
- [ ] I have updated the documentation accordingly
```

---

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Commit Message Rules

1. **Subject line**: Maximum **50 characters**
2. **Body**: Wrap at **72 characters**, explain *what* and *why* (not *how*)
3. **Footer**: Reference issues and breaking changes

### Atomic Commits

Each commit should:

- Represent a single logical change
- Be compilable and pass tests independently
- Not break the build

### Lines of Code per Commit

| Lines | Guideline |
|-------|-----------|
| **1-50** | Ideal - focused, reviewable |
| **51-100** | Acceptable for larger features |
| **100+** | Should be split into multiple commits |

**Target**: Keep commits under **100 lines** of code changes.

### Example Commit Messages

**Good:**

```
feat(auth): add JWT token refresh endpoint

Implement automatic token refresh to improve user experience.
Users will no longer need to re-login when their token expires.

Closes #42
```

**Bad:**

```
fixed stuff
```

---

## PR Review Process

### Review Requirements

- All PRs require at least **1 approval** before merging
- CI checks must pass
- No unresolved conversations

### Reviewer Responsibilities

1. Review code within **24-48 hours** when possible
2. Provide constructive feedback
3. Approve only when confident in the changes
4. Use GitHub's suggestion feature for small fixes

### Review Labels

| Label | Description |
|-------|-------------|
| `lgtm` | Looks Good To Me - approved |
| `needs-rebase` | PR needs to be rebased on main |
| `needs-tests` | PR requires additional tests |
| `needs-docs` | PR requires documentation updates |
| `do-not-merge` | PR should not be merged yet |

### Merging Strategy

- Use **Squash and Merge** for feature branches
- Ensure the squashed commit message follows conventions
- Delete the branch after merging

---

## Quick Reference

| Metric | Target | Maximum |
|--------|--------|---------|
| PR title length | 50 chars | 72 chars |
| Lines per commit | 50 | 100 |
| Lines per PR | 200 | 500 |
| Commits per PR | 3 | 5 |
| Review turnaround | 24h | 48h |

---

## Questions?

If you have questions about these guidelines, please open an issue or reach out to the maintainers.
