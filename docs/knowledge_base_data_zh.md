# 数据与媒体

🌐 [English](knowledge_base_data.md) · [知识库](knowledge_base_zh.md)

客户端是在线优先。卡组、词条、到期时间、标签、目录、贡献、统计和媒体二进制的权威都在服务端。本机只留会话、偏好、发现收藏、待提交贡献，以及为了播放而下载的临时媒体。

`offline_learning_cache_plan_zh.md` 和 `hive-local-storage_zh.md` 里的 `local_decks`、`local_facts`、`local_cards`、`review_outbox` 在 `lib/` 里没有实现。

## 三层数据

| 层 | 放什么 | 断了会怎样 |
| --- | ------ | ---------- |
| 远程 API | 业务主数据 | 出卡和评分失败。加载失败往往显示成「没有卡」，没有单独的断网文案 |
| 内存 | 卡组列表、当前学习卡、预取、筛选、播放器 | 进程结束就没了。登出会使卡组列表和资料失效 |
| 本机 | 见下表 | 还在。已下载的图片和音频可能还能打开。视频没有本地文件缓存 |

### 本机键

| 位置 | 键 | 内容 |
| ---- | -- | ---- |
| SharedPreferences | `token` / `isLogin` | 会话 |
| SharedPreferences | `localeCode` | 语言 |
| Hive `hydrated_box` | `ThemeModeNotifier` | light / dark / sepia / system |
| SharedPreferences | `discovery_favorite_ids` | 发现收藏的源卡组 id |
| SharedPreferences | `retentio_pending_contribs_v2:{deckId}` | 待提交贡献 |
| SharedPreferences | `retentio_sent_contribs_v1:{deckId}` | 已发送贡献，最多 200 条 |
| SharedPreferences | `qa_columns_{deckId}` | QA 勾选过的列 |
| SharedPreferences | `deck_typography_*_{deckId}` | 这套卡组的正反面和注音字号 |
| 临时目录 `audio/` | 按远程地址 | 音频播放缓存。小于 256 字节视为无效 |
| 临时目录 | 图片缓存 | 学习时的图片。请求带 Bearer |
| 临时目录 | `fact_voice_*` | 还没上传的录音 |

## 环境和鉴权

`--dart-define=API_ENV=debug|dev|release`。不传时，release 构建用 release，其他构建用 dev。`--dart-define=API_HOST=` 优先于这张表。

| `API_ENV` | 主机 |
| --------- | ---- |
| `debug` | `http://localhost:8080` |
| `dev` | `https://10.0.0.145:8443` |
| `release` | `https://api.retentio.app:8443` |

有 token 时，请求头是 `Authorization: Bearer <token>`。图片和视频播放单独带上同一头。401 清 token 并恢复会话，见 [账号与导航](knowledge_base_auth_zh.md)。

没有全局请求重试队列。图片加载器自身会重试几次。同一段音频的并发下载会合并成一次。

## 客户端真正在调用的接口

`docs/api_progress_tracker.md` 里不少「前端未做」已经过时。下面是 `lib/` 里实际发出的动作。

| 域 | 动作 |
| --- | ---- |
| 认证 | `POST /auth/register`、`/auth/login`、`/auth/logout`、`/auth/forgot-password`、`/auth/reset-password`、`/auth/verify-email`、`/auth/resend-verification` |
| 资料 | `GET /api/profile` |
| 卡组 | `GET/POST /api/decks`，`GET/PATCH/DELETE /api/decks/{id}` |
| 学习 | `GET/PATCH /api/decks/{id}/card`；`DELETE /api/decks/{id}/cards/{cardId}`；`GET /api/decks/{id}/cards?stats_only=true`（可带 `tag_id`） |
| 词条 | `POST /api/decks/{id}/facts/append`；`GET/PATCH /api/decks/{id}/facts/{factId}`；`GET /api/decks/{id}/facts/ids` |
| 媒体 | `POST /api/media`。播放地址由客户端拼成 `/api/media/{id}`，更新对比里可以带 `?v=` |
| 标签 | `/api/tags` 的增删改查；卡组标签和词条标签的挂上、卸下、列表 |
| 目录 | `GET /api/decks/catalog`、`GET /api/decks/catalog/{id}`、`POST /api/decks/import` |
| 同步 | `GET /api/decks/{id}/updates`、`GET …/updates/facts/{factId}`、`POST …/sync` |
| 发布 | `POST /api/decks/{id}/publish`、`GET …/publish-preview` |
| 贡献 | report / edit / add / fact_tags / deck_tags 的提交；`GET …/contributions`；接受；`PATCH` 状态 |
| 统计 | `GET /api/decks/{id}/reviews/by-day?days=` |
| QA | `GET/PUT …/facts/{factId}/quality`；`GET …/quality/stats` |

路径已经定义、学习或发件箱没有调用的包括：词条分页列表、`/reschedule`、字段重命名贡献、模板贡献。

## 媒体怎么走

选文件、相册或录音 → 按大小和类型预检 → 先挂在添加/编辑行的本地路径上 → 保存词条时上传 → entry 里换成媒体 id → 服务端再在出卡时把媒体放进卡片槽位。

录音前会暂停正在播的卡片音频，避免和麦克风抢会话。

学习时：

- 图片走带鉴权的缓存。失败显示加载失败。
- 音频先下载到临时目录再播。出卡和预取时会尽力预下载，失败不提示。加载失败只在控件上显示不可用。
- 视频直接播网络地址，带鉴权，不落本地文件。翻面或离开时暂停。

`json` 类型的卡片条目当前不渲染。

## 用户能看见的失败

| 场景 | 表现 |
| ---- | ---- |
| 评分或隐藏失败 | 错误提示，停在当前卡 |
| 取卡失败 | 多半变成空卡文案，而不是「网络错误」 |
| 上传或保存词条失败 | 提示。已填内容留在表单上的程度以当前页面为准 |
| 贡献 | 先只在本机。用户打开发件箱才上传。成功和失败都有提示 |
| 401 | 回登录流程，没有单独的全局提示 |

## 代码入口

`lib/services/env.dart`、`lib/services/api.dart`、`lib/services/apis/`、`lib/pre_config.dart`、`lib/features/deck_study/data/repositories/deck_study_legacy_service_repository.dart`、`lib/screen/deck/fact_add_composer/media_handling_coordinator.dart`、`lib/utils/audio_cache_utils.dart`、`lib/features/contributions/pending_contributions_store.dart`。
