# Retentio（Flutter）

🌐 [English](../README.md) | 中文

Retentio 的 Flutter 客户端。入口：`lib/main.dart`。依赖与 SDK 版本见 `pubspec.yaml`。

## 快速开始

在仓库根目录执行：

```bash
flutter pub get
flutter run
```

`ios/Flutter/Generated.xcconfig` 由 Flutter **生成**且已在 `.gitignore` 中。若 Xcode 提示找不到该文件，请在仓库根目录再次执行 **`flutter pub get`**，并打开 **`ios/Runner.xcworkspace`** 进行构建或归档。

### 后端环境与 API 地址

通过 `--dart-define` 在编译期配置（实现见 `lib/services/env.dart`）：

- `API_ENV=debug|dev|release`。未指定时：**release / 正式构建**（如 `flutter build ipa`、Xcode Archive）默认连 **生产**；日常 `flutter run` 等非 release 构建默认 **dev**。
- `API_HOST=<完整 base URL>` 若非空，则覆盖 `API_ENV` 对应的主机。

主机映射：

- `debug` → `http://localhost:8080`
- `dev` → `https://10.0.0.145:8443`
- `release` → `https://api.retentio.app:8443`

示例：`flutter build ipa --dart-define=API_ENV=dev` 可在正式包中指向开发环境。

## Git 钩子

克隆后于仓库根目录执行一次 `./utils/setup-hooks.sh`，安装 **pre-commit**（dart格式、`flutter analyze`、测试）。

完整说明：[pre_commit_hook_zh.md](pre_commit_hook_zh.md) · [English](pre_commit_hook.md)

## 仓库结构

| 路径 | 说明 |
|------|------|
| `lib/`、`android/`、`ios/`、… | Flutter 应用（`pubspec.yaml` 位于仓库根目录）。 |
| `docs/` | 项目文档：`docs/` 根目录下的 Markdown 文件（无子文件夹）。 |
| `utils/` | 辅助脚本（例如 pre-commit）。 |
| `.github/` | GitHub 模板与工作流。 |

## 文档

- **API 文档：** [api_zh.md](api_zh.md)（[English](api.md)）

## `lib/` — 应用代码

### 启动与配置

- **`main.dart`** — `main()`、`WidgetsFlutterBinding`、`PreConfig.init()`、`runApp`（`UncontrolledProviderScope` + `ProviderScope`）、`MaterialApp.router`、底部导航 `MainTabScreen`。
- **`pre_config.dart`** — 一次性启动：文档目录、基于 Hive 的 hydrated 存储、`ApiService.init()`、带拦截器的 `DioClient` 配置。
- **`constants.dart`** — 应用内共享常量。

### 路由

- **`routers/routers.dart`** — `AppRoutes` 枚举（登录、主页、注册、学习等路径字符串）。
- **`routers/app_pages.dart`** — `GoRouter`：路由、鉴权 `redirect`、随登录状态刷新的 `refreshListenable`。

### 全局 providers

- **`providers/`** — 应用级 Riverpod 状态：认证（`auth_provider.dart`）、主题、语言、加载辅助等。

### 网络与持久化

- **`services/index.dart`** — 聚合 HTTP 客户端、环境与 API 路径常量；从此路径导入 `DioClient`、`Env`、`Api`。
- **`services/dio_client/`** — `DioClient` 单例、请求辅助、`interceptors.dart`（请求头、响应处理、非 release 构建下的日志）。
- **`services/apis/`** — 薄 API 封装：`api_service.dart`（token、通用 HTTP）、`auth_service.dart`、`deck_service.dart`、`card_service.dart` 等，基于 `ApiService` / `DioClient` 并将响应映射为模型。
- **`services/storage/`** — Hydrated 存储（`hydrated_storage.dart`、`hydrated_notifier.dart`、存储相关异常）。

### 数据模型

- **`models/`** — 与后端对齐的可序列化类型：`api_response.dart`、`deck.dart`、`card.dart`、`fact.dart`、`user.dart` 等。

### 页面（功能 UI）

`screen/` 下按功能域划分：

| 目录 | 职责 |
|--------|------|
| `screen/login/` | 登录 UI、控制器、找回密码控件。 |
| `screen/register/` | 注册与控制器。 |
| `screen/home/` | 首页 Tab（欢迎类占位内容）。 |
| `screen/decks/` | 卡组列表 Tab：`deck_list_screen.dart`、`providers/`（`deck_list.dart`、`deck_create.dart`）、`widgets/`（列表主体、列表行卡片、创建表单、加载态展示等）。 |
| `screen/deck/` | 卡组视图 / 学习：`deck_view_screen.dart`、`providers/`（`card_review.dart`、`review_interval_range.dart`、`audio_player.dart`）、`formatters/`、`deck_widgets/`（菜单、主体、间隔控件）、`card_widgets/`（翻面、卡面、媒体）、`fact_widgets/`（添加 / 编辑 / 内容）、`fact_add_composer/`（添加知识点表单相关模型与 UI 片段）。 |
| `screen/profile/` | 个人资料 Tab 及相关 providers。 |

功能的 provider 通常与页面同级（`screen/<功能>/providers/`）。部分页面使用嵌套的 **`ProviderScope`** 与 **overrides**（例如 `deck_view_screen.dart` 向 `cardProvider` 注入当前 `Deck`，并为标题栏 / 编辑流程初始化 `createDeckParamsProvider`）。

### 共享 UI 与工具

- **`widgets/`** — 可复用组件（`buttons_tab_bar`、`common_refresher`、`common_bottom_sheet`、`number_picker` 等）。
- **`video_player/`** — 基于官方 `video_player` 插件的自研播放 UI（内嵌与全屏、控件与设置等）。
- **`utils/`** — 日志、防抖、小工具。
- **`extensions/`** — `BuildContext`、`Widget`、`Map` 等扩展。
- **`mixins/`** — 共享 notifier 或生命周期行为（`refresh_controller_mixin`、`delayed_init_mixin` 等）。

### 本地化

- **`l10n/`** — 生成的 `app_localizations*.dart` 与 ARB 源文件（`app_en.arb`、`app_zh.arb`）。`pubspec.yaml` 中启用 Flutter `generate: true`。

## 模块如何协作

1. **启动** — `PreConfig` 初始化存储、加载 auth token，用 **`Env`** 中的 base URL 配置 **Dio**。
2. **导航** — `app_pages.dart` 中的 **go_router** 根据登录状态控制路由；auth notifier 上的 **`ChangeNotifier`** 在登录态变化时刷新路由。
3. **数据流** — UI **Consumer** / **ref.watch** → **Notifier** providers → **\*Service** → **ApiService** / **DioClient** → **`ApiResponse`** / 领域 **models**。
4. **作用域状态** — 部分路由使用 **`ProviderScope(overrides: …)`**，向功能 provider 注入正确的 `Deck` 或参数，而无需全局单例。

## 测试

测试位于 `test/`，结构尽量与 `lib/` 对应（`test/providers/`、`test/screen/`、`test/services/`、`test/models/` 及 `test/helpers/` 等）。命令与约定见 [frontend_tests_zh.md](frontend_tests_zh.md)（[English](frontend_tests.md)）。

## 工具链

- **`analysis_options.yaml`** — Dart 分析器与 lint 规则（继承 `flutter_lints`）。
- **`devtools_options.yaml`** — DevTools 偏好。

各平台构建产物位于 `android/`、`ios/` 等目录；此处不重复说明。
