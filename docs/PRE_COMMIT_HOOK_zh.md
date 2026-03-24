🌐 [English](PRE_COMMIT_HOOK.md) | [中文](PRE_COMMIT_HOOK_zh.md)

---

# Pre-commit 钩子

本项目包含一个 pre-commit 钩子，在每次提交前自动运行格式检查和测试，在代码进入 CI 之前及早发现问题。

## 检查内容

钩子只对你提交的文件运行相关检查：

### YAML（`.yml` / `.yaml` 文件变更时）

| 检查项 | 命令 | 目的 |
|--------|------|------|
| YAML 语法检查 | `yamllint` | 验证 YAML 语法和格式 |

> 如果未安装 `yamllint`，检查会跳过并显示警告。安装命令：`pip install yamllint`

### 后端（`api/` 文件变更时）

| 检查项 | 命令 | 目的 |
|--------|------|------|
| Swagger 文档 | `make swagger-prod` | 重新生成并暂存 API 文档 |
| Go 格式化 | `gofmt -l` | 确保格式一致 |
| Go vet | `go vet ./...` | 捕获常见错误 |
| Go 编译 | `go build` | 验证编译通过 |
| Go 测试 | `go test ./tests/unit/...` | 运行单元测试 |

### Flutter 应用（仓库根目录：`lib/`、`test/`、`pubspec.yaml` 等）

| 检查项 | 命令 | 目的 |
|--------|------|------|
| Dart 格式化 | `dart format --set-exit-if-changed .` | 确保格式一致 |
| Flutter 分析 | `flutter analyze --no-pub` | 静态分析，检测错误 |
| Flutter 测试 | `flutter test` | 运行所有测试 |

如果提交只涉及文档或配置文件，所有检查会自动跳过。

## 安装

克隆仓库后运行一次安装脚本：

```bash
./utils/setup-hooks.sh
```

完成。钩子已对所有后续提交生效。

### 手动安装

如果你更喜欢手动安装：

```bash
cp utils/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 使用方法

钩子在每次 `git commit` 时自动运行，无需额外操作。

```bash
# 正常提交 — 钩子自动运行
git commit -m "feat(deck): add card sorting"

# 如果检查失败，修复问题后重新提交
dart format .
git add .
git commit -m "feat(deck): add card sorting"
```

### 跳过钩子

在极少数需要绕过钩子的情况下（不推荐）：

```bash
git commit --no-verify -m "wip: work in progress"
```

## 常见问题

### `flutter: command not found`

确保 Flutter 在 PATH 中：

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

将此行添加到 `~/.bashrc` 或 `~/.zshrc` 使其永久生效。

### `gofmt: command not found`

确保 Go 已安装且在 PATH 中：

```bash
export PATH="$PATH:/usr/local/go/bin"
```

### 钩子没有运行

验证钩子已安装且有执行权限：

```bash
ls -la .git/hooks/pre-commit
```

如果缺失，重新运行安装脚本：

```bash
./utils/setup-hooks.sh
```

## 平台兼容性

| 操作系统 | 是否支持 | 说明 |
|----------|----------|------|
| Linux | 是 | 完全兼容 |
| macOS | 是 | 完全兼容 |
| Windows + Git Bash | 是 | Git for Windows 自带 Git Bash，钩子会自动通过它运行 |
| Windows (cmd / PowerShell) | 否 | Bash 脚本 — 请使用 Git Bash |

> **注意**：如果你使用 Windows，请确保安装了 [Git for Windows](https://gitforwindows.org/)，它包含 Git Bash。Git 钩子会自动通过 Git Bash 运行，无需额外配置。

## 编辑钩子

钩子源文件在 git 中跟踪，位于：

```
utils/pre-commit
```

修改钩子的步骤：

1. 编辑 `utils/pre-commit`
2. 重新运行 `./utils/setup-hooks.sh` 安装更新版本
3. 提交更新后的源文件，让团队也获得修改
