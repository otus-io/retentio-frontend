
🌐 [English](cursor_rules.md) | [中文](cursor_rules_zh.md)

---

# AI 代理指令

Claude Code、Cursor 和 Codex 共用同一套指令。

| 内容 | 位置 | 何时加载 |
|------|------|----------|
| 始终生效的规则 | [`AGENTS.md`](../AGENTS.md) | 每个任务 |
| Claude Code 入口 | `CLAUDE.md`（导入 `AGENTS.md`） | 每个任务 |
| 针对特定任务的技能 | `.agents/skills/<name>/SKILL.md` | 按描述按需加载 |
| Claude Code 技能路径 | `.claude/skills`（指向 `.agents/skills` 的符号链接） | 按需加载 |

## 始终生效的规则（`AGENTS.md`）

- 项目规范：提交、PR、文档、Dart 代码风格
- Git 工作流：使用功能分支，禁止直接推送到 `main`
- 校验与最小改动：改动前后校验、最小化 diff、修复生产代码而不是测试、新代码 100% 覆盖率
- 简洁回复与成本优化

## 技能

| 技能 | 何时使用 | 说明 |
|------|----------|------|
| `flutter-frontend` | 编辑 `lib/**/*.dart`、ARB 文件 | Riverpod、go_router、Dio、共享组件 |
| `testing` | 编辑 `test/**/*.dart` | Widget/模型测试、黑盒测试原则 |
| `ci-workflows` | 编辑 `.github/workflows/**` | 本仓库的 GitHub Actions |

## 添加或修改指令

1. 每个任务都必须遵守的规则写入 `AGENTS.md`。
2. 只针对某类任务的指导写入新的 `.agents/skills/<name>/SKILL.md`，frontmatter 包含 `name`
   （与目录名一致）和 `description`，并在描述中说明何时使用。
3. 不要添加工具专用的副本（`.cursor/rules`、`.claude/skills` 下的文件），请直接修改共享文件。
4. 同步更新本文档和 `cursor_rules.md`。
