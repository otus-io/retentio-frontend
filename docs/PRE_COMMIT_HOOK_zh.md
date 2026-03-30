🌐 [English](pre_commit_hook.md) | [中文](pre_commit_hook_zh.md)

---

# Pre-commit 钩子

本仓库为 **Retentio Flutter** 客户端。Git **pre-commit** 在每次提交时运行 Dart/Flutter 检查；若暂存区包含对应类型的文件，还会可选运行 YAML / Markdown 检查，便于在 CI 之前发现问题。

## 检查内容

### 每次提交都会运行

| 检查项 | 命令 | 目的 |
|--------|------|------|
| Dart 格式化 | `dart format --set-exit-if-changed .` | 格式一致 |
| Flutter 分析 | `flutter analyze --no-pub` | 静态分析 |
| Flutter 测试 | `flutter test` | 跑全部测试 |

在**仓库根目录**执行（与 `pubspec.yaml` 同级）。

### 仅当本次提交包含相应文件时

**YAML**（暂存了 `.yml` / `.yaml`）：

| 检查项 | 命令 | 目的 |
|--------|------|------|
| YAML 检查 | `yamllint` | 语法与风格 |

**Markdown**（暂存了 `.md` / `.mdc`）：

| 检查项 | 命令 | 目的 |
|--------|------|------|
| Markdown 检查 | `markdownlint` 或 `markdownlint-cli2` | 按 `.markdownlint.json` 规则检查 |

若未安装 `yamllint` 或 `markdownlint`，对应步骤会**跳过**并提示（安装示例：`pip install yamllint`，或 `npm install -g markdownlint-cli`）。

## 安装

克隆后在仓库根目录执行一次：

```bash
./utils/setup-hooks.sh
```

### 手动安装

```bash
cp utils/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 不提交也可跑检查

与钩子相同，无需执行 `git commit`：

```bash
./utils/run-pre-commit-checks.sh
```

## 使用方法

在本仓库内每次 `git commit` 都会触发钩子。

```bash
git commit -m "feat(deck): add card sorting"
```

若检查失败，修复后：

```bash
dart format .
git add .
git commit -m "feat(deck): add card sorting"
```

### 跳过钩子

不建议：

```bash
git commit --no-verify -m "wip: work in progress"
```

## 常见问题

### `flutter: command not found`

将 Flutter 加入 `PATH`，例如：

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

### 钩子没有运行

```bash
ls -la .git/hooks/pre-commit
```

若不存在或版本过旧：

```bash
./utils/setup-hooks.sh
```

## 平台兼容性

| 操作系统 | 是否支持 | 说明 |
|----------|----------|------|
| Linux | 是 | 完全兼容 |
| macOS | 是 | 完全兼容 |
| Windows + Git Bash | 是 | Git for Windows 通过 Git Bash 执行钩子 |
| Windows (cmd / PowerShell) | 否 | 本钩子是 Bash 脚本，请使用 **Git Bash** |

## 编辑钩子

源码在 git 中跟踪：`utils/pre-commit`。

1. 编辑 `utils/pre-commit`
2. 执行 `./utils/setup-hooks.sh` 更新 `.git/hooks/pre-commit`
3. 提交修改，便于团队同步
