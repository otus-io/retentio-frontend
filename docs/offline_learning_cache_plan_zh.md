# 本地优先学习缓存方案

英文版：[offline_learning_cache_plan.md](offline_learning_cache_plan.md)

Flutter 应用采用本地优先学习：卡组元数据、词条、媒体和卡片调度一次性下载到 Hive 后，出卡与复习都在本地完成，沿用后端同一套选卡规则，无需每次点击都等网络。

复习/隐藏先写入本地队列，后台批量同步——逐条 `PATCH /api/decks/{id}/card` 上传进度，批次结束后再 `GET /api/decks/{id}` 对齐统计；队列达到 100 条及以上或离开学习/恢复网络时触发，且不用服务端 `cards[]` 覆盖本地调度。

**目标：** 无论是否联网，默认都从本地 Hive 读卡学习；仅在需要从服务端下载/更新词条与媒体，或把本地复习进度推送到服务端时才与服务器通信。无网络时亦可继续学习已下载卡组。

做一个独立的本地优先学习链路：

- 学习时默认从本地 Hive 读卡片，由前端调度器按后端 `GetNextCard` 同一套规则计算下一张。
- 按需用现有列表接口下载或刷新卡组元数据、词条、媒体；卡片调度只在首次落地时从 `GET /api/decks/{id}/cards` 播种。
- 复习、隐藏操作先落本地，再写同步队列。
- 待同步队列达到 100 条及以上时可尝试自动上传；未达到 100 条时不自动上传。离开学习页、前后台、网络恢复时也可刷写。
- **卡片进度** → `PATCH /api/decks/{id}/card`（队列 FIFO，逐条复习/隐藏）。
- **卡组统计** → 刷写批次结束后 `GET /api/decks/{id}` 的 `stats`（不用 `GET /cards` 的 `cards[]` 覆盖 Hive 调度）。
- 学习进度只走本地队列与上传；本方案不覆盖内容编辑。

## 目录

