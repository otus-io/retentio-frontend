# 本地离线学习缓存方案

**目标：** 无论是否联网，默认都从本地 Hive 读卡学习；仅在需要从服务端下载/更新学习包，或把本地卡片数据推送到服务端时才与服务器通信。无网络时亦可继续学习已下载卡组。

做一个独立的本地优先学习链路：

- 学习时默认从本地 Hive 读卡片，由前端调度器计算下一张。
- 按需从服务端下载或刷新卡组学习包。
- 复习、隐藏操作先落本地，再写同步队列。
- 待同步队列超过 100 张卡片时可尝试自动上传；未超过阈值时，即使已联网也不自动上传。
- 同步成功后，以服务端返回的卡片状态覆盖本地临时状态。
- 学习进度只走本地队列与上传；本方案不覆盖内容编辑。

## 首期范围

首期只做离线学习与复习进度同步，不考虑离线编辑（意义不大）。

支持：

- 打开已下载卡组。
- 看正反面、翻面。
- 提交复习间隔。
- 隐藏当前卡片。
- 使用已下载的标签筛选。
- 展示待同步状态。
- 待同步队列超过 100 张时自动上传复习进度。

不支持：

- 离线创建、删除卡组。
- 离线新增、删除词条。
- 离线上传媒体。
- 离线导入、同步共享卡组。
- 离线删除卡片。

新增、删除、媒体上传和共享卡组同步涉及服务端 ID、权限和版本冲突，首期不纳入。

## 用户路径

### 下载

下载入口放在两个地方：

- 发现模块中点击“导入”时，下载卡组的离线学习数据。
- 点击卡组进入学习时，检查并补充本地缓存。

下载策略：

- 文本必下。
- 音频、图片默认下载。
- 视频默认不下载。
- 下载完成后，卡组显示“可离线学习”。
- 下载失败不阻塞导入和学习入口，页面只展示缓存状态。

### 学习

进入学习页时：

1. 有本地学习包：优先本地出卡，后台尝试刷新。
2. 无本地学习包且在线：走现有服务端学习接口。
3. 无本地学习包且离线：提示需要联网下载。

离线复习不能等待网络。用户点下一张后，UI 立即更新。

本地学习查询直接查 Hive，不起本地 HTTP 服务，也不走 `127.0.0.1`。

### 同步

用户复习卡片后，客户端直接写本地同步队列。

自动上传条件：待同步队列超过 100 张卡片，且当前已联网。未超过 100 张时，即使已联网也不自动上传。

满足阈值后，可在网络恢复、应用启动、回到前台，或用户手动重试时触发同步。

同步失败不阻塞学习，只更新状态：

- `离线学习`
- `等待同步`
- `同步中`
- `同步失败`
- `需要重新登录`

### 红点

红点只表示需要用户处理的更新状态，不表示学习进度同步。

| 类型 | 触发条件 | 无网时是否显示 |
| --- | --- | --- |
| 有更新 | 导入卡组检测到源卡组有新版本 | 否 |

更新检查触发时机：

- 进入卡组页。
- App 回到前台。
- 网络从无到有。
- 学习页后台低频检查。

导入卡组的更新检查使用 GET 请求，轮询间隔为 60 秒。无网时不发请求，也不显示“有更新”红点。

## 架构

```text
[发现模块-导入] --------+
                         |
[点击卡组进入学习] ------+--> [离线包检查]
                              |
                 +------------+------------+
                 |                         |
            [本地有缓存]              [无缓存且在线]
                 |                         |
                 v                         v
              [Hive] <------------- [远程接口]
                 |
                 v
          [OfflineScheduler]
                 |
                 v
       [DeckStudyRepository]
                 |
                 v
           [DeckStudyBloc]
                 |
                 v
             [学习页面]

[复习/隐藏]
     |
     v
[更新本地卡片] -> [StudySyncQueue] -> [队列 > 100 且已联网] -> [同步接口]
```

学习链路：

- `LocalOfflineLearningDataSource`：读写本地 Hive 中的离线卡组、词条和卡片。
- `RemoteOfflinePackageDataSource`：联网时下载或刷新离线学习包。
- `OfflineScheduler`：在前端执行后端原有的下一张卡计算逻辑。
- `StudySyncQueue`：记录待同步的复习和隐藏事件。
- `OfflineFirstDeckStudyRepository`：统一本地读取、远程刷新、出卡和同步入口。

关键点：

- `DeckStudyBloc` 尽量不改。
- 保持 `DeckStudyRepository` 接口稳定。
- 新增 `OfflineFirstDeckStudyRepository` 替换旧的纯远程实现。
- API 层不直接改 BLoC、Cubit 或 Riverpod 状态。

## 本地存储

不要把离线学习包塞进现有 `hydrated_box`。它是业务数据，需要独立 Box。

Web 前端可以用 React Query 做服务端缓存；Flutter APP 侧以 Hive 和 Repository 为准。

新增 Hive boxes：

```text
offline_decks
offline_facts
offline_cards
offline_tags
offline_media
offline_sync_queue
offline_sync_meta
```

