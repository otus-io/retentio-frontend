# Retentio 业务知识库

🌐 [English](knowledge_base.md)

界面品牌名是 **Rete**（`lib/constants.dart` 的 `kAppName`，以及 en / zh / ja 的 `appTitle`）。仓库名是 Retentio。客户端代码和文案里没有「真理」。

本文按当前 Flutter 客户端整理业务规则，给产品、测试和后续开发当对照。服务端内部公式客户端读不到时，标成「客户端未证实」。

下列文档若与本文冲突，以本文和代码为准：`api_progress_tracker.md`（多处前端状态已过时）、`offline_learning_cache_plan_zh.md`、`hive-local-storage_zh.md`、`plan_add_facts.md`。

## 产品

Rete 是在线优先的间隔重复词汇客户端。用户拥有卡组；卡组由词条组成；服务端按模板把词条变成卡片。学习时取出最紧急的一张，先回忆正面，再翻面核对，用滑块选定下次间隔并提交。作者可以把源卡组公开发布；其他人导入成自己的副本，在副本上学习和修改，再把修改作为贡献交给作者。作者再发布后，导入者可以逐条选择接受更新或保留本地。

学习出卡、评分、改词条、上传媒体都走 HTTP。断网不能完成一轮复习。本地只持久化登录态、偏好、发现收藏和待提交贡献。

## 领域

| 文档 | 回答的问题 |
| ---- | ---------- |
| [账号与导航](knowledge_base_auth_zh.md) | 谁能进哪些页面，会话怎么维持 |
| [卡组与发现](knowledge_base_decks_zh.md) | 卡组从创建到发布、导入、同步的生命周期 |
| [学习](knowledge_base_study_zh.md) | 一次复习怎么进行，间隔和进度怎么算 |
| [词条、标签与协作](knowledge_base_content_zh.md) | 内容怎么写、怎么筛、导入者与作者怎么协作 |
| [数据与媒体](knowledge_base_data_zh.md) | 数据放在哪、媒体怎么走、断网时还剩什么 |

## 对象

```text
用户
 └─ 源卡组（sourceDeckId 为空）
     ├─ 列名 fields、每日新卡上限 rate
     ├─ 词条 Fact（一行 = 若干 entry：文本 / 图 / 音 / 视频）
     ├─ 卡片 Card（学习单位，引用 factId；正反面由服务端按 template 填好）
     └─ 发布快照 → 目录 CatalogDeck
            └─ 他人导入 → 导入副本（新 id，钉住 sourceDeckId + sourceVersion）
```

标签是用户级对象，可以挂在卡组或词条上。学习筛选只用词条标签。

一张词条通常对应一张卡（添加时客户端不传 template，由服务端生成）。模型允许多张 sibling 卡。删除一张卡不会删除词条，也不会动同词条的其他卡。客户端没有编辑 template 的界面，也没有删除词条的入口。

## 两种卡组

| | 源卡组 | 导入副本 |
| --- | --- | --- |
| 判定 | `sourceDeckId` 为空 | `sourceDeckId` 非空 |
| 改名称、列名 | 可以 | 界面禁用，提交只改每日配额 |
| 发布 | 可以，且界面只发 `public` | 不可以 |
| 删除 | `publishedVersion > 0` 时客户端直接禁止 | 可以 |
| 贡献 | 收件箱（已发布源） | 发件箱 |
| QA | 菜单不提供 | 提供 |
| 更新 | 发布预览，提示有未发布改动 | 对比源版本，接受或保留本地 |

`isImported` 与「已发布源」互斥。导入副本即使带有 `publishedVersion`，也不算已发布源。

## 一条学习

1. 打开卡组，向服务端要最紧急的卡（可带词条标签）。
2. 看正面。点「显示答案」只翻面，不请求网络。
3. 在背面用滑块选下次间隔（秒）。短、中、长由「当前间隔（不足 5 分钟按 5 分钟）× 逾期程度」算出，不读卡组上的 `minInterval` / `defInterval` / `maxInterval`。详见 [学习](knowledge_base_study_zh.md)。
4. 点下一张：提交 `interval` 和客户端的 `last_review`。到期日由服务端写回。
5. 成功后展示预先取好的下一张。失败则停在当前卡。

隐藏走另一次提交（`hidden: true`），不能和间隔放在同一次请求里。

## 全局规则

- 路由是否放行看 `AuthBloc` 是否 `authenticated`，不是单独看本地 `isLogin` 标记。
- 免登录路径：`/login`、`/register`、`/reset-password`、`/verify-email`，以及任意 `/discovery/` 详情。主壳 `/` 和学习 `/study` 需要登录。
- 没有 refresh token。401 会清掉本地 token，再走一次会话恢复，受保护页面回到登录。
- 邮箱未验证不阻止登录，只在资料页提示并可重发。
- 注册成功不自动登录。
- 发现收藏只存在本机，不跟账号走。
- 导入者的修改先落在自己的副本上，贡献要在发件箱里手动提交。
- 客户端没有离线复习队列，也没有假期重排界面（`/reschedule` 只有路径常量和错误文案）。

## 客户端没有的能力

- 离线整卡组学习、本地调度、复习补传
- 子卡组
- 添加词条时选择 prepend / shuffle / spread，或手改出卡模板
- 删除词条、编辑个人资料（没有 `PATCH /api/profile` 调用）
- 排行榜
- 目录里标识「我已导入」
- 创建卡组时选择 private / public（发布时写死 public）

## 代码入口

| 区域 | 路径 |
| ---- | ---- |
| 启动与主壳 | `lib/main.dart`、`lib/pre_config.dart` |
| 路由 | `lib/routers/routers.dart`、`lib/routers/app_pages.dart` |
| 认证 | `lib/features/auth/` |
| 卡组列表与发现 | `lib/screen/decks/`、`lib/features/discovery/` |
| 学习 | `lib/features/deck_study/`、`lib/screen/deck/` |
| 词条与贡献 | `lib/screen/deck/fact_widgets/`、`lib/features/contributions/` |
| QA | `lib/screen/qa/` |
| API | `lib/services/api.dart`、`lib/services/apis/` |
