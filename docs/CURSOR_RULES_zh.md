🌐 [English](CURSOR_RULES.md) | [中文](CURSOR_RULES_zh.md)

---

# Cursor 规则

本项目使用 [Cursor Rules](https://docs.cursor.com/context/rules-for-ai) 为 AI 提供持久化的编码指导。规则文件存储在 `.cursor/rules/` 目录下，根据上下文自动激活。

## 规则概览

| 规则 | 文件 | 适用范围 | 说明 |
|------|------|----------|------|
| 项目规范 | `project-conventions.mdc` | 始终生效 | 项目级标准：提交、PR、文档、代码风格 |
| Go 后端 | `go-backend.mdc` | `api/**/*.go` | Go 编码模式、Redis、JWT、中间件、Swagger |
| Flutter 前端 | `flutter-frontend.mdc` | `frontend/lib/**/*.dart` | Riverpod、go_router、Dio、模型与页面规范 |
| 测试 | `testing.mdc` | `frontend/test/**/*.dart` | 黑盒测试原则与 Flutter 测试规范 |
| CI/CD 工作流 | `ci-workflows.mdc` | `.github/workflows/**` | GitHub Actions 工作流规范 |

## 规则如何工作

- **始终生效** 的规则在每次 AI 对话中都会激活，无论打开了哪些文件。
- **文件范围** 的规则在打开或编辑匹配 glob 模式的文件时自动激活。
- 规则只是为 AI 提供的只读指导——不会修改代码或强制执行 lint 检查。

## 规则详情

### 项目规范（始终生效）

适用于所有场景的核心标准：

- **提交格式**：`<type>(<scope>): <subject>`（例如 `feat(deck): add card sorting`）
- **PR 大小**：代码变更不超过 200 行，提交不超过 3 个
- **代码风格**：Go 遵循 Effective Go + `gofmt`；Dart 遵循 Effective Dart + `dart format`
- **文档**：所有面向用户的文档必须提供中英文版本
- **测试原则**：不要为了让测试通过而修改生产代码——测试是用来发现 bug 的

### Go 后端

编辑 `api/` 中的文件时激活：

- 架构概览：gorilla/mux 路由、Redis 存储、JWT 认证
- 中间件链：CorsMiddleware → JwtAuthMiddleware → 处理函数
- 使用 `common.SendErrorResponse` 的错误处理模式
- Redis 键模式和数据访问规范
- Swagger 注解要求

### Flutter 前端

编辑 `frontend/lib/` 中的文件时激活：

- 使用 Riverpod 进行状态管理（ProviderScope、StateNotifier、ConsumerWidget）
- 使用 go_router 进行路由管理
- 通过 Dio 和拦截器进行 HTTP 调用
- 模型规范：`fromJson`/`toJson` 需要处理空值和类型安全
- 页面组织：每个功能模块有自己的 `providers/` 和 `widgets/`

### 测试

编辑 `frontend/test/` 中的文件时激活：

- **黑盒测试原则**：测试是用来发现 bug 的，不是用来通过的
- 不要为了绕过生产代码的 bug 而修改测试数据
- 使用 ProviderScope 包装的 Widget 测试模式
- 针对空值和边界情况的模型测试模式
- 测试报告格式和位置（`docs/` 根目录下的按日期命名的 Markdown 摘要，例如 `docs/2026-02-11-test-summary.md`）

### CI/CD 工作流

编辑 `.github/workflows/` 中的文件时激活：

- 后端 CI：Go 1.23、Redis 服务、构建 + vet + 格式化 + 测试
- 前端 CI：Flutter stable、格式化 + 分析 + 测试
- PR 审查：Claude AI 自动审查
- 部署：推送到 main 时通过 SSH 部署

## 添加新规则

1. 在 `.cursor/rules/` 中创建 `.mdc` 文件
2. 添加 YAML frontmatter，包含 `description`、`globs`（可选）和 `alwaysApply`
3. 规则保持简洁（50 行以内）且可操作
4. 添加或修改规则时请更新本文档