所有 key 带账号作用域：

```text
{accountId}:deck:{deckId}
{accountId}:fact:{factId}
{accountId}:card:{cardId}
{accountId}:sync:{operationId}
```

这样可以避免切换账号后读到别人的缓存。

### 离线卡组

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "name": "Japanese N5",
  "server_version": 12,
  "content_hash": "sha256:...",
  "downloaded_at": 1776153600,
  "last_synced_at": 1776157200,
  "card_count": 1200,
  "media_bytes": 52428800,
  "has_pending_operations": false
}
```

### 离线词条

词条数据以 JSON 形式保存，再导入 Hive。它用于离线渲染，以及后续做内容增量更新。

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "fact_id": "fact-1",
  "fields": ["Question", "Answer"],
  "entries": [
    {
      "text": "猫",
      "audio": "media-1",
      "image": "",
      "video": "",
      "json": ""
    }
  ],
  "server_version": 12,
  "updated_at": 1776157200
}
```

### 离线卡片

直接保存现有 `CardDetail` 需要的内容，再加本地同步字段。注意 `front`/`back` 实际嵌套在 `CardDetail.card` 里（见 `lib/models/card.dart`），不是 `CardDetail` 的顶层字段，落库结构需按实际嵌套调整，下面为方便阅读做了展平。

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "card_id": "card-1",
  "fact_id": "fact-1",
  "front": [],
  "back": [],
  "hidden": false,
  "last_review": 1776150000,
  "due_date": 1776236400,
  "urgency": 0.8,
  "tag_ids": ["tag-1"],
  "server_version": 12,
  "local_revision": 3,
  "dirty": true,
  "updated_at": 1776157200
}
```

### 同步队列

复习结果用事件队列保存，不只保存最终状态。

```json
{
  "operation_id": "op-01J...",
  "account_id": "user-1",
  "device_id": "device-a",
  "client_sequence": 1024,
  "deck_id": "deck-1",
  "card_id": "card-1",
  "type": "review",
  "payload": {
    "interval": 86400,
    "last_review": 1776157200
  },
  "created_at": 1776157200,
  "attempts": 0,
  "next_retry_at": 1776157200,
  "status": "pending",
  "last_error": null
}
```

首期队列类型：

| 类型 | 用途 |
| --- | --- |
| `review` | 同步复习间隔和复习时间 |
| `hide` | 同步隐藏状态 |

## 本地出卡规则

当前 `GET /api/decks/{id}/card` 会由后端计算最紧急卡片，并返回下一张预取卡。
离线时不再调用这个接口，必须把同一套选卡逻辑移植到前端。

后端需要提供或明确以下规则，前端按同样规则实现：

- 哪些卡片属于候选集。
- 新卡、到期卡和逾期卡的优先级。
- `urgency` 的计算方式。
- 同一优先级下的稳定排序规则。
- 隐藏卡、标签筛选和已复习卡的处理方式。
- 无卡可学时的结束条件。

不要在前端重新设计一套近似算法，否则在线和离线会出现不同的学习顺序。

候选卡片：

```text
hidden == false
due_date <= nowUtcSeconds
tagId == null 或 tag_ids 包含 tagId
```

排序：

1. 先执行后端定义的候选过滤。
2. 按后端定义的紧急度和卡片类型排序。
3. 使用 `card_id` 作为最终稳定排序字段。

复习提交后立即更新本地卡片：

```text
last_review = nowUtcSeconds
due_date = nowUtcSeconds + selectedInterval
dirty = true
```

然后写入同步队列。卡片更新和队列写入需要封装成同一个本地事务语义，避免应用被杀后只写了一半。

## 后端接口

### 离线学习包

新增：

```http
GET /api/decks/{id}/offline-package
```

参数：

| 参数 | 说明 |
| --- | --- |
| `version` | 客户端已有版本，用于增量更新 |
| `include_media` | 是否返回媒体清单 |
| `cursor` | 分页游标 |
| `limit` | 单页数量 |

响应核心字段：

```json
{
  "data": {
    "deck": {
      "id": "deck-1",
      "name": "Japanese N5",
      "fields": ["Question", "Answer"],
      "version": 12
    },
    "tags": [],
    "facts": [],
    "cards": [],
    "media": [],
    "pagination": {
      "cursor": "next...",
      "has_more": true
    },
    "content_hash": "sha256:..."
  },
  "meta": {
    "version": 12
  }
}
```

为什么要新接口：

- 现有 `GET /api/decks/{id}/card` 只给当前卡和一张预取卡。
- 现有 `GET /api/decks/{id}/cards` 主要是统计和列表，不适合完整离线包。
- 客户端自己拼多个接口，容易出现半成功状态。

### 复习事件同步

新增批量同步接口：

```http
POST /api/sync/study-events
```

请求：

```json
{
  "device_id": "device-a",
  "events": [
    {
      "operation_id": "op-01J...",
      "client_sequence": 1024,
      "deck_id": "deck-1",
      "card_id": "card-1",
      "type": "review",
      "interval": 86400,
      "last_review": 1776157200
    }
  ]
}
```

响应：

```json
{
  "data": {
    "accepted": ["op-01J..."],
    "already_applied": [],
    "conflicts": [],
    "cards": [
      {
        "card_id": "card-1",
        "last_review": 1776157200,
        "due_date": 1776243600,
        "hidden": false,
        "server_version": 13
      }
    ]
  }
}
```

接口要求：

- `operation_id` 幂等。
- `client_sequence` 保证同设备顺序。
- 服务端返回最终卡片状态。
- 客户端同步成功后用服务端状态覆盖本地状态。

短期如果只能复用 `PATCH /api/decks/{id}/card`，至少要加 `Idempotency-Key`，否则重试会有重复复习风险。

## 同步规则

队列处理：

1. 取 `pending` 且 `next_retry_at <= now` 的事件。
2. 按 `client_sequence` 升序上传。
3. 每批 20 到 50 条。
4. `accepted` / `already_applied` 后删除队列项。
5. 网络错误指数退避：`30s -> 2m -> 10m -> 30m -> 2h`。
6. 401 暂停同步，不删除队列。
7. 参数错误标记 `failed`，保留 payload。

冲突处理：

| 场景 | 处理 |
| --- | --- |
| 重复上传 | `operation_id` 去重 |
| 同设备重试 | `client_sequence` 去重 |
| 多设备复习同一卡 | 服务端按事件顺序计算最终状态 |
| 本地版本落后 | 同步后拉增量 |
| 服务端卡片已删除 | 本地标记 `remote_deleted`，不再出卡 |

## 媒体缓存

媒体单独落文件系统：

```text
documents/offline_media/{accountId}/{deckId}/{mediaId}.{ext}
```

Hive 只保存索引：

- `media_id`
- `local_path`
- `content_type`
- `bytes`
- `sha256`
- `download_status`
- `last_accessed_at`

规则：

- 文本可学是底线，媒体失败不能阻断学习。
- 下载先写临时文件，hash 通过后再替换正式文件。
- 音频、图片按卡组目录缓存。
- 视频默认不下载。
- 删除离线卡组时，只删除该卡组独占媒体。

## 安全

离线学习包包含用户内容，落地前需要：

- 离线业务 Box 使用 Hive AES 加密（当前 Hive 默认未加密，需要新增）。
- 加密 key 放安全存储，不放 `SharedPreferences`。项目目前未引入 `flutter_secure_storage`，这是新依赖，需单独评估。
- key 和数据都按账号隔离。
- 登出时检查是否有未同步事件。
- 401 时暂停队列，重新登录后继续同步。

## 代码落点

新增模块：

```text
lib/features/offline_learning/
  data/
    datasources/
      local_offline_learning_data_source.dart
      remote_offline_package_data_source.dart
      study_sync_data_source.dart
    repositories/
      offline_learning_repository_impl.dart
  domain/
    entities/
      offline_deck.dart
      offline_card.dart
      study_sync_operation.dart
    repositories/
      offline_learning_repository.dart
    services/
      offline_scheduler.dart
      offline_sync_service.dart
  presentation/
    bloc/
      offline_sync_bloc.dart
      offline_sync_event.dart
      offline_sync_state.dart