- [首期范围](#首期范围)
- [用户路径](#用户路径)
  - [下载](#下载)
  - [学习](#学习)
  - [同步](#同步)
    - [卡组统计（DeckStats）](#卡组统计deckstats)
  - [红点](#红点)
- [架构](#架构)
- [本地存储](#本地存储)
  - [离线卡组](#离线卡组)
  - [离线词条](#离线词条)
  - [离线卡片](#离线卡片)
  - [同步队列](#同步队列)
- [本地出卡规则](#本地出卡规则)
- [后端接口](#后端接口)
  - [下载与刷新（已有）](#下载与刷新已有)
  - [复习进度（已有）](#复习进度已有)
- [同步规则](#同步规则)
- [媒体缓存](#媒体缓存)
- [安全](#安全)
- [代码落点](#代码落点)
- [测试](#测试)
- [附录：对象形状参考](#附录对象形状参考)
  - [Deck（卡组）](#deck卡组)
  - [Fact / Entry（词条）](#fact--entry词条)
  - [Card（卡片）](#card卡片)
  - [Media（媒体）](#media媒体)
  - [Tag（标签）](#tag标签)
  - [Contribution（贡献 / 反馈）](#contribution贡献--反馈)
  - [离线 Hive 与 API 形状对照](#离线-hive-与-api-形状对照)

---

## 首期范围

首期只做离线学习与复习进度同步，不考虑离线编辑（意义不大）。

支持：

- 打开已下载卡组。
- 看正反面、翻面。
- 提交复习间隔。
- 隐藏当前卡片。
- 使用已下载的**词条标签**筛选（与 `GET /api/decks/{id}/card?tag_id=` 相同）。
- 展示待同步状态。
- 待同步队列达到 100 条及以上时自动上传复习进度，并对齐服务端卡组统计。

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
- 音频、图片默认下载（按词条 `entries` 里的媒体 **ID**，不要存 `GET /card` 返回的 HTTPS URL）。
- 视频默认不下载。
- 下载完成后，卡组显示“可离线学习”。
- 下载失败不阻塞导入和学习入口，页面只展示缓存状态。

首次落地（组装本地学习包，不新增后端接口）：

1. `GET /api/decks/{id}`：卡组元数据，`fields` 在这里，不在词条上。
2. `GET /api/decks/{id}/facts?limit=&offset=`：分页词条（默认 50，最大 200，`meta.has_more`）。
3. `GET /api/decks/{id}/cards`：播种本地卡片调度（`id` / `fact_id` / `template` / `last_review` / `due_date` / `hidden` / `created_at`）。此接口**没有** `front` / `back` / `urgency`。
4. 按词条媒体 ID 下载文件到本地。

之后内容刷新只拉词条与媒体，**不再**把服务端卡片调度当真相来源。

### 学习

进入学习页时：

1. 有本地学习包：优先本地出卡。在线时后台只刷新词条/媒体，不覆盖本地 `due_date` / `last_review`。
2. 无本地学习包且在线：走现有 `GET /api/decks/{id}/card`。
3. 无本地学习包且离线：提示需要联网下载。

离线复习不能等待网络。用户点下一张后，UI 立即更新。

本地学习查询直接查 Hive，不起本地 HTTP 服务，也不走 `127.0.0.1`。

`DeckStudyBloc` 继续消费 Flutter `CardDetail`。该对象是**学习时派生的 DTO**，不要当 Hive 行来存。从本地 `Card` + `Fact` + `deck.fields` 现场拼出 `CardDetail`（见下文）。

### 同步

用户复习卡片后，客户端直接写本地同步队列。**上传到服务端只用** `PATCH /api/decks/{id}/card`；`GET /api/decks/{id}/card` 仅用于无本地包时的在线出卡，不参与进度同步。

自动上传条件：待同步队列达到 100 条及以上，且当前已联网。未达到 100 条时，即使已联网也不自动上传。

满足阈值后，可在网络恢复、应用启动、回到前台、离开学习页，或用户手动重试时触发同步。**一次刷写分两步**：（1）按队列 FIFO `PATCH` 每条复习/隐藏；（2）本批次 PATCH 结束后 `GET /api/decks/{id}`，用响应 `stats` 对齐 `total_reviews` / `total_reviews_today` 等服务端计数（见「卡组统计」）。离开学习页等其它触发条件也走同样两步。

首期刷写复用现有 `PATCH /api/decks/{id}/card`（与 `DeckStudyLegacyServiceRepository.submitCard` 相同拆分）：

- 复习：`{ "card_id", "interval", "last_review" }`（不能同时带 `hidden`）。
- 隐藏：`{ "card_id", "hidden" }`（不能带 `last_review`）。

`interval` 在服务端会截成 `int64`；若 `last_review > now`，服务端会钳到 `now`，然后 `due_date = last_review + interval`。客户端本地更新应使用同一规则。

当前 PATCH **没有** 服务端幂等。刷写时每次 PATCH 必须携带 `Idempotency-Key: {operation_id}`（或等价的请求头/字段，需与后端约定）；队列侧用 `operation_id` 保证同一事件只成功提交一次，重试不得重复计入 `total_reviews`。

同步失败不阻塞学习，只更新状态：

- `离线学习`
- `等待同步`
- `同步中`
- `同步失败`
- `需要重新登录`

### 卡组统计（DeckStats）

`PATCH /api/decks/{id}/card` **只**回传单张卡的调度字段，**不**回传整包 `DeckStats`。统计分两类，离线/local-first 处理方式不同：

| 字段 | 服务端怎么来 | 本地/local-first |
| --- | --- | --- |
| `due_cards`, `unseen_cards`, `reviewed_cards`, `hidden_cards`, `new_cards_today`, `last_reviewed_at`, `cards_count` | 对卡片列表跑 `ComputeStats`（见附录） | **本地重算**：用 Hive `offline_cards`（+ 本地 `facts_count`）按同一规则算；每次复习/隐藏后立即更新。有 `tag_id` 时先按词条标签过滤 `fact_id` 再算 |
| `total_reviews`, `total_reviews_today` | **独立 Redis 计数器**；仅 PATCH **interval** 成功时 +1（隐藏不算复习） | 学习过程中本地可先乐观展示；**队列刷写批次结束后**（含达到 100 条及以上触发）必须 `GET /api/decks/{id}` 拉 `stats` 对齐。也可在 PATCH 过程中逐条 +1 估算，但以刷写后 GET 为准 |
| `facts_count` | 词条集合大小 | 本地 `offline_facts` 数量 |

**与 PATCH / GET 的关系：**

- 复习/隐藏后：本地 card 行 + 本地 **调度类** stats 立即重算；**计数类** stats 在刷写批次完成前可滞后。
- **刷写触发**（队列 ≥ 100、离开学习、前后台、网络恢复、手动重试）：先 PATCH 队列 → 再 `GET /api/decks/{id}` 同步 `stats`（至少 `total_reviews*`；可选校验 `due_cards` 等与本地重算一致）。
- `GET /api/decks/{id}/cards` 响应含 `stats` + `cards[]`：若用此接口取 stats，**只读 `stats`**；**不要用** `cards[]` 覆盖 Hive 里尚未刷写的本地调度。
- 学习页「待复习 / 进度条」：用本地 `ComputeStats`，不为 live due 打 GET。

**各 UI 建议：**

| 场景 | 做法 |
| --- | --- |
| 学习页 live due / 进度条 | 本地 `ComputeStats(local_cards)`，每次复习后刷新 |
| 卡组列表「待复习」 | 本地重算；刷写批次后可用 `GET /decks` 的 `stats.due_cards` 校验 |
| 卡组列表「累计复习 / 今日复习」 | **刷写批次结束后** `GET /decks/{id}` 更新 `stats.total_reviews*`（与 ≥100 触发同步同一时机） |

### 红点

红点只表示需要用户处理的更新状态，不表示学习进度同步。

| 类型 | 触发条件 | 无网时是否显示 |
| --- | --- | --- |
| 有更新 | 导入卡组 `source_version` 小于源卡组 `published_version` | 否 |

卡片、词条、卡组 JSON **没有** `server_version`。导入更新走现有 source / published 版本接口，不要发明通用 `version` / `content_hash` 轮询。

更新检查触发时机：

- 进入卡组页。
- App 回到前台。
- 网络从无到有。
- 学习页后台低频检查。

无网时不发请求，也不显示“有更新”红点。

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
              [Hive] <------------- [GET deck/facts/cards]
                 |                         [GET media]
                 v
          [OfflineScheduler]
                 |
                 v
       [派生 CardDetail]
                 |
                 v
           [DeckStudyBloc]
                 |
                 v
             [学习页面]

[复习/隐藏]
     |
     v
[更新本地 Card] -> [StudySyncQueue] -> [队列 ≥ 100 且已联网]
                                         -> [PATCH 队列 FIFO]
                                         -> [GET /decks/{id} 对齐 stats]
```

学习链路：

- `LocalOfflineLearningDataSource`：读写本地 Hive 中的离线卡组、词条和卡片（后端 `Deck` / `Fact` / `Card` 形状）。
- `RemoteOfflinePackageDataSource`：联网时用现有 GET 接口下载或刷新；不调用 `GET /api/decks/{id}/card` 来灌缓存。
- `OfflineScheduler`：在前端执行 `GetNextCard` 的选卡逻辑。
- `StudySyncQueue`：记录待同步的复习和隐藏事件。
- `OfflineFirstDeckStudyRepository`：统一本地读取、内容刷新、出卡和同步入口；出卡时把本地行转成 `CardDetail`。

关键点：

- `DeckStudyBloc` 尽量不改，继续吃 `CardDetail`。
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

字段名对齐后端 `deck.Deck`。列名在卡组上，不在词条上。导入卡组用 `source_version` 对源卡组 `published_version`。

```json
{
  "account_id": "user-1",
  "id": "deck-1",
  "name": "Japanese N5",
  "fields": ["Question", "Answer"],
  "rate": 20,
  "source_deck_id": "",
  "source_version": 0,
  "downloaded_at": 1776153600,
  "last_synced_at": 1776157200,
  "card_count": 1200,
  "media_bytes": 52428800,
  "has_pending_operations": false
}
```

### 离线词条

对齐后端 `deck.Fact` 与 `GET /api/decks/{id}/facts`：`id`、`entries`、HTTP 响应里的 `tags`。`entries` 与 Flutter `FactEntry` / 后端 `Entry` 相同。媒体字段存 **ID**，空字符串可省略。不要存 `fields`（在卡组上），也不要存 `server_version`。

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "id": "fact-1",
  "entries": [
    {
      "text": "猫",
      "audio": "media-1"
    }
  ],
  "tags": [
    { "id": "tag-1", "name": "N5" }
  ]
}
```

### 离线卡片

对齐后端 `deck.Card` 与 Flutter `Card` 的调度字段，再加上本地脏标记。

**不要**把 `GET /api/decks/{id}/card` 的 `CardDetail` 整包写入 Hive：

- `CardDetail` 是 `{ "card": { ... }, "urgency": ... }`；`next_card` 里 `urgency` 才嵌在卡对象上。
- `front` / `back` 是用词条 + `template` + `deck.fields` 算出来的，且接口会把媒体 ID 改写成 HTTPS URL，不适合离线。
- `urgency`、`tag_ids`、`server_version` 都不在 `Card` 上。标签在词条上。

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "id": "card-1",
  "fact_id": "fact-1",
  "template": [[0], [1]],
  "last_review": 1776150000,
  "due_date": 1776236400,
  "hidden": false,
  "created_at": 1776150000,
  "dirty": true
}
```

`template` 必须保留：`[[正面词条下标], [背面词条下标]]`，与后端 `ValidTemplate` 相同（两段不相交、覆盖 `0..n-1`）。没有 `template` 就无法在词条更新后重算正反面。

学习时派生 Flutter `CardDetail`（给 BLoC / UI，不落库）：

```text
fact = Hive fact by card.fact_id
front, back = ApplyTemplateToEntryObjects(fact.entries, card.template, deck.fields)
  每个槽位：{ field?, text?, audio?, image?, video?, json? }（同一对象可含多种类型）
  Flutter CardSlot.fromJson 会把它收成 { field, items: [{type, value}] }
urgency = (now - last_review) / (due_date - last_review)
CardDetail = { card: { ...card, front, back }, urgency }
```

不要把 `Card.toJson()`（items 形态）回传给服务端。

### 同步队列

复习结果用事件队列保存，不只保存最终状态。每条应对应一次 PATCH。

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

| 类型 | 对应 PATCH | 用途 |
| --- | --- | --- |
| `review` | `{ card_id, interval, last_review }` | 同步复习间隔和复习时间 |
| `hide` | `{ card_id, hidden }` | 同步隐藏状态 |

## 本地出卡规则

当前 `GET /api/decks/{id}/card` 由后端 `GetNextCard` 计算最紧急卡片，并在有第二张时返回 `next_card`。
离线时不再调用这个接口，必须把**同一套**选卡逻辑移植到前端，不要另做「只出到期卡」的近似算法。

实现（见 `retentio-backend/api/deck/card.go`）：

1. 加载该卡组全部本地卡片。
2. 若学习页带了 `tag_id`：只保留 `fact_id` 落在该标签词条集合里的卡片（与 `UserTagFactsKey` / `?tag_id=` 相同）。卡片本身没有 `tag_ids`。
3. 跳过 `hidden == true`。
4. 若 `due_date - last_review <= 0`：与后端一样视为数据损坏，该卡不出队（后端对此返回 400）。
5. `now = unix 秒`。
6. `urgency = (now - last_review) / (due_date - last_review)`（`float32` 除法）。
7. 在剩余卡片中取 urgency **严格最大**的一张；**urgency 并列时按 `card_id` 字典序取较小者**（客户端与后端须一致；本地 Hive 加载后先按 `card_id` 升序排序再遍历，后端 `GetNextCard` 亦应在选卡前对候选集做相同排序）。
8. 第二大 urgency 作为 lookahead（对应响应里的 `next_card`）；若与第一名 urgency 并列，同样按 `card_id` 字典序取较小者，且须不同于主卡。
9. 若没有非隐藏卡：结束学习（后端此时 `card` 为 `[]`）。

未到期卡**可以**出队：后端并不要求 `due_date <= now`。当没有更紧急的卡时，会出 urgency 最高的未到期卡。

未见过的卡：`due_date - last_review == 1`。溢出队列里的未见卡可能带有未来的 `last_review`；`GetNextCard` 出卡时会把 `last_review` 钳到 `now` 并写回。本地出卡应对当前这张做同样的钳制。

复习提交后立即更新本地卡片（与 PATCH 语义一致）：

复习：

```text
if last_review > now: last_review = now
due_date = last_review + int64(selectedInterval)
dirty = true
```

隐藏：

```text
hidden = true
dirty = true
```

然后写入同步队列。卡片更新和队列写入需要封装成同一个本地事务语义，避免应用被杀后只写了一半。隐藏后调度器跳过 `hidden == true` 的卡。

## 后端接口

首期**不新增** `GET /offline-package` 或 `POST /api/sync/study-events`。用现有接口组装下载、刷写进度。

### 下载与刷新（已有）

| 接口 | 用途 |
| --- | --- |
| `GET /api/decks/{id}` | 卡组元数据与 `fields` |
| `GET /api/decks/{id}/facts` | 词条分页：`limit` / `offset`，`meta.has_more`；每条含 `id`、`entries`、`tags` |
| `GET /api/decks/{id}/cards` | 首次播种本地 `Card` 调度；响应是 `stats` + `cards`，无正反面 |
| `GET /api/decks/{id}/card` | 仅无本地包时的在线学习；**不要**拿它灌 Hive（媒体已被改写成 URL） |
| `GET /api/media/{id}` | 按词条里的媒体 ID 下载字节 |

`GET /facts` 没有 cursor。客户端按 `offset` 翻页直到 `has_more == false`，再标记卡组本地就绪，避免半成功。

### 复习进度（已有）

```http
PATCH /api/decks/{id}/card
```

复习成功响应：

```json
{
  "data": {
    "last_review": 1776157200,
    "due_date": 1776243600,
    "new_interval": 86400
  }
}
```

隐藏成功响应：

```json
{
  "data": {
    "hidden_status": true
  }
}
```

没有 `server_version`，也没有整张卡回传。客户端用上述字段确认本地行，然后删除对应队列项。

**刷写层 PATCH 封装：** 现有 `CardService.updateCard` 返回 `Future<bool?>`，无法区分 HTTP 状态与响应体。同步刷写器须改用（或新增）返回 **typed result** 的封装，至少包含：`httpStatus`、`isSuccess`、`responseData`（`last_review` / `due_date` / `new_interval` 或 `hidden_status`）、`operationId`（回传对账）。刷写器据此区分：成功（删队列项）、401（暂停刷写、保留队列）、400（标记 `failed`、保留 payload）、404（标记 `remote_deleted`、删队列项）、其它（退避重试）。在线 `DeckStudyLegacyServiceRepository` 可继续用 bool 封装，但 outbox flusher 必须走 typed 路径。

后续若要做批量幂等同步，再新增 `POST /api/sync/study-events`（`operation_id` 去重）；在此之前不要依赖服务端幂等。

## 同步规则

队列处理：

1. 取 `pending` 且 `next_retry_at <= now` 的事件。
2. 按 `client_sequence` 升序上传。
3. 每条对应一次 `PATCH /api/decks/{id}/card`（复习与隐藏拆开），请求头携带 `Idempotency-Key: {operation_id}`。
4. 根据 typed PATCH 结果处理：HTTP 2xx 且 `operation_id` 未处理过 → 用响应字段确认本地卡，删除队列项。
5. **本批次全部 PATCH 完成后**：`GET /api/decks/{id}`，用 `stats` 更新本地缓存的 `total_reviews` / `total_reviews_today`（及卡组列表展示用的其它 stats 字段）；**不要**用 `GET /cards` 的 `cards[]` 覆盖 Hive 调度。
6. 网络错误指数退避：`30s -> 2m -> 10m -> 30m -> 2h`。
7. 401 暂停同步，不删除队列。
8. 400 参数错误标记 `failed`，保留 payload。
9. 404 标记本地卡 `remote_deleted`，删除队列项，不再出卡。

冲突处理：

| 场景 | 处理 |
| --- | --- |
| 同一事件重试 | 客户端 `operation_id` 去重 + PATCH `Idempotency-Key`；服务端须保证同一 key 不重复计入 `total_reviews` |
| 同设备顺序 | `client_sequence` 升序 |
| 多设备复习同一卡 | 服务端以最后一次成功的 PATCH 为准；另一台设备不回拉调度 |
| 词条被删导致卡不存在 | PATCH 404 后本地标记 `remote_deleted`，不再出卡，丢掉该队列项 |
| 内容落后 | 只拉词条/媒体增量，不覆盖本地调度 |

## 媒体缓存

媒体单独落文件系统：

```text
documents/offline_media/{accountId}/{deckId}/{mediaId}.{ext}
```

Hive 只保存索引：

- `media_id`（词条 `entries.audio` / `image` / `video` / `json` 的原始 ID）
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
- **登出策略（待同步队列）：** 若 `offline_sync_queue` / `review_outbox` 非空，**不得无条件删除**。v1 默认：提示用户，提供「立即同步并登出」「保留待同步数据并登出（同账号重新登录后继续刷写）」或「放弃未同步复习并登出」。仅当队列为空，或用户明确选择「放弃未同步」时，才清除该账号的 Hive 离线 box 与媒体缓存。
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
- 它实现现有 `DeckStudyRepository`，出卡时从 Hive 派生 `CardDetail`，且需保留 `DeckStudyBloc` 现有的下一张卡预取（lookahead）逻辑，否则会有体验回归。
- `deck_study` 目前未注册进 `get_it`（`lib/core/di/app_service_locator.dart` 只注册了 `auth` 模块），需先补上这一步，DI 才能按网络状态注入 Repository。

公共能力：

```text
lib/core/network/connectivity_service.dart
lib/core/storage/offline_hive_boxes.dart
lib/core/storage/account_scope.dart
```

## 测试

单元测试：

- 隐藏卡不出队。
- `due_date - last_review <= 0` 视为损坏。
- 词条标签筛选（按 `fact_id`，不是卡上的 `tag_ids`）。
- urgency 公式与并列时按 `card_id` 字典序取较小者。
- 未到期卡在没有更紧急卡时仍可出队。
- 未见卡 interval 为 1；未来 `last_review` 钳到 now。
- 前端调度器与后端 `GetNextCard` 在同一时间点、同一卡集上选出同一张（含 urgency 并列时的 `card_id` tie-break）。
- 队列序列化；复习/隐藏 PATCH body 拆分；隐藏时本地 `hidden = true` 与队列项同事务写入。
- 重试退避与 `operation_id` 去重；同一 `operation_id` 重试携带相同 `Idempotency-Key`，`total_reviews` 不得重复 +1。
- 账号隔离。
- 导入卡组红点用 `source_version` / `published_version`。

Repository 测试：

- 本地有卡时学习不打 `GET /card`。
- 离线时回退本地。
- 复习后立即更新本地 `last_review` / `due_date`。
- 卡片状态和队列同时写入。
- PATCH 成功后用响应字段确认本地，不回拉 `GET /cards` 覆盖调度。
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
- 同一 `operation_id` 多次触发同步不会重复 PATCH；重试时 `total_reviews` 不重复计入。
- PATCH 成功后本地 `last_review` / `due_date` / `hidden` 与响应一致。
- 相同卡集和相同 `now` 下，本地调度器与 `GetNextCard` 的下一张卡一致。
- 未下载卡组不会误显示为可离线学习。

---

## 附录：对象形状参考

以下字段对齐当前后端 `retentio-backend/api/deck/` 与 Flutter `lib/models/`。离线 Hive 应优先存 **Redis 真相形状**（词条媒体 ID、卡片调度、卡组 `fields`），不要存 `GET /card` 派生出的 URL 或 `CardDetail`。

### Deck（卡组）

**Redis 存储**（`deck:{id}`，`deck.Deck`）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `name` | string | 卡组名 |
| `description` | string? | 可选描述 |
| `owner` | string | 用户名（导入卡组在 API 层会换成源作者） |
| `fields` | string[] | 列名；词条 `entries[i]` 的标签来源 |
| `rate` | int | 新卡引入速率（1–1000） |
| `created_at` | ISO8601 | 创建时间 |
| `updated_at` | ISO8601 | 更新时间 |
| `visibility` | string? | 源卡组：`private` / `public` |
| `published_version` | int? | 源卡组：最新已发布快照版本，`0` = 从未发布 |
| `source_deck_id` | string? | 导入卡组：源卡组 id |
| `source_version` | int? | 导入卡组：当前钉住的源快照版本 |
| `imported_at` | ISO8601? | 导入卡组：导入时间 |

**`GET /api/decks/{id}` 额外计算字段**（不在 Redis `Deck` JSON 里）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 路径参数 |
| `stats` | DeckStats | 见下表 |
| `latest_source_version` | int | 仅导入卡组：源卡组当前 `published_version` |
| `source_update_available` | bool | 仅导入卡组：`source_version < latest_source_version` |

**DeckStats**（`stats`，由卡片 + 词条数计算）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `cards_count` | int | 卡片总数 |
| `facts_count` | int | 词条总数 |
| `unseen_cards` | int | 未见：`due_date - last_review == 1` 且未隐藏 |
| `reviewed_cards` | int | 已见（含隐藏） |
| `due_cards` | int | 到期：`due_date <= now` 且未隐藏 |
| `hidden_cards` | int | 隐藏数 |
| `new_cards_today` | int | 今日新建（UTC 日） |
| `last_reviewed_at` | int64 | 最近复习时间（Unix 秒） |
| `total_reviews` | int64 | 累计复习次数（PATCH interval 计数） |
| `total_reviews_today` | int64 | 今日复习次数（UTC 日桶） |

**离线/local-first**：调度类字段本地重算；`total_reviews*` 在队列刷写批次（含 ≥100 触发）PATCH 完成后经 `GET /decks/{id}` 的 `stats` 对齐（见「卡组统计（DeckStats）」）。

**Flutter `Deck`**（`lib/models/deck.dart`）还解析 `min_interval` / `def_interval` / `max_interval`，但当前后端 **不返回** 这些字段；复习滑块区间由客户端按 urgency 计算（`ReviewIntervalRange`）。

**离线 Hive 建议**：存 `id`、`name`、`fields`、`rate`、`source_deck_id`、`source_version`，以及本地 `downloaded_at` / `last_synced_at` 等元数据。不要用通用 `server_version`。

```json
{
  "id": "deck-1",
  "name": "Japanese N5",
  "fields": ["Word", "Translation"],
  "rate": 20,
  "source_deck_id": "",
  "source_version": 0,
  "published_version": 0,
  "visibility": "private"
}
```

### Fact / Entry（词条）

**Entry**（`deck.Entry`，一个槽位）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `text` | string? | 文本 |
| `audio` | string? | 媒体 **ID**（非 URL） |
| `image` | string? | 媒体 ID |
| `video` | string? | 媒体 ID |
| `json` | string? | JSON 附件媒体 ID |
| | | 空字符串在 JSON 中省略；至少一个槽位要有内容 |

**Fact**（Redis `fact:{id}` 或导入快照 / overlay）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 8 位 nanoid |
| `entries` | Entry[] | 词条内容 |

**HTTP 响应**（`GET /api/decks/{id}/facts`、`GET …/facts/{factId}`）在 `Fact` 上额外嵌套：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `tags` | Tag[] | 仅响应；**不写入** Redis `fact:{id}` |

**没有** per-fact `fields`；列名在 `deck.fields[i]`。

导入卡组词条来自作者快照；导入者私有修改走 overlay（`FactOverlayKey`），不改变共享快照。

**离线 Hive 建议**：`id`、`entries`（原始媒体 ID）、`tags`（从 GET facts 缓存）。词条更新时按 id upsert，不覆盖卡片调度。

```json
{
  "id": "fact-1",
  "entries": [
    { "text": "猫", "audio": "aud001" },
    { "text": "ねこ" }
  ],
  "tags": [
    { "id": "tag-1", "name": "N5", "description": "" }
  ]
}
```

### Card（卡片）

**Redis 存储**（`card:{id}`，`deck.Card`）——调度真相来源：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 8 位 nanoid |
| `fact_id` | string | 关联词条 id |
| `template` | int[][] | `[[正面 entry 下标], [背面 entry 下标]]`；两段不相交、覆盖 `0..n-1` |
| `last_review` | int64 | Unix 秒 |
| `due_date` | int64 | Unix 秒 |
| `hidden` | bool | 是否隐藏 |
| `created_at` | int64 | Unix 秒 |

**`GET /api/decks/{id}/cards`**：返回 `{ stats, cards: Card[] }`。`cards` 与 Redis 形状相同，**没有** `front` / `back` / `urgency`。

**`GET /api/decks/{id}/card`**：在 `Card` 上临时附加：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `front` | FaceEntry[] | 由 template + fact + deck.fields 算出 |
| `back` | FaceEntry[] | 同上；仅正面卡时 `back` 可为 `[]` |
| `urgency` | float32 | **仅**在响应顶层（主卡）或 `next_card` 对象内 |

**FaceEntry**（正/反面槽位，一个对象可含多种媒体）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `field` | string? | 列名（无列名时可省略） |
| `text` | string? | 文本 |
| `audio` | string? | 媒体 ID 或 **完整 HTTPS URL**（GET /card 会改写） |
| `image` | string? | 同上 |
| `video` | string? | 同上 |
| `json` | string? | 同上 |

**Flutter `CardDetail`**（`lib/models/card.dart`，学习 DTO，**不落 Hive**）：

```json
{
  "card": {
    "id": "card-1",
    "fact_id": "fact-1",
    "template": [[0], [1]],
    "last_review": 1776150000,
    "due_date": 1776236400,
    "hidden": false,
    "created_at": 1776150000,
    "front": [{ "field": "Word", "items": [{ "type": "text", "value": "猫" }] }],
    "back": [{ "field": "Translation", "items": [{ "type": "text", "value": "ねこ" }] }]
  },
  "urgency": 0.8
}
```

Flutter 会把 FaceEntry 收成 `{ field, items: [{type, value}] }`；离线本地应存 Redis `Card` + 本地 `dirty`，出卡时再派生 `CardDetail`。

**PATCH `/api/decks/{id}/card`**：

- 复习：`{ "card_id", "interval", "last_review" }` → `{ last_review, due_date, new_interval }`
- 隐藏：`{ "card_id", "hidden" }` → `{ hidden_status }`
- 二者不可同包；`interval` 截为 int64；`last_review > now` 时服务端钳到 `now`

卡片 **没有** `tag_ids`；标签在词条上，选卡时用 `?tag_id=` 过滤 `fact_id` 集合。

### Media（媒体）

**元数据**（Redis `media:{id}`，`deck.Media`）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 媒体 id |
| `owner` | string | 上传者用户名 |
| `deck_id` | string? | 关联网组 |
| `filename` | string | 原始文件名 |
| `mime` | string | MIME 类型 |
| `size` | int64 | 字节数 |
| `checksum` | string | 校验和 |
| `created_at` | int64 | Unix 秒 |

**下载**：`GET /api/media/{id}`（导入快照可加 `?v=` 版本号）。响应体是字节流；元数据走 `GET /api/media` 列表或上传响应。

**词条引用**：

- 自有媒体：存裸 id，如 `"audio": "aud001"`
- 导入共享媒体：id 以 `shared:` 开头（如 `shared:abc123`），解析 marker `[audio:shared:xxx]` 时使用
- **离线缓存 key** 用裸 id；不要存 `GET /card` 返回的 HTTPS URL

**离线文件索引**（Hive `offline_media`，非后端对象）：

| 字段 | 说明 |
| --- | --- |
| `media_id` | 词条里的原始 id |
| `local_path` | `documents/offline_media/...` |
| `content_type` | MIME |
| `bytes` | 大小 |
| `sha256` | 校验 |
| `download_status` | pending / ready / failed |
| `last_accessed_at` | Unix 秒 |

### Tag（标签）

**Tag**（`deck.Tag`，嵌在 fact/deck 标签 API 响应里）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 标签 id |
| `name` | string | 显示名 |
| `description` | string | 描述 |

**TagListItem**（`GET /api/tags` 列表项，多两个计数字段）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `deck_count` | int | 关联卡组数 |
| `fact_count` | int | 关联词条数 |
| `used_on` | string[] | `"deck"` 和/或 `"fact"` |

**关联模型**（Redis set，不在 Card 上）：

- 卡组标签：`user:{username}:deck:{deckId}:tags`
- 词条标签：`user:{username}:fact:{deckId}:{factId}:tags`
- 按标签查词条：`user:{username}:tag:{tagId}:facts` → `"deckId:factId"` 引用

**选卡筛选**：`GET /api/decks/{id}/card?tag_id=` 与 `GET /api/decks/{id}/cards?tag_id=` 用同一套 fact 集合过滤；离线复制该逻辑。

创建/关联时：`tags`（名称，可自动创建）与 `tag_ids`（已有 id）**互斥**。

### Contribution（贡献 / 反馈）

导入者对**源卡组**提交的提案；作者在源卡组 inbox 处理。首期离线方案**不涉及**贡献同步，此处供共享/导入功能对照。

**Contribution**（Redis，`deck.Contribution`）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 贡献 id |
| `source_deck_id` | string | 源卡组（作者） |
| `import_deck_id` | string | 导入者卡组 |
| `fact_id` | string? | 相关词条 |
| `reporter` | string | 提交者用户名 |
| `source_version` | int | 提交时源快照版本 |
| `type` | string | 见下表 |
| `message` | string? | 说明（≤2000 字） |
| `status` | string | `open` / `accepted` / `resolved` / `dismissed` |
| `created_at` | ISO8601 | |
| `updated_at` | ISO8601 | |
| `resolved_at` | ISO8601? | |
| `accepted_at` | ISO8601? | |
| `dedupe_target` | string? | 去重键 |

**按 `type` 使用的 payload 字段**：

| type | 主要字段 |
| --- | --- |
| `fact_edit` | `entry_index?`, `reported_fact`, `proposed_entries`, `media_attachments?` |
| `fact_add` | `proposed_entries`, `media_attachments?` |
| `fact_tag_update` | `reported_tags?`, `add_tags`, `remove_tags` |
| `deck_tag_update` | `add_tags`, `remove_tags` |
| `template_add` | `template` |
| `field_rename` | `reported_fields`, `proposed_fields` |
| `report` | `message`（举报，无结构化 diff） |

**嵌套类型**：

- **ReportedFact**：`{ id, entries[] }` — 提交时冻结的「修改前」快照
- **proposed_entries**：`Entry[]` — 导入者提议的「修改后」
- **MediaChange**（派生 diff，inbox 筛选用）：`{ type, action, entry_index }`，`type` = audio/image/video/json，`action` = add/edit/remove
- **MediaAttachment**：`{ attachment_id, source_media_id, references[], filename?, mime?, size?, checksum?, preview_path?, available? }`
- **MediaAttachmentRef**：`{ entry_index, field }`
- **AcceptedMediaMappingEntry**：接受后 `{ author_media_id, checksum? }`

**ContributionListItem**（`GET /api/decks/{sourceDeckId}/contributions` 单行）= `Contribution` + 可选 **edit**：

```json
{
  "edit": {
    "deck_id": "source-deck-1",
    "fact_id": "fact-1",
    "get_fact_path": "/api/decks/source-deck-1/facts/fact-1",
    "patch_fact_path": "/api/decks/source-deck-1/facts/fact-1"
  }
}
```

**Flutter** 对应 `DeckContribution` / `ContributionMediaAttachment`（`lib/models/deck_contribution.dart`）。

### 离线 Hive 与 API 形状对照

| 对象 | 离线 Hive 存什么 | 不要存什么 |
| --- | --- | --- |
| Deck | Redis/API 卡组字段 + 本地同步元数据 | 通用 `server_version` |
| Fact | `id`, `entries`（媒体 ID）, `tags` | per-fact `fields` |
| Card | Redis `Card` + `dirty` | `front`, `back`, `urgency`, `tag_ids` |
| CardDetail | 不存；学习时派生 | GET /card 的 HTTPS 媒体 URL |
| Media | 本地文件 + 索引行 | 完整 download URL 当主键 |
| Tag | `id`, `name`, `description` | 把标签挂到 Card 上 |
| Contribution | 首期不缓存 | — |

**代码索引**：`retentio-backend/api/deck/{deck,fact,card,media,tag,contribution}.go`；Flutter `lib/models/{deck,fact,card,tag,deck_contribution}.dart`。