```

核心接入：

- 新增 `OfflineFirstDeckStudyRepository`。
- 它实现现有 `DeckStudyRepository`，且需保留 `DeckStudyBloc` 现有的下一张卡预取（lookahead）逻辑，否则会有体验回归。
- `deck_study` 目前未注册进 `get_it`（`lib/core/di/app_service_locator.dart` 只注册了 `auth` 模块），需先补上这一步，DI 才能按网络状态注入 Repository。

公共能力：

```text
lib/core/network/connectivity_service.dart
lib/core/storage/offline_hive_boxes.dart
lib/core/storage/account_scope.dart
```

## 测试

单元测试：

- 本地出卡筛选。
- due date 边界。
- 标签筛选。
- 隐藏卡不出队。
- 排序稳定。
- 前端调度器与后端选卡结果一致。
- 队列序列化。
- 重试退避。
- 账号隔离。
- 红点状态计算。

Repository 测试：

- 本地有卡时不打网络。
- 离线时回退本地。
- 复习后立即更新本地卡。
- 卡片状态和队列同时写入。
- 同步成功后使用服务端状态覆盖本地。
- 401 不丢队列。

BLoC / Widget 测试：

- 无离线包时提示下载。
- 离线复习后立即显示下一张。
- 同步失败不阻塞学习。
- 切换账号后看不到上个账号缓存。
- 有网后检测到导入卡组更新才显示更新红点。

验收标准：

- 飞行模式下，已下载卡组可连续学习 100 张。
- 复习点击到 UI 更新小于 100 ms。
- 杀进程再打开，待同步事件不丢。
- 多次触发同步不会重复复习。
- 同步后本地状态与服务端一致。
- 相同卡组和相同时间点下，在线与离线的下一张卡一致。
- 未下载卡组不会误显示为可离线学习。
