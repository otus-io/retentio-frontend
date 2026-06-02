🌐 [English](api.md) | [中文](api_zh.md)

---

# 快速入门指南 - Swagger UI 教程

本指南将帮助您通过 Swagger UI 使用 Retentio API。

## 目录

- [前提条件](#前提条件)
- [API 接口参考](#api-接口参考)
- [1. 身份验证](#1-身份验证)
  - [创建用户](#创建用户)
  - [登录](#登录)
  - [授权](#授权)
  - [登出](#登出)
  - [忘记密码](#忘记密码)
  - [重置密码](#重置密码)
- [1.1 用户资料](#11-用户资料)
- [2. 卡组](#2-卡组)
  - [创建卡组](#创建卡组)
  - [获取单个卡组](#获取单个卡组)
  - [获取所有卡组](#获取所有卡组)
  - [更新卡组](#更新卡组)
  - [删除卡组](#删除卡组)
  - [假期模式（平移复习计划）](#假期模式平移复习计划)
  - [卡组共享（概述）](#卡组共享概述)
  - [卡组目录](#卡组目录)
  - [发布卡组](#发布卡组)
  - [导入已发布卡组](#导入已发布卡组)
  - [获取导入更新（差异）](#获取导入更新差异)
  - [同步导入卡组](#同步导入卡组)
  - [共享：卡组与词条扩展行为](#共享卡组与词条扩展行为)
- [3. 词条](#3-词条)
  - [添加词条](#添加词条)
  - [获取所有词条](#获取所有词条)
  - [获取单个词条](#获取单个词条)
  - [更新词条](#更新词条)
  - [删除词条](#删除词条)
- [4. 标签](#4-标签)
  - [创建标签](#创建标签)
  - [列出你的标签](#列出你的标签)
  - [获取单个标签](#获取单个标签)
  - [更新标签](#更新标签)
  - [删除标签](#删除标签)
  - [将标签关联到卡组](#将标签关联到卡组)
  - [从卡组移除标签](#从卡组移除标签)
  - [列出卡组上的标签](#列出卡组上的标签)
  - [将标签关联到词条](#将标签关联到词条)
  - [从词条移除标签](#从词条移除标签)
  - [列出词条上的标签](#列出词条上的标签)
  - [列出拥有某标签的所有词条](#列出拥有某标签的所有词条)
- [5. 卡片](#5-卡片)
  - [为已有词条添加一张卡（如反向卡）](#为已有词条添加一张卡如反向卡)
  - [获取下一张最紧急卡片](#获取下一张最紧急卡片)
  - [复习卡片](#复习卡片)
  - [隐藏卡片](#隐藏卡片)
  - [删除卡片](#删除卡片)
  - [获取卡片统计](#获取卡片统计)
- [6. 媒体（音频 / 图片）](#6-媒体音频--图片)
  - [上传媒体](#上传媒体)
  - [列出媒体](#列出媒体)
  - [获取媒体元数据](#获取媒体元数据)
  - [下载媒体](#下载媒体)
  - [删除媒体](#删除媒体)
  - [在词条中使用媒体](#在词条中使用媒体)
- [响应示例速查](#响应示例速查)
- [后续步骤](#后续步骤)

---

## 前提条件

- 打开 Swagger UI：
  - **本地**: <http://localhost:8080/docs>
  - **生产环境**: <https://api.retentio.app:8443/docs>

> **时间戳规范：** API 中所有时间戳均使用 **UTC** 时区。
> ISO 8601 字符串使用 `Z` 后缀（例如 `2026-02-08T12:00:00Z`）。
> Unix 时间戳为自 Unix 纪元（1970-01-01T00:00:00Z）以来的秒数。
> 客户端需自行进行本地时间的转换。
>
> **ID 格式：** 卡组、词条、卡片与**标签** ID 均为随机 **小写字母数字** 字符串（无下划线或连字符）。后端生成：**deck_id** 12 位；**fact_id**、**card_id**、**tag_id** 各 8 位。媒体 ID（如 `[audio:id]` 中的 id）为 10 位。本指南中的示例 ID 均符合上述长度。

---

## API 接口参考

| 接口                                          | 方法   | 说明                                                                                                                                                 |
| --------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/auth/register`                              | POST   | 注册用户                                                                                                                                             |
| `/auth/login`                                 | POST   | 登录                                                                                                                                                 |
| `/auth/logout`                                | POST   | 登出（使令牌失效）                                                                                                                                   |
| `/auth/forgot-password`                       | POST   | 请求密码重置令牌                                                                                                                                     |
| `/auth/reset-password`                        | POST   | 使用令牌重置密码                                                                                                                                     |
| `/api/profile`                                | GET    | 获取当前用户资料                                                                                                                                     |
| `/api/decks`                                  | POST   | 创建卡组。请求体：`name`、**`fields`**（≥1 列名，必填）、**`rate`**（必填，1–1000）、可选 **`tags`**。                                                    |
| `/api/decks`                                  | GET    | 获取所有卡组                                                                                                                                         |
| `/api/decks/{id}`                             | GET    | 获取卡组详情。源卡组含 `visibility`、`published_version`；导入卡组含 `source_deck_id`、`source_version`、`imported_at`。                             |
| `/api/decks/{id}`                             | PATCH  | 更新卡组。源卡组：首次发布前可改 `visibility`。导入卡组：**仅可改 `rate`**（不可改 `name`、`fields`、`visibility`）。                              |
| `/api/decks/{id}`                             | DELETE | 删除卡组。源卡组若 `published_version > 0` → **409**。导入卡组删除时撤销媒体授权。                                                                 |
| `/api/decks/import`                           | POST   | **（共享）** 从已发布的公开源卡组创建导入学习副本。请求体：`source_deck_id`。**201**。                                                               |
| `/api/decks/catalog`                          | GET    | **（共享）** 列出可导入的公开已发布源卡组。**无需登录。** 查询：`limit`、`offset`，可选 `query`（名称、描述、所有者、卡组标签名）。按最新发布时间排序。`POST /api/decks/import` 导入仍需 JWT。 |
| `/api/decks/catalog/{id}`                     | GET    | **（共享）** 按源卡组 ID 获取一条公开已发布目录记录（字段与列表行相同）。**无需登录。** 不可导入时 **404**。 |
| `/api/decks/{id}/publish`                     | POST   | **（共享）** 作者：将工作副本快照为下一 `published_version`。首次发布须 `visibility: "public"`。**200**。                                            |
| `/api/decks/{id}/feedback`                    | POST   | **（共享）** 导入者：向源卡组作者提交词条反馈/修改建议。路径使用**导入**卡组 id。**201**；超过每日上限（每源卡组每天 20 条）→ **429**。              |
| `/api/decks/{id}/feedback`                    | GET    | **（共享）** 作者：在**源**卡组 id 上查看反馈收件箱。查询：`limit`、`offset`，可选 `status`、`fact_id`。                                             |
| `/api/decks/{id}/feedback/{feedbackId}`       | PATCH  | **（共享）** 作者：更新反馈 `status`（`open`、`resolved`、`dismissed`）。仅源卡组。                                                                 |
| `/api/decks/{id}/feedback/{feedbackId}/accept` | POST | **（共享）** 作者：将 `proposed_entries` 应用到工作副本；状态设为 `accepted`。不自动发布。仅源卡组。                                                   |
| `/api/decks/{id}/updates`                     | GET    | **（共享）** 导入者：对比钉住的 `source_version` 与源卡组最新发布版本。仅导入卡组。                                                                  |
| `/api/decks/{id}/sync`                        | POST   | **（共享）** 导入者：接受较新快照（可选 `target_version`）。仅导入卡组。**200**。                                                                    |
| `/api/decks/{id}/facts/{operation}`           | POST   | 添加词条：operation 为 append/prepend/shuffle/spread。请求体：facts（必填）、可选 template，以及每项词条可选 **`tags`** 或 **`tag_ids`**（同一条词条上互斥；`tags` 为名称、不存在则自动创建，`tag_ids` 为已有 ID）。列名在卡组上维护（`PATCH /api/decks/{id}` → `fields`），不在每条词条上。为已有词条添加一张卡请使用 POST `/api/decks/{id}/card`。导入卡组 → **403**。 |
| `/api/decks/{id}/facts`                       | GET    | 获取词条（分页）：默认 `limit` **50**、`offset` **0**；`limit` 最大 **200**。`meta` 含 `count`、`has_more`、`limit`、`offset`、`total`。 |
| `/api/decks/{id}/facts/{factId}`              | GET    | 获取单个词条                                                                                                                                         |
| `/api/decks/{id}/facts/{factId}`              | PATCH  | 仅更新词条 `entries`（列名在卡组上改）。导入卡组 → **403**。                                                                                         |
| `/api/decks/{id}/facts/{factId}`              | DELETE | 删除词条。导入卡组 → **403**。                                                                                                                       |
| `/api/decks/{id}/card`                        | GET    | 获取最紧急卡片。可选查询：`tag_id`，仅在当前卡组中从带该标签的词条对应卡片里选取下一张。                                                           |
| `/api/decks/{id}/card`                        | POST   | 为已有词条添加一张卡（如反向卡）。请求体：fact_id、template，可选 operation。                                                                        |
| `/api/decks/{id}/card`                        | PATCH  | 更新卡片间隔或可见性（按 card_id）                                                                                                                   |
| `/api/decks/{id}/cards`                       | GET    | 获取卡片统计。可选查询：`tag_id`，按当前卡组中该标签对应词条过滤卡片。                                                                             |
| `/api/decks/{id}/cards/{cardId}`              | DELETE | 删除单张卡片（词条及其他卡片不变）                                                                                                                   |
| `/api/decks/{id}/reschedule`                  | POST   | 假期模式：按天数平移卡片复习计划                                                                                                                     |
| `/api/tags`                                   | POST   | 创建标签（`name`、可选 `description`）。成功时 **201**。                                                                                             |
| `/api/tags`                                   | GET    | 列出当前用户全部标签                                                                                                                                 |
| `/api/tags/{tagId}`                           | GET    | 获取单个标签                                                                                                                                         |
| `/api/tags/{tagId}`                           | PATCH  | 部分更新标签 `name` / `description`                                                                                                                  |
| `/api/tags/{tagId}`                           | DELETE | 删除标签及其所有卡组/词条关联                                                                                                                        |
| `/api/tags/{tagId}/facts`                     | GET    | 列出带该标签的词条（`deck_id` + `fact_id`，跨卡组）                                                                                                  |
| `/api/decks/{id}/tags/{tagId}`                | PUT    | 将已有标签关联到卡组（无请求体）                                                                                                                     |
| `/api/decks/{id}/tags/{tagId}`                | DELETE | 从卡组移除标签                                                                                                                                       |
| `/api/decks/{id}/tags`                        | GET    | 列出卡组上的标签                                                                                                                                     |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | PUT    | 将已有标签关联到词条（无请求体）                                                                                                                     |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | DELETE | 从词条移除标签                                                                                                                                       |
| `/api/decks/{id}/facts/{factId}/tags`         | GET    | 仅列出某词条上的标签                                                                                                                                 |
| `/api/media`                                  | POST   | 上传媒体（音频/图片）                                                                                                                                |
| `/api/media`                                  | GET    | 列出用户媒体（同步清单）                                                                                                                             |
| `/api/media/{id}/meta`                        | GET    | 获取媒体元数据（不含文件体）                                                                                                                         |
| `/api/media/{id}`                             | GET    | 下载媒体文件                                                                                                                                         |
| `/api/media/{id}`                             | DELETE | 删除媒体                                                                                                                                             |

---

## 1. 身份验证

### 创建用户

**接口:** `POST /auth/register`

```json
{
  "email": "swagger@example.com",
  "password": "123456",
  "username": "swagger"
}
```

### 登录

**接口:** `POST /auth/login`

```json
{
  "password": "123456",
  "username": "swagger"
}
```

**响应:**

```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "meta": {
    "expires": "2026-02-14T05:05:20Z"
  }
}
```

### 授权

1. 点击 Swagger UI 右上角的 **"Authorize"** 按钮
2. 粘贴登录响应中的 token
3. 点击 **"Authorize"** 保存

现在所有后续请求都会自动包含您的身份验证令牌。

### 登出

**接口:** `POST /auth/logout`

需要 `Authorization: Bearer <token>` 请求头。使令牌失效，之后无法再使用。

**响应:**

```json
{
  "data": {
    "msg": "Logged out successfully"
  },
  "meta": null
}
```

### 忘记密码

**接口:** `POST /auth/forgot-password`

```json
{
  "email": "swagger@example.com"
}
```

**响应:**

```json
{
  "data": {
    "reset_token": "a3f8b2c1d4e5f6..."
  },
  "meta": {
    "expires_in": "15m0s"
  }
}
```

> 重置令牌在 15 分钟后过期。在生产环境中，此令牌将通过电子邮件发送，而不是在响应中返回。

### 重置密码

**接口:** `POST /auth/reset-password`

```json
{
  "token": "a3f8b2c1d4e5f6...",
  "new_password": "mynewpassword"
}
```

**响应:**

```json
{
  "data": {
    "msg": "Password reset successfully"
  },
  "meta": null
}
```

> 重置后，请使用新密码登录。重置令牌为一次性使用，不能重复使用。

---

## 1.1 用户资料

**接口：** `GET /api/profile`

需在请求头中携带 `Authorization: Bearer <token>`。返回当前用户的资料（如用户名、邮箱）。

---

## 2. 卡组

### 卡组、词条与卡片（关系）

**卡组（deck）** 是学习容器：元数据（`name`、`fields`、`rate`、所有者）加上两个成员列表——哪些**词条（facts）**属于该卡组、哪些**卡片（cards）**用于复习。**词条**保存词汇内容（`entries`：文本及可选媒体 id）。**卡片**是可调度的复习单元：每张卡通过 `fact_id` 指向一条词条，并保存 **template**（哪些 entry 索引在正面/背面）以及间隔重复状态（`due_date`、`last_review`、`hidden`）。

列名（如 `English`、`Japanese`）仅存在于**卡组**的 `fields` 上。词条不存列名；entry 索引 `0` 为第一列，`1` 为第二列，依此类推。

| 概念 | 作用 | 典型 API |
|--------|------|-------------|
| **卡组** | 容器 + 列结构 + 每日 `rate` | `POST/GET/PATCH/DELETE /api/decks/{id}` |
| **词条** | 学习内容（entries） | `POST …/facts/{operation}`、`GET/PATCH/DELETE …/facts/{factId}` |
| **卡片** | 某词条的一种可复习方向/布局 | 添加词条时默认创建，或 `POST …/card`；复习经 `GET/PATCH …/card` |

#### 数量关系

- 一个卡组 → 多条词条（集合成员）。
- 一个卡组 → 多张卡片（集合成员）。
- 卡组内一条词条 → **一张或多张**卡片（默认一张；**兄弟卡** = 同一词条、不同 `template`，如反向卡）。
- 一张卡片 → 恰好一个 `fact_id`（须仍在卡组词条集合中）。

#### 生命周期（源卡组）

1. 创建卡组 → 词条/卡片集合为空。
2. 添加词条 → 新建 `fact:{id}` 行 + 每条词条一张或多张卡 + `SADD` 进卡组集合。
3. 学习 → `GET …/card` 选取卡组中最紧急的卡片；响应合并卡片 + 词条 + template。
4. 删除词条 → 删除该词条及卡组中所有引用它的卡片。
5. 删除卡片 → 仅删该卡；词条及同词条的其他卡片保留。

**导入卡组（[卡组共享](#卡组共享概述)）：** 词条**正文**只读（钉住快照）；卡组元数据大多来自快照——导入者仅可对导入卡组 **`PATCH` `rate`**。导入者仍拥有**独立的卡片集合**，卡片 `PATCH` / 隐藏 / 删除行为与自有卡组相同。导入卡组上的标签以导入者为键——见 [§4 标签](#4-标签)。

---

### 创建卡组

**接口:** `POST /api/decks`

```json
{
  "fields": ["English", "Japanese"],
  "name": "English Japanese IELTS Deck",
  "description": "雅思口语核心词汇",
  "rate": 20,
  "tags": ["IELTS", "vocabulary"]
}
```

可选 **`description`** — 卡组简介（发布后出现在目录快照中）。最多 **500** 字符；省略或 `""` 表示无简介。

#### 可选标签（创建时）

请求可通过 **二选一** 的方式附带卡组标签（不可同时使用）：

| 字段 | 类型 | 适用场景 |
|------|------|----------|
| **`tags`** | 标签**名称**（`string[]`） | 批量导入 / 脚本 — 不存在的名称会自动创建 |
| **`tag_ids`** | 已有标签 **ID**（`string[]`） | TagPicker UI — 标签须已存在（`POST /api/tags`） |

两者都省略或传 `[]` 表示无标签。同时传 **`tags` 与 `tag_ids`** → **400** `provide either tags or tag_ids, not both`。

##### `tags`（名称）

| 行为 | 说明 |
|------|------|
| **校验** | 与 [`POST /api/tags`](#创建标签) 名称规则相同。非法名称 → **400**。 |
| **复用** | 按规范化名称匹配当前用户已有标签并复用。 |
| **创建** | 不存在的名称自动创建；计入**每用户 100 个标签**上限。 |
| **去重** | 同一次请求内重复名称（如 `"Noun"` 与 `" noun "`）合并为一条关联。 |

##### `tag_ids`（已有 ID）

| 行为 | 说明 |
|------|------|
| **校验** | 每个 id 须非空；未知 id → **404** `tag not found`。 |
| **归属** | 标签须属于当前用户。 |
| **创建** | 不会自动创建标签。 |
| **去重** | 同一次请求内重复 id 合并为一条关联。 |

##### 两种形式共通

| 行为 | 说明 |
|------|------|
| **上限** | 解析后同一卡组最多 **20** 个不同标签 → **400** `maximum tags per deck reached`。 |
| **存储** | 标签不写入卡组 JSON；创建后用 [`GET /api/decks/{id}/tags`](#列出卡组上的标签) 查看。 |
| **创建响应** | 仅返回 `deck_id`，不含标签对象。 |

> **理解 `rate`（速率）：**
>
> 速率控制**每天引入多少张新卡片**。系统会将新卡片均匀分布在一天中：
>
> - `间隔 = 86400 秒（1 天）/ rate`
> - 示例：`rate: 20` → 每 **72 分钟**引入一张新卡片（86400 / 20 = 4320 秒）
> - 示例：`rate: 10` → 每 **144 分钟**引入一张新卡片（86400 / 10 = 8640 秒）
>
> 速率越高，每天引入的新卡片越多；速率越低，学习节奏越平缓。

**响应:**

```json
{
  "data": {
    "deck_id": "a1b2c3d4e5f6"
  },
  "meta": {
    "msg": "Deck created successfully"
  }
}
```

> 📝 保存 `deck_id` - 后续步骤需要用到。
> **`fields`：** 必填 — 至少一个列名（与学习时 `entries` 下标顺序一致）。空数组 → **400** `fields must contain at least one column name`。
> **`rate`：** 必填 — 整数 1–1000。省略 → **400**。
> 之后在**源卡组**上重命名列名请用 **`PATCH /api/decks/{id}`** 传非空 `fields` 数组（**整体替换**）。
> **为什么卡组没有 template？** 模板不存储在卡组上。添加词条时可传入可选参数 `template`（详见下方 [添加词条](#添加词条)）。默认每词条**一张卡**（正面第一条、背面其余）。若要生成**兄弟卡**（同一词条的多张卡），需传入三维 template，见下文。

---

### 获取单个卡组

**接口:** `GET /api/decks/{id}`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**响应:**

```json
{
  "data": {
    "id": "a1b2c3d4e5f6",
    "name": "English Japanese IELTS Deck",
    "owner": "swagger",
    "fields": ["English", "Japanese"],
    "rate": 20,
    "stats": {
      "cards_count": 0,
      "facts_count": 0,
      "unseen_cards": 0,
      "reviewed_cards": 0,
      "due_cards": 0,
      "hidden_cards": 0,
      "new_cards_today": 0,
      "last_reviewed_at": 0
    },
    "created_at": "2026-02-08T12:00:00Z",
    "updated_at": "2026-02-08T12:00:00Z",
    "visibility": "public",
    "published_version": 2
  },
  "meta": {
    "msg": "Deck retrieved successfully"
  }
}
```

**源卡组（作者）** — 当你拥有 canonical 卡组时的可选字段：

| 字段 | 说明 |
| ----- | ----------- |
| `visibility` | `private`（默认）或 `public`。发布后决定谁可导入。 |
| `published_version` | 最新已发布快照版本。`0` = 从未发布。 |

**导入卡组（订阅者）** — 当设置了 `source_deck_id` 时的可选字段：

| 字段 | 说明 |
| ----- | ----------- |
| `source_deck_id` | 作者源卡组 ID（12 位）。 |
| `source_version` | 钉住的快照版本，用于读取词条/媒体。 |
| `imported_at` | 创建导入时的 ISO 8601 时间戳。 |

### 获取所有卡组

**接口:** `GET /api/decks`

**响应:**

```json
{
  "data": {
    "decks": [
      {
        "id": "a1b2c3d4e5f6",
        "name": "English Japanese IELTS Deck",
        "owner": "swagger",
        "fields": ["English", "Japanese"],
        "rate": 20,
        "stats": {
          "cards_count": 0,
          "facts_count": 0,
          "unseen_cards": 0,
          "reviewed_cards": 0,
          "due_cards": 0,
          "hidden_cards": 0,
          "new_cards_today": 0,
          "last_reviewed_at": 0
        },
        "created_at": "2026-02-08T12:00:00Z",
        "updated_at": "2026-02-08T12:00:00Z"
      }
    ]
  },
  "meta": {
    "total": "1",
    "msg": "All Decks associated with this user retrieved successfully"
  }
}
```

> **理解 `meta`（元数据）：**
>
> | 字段            | 说明                   |
> | --------------- | ---------------------- |
> | `total`（总数） | 当前用户拥有的卡组总数 |
> | `msg`（消息）   | 状态信息               |

<!-- -->

> **理解 `stats`（统计信息）：**
>
> | 字段                               | 说明                                           |
> | ---------------------------------- | ---------------------------------------------- |
> | `cards_count`（卡片总数）          | 卡组中的卡片总数                               |
> | `facts_count`（词条总数）          | 卡组中的词条总数                               |
> | `unseen_cards`（未学习卡片）       | 从未复习过的新卡片数量                         |
> | `reviewed_cards`（已学习卡片）     | 已学习过至少一次的卡片数量                     |
> | `due_cards`（待复习卡片）          | 当前待复习的卡片数量（due_date <= 当前时间）   |
> | `hidden_cards`（已隐藏卡片）       | 被用户隐藏的卡片数量                           |
> | `new_cards_today`（今日新增卡片）  | 今天添加的卡片数量（从午夜开始计算）           |
> | `last_reviewed_at`（上次复习时间） | 最近一次复习的 Unix 时间戳（未复习过则为 `0`） |
>
> 统计信息是实时计算的。对于刚创建的空卡组，所有值都为 `0`。
> 添加词条后，`cards_count` 和 `unseen_cards` 会增加。
> 随着复习的进行，`reviewed_cards` 会增长，`unseen_cards` 会减少。
>
> 默认每词条一张卡（见 [模板：默认与兄弟卡](#模板默认与兄弟卡)）。若需为某词条再增加一张卡（如反向卡），请调用 `POST /api/decks/{id}/card`，body 传 `{"fact_id": "<factId>", "template": [[1], [0]]}`。若该 template 已存在则返回 400。
>
> 客户端计算学习进度百分比：`reviewed_cards / cards_count * 100`。
>
> 列表项与 [获取单个卡组](#获取单个卡组) 使用相同的可选共享字段（源卡组含 `visibility` / `published_version`；导入卡组含 `source_deck_id` / `source_version` / `imported_at`）。

### 更新卡组

**接口:** `PATCH /api/decks/{id}`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**请求体:**

```json
{
  "name": "更新后的卡组名称",
  "fields": ["English", "Japanese"],
  "rate": 30,
  "visibility": "public"
}
```

> **源卡组：** 除 `name` 外，其余键均为可选。**每次请求 `name` 必填。**
> **`visibility`**（`private` \| `public`）仅适用于**源卡组**，且仅在 `published_version == 0` 时可改。首次成功发布后可见性**不可变**（省略或传当前值；传不同值 → **400**）。
> 在**源卡组**上，若 **`fields`** 以**非空**数组发送，则**整体替换**列名列表（长度 ≥ 1 即可）。省略 `fields` 或传空数组则列名不变。
> 提供 **`rate`** 时须在 1–1000 之间。
>
> **导入卡组**（已设置 `source_deck_id`）：仅 **`rate`** 可改。**每次 PATCH 必须带 `rate`**（例如仅 `{ "rate": 30 }`）。**不得**发送 **`name`** 或 **`fields`**（即使与当前值相同）→ **400** `cannot change name on an imported deck` / `cannot change fields on an imported deck`。非空 **`visibility`** → **400**。卡组标题与列结构来自钉住的快照，并在 [同步](#同步导入卡组) 时从作者侧刷新。

当请求体中的 **`rate`** 存在且与卡组当前 **`rate`** **不同** 时，服务器对**未学习**卡片（`DueDate - LastReview == 1`）做**仅调整间隔（gap）**的重排：未学习行按**引入顺序**（`DueDate` 升序，再 `card_id`）排列；该顺序中**第一张**（最早到期）保留时间戳；其后每张未学习的 `DueDate` 相对前一张未学习卡按 **`86400 / 新 rate`** 秒递增（与新增卡片引入间隔定义一致）。**已学习**卡片不变。卡组 JSON 与卡片键在**同一** Redis 事务中更新。省略 `rate` 或 `rate` 未变则不重写卡片时间戳。

设计说明见 [rate-change-update.md](rate-change-update.md)。

**响应:**

```json
{
  "data": {
    "deck_id": "a1b2c3d4e5f6"
  },
  "meta": {
    "msg": "Deck updated successfully",
    "updated_at": "2026-02-08T13:00:00Z"
  }
}
```

### 删除卡组

**接口:** `DELETE /api/decks/{id}`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

> 永久删除卡组及其关联词条与卡片（导入卡组仅删除导入方拥有的键；版本化快照与作者工作副本不删除）。

| 卡组类型 | 删除行为 |
| --------- | ---------------- |
| **源卡组**，`published_version == 0` | 允许（**200**）。 |
| **源卡组**，`published_version > 0` | **409** — `published decks cannot be deleted`。 |
| **导入卡组** | 允许（**200**）。撤销本导入创建的 `user:{你}:readable_media_versions` 授权。 |

**响应:**

```json
{
  "data": {
    "deck_id": "a1b2c3d4e5f6"
  },
  "meta": {
    "msg": "Deck deleted successfully"
  }
}
```

### 假期模式（平移复习计划）

**接口：** `POST /api/decks/{id}/reschedule`

将卡组内所有卡片的 due_date 与 last_review 按 N 天（1–365）平移。仅当卡组存在逾期卡片时允许调用。

**请求体：**

```json
{ "days": 5 }
```

**响应示例：**

```json
{
  "data": {
    "cards_shifted": 42,
    "days": 5,
    "max_days_away": 10
  },
  "meta": { "msg": "Successfully rescheduled 42 cards by 5 days" }
}
```

---

## 卡组共享（概述）

用户间卡组共享让**作者**发布卡组版本化快照，其他用户可**导入**个人学习副本。每次导入是导入者拥有的**新卡组**，拥有独立卡片与调度；**词条与内嵌媒体**为只读，通过钉住的快照版本解析。

完整设计见 [deck-sharing-feature.md](deck-sharing-feature.md)。

### 概念

| 术语 | 含义 |
| ---- | ------- |
| **源卡组** | 作者工作副本（`source_deck_id` 为空）。可对词条/媒体完整增删改。 |
| **发布** | 将工作副本快照为不可变 `v1`、`v2`、…（`published_version`）。 |
| **导入卡组** | 导入者拥有的新卡组；含 `source_deck_id` + 钉住的 `source_version`。 |
| **工作副本** | 实时 `fact:{id}` / `media:{id}` — 发布前仅作者可见。 |
| **快照** | `deck:{src}:snapshot:v{N}` 清单 + 版本化 `fact:{id}:v{N}` / `media:{id}:v{N}`。 |

**规则：**

- 首次发布须 **`visibility: "public"`**（导入要求源卡组已发布且公开）。
- 首次发布后**可见性不可改**，**源卡组不可删除**（**409**）。
- 作者对工作副本的编辑在再次发布前对导入者**不可见**。
- 导入者通过 `GET …/updates` + `POST …/sync` **主动**接受更新（无自动同步）。
- 再次发布采用**写时复制**：仅内容变化的词条/媒体获得新版本；未变行复用旧版本（更新差异仅列出真实变更）。

多数共享接口需 **`Authorization: Bearer <token>`**（与其他 `/api` 路由相同）。**例外：** **`GET /api/decks/catalog`** 与 **`GET /api/decks/catalog/{id}`** 无需登录即可浏览；[导入](#导入已发布卡组) 仍需有效 JWT。

---

### 卡组目录

**接口：** `GET /api/decks/catalog`

**调用方：** 任何人（无需 `Authorization` 头）。从目录 [导入](#导入已发布卡组) 前须登录。

**用途：** 在调用 [导入已发布卡组](#导入已发布卡组) 之前，浏览可**导入**的源卡组（已发布、公开、非导入行）。结果按**最新发布时间**排序（Redis `catalog:decks` ZSET，每次成功发布后更新）。

**查询参数：**

| 参数 | 默认 | 说明 |
| --------- | ------- | ----------- |
| `limit` | `50` | 每页条数（最大 **200**）。 |
| `offset` | `0` | 跳过条数。 |
| `query` | *（空）* | 可选；对**卡组名**、**描述**、**所有者用户名**、最新快照中的**卡组标签名**做不区分大小写的子串匹配。 |

示例：`GET /api/decks/catalog?limit=20&offset=0&query=JLPT`

**成功（200）：**

```json
{
  "data": {
    "decks": [
      {
        "id": "a1b2c3d4e5f6",
        "name": "JLPT N5 Core",
        "description": "JLPT N5 核心词汇",
        "owner": "alice",
        "fields": ["English", "Japanese"],
        "published_version": 3,
        "fact_count": 120,
        "deck_tag_names": ["JLPT N5", "verbs"],
        "published_at": "2026-05-22T12:00:00Z"
      }
    ]
  },
  "meta": {
    "msg": "ok",
    "count": "1",
    "total": "1",
    "limit": "50",
    "offset": "0",
    "has_more": "false"
  }
}
```

| 字段 | 含义 |
| ----- | ------- |
| `id` | 源卡组 ID — 作为 `source_deck_id` 传给 `POST /api/decks/import`。 |
| `name`, `description`, `fields` | 来自最新已发布快照清单（`description` 为空时省略）。 |
| `owner` | 作者用户名。 |
| `published_version` | 源卡组上的最新发布版本号。 |
| `fact_count` | 该快照中的词条数。 |
| `deck_tag_names` | 快照中的卡组标签名（无标签时可省略）。 |
| `published_at` | 该快照创建的 UTC 时间。 |

**收录条件**（与导入资格相同）：

- 仅源卡组（`source_deck_id` 为空）。
- `visibility` 为 **`public`**。
- `published_version > 0`。

未发布或非公开的卡组不会出现；即使已发布，私有卡组也不会出现在目录中。

**错误：**

| 状态码 | 典型原因 |
| ------ | ------------- |
| **500** | 列出目录失败（`Error listing catalog decks`）。 |

#### 获取单条目录记录

**接口：** `GET /api/decks/catalog/{id}`

**调用方：** 任何人（无需 `Authorization` 头）。

**用途：** 按**源卡组 ID** 加载**一条**可导入的目录记录 — 字段与列表行相同（`id`、`name`、`description`、`owner`、`fields`、`published_version`、`fact_count`、`deck_tag_names`、`published_at`）。用于目录详情页或直接链接，无需翻页扫描整个列表。

**路径参数：** `{id}` — 源卡组 ID（与 `POST /api/decks/import` 的 `source_deck_id` 相同）。

示例：`GET /api/decks/catalog/a1b2c3d4e5f6`

**成功（200）：**

```json
{
  "data": {
    "id": "a1b2c3d4e5f6",
    "name": "JLPT N5 Core",
    "description": "JLPT N5 核心词汇",
    "owner": "alice",
    "fields": ["English", "Japanese"],
    "published_version": 3,
    "fact_count": 120,
    "deck_tag_names": ["JLPT N5", "verbs"],
    "published_at": "2026-05-22T12:00:00Z"
  },
  "meta": {
    "msg": "ok"
  }
}
```

字段含义见上方[列表](#卡组目录)表格。**`description`** 来自最新已发布快照；若快照中为空，服务器回退到源卡组上存储的描述。

**收录条件：** 与列表相同 — 仅公开、已发布的源卡组。私有、未发布或导入行 → **404**。

**错误：**

| 状态码 | 典型原因 |
| ------ | ------------- |
| **404** | `Deck not found in catalog` — ID 不存在、非公开、未发布或为导入行。 |
| **500** | 加载目录记录失败（`Error loading catalog deck`）。 |

---

### 发布卡组

**接口：** `POST /api/decks/{id}/publish`

**调用方：** **源**卡组所有者（非导入行）。

**请求体：**

```json
{
  "visibility": "public"
}
```

| 情况 | 请求体中的 `visibility` |
| ---- | -------------------- |
| **首次发布**（`published_version == 0`） | **必填** — 须为 `"public"`。 |
| **再次发布**（`published_version > 0`） | 可省略，或传与存储值完全相同；不同值 → **400** `cannot change visibility after publishing`。 |

**成功（200）：**

```json
{
  "data": {
    "published_version": 2,
    "visibility": "public"
  },
  "meta": {
    "msg": "published"
  }
}
```

**服务端行为：** `published_version` 递增，写入 `deck:{id}:snapshot:v{N}`，写时复制版本化词条/媒体，首次发布时更新卡组 `visibility`。

**错误：**

| 状态码 | 典型 `msg` |
| ------ | ------------- |
| **400** | `first publish requires visibility public`、`invalid visibility`、`cannot change visibility after publishing`、`cannot publish an imported deck` |
| **403** | `Not authorized` |
| **404** | `Deck not found` |
| **409** | `no changes to publish`（工作副本与上一快照相同） |

---

### 导入已发布卡组

**接口：** `POST /api/decks/import`

**调用方：** 任意已认证用户（无需拥有源卡组）。可通过 [卡组目录](#卡组目录) 获取 `source_deck_id`，或直接使用已知的源卡组 ID。

**请求体：**

```json
{
  "source_deck_id": "a1b2c3d4e5f6"
}
```

`source_deck_id` 必填（为空 → **400** `source_deck_id is required`）。

**成功（201）：**

```json
{
  "data": {
    "id": "z9y8x7w6v5u4",
    "source_deck_id": "a1b2c3d4e5f6",
    "source_version": 3,
    "imported_at": "2026-05-22T12:00:00.000000000Z"
  },
  "meta": {
    "msg": "imported"
  }
}
```

学习与 `GET/POST …/updates`、`…/sync` 请使用 **`data.id`** 作为导入卡组 ID。

**源卡组要求：**

- 卡组存在。
- `published_version > 0`。
- `visibility` 为 **`public`**（有效可见性）。
- 源卡组本身不是导入行（`cannot import an imported deck`）。
- 导入者不是源卡组所有者（`cannot import your own deck`）。

**错误：**

| 状态码 | 典型 `msg` |
| ------ | ------------- |
| **404** | `source deck not found` |
| **403** | `source deck is not importable`、`source deck has not been published`、`cannot import an imported deck`、`cannot import your own deck` |
| **400** | 其他校验失败 |

---

### 获取导入更新（差异）

**接口：** `GET /api/decks/{importId}/updates`

**调用方：** **导入**卡组所有者。

**请求：** 无请求体。

**成功（200）：** 从导入卡组钉住的 `source_version` 到源卡组最新 `published_version` 的差异。

```json
{
  "data": {
    "source_version": 3,
    "latest_version": 5,
    "added_facts": [{ "fact_id": "abcd1234" }],
    "removed_facts": [{ "fact_id": "efgh5678" }],
    "edited_facts": [
      {
        "fact_id": "ijkl9012",
        "before": { "id": "ijkl9012", "entries": [{ "text": "old" }, { "text": "old2" }] },
        "after": { "id": "ijkl9012", "entries": [{ "text": "new" }, { "text": "old2" }] }
      }
    ],
    "media_changes": [
      {
        "media_id": "pron123456",
        "before_hash": "sha256:abc…",
        "after_hash": "sha256:def…",
        "before_bytes": 12345,
        "after_bytes": 23456
      }
    ],
    "change_summary": ""
  },
  "meta": {
    "msg": "ok"
  }
}
```

已是最新时：`source_version == latest_version`，差异数组为空。

`edited_facts` 仅列出**版本化内容**在快照间不同的词条（非卡组内全部词条）。

**错误：**

| 状态码 | 典型 `msg` |
| ------ | ------------- |
| **400** | `updates are only available for imported decks`，或源卡组缺失 |
| **403** | `Not authorized` |
| **404** | `Deck not found` |

---

### 同步导入卡组

**接口：** `POST /api/decks/{importId}/sync`

**调用方：** 导入卡组所有者。

**请求体（可选）：**

```json
{
  "target_version": 5
}
```

| 字段 | 行为 |
| ----- | -------- |
| 省略或为 `0` | 推进到源卡组当前 `published_version`。 |
| `target_version` | 须满足 `source_version < target_version <= source.published_version`。 |

**成功（200）：**

```json
{
  "data": {
    "source_version": 5
  },
  "meta": {
    "msg": "synced"
  }
}
```

**服务端行为：** 提升钉住版本；按目标清单重建导入词条集；删除已移除词条的导入者卡片；为新词条添加卡片；更新 `user:{导入者}:readable_media_versions` 授权。同时将目标快照清单中的 **`name`**、**`fields`**、**`rate`** 写入导入卡组行（会覆盖导入者此前通过 PATCH 设置的 `rate`）。

**错误：**

| 状态码 | 典型 `msg` |
| ------ | ------------- |
| **400** | `not an imported deck`、`invalid target version` 等 |
| **403** | `Not authorized` |
| **404** | `Deck not found` |

---

### 共享：卡组与词条扩展行为

#### 导入卡组的 PATCH 卡组

| 字段 | 导入卡组 |
| ----- | ----------- |
| **`rate`** | **必填。** 唯一可改的卡组字段。须在 1–1000 之间。修改 `rate` 时对**未学习**卡片的重排规则与源卡组相同（见 [更新卡组](#更新卡组)）。 |
| **`name`** | 锁定（来自快照 / 同步）。必须**省略**（非空值 → **400** `cannot change name on an imported deck`）。 |
| **`fields`** | 锁定。必须**省略**（非空数组 → **400** `cannot change fields on an imported deck`）。 |
| **`visibility`** | 不适用。非空值 → **400** `cannot change visibility on an imported deck`。 |

导入卡组 PATCH 时省略 **`rate`** → **400** `Rate is required for imported deck updates`。

#### 导入卡组上的词条

| 方法 | 路径 | 导入卡组 |
| ------ | ---- | ------------- |
| GET | `/api/decks/{id}/facts`、`…/facts/{factId}`、下一张卡 | 读取钉住版本的快照 `entries`。 |
| POST / PATCH / DELETE | 词条相关路由 | **403** `cannot modify facts on an imported deck` |

#### 反馈（导入者 → 作者）

| 方法 | 路径 | 角色 |
| ------ | ---- | --- |
| POST | `/api/decks/{importDeckId}/feedback` | 导入卡组所有者。请求体：`fact_id`（必填），可选 `category`（`translation` \| `audio` \| `typo` \| `other`，默认 `other`），`message`（未提供 `proposed_entries` 时必填；1–2000 字符），可选 `entry_index`，可选 `proposed_entries`（与词条 PATCH `entries` 同形；须与快照不同）。**201** 返回 `feedback_id`、`source_deck_id`、`fact_id`、`status`。每源卡组每 UTC 日 20 条后 **429**。 |
| GET | `/api/decks/{sourceDeckId}/feedback` | 仅源卡组所有者。可选查询：`status`、`fact_id`、`limit`、`offset`。 |
| PATCH | `/api/decks/{sourceDeckId}/feedback/{feedbackId}` | 源卡组所有者。请求体：`{ "status": "resolved" \| "dismissed" \| "open" }`。 |
| POST | `/api/decks/{sourceDeckId}/feedback/{feedbackId}/accept` | 源卡组所有者。反馈行须含 `proposed_entries`。更新作者**工作副本**；作者仍须 **POST /publish**，导入者 **POST /sync**。 |

#### 导入卡组上的卡片

与普通自有卡组相同：`GET/POST/PATCH/DELETE` 卡片路由可用；调度与模板由导入者自行管理。

#### 导入者的媒体

- 当 `user:{username}:readable_media_versions` 中有 `(media_id, version)` 授权（成员格式 `mediaId@version`）时，可通过 `GET /api/media/{id}` 下载作者媒体。
- 返回**版本化**二进制，非作者工作副本。
- 同一 `media_id` 存在多条授权时，使用查询参数 **`?v=<version>`**（歧义时必填）。
- 导入者不能上传或删除他人工作副本媒体。

#### 导入卡组上的标签

标签关联以**导入者**为键（与作者独立）。若某标签操作隐含修改只读词条内容，可能仍受限；详见 [§4 标签](#4-标签)。

---

## 3. 词条

### 添加词条

**接口:** `POST /api/decks/{id}/facts/{operation}`

> **导入卡组：** **403** `cannot modify facts on an imported deck`。请通过 [同步导入卡组](#同步导入卡组) 接受作者新内容。

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）
- `operation`: `append`

**请求体：** 对象，含必填 **`facts`** 数组与可选 **`template`**。每条词条项含必填 **`entries`** 与可选 **`tags`** 或 **`tag_ids`**（同一条词条上不可同时传）。每条 **entry** 为对象，含可选 `text`、`audio`、`image`、`video`、`json`（整条词条至少有一项有内容）。**不在每条词条上传 `fields`** — 列名使用 **`GET /api/decks/{id}`**（或 `PATCH` 卡组）中的 `fields`，与学习时下一张卡各 entry 的 `field` 标签对应。服务端为每个词条生成唯一 ID，并根据 `template` 创建一张或多张卡片（见下方 **模板：默认与兄弟卡**）。

#### 可选标签（按词条）

**`facts`** 中每一项可按需附带标签，**二选一**（同一条词条上不可同时传）：

| 字段 | 类型 | 适用场景 |
|------|------|----------|
| **`tags`** | 标签**名称**（`string[]`） | 批量导入 / 脚本 — 缺失名称会自动创建 |
| **`tag_ids`** | 已有标签 **ID**（`string[]`） | TagPicker UI — 标签须已存在（`POST /api/tags`） |

两者都省略或传 `[]` 表示该词条无标签。**同一条**词条同时传 **`tags` 与 `tag_ids`** → **400** `provide either tags or tag_ids, not both`。

##### `tags`（名称）

| 行为 | 说明 |
|------|------|
| **作用范围** | 按**本条词条**生效（同一批中 A 可有标签、B 可无）。 |
| **校验** | 与 [`POST /api/tags`](#创建标签) 名称规则相同（字母、数字、空格、`-`、`'`；最长 50 字符）。非法名称 → **400**。 |
| **复用** | 名称经规范化后若已存在于当前用户，则复用该标签。 |
| **创建** | 不存在的名称会为当前用户自动创建并关联到新词条；计入**每用户 100 个标签**上限。 |
| **去重** | **同一条**词条内重复名称（如 `"Noun"` 与 `" noun "`）合并为一条关联。 |

##### `tag_ids`（已有 ID）

| 行为 | 说明 |
|------|------|
| **校验** | 每个 id 须非空；未知 id → **404** `tag not found`。 |
| **归属** | 标签须属于当前用户。 |
| **创建** | 不会自动创建标签。 |
| **去重** | **同一条**词条内重复 id 合并为一条关联。 |

##### 两种形式共通

| 行为 | 说明 |
|------|------|
| **存储** | 标签**不**写入 Redis 中 `fact:{id}` 的 JSON；关联单独存储，仅在 GET 时返回。 |
| **添加响应** | `POST …/facts/{operation}` 仅返回 `fact_length`，**不**返回标签对象。创建成功后请用 [`GET /api/decks/{id}/facts`](#获取所有词条) 或 [获取单个词条](#获取单个词条) 查看 `tags`。 |
| **更新** | [`PATCH /api/decks/{id}/facts/{factId}`](#更新词条) **不接受** `tags` 或 `tag_ids`；请用 [词条标签 `PUT`/`DELETE`](#将标签关联到词条) 或在添加时传入标签。 |

```json
{
  "facts": [
    { "entries": [{ "text": "Apple" }, { "text": "りんご" }], "tags": ["food", "noun"] },
    { "entries": [{ "text": "Book" }, { "text": "本" }], "tag_ids": ["Kt8QmNz2"] },
    { "entries": [{ "text": "Water" }, { "text": "水" }], "tags": ["noun"] },
    { "entries": [{ "text": "School" }, { "text": "学校" }] }
  ]
}
```

带媒体与多条例句（每句可有独立音频）示例：

```json
{
  "entries": [
    { "text": "School" },
    { "text": "学校" },
    { "audio": "pron123" },
    { "image": "img456" },
    { "video": "vid789" },
    { "text": "I go to school every day.", "audio": "ex1aud" },
    { "text": "School starts at nine.", "audio": "ex2aud" }
  ]
}
```

将上述对象放入完整请求的 `"facts": [ … ]` 中。请通过 **`PATCH /api/decks/{id}`** 确保卡组 `fields` 有 **七个** 与上述七个 entry 顺序一致的列名，以便学习时标签正确。

#### 模板：默认与兄弟卡

**模板**定义一张卡如何展示词条的条目：**正面**（问题）和**背面**（答案），各为一组条目索引。

- **一张卡**由**二维**值表示：`[[正面索引], [背面索引]]`。  
  例：`[[0], [1]]` 表示正面为第 0 条、背面为第 1 条。  
  例：`[[0], [1, 2, 3]]` 表示正面为第 0 条、背面为第 1、2、3 条。

- **省略 `template` 时的默认行为：**  
  每个词条生成**一张卡**，布局为：正面 = 第 `0` 条，背面 = 其余 `[1, 2, …]`。因此简单「第一条为问题、其余为答案」时无需传 `template`。

- **兄弟卡**指同一词条的**多张**卡（如「词→译」和「译→词」）。若在添加词条时一次性生成，需传入**三维** `template`：即**二维模板的数组**。服务端会为请求中的**每个词条**按该数组中的每个二维模板各生成一张卡。  
  例：对 3 条目的词条，每个词条生成 3 张卡（第 0 条→其余、第 1 条→其余、第 2 条→其余）：

```json
{
  "template": [
    [[0], [1, 2]],
    [[1], [0, 2]],
    [[2], [0, 1]]
  ]
}
```

因此：**二维** = 一张卡（一种正/背面划分）；**三维** = 每词条多张卡（兄弟卡）。若只传一个二维模板（如仅反向 `[[1], [0]]`），API 也接受：会视为「仅含一个模板」的数组，即每个词条一张反向卡。

示例：每个词条两张兄弟卡（正常 + 反向）：

```json
{
  "template": [
    [[0], [1]],
    [[1], [0]]
  ]
}
```

每个词条会得到正面=0/背面=1 与正面=1/背面=0 各一张。若只想为部分词条增加反向卡，可稍后对单个词条调用 `POST /api/decks/{id}/card` 添加。

> **理解请求体：**
>
> - **`entries`**：entry 对象数组。每个 entry 含可选 `text`、`audio`、`image`、`video`、`json`（整条词条至少有一项有内容）。第 `i` 个 entry 与卡组 **`fields[i]`** 对应（见 **获取下一张最紧急卡片**）。在同一 entry 中同时写文本与音频（如 `{ "text": "I go to school.", "audio": "ex1id" }`）可明确该音频对应该句。
> - **`tags`** / **`tag_ids`**（可选，按词条）：`tags` 为标签**名称**数组；`tag_ids` 为已有标签 ID 数组；同一条词条上二选一。无标签时可省略。详见上文 [可选标签（按词条）](#可选标签按词条)。
> - **`template`**（可选）：省略或为空时，每个词条生成**一张卡**，默认布局 `[[0], [1, 2, ...]]`。若提供，须为**三维**数组：二维模板的列表。**每个**词条会按该列表中的每个二维模板各生成一张卡（兄弟卡）。每个二维模板须对当前所有词条有效（条目数一致）；索引须在范围内、互不重复且覆盖全部条目。

**响应:**

```json
{
  "data": {
    "fact_length": 20
  },
  "meta": {
    "msg": "Added 20 facts successfully"
  }
}
```

添加词条的响应**不会**返回新建的词条 ID 或标签关联。若需要每条词条的 `id` 与 `tags`，请在创建成功后调用 **GET** 词条列表或单个词条接口。

### 获取所有词条

**接口：** `GET /api/decks/{id}/facts`

**查询参数（可选）：** `limit`（默认 **50**，最大 **200**）、`offset`（默认 **0**）。省略时使用默认值；**`meta` 回显 `limit` 与 `offset`**，并含 `count`、`has_more`、`total`。

| 名称 | 说明 |
|------|------|
| `limit` | 每页条数。非法或非正数→默认；超过最大→**200**。 |
| `offset` | 按词条 **`id` 升序**排序后跳过的条数。负数→**0**。 |

**请求示例**（首页；省略查询串则使用默认 `limit` 与 `offset`）：

```http
GET /api/decks/{id}/facts?limit=50&offset=0
Authorization: Bearer <token>
```

**响应示例**（两条例词、首页；URL 不传参数时 `meta` 同样为默认 `limit`/`offset`）：

```json
{
  "data": {
    "facts": [
      {
        "id": "x9k2m4np",
        "entries": [{ "text": "Apple" }, { "text": "りんご" }],
        "fields": ["English", "Japanese"],
        "tags": [
          { "id": "a1b2c3d4", "name": "food", "description": "" },
          { "id": "f6e5d4c3", "name": "noun", "description": "Parts of speech" }
        ]
      },
      {
        "id": "b00k1ab2",
        "entries": [{ "text": "Book" }, { "text": "本" }],
        "tags": []
      }
    ]
  },
  "meta": {
    "msg": "Facts retrieved successfully",
    "count": 2,
    "has_more": false,
    "limit": 50,
    "offset": 0,
    "total": 2
  }
}
```

每个词条均包含 **`tags`**：`{ "id", "name", "description" }` 对象数组；无标签时为 `[]`。同一词条可有**多个**标签；列表与详情接口中标签按 **name** 排序。标签不存放在 Redis 的 `fact:{id}` JSON 内，由服务端按用户维度的关联键解析。

### 获取单个词条

**接口：** `GET /api/decks/{id}/facts/{factId}`

**响应示例：**

```json
{
  "data": {
    "fact": {
      "id": "x9k2m4np",
      "entries": [{ "text": "Apple" }, { "text": "りんご" }],
      "fields": ["English", "Japanese"],
      "tags": [
        { "id": "a1b2c3d4", "name": "food", "description": "" },
        { "id": "f6e5d4c3", "name": "noun", "description": "Parts of speech" }
      ]
    }
  },
  "meta": { "msg": "Fact retrieved successfully" }
}
```

### 更新词条

**接口：** `PATCH /api/decks/{id}/facts/{factId}`

> **导入卡组：** **403** `cannot modify facts on an imported deck`。请通过 [同步导入卡组](#同步导入卡组) 接受作者新内容，或使用 `POST …/feedback` 向作者提议修改。

**参数：** `id`（卡组 ID）、`factId`（词条 ID，来自 GET 词条或添加词条）。

**请求体：** 仅可选 **`entries`** — entry 对象数组，含可选 `text`、`audio`、`image`、`video`、`json`。提供时替换该词条 entries。重命名或重排列名请用 **`PATCH /api/decks/{id}`** 的 `fields`（非本接口）。

```json
{
  "entries": [{ "text": "Apple" }, { "text": "りんご" }]
}
```

**响应：**

```json
{
  "data": { "fact_id": "x9k2m4np" },
  "meta": { "msg": "Fact updated successfully" }
}
```

### 删除词条

**接口：** `DELETE /api/decks/{id}/facts/{factId}`

> **导入卡组：** **403** `cannot modify facts on an imported deck`。

**参数：** `id`（卡组 ID）、`factId`（词条 ID）。

永久删除该词条及其衍生出的所有卡片。

**响应：**

```json
{
  "data": { "fact_id": "x9k2m4np" },
  "meta": { "msg": "Fact deleted successfully" }
}
```

---

## 4. 标签

标签按**用户**隔离：先用 `POST /api/tags` 创建，再通过 **`PUT`**（无 JSON 请求体）挂到**卡组**和/或**词条**上。也可在同一请求中传入可选 **`tags`**（名称）或 **`tag_ids`**（已有 ID）：

- **[创建卡组](#创建卡组)**（`POST /api/decks`）— 见 [可选标签（创建时）](#可选标签创建时)。
- **[添加词条](#添加词条)**（`POST /api/decks/{id}/facts/{operation}`）— 每条词条项可带 `tags` 或 `tag_ids`（同条互斥）；见 [可选标签（按词条）](#可选标签按词条)。

在创建卡组或添加词条的请求中，仅当客户端传入 **`tags`**（名称模式）时，服务端会创建缺失的标签并在该请求中完成关联；若传入 **`tag_ids`**，则须为已有标签 ID（可先 `POST /api/tags` 创建），服务端不会自动创建。已有标签也可通过上文 **`PUT`**（无 JSON 请求体）挂到卡组或词条。同一标签可关联多个卡组、多个词条。键空间与命名规则见 **[标签系统设计文档](tagging-system.md)**。

**限制：** 每用户最多 **100** 个不同标签；单个卡组最多关联 **20** 个标签。标签**名称**允许 Unicode 字母与数字、空格、连字符 `-`、撇号 `'`；首尾空白会去掉，连续空白合并为一个。唯一性按**规范化**结果校验（去首尾空白 → 合并空白 → 小写）。**`tag_id`** 为 8 位小写字母数字。

错误响应为 `{ "msg": "..." }`（例如 **409** `tag name already exists`，**400** 校验失败或超出限制）。

### 创建标签

**接口：** `POST /api/tags`

```json
{
  "name": "Food Recipes",
  "description": "Cooking vocabulary"
}
```

**响应（201）：**

```json
{
  "data": {
    "tag": {
      "id": "Kt8QmNz2",
      "name": "Food Recipes",
      "description": "Cooking vocabulary"
    }
  },
  "meta": { "msg": "Tag created successfully" }
}
```

### 列出你的标签

**接口：** `GET /api/tags`

**说明：** `data.tags` 为你拥有的全部标签（最多 100 个）。顺序为 **tag id 字典序**，不是按 `name` 排序——若需按名称展示请在客户端排序。

```json
{
  "data": {
    "tags": [
      {
        "id": "Kt8QmNz2",
        "name": "Food Recipes",
        "description": "Cooking vocabulary"
      },
      { "id": "p4q5r6s7", "name": "GRE Verbal", "description": "" },
      { "id": "z9y8x7w6", "name": "Japanese", "description": "JLPT prep" }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### 获取单个标签

**接口：** `GET /api/tags/{tagId}`

**响应：** 与 `data.tags` 中单条结构相同，但放在 `data.tag` 下，并带 `meta.msg`。

### 更新标签

**接口：** `PATCH /api/tags/{tagId}`

可选字段（不改的字段请省略）：

```json
{
  "name": "Renamed Tag",
  "description": "Updated note"
}
```

**响应：** `data.tag` 为更新后的标签。

### 删除标签

**接口：** `DELETE /api/tags/{tagId}`

删除该标签、其名称索引，以及所有**卡组**与**词条**上的关联。

**响应：**

```json
{
  "data": { "decks_untagged": 3 },
  "meta": { "msg": "Tag deleted successfully" }
}
```

（`decks_untagged` 表示删除前在正向索引上曾带有该标签的卡组数量。）

### 将标签关联到卡组

**接口：** `PUT /api/decks/{id}/tags/{tagId}`

无请求体。须拥有该卡组与该标签。已关联时再次 `PUT` 为幂等。

**响应：** `data.tags` 为**本次关联之后**该卡组上的**全部**标签（与 `GET /api/decks/{id}/tags` 形状相同）。示例：卡组上已有两个标签，再关联第三个：

```json
{
  "data": {
    "tags": [
      { "id": "a1b2c3d4", "name": "GRE", "description": "" },
      { "id": "m9n8p7q6", "name": "Verbal", "description": "" },
      { "id": "Kt8QmNz2", "name": "Vocabulary", "description": "Core words" }
    ]
  },
  "meta": { "msg": "Tags updated successfully" }
}
```

### 从卡组移除标签

**接口：** `DELETE /api/decks/{id}/tags/{tagId}`

**响应：** 与 `PUT` 相同信封，`data.tags` 为移除后剩余标签。

### 列出卡组上的标签

**接口：** `GET /api/decks/{id}/tags`

**响应：** 与 `PUT`/`DELETE` 的 `data.tags` 相同。多标签示例：

```json
{
  "data": {
    "tags": [
      { "id": "a1b2c3d4", "name": "GRE", "description": "" },
      { "id": "m9n8p7q6", "name": "Verbal", "description": "" },
      { "id": "Kt8QmNz2", "name": "Vocabulary", "description": "Core words" }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### 将标签关联到词条

**接口：** `PUT /api/decks/{id}/facts/{factId}/tags/{tagId}`

无请求体。标签须已存在（`POST /api/tags`）。词条须属于该卡组。

**响应：** `PUT` 后该词条的完整标签列表（可有多个标签）：

```json
{
  "data": {
    "tags": [
      { "id": "Kt8QmNz2", "name": "verb", "description": "Part of speech" },
      { "id": "r5s6t7u8", "name": "hard", "description": "" }
    ]
  },
  "meta": { "msg": "Tags updated successfully" }
}
```

### 从词条移除标签

**接口：** `DELETE /api/decks/{id}/facts/{factId}/tags/{tagId}`

**响应：** 同 `PUT`（`data.tags` 为该词条剩余标签）。

### 列出词条上的标签

**接口：** `GET /api/decks/{id}/facts/{factId}/tags`

**响应：** 与 `data.tags` 形状相同（可不拉取完整词条仅取标签）。两标签示例：

```json
{
  "data": {
    "tags": [
      { "id": "Kt8QmNz2", "name": "verb", "description": "Part of speech" },
      { "id": "r5s6t7u8", "name": "hard", "description": "" }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### 列出拥有某标签的所有词条

**接口：** `GET /api/tags/{tagId}/facts`

**响应：** 你所有卡组中带该标签的词条，常有多条：

```json
{
  "data": {
    "facts": [
      { "deck_id": "dk7xm2n9pq4w", "fact_id": "f4k2m9x1" },
      { "deck_id": "dk7xm2n9pq4w", "fact_id": "n3p4q5r6" },
      { "deck_id": "ab12cd34ef56", "fact_id": "s7t8u9v0" }
    ]
  },
  "meta": { "msg": "Facts retrieved successfully" }
}
```

---

## 5. 卡片

### 为已有词条添加一张卡（如反向卡）

默认**每词条一张卡**。若要为某词条再增加一张卡（如反向卡：先显示背面再显示正面），请使用 **POST /api/decks/{id}/card**，请求体传 `fact_id` 与 `template`。此接口与「添加词条」分开。

**接口:** `POST /api/decks/{id}/card`

**参数:**

- `id`: 卡组 ID

**请求体:**

```json
{
  "fact_id": "x9k2m4np",
  "template": [[1], [0]]
}
```

- **`fact_id`**（必填）：词条 ID（来自 `GET /api/decks/{id}/facts` 或添加词条后的数据）。
- **`template`**（必填）：`[[正面索引], [背面索引]]`，指定卡片如何展示词条各列。两列词条：`[[0],[1]]` = 正面第 0 列、背面第 1 列；`[[1],[0]]` = 反向。索引须在 `0..(n-1)` 内、互不重复且覆盖所有列。若该 fact 下已有卡片使用相同 template 则返回 400。
- **`operation`**（可选）：`append`、`prepend`、`shuffle` 或 `spread`，表示新卡在未复习卡中的位置，默认为 `append`。

**响应:**

```json
{
  "data": {
    "card_id": "n3w4c5a6"
  },
  "meta": {
    "msg": "Card added successfully"
  }
}
```

---

### 获取下一张最紧急卡片

**接口:** `GET /api/decks/{id}/card`

**查询参数（可选）：**

| 参数     | 说明 |
|----------|------|
| `tag_id` | 标签 ID。提供后，仅在当前卡组中、其 `fact_id` 对应到该标签词条的卡片范围内进行“下一张”选择。 |

示例：`GET /api/decks/{id}/card?tag_id=Kt8QmNz2`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**响应结构：** `front` 与 `back` 为按 **template 顺序**排列的 **entry 对象数组**（正面/背面每一侧每个 fact entry 索引对应一个对象）。每个对象与 fact **entry** 一致：可选 **`field`**（列名标签）及可选 **`text`**、**`audio`**、**`image`**、**`video`**、**`json`** 字符串键（无内容则省略）。存在 **`field`** 时来自卡组 **`fields`**（entry 索引 `i` 对应 `fields[i]`）；卡组列名少于 entry 数时，部分对象可能无 `field`。正文与读音可在同一对象并列（如 `"text": "Hello"` 与 `"audio": "https://.../api/media/…"`）。媒体键在服务端能确定 base URL 时为**完整 URL**；用相同 `Authorization: Bearer <token>` 下载。

下列 JSON 示例均有对应集成测试：[`api/tests/integration/card_test.go`](../api/tests/integration/card_test.go) 中的 `TestGetNextCard`（含卡组字段名）与 `TestNextCardUrgencySelection`（卡组列名缺失/过短、text+audio+image、多正面、仅正面、分屏 template `[[0,1],[2,3]]`、完整 URL host）。

**响应（无字段名）：**

```json
{
  "data": {
    "card": {
      "id": "k7m2n9p1",
      "fact_id": "a3b4c5d6",
      "template": [[0], [1]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [{ "text": "Apple" }],
      "back": [{ "text": "苹果" }]
    },
    "urgency": 1.0
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

**响应（含字段名）：**

```json
{
  "data": {
    "card": {
      "id": "xyz12345",
      "fact_id": "x9k2m4np",
      "template": [[0], [1]],
      "last_review": 1763269701,
      "due_date": 1763269702,
      "hidden": false,
      "created_at": 1763269700,
      "front": [{ "field": "Word", "text": "Apple" }],
      "back": [{ "field": "Translation", "text": "苹果" }]
    },
    "urgency": 2.598
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

**响应（一项含 text + audio + image）：**

```json
{
  "data": {
    "card": {
      "id": "m8n9p0q1",
      "fact_id": "e7f8g9h0",
      "template": [[0], [1]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        {
          "field": "Word",
          "text": "Hello",
          "audio": "https://api.example.com/api/media/aud001",
          "image": "https://api.example.com/api/media/img002"
        }
      ],
      "back": [{ "field": "Translation", "text": "你好" }]
    },
    "urgency": 1.0
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

**响应（正面多词条 — 如两句例句各有 text + audio）：**

```json
{
  "data": {
    "card": {
      "id": "k7m2n9p1",
      "fact_id": "a3b4c5d6",
      "template": [[0, 1], [2]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        {
          "field": "Example",
          "text": "First sentence.",
          "audio": "https://api.example.com/api/media/aud001"
        },
        {
          "field": "Example",
          "text": "Second sentence.",
          "audio": "https://api.example.com/api/media/aud002"
        }
      ],
      "back": [{ "field": "Translation", "text": "翻译" }]
    },
    "urgency": 1.0
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

**仅正面卡片（背面为空，如 template `[[0], []]`）：**

```json
{
  "data": {
    "card": {
      "id": "p4q5r6s7",
      "fact_id": "w1x2y3z4",
      "template": [[0], []],
      "last_review": 0,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [{ "field": "Question", "text": "Only front text" }],
      "back": []
    },
    "urgency": 1.0
  },
  "meta": { "msg": "Next urgent card retrieved successfully" }
}
```

**多词条且含媒体的卡片（template [[0, 1], [2, 3]]；媒体键的值为完整 URL）：**

```json
{
  "data": {
    "card": {
      "id": "m8n9o0p1",
      "fact_id": "f2a3b4c5",
      "template": [
        [0, 1],
        [2, 3]
      ],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        { "field": "Front", "text": "Word" },
        {
          "field": "Pronunciation",
          "audio": "https://api.retentio.app:8443/api/media/abc123"
        }
      ],
      "back": [
        {
          "field": "Picture",
          "image": "https://api.retentio.app:8443/api/media/def456"
        },
        {
          "field": "Clip",
          "video": "https://api.retentio.app:8443/api/media/vid789",
          "text": "Translation"
        }
      ]
    },
    "urgency": 1.2
  },
  "meta": { "msg": "Next urgent card retrieved successfully" }
}
```

> 请保存 `card.id` — 更新卡片时（步骤 6）需要用到。

---

### 复习卡片

查看卡片后，您需要根据记忆程度更新复习间隔。

**接口:** `PATCH /api/decks/{id}/card`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**请求体:**

```json
{
  "card_id": "xyz12345",
  "interval": 600,
  "last_review": 1763272400
}
```

> 使用 GET 响应中的 `card.id` 作为 `card_id`。
> `last_review` 为 UTC Unix 时间戳（秒）—
> 客户端通常使用 `Math.floor(Date.now() / 1000)`。

<!-- -->

> 💡 **计算最小和最大间隔（前端计算）：**
>
> 服务器只在每张卡片上存储 `last_review` 和 `due_date`。
> 前端必须推算当前间隔并计算允许范围后再提交。
> 同一请求中不能同时发送 `interval` 和 `hidden`。
>
> **第 1 步 — 推算当前间隔：**
>
> ```text
> current_interval = due_date - last_review    （最小 60 秒）
> ```
>
> 对于全新卡片（`last_review = 0`），将 `current_interval` 视为 60 秒。
>
> **第 2 步 — 计算紧迫度：**
>
> ```text
> urgency = (now - last_review) / (due_date - last_review)
> ```
>
> **第 3 步 — 计算最小和最大间隔：**
>
> 当卡片已逾期（`urgency >= 1`）：
>
> ```text
> min_interval = current_interval × 0.5
> max_interval = current_interval × 4.0
> ```
>
> 当卡片尚未到期（`urgency < 1`）：
>
> ```text
> min_interval = current_interval × ((0.5 - 1) × urgency + 1)
> max_interval = current_interval × ((4.0 - 1) × urgency + 1)
> ```
>
> **第 4 步 — 提交前验证：**
>
> 前端必须验证所选的 `interval` 满足
> `min_interval <= interval <= max_interval`，
> 然后再发送 PATCH 请求。

**响应:**

```json
{
  "data": {
    "last_review": 1763272400,
    "due_date": 1763273000,
    "new_interval": 600
  },
  "meta": {
    "msg": "Card interval updated successfully"
  }
}
```

---

### 隐藏卡片

如果您想暂时从复习中隐藏某张卡片：

**接口:** `PATCH /api/decks/{id}/card`

**参数:**

- `id`: `a1b2c3d4e5f6`

**请求体:**

```json
{
  "card_id": "xyz12345",
  "hidden": true
}
```

**响应:**

```json
{
  "data": {
    "hidden_status": true
  },
  "meta": {
    "msg": "Card visibility updated successfully"
  }
}
```

---

### 删除卡片

从卡组中永久删除单张卡片。该词条及该词条的其他卡片（如反向卡）不受影响。

**接口：** `DELETE /api/decks/{id}/cards/{cardId}`

**参数：**

- `id`：卡组 ID（如 `a1b2c3d4e5f6`）
- `cardId`：卡片 ID（来自获取下一张卡片或卡片统计的响应）

**请求体：** 无。

**响应：**

```json
{
  "data": {
    "card_id": "xyz12345"
  },
  "meta": {
    "msg": "Card deleted successfully"
  }
}
```

### 获取卡片统计

**接口：** `GET /api/decks/{id}/cards`

**查询参数（可选）：**

| 参数     | 说明 |
|----------|------|
| `tag_id` | 标签 ID。提供后，仅统计当前卡组中、其 `fact_id` 对应到该标签词条的卡片。 |

示例：`GET /api/decks/{id}/cards?tag_id=Kt8QmNz2`

**响应示例：**

```json
{
  "data": {
    "total_cards": 20,
    "hidden_cards_count": 3,
    "due_cards": 7,
    "unseen_cards": 5,
    "hidden_cards_list": [
      {
        "id": "cd1ef2gh",
        "fact_id": "h1d2e3n4",
        "template": [[0], [1]],
        "last_review": 1710000000,
        "due_date": 1710500000,
        "hidden": true,
        "created_at": 1709000000
      }
    ],
    "cards": [
      {
        "id": "cd1ef2gh",
        "fact_id": "h1d2e3n4",
        "template": [[0], [1]],
        "last_review": 1710000000,
        "due_date": 1710500000,
        "hidden": true,
        "created_at": 1709000000
      }
    ],
    "orphaned_hidden_cards": 0
  },
  "meta": { "msg": "Card stats retrieved successfully" }
}
```

---

## 6. 媒体（音频 / 图片）

可为词条附加音频、图片和视频。每条 entry 为对象，含可选 `text`、`audio`、`image`、`video`；可单独用一项媒体（如 `{ "audio": "abc123" }`），或与文本合在同一 entry（如 `{ "text": "例文。", "audio": "ex1id" }`）以明确该音频对应该句。

**大小限制：** 图片最大 **5 MB**；音频与视频各最大 **200 MB**。可通过环境变量覆盖：`MEDIA_MAX_SIZE_IMAGE`、`MEDIA_MAX_SIZE_VIDEO`、`MEDIA_MAX_SIZE_AUDIO`。

**格式：** 支持的输入：图片（JPEG、PNG、GIF、HEIC、HEIF、WebP），音频（MPEG/MP3、WAV、OGG、MP4/AAC），视频（MP4、QuickTime、WebM），以及 JSON（`application/json`）。文件按上传原样存储，不做转码。下载时返回存储后的文件（二进制）。

### 上传媒体

**接口：** `POST /api/media` — multipart/form-data。

| 字段        | 必填 | 说明                                                                           |
| ----------- | ---- | ------------------------------------------------------------------------------ |
| `file`      | 是   | 媒体文件（图片、音频或视频）。                                                 |
| `client_id` | 否   | 客户端生成的 ID，用于幂等上传；若该用户下该媒体已存在，则返回 201 及已有记录。 |

**响应：**

```json
{
  "data": {
    "id": "abc1234def0",
    "owner": "swagger",
    "filename": "pronunciation.mp3",
    "mime": "audio/mpeg",
    "size": 51200,
    "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924",
    "created_at": 1704067200
  },
  "meta": { "msg": "media uploaded" }
}
```

### 列出媒体

**接口：** `GET /api/media` — 返回当前用户的媒体（分页）。

| 查询参数 | 说明                                            |
| -------- | ----------------------------------------------- |
| `since`  | 可选。Unix 时间戳；仅返回该时间之后创建的媒体。 |
| `limit`  | 可选。每页条数（默认 50，最大 200）。           |
| `offset` | 可选。跳过条数（默认 0）。                      |

**响应：**

```json
{
  "data": [
    {
      "id": "abc1234def0",
      "owner": "swagger",
      "filename": "pronunciation.mp3",
      "mime": "audio/mpeg",
      "size": 51200,
      "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924",
      "created_at": 1704067200
    }
  ],
  "meta": { "count": 1, "has_more": false }
}
```

### 获取媒体元数据

**接口：** `GET /api/media/{id}/meta`

仅返回元数据（id、owner、filename、mime、size、checksum、created_at），不含文件体。

### 下载媒体

**接口：** `GET /api/media/{id}`

按 ID 返回用户拥有的媒体文件（二进制）。需在请求头中携带 `Authorization: Bearer <token>`。响应头包含 `Content-Type`、`Content-Length` 和 `ETag`（与 `checksum` 一致）。请求头中携带 `If-None-Match: <ETag>` 可在文件未变更时获得 `304 Not Modified`。**获取下一张卡片** 接口会在每个正面/背面词条对象的 `audio`、`image`、`video` 字段中给出完整 URL（如 `https://api.retentio.app:8443/api/media/{id}`）；使用该 URL 并携带相同认证头即可加载文件。

**卡组共享（导入者）：** 若已导入卡组，当你的账号在 `user:{username}:readable_media_versions` 中有来自该快照的 `mediaId@version` 授权时，可下载作者媒体。服务端返回**版本化**字节。同一 `media_id` 存在多个可能版本时，请追加 **`?v=<version>`**（部分词条响应中的媒体 URL 已自动带 `?v=`）。

### 删除媒体

**接口：** `DELETE /api/media/{id}`

**响应：**

```json
{
  "data": { "msg": "media deleted" }
}
```

### 在词条中使用媒体

每条 entry 为对象，含可选 `text`、`audio`、`image`、`video`。可为媒体单独建 entry（如 `{ "audio": "abc123" }`），或与正文合并在同一 entry（如 `{ "text": "Example sentence.", "audio": "ex1id" }`）以标明音频属于该句。可选用 `template` 指定每词条正/背面布局；省略则默认（正面第一条 entry、背面其余）。

完整设计（上传、删除、展示、同步）见 **[媒体上传设计文档](media-upload.md)**。

---

## 响应示例速查

| 接口                                          | 方法        | 响应结构                                                                                                                                             |
| --------------------------------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/auth/register`                              | POST        | `{ "data": { … }, "meta": { "msg": "..." } }` — 见 [创建用户](#创建用户)                                                                             |
| `/auth/login`                                 | POST        | `{ "data": { "token", "expires" }, "meta": { "expires" } }`                                                                                          |
| `/auth/logout`                                | POST        | `{ "data": { "msg": "Logged out successfully" }, "meta": null }`                                                                                     |
| `/auth/forgot-password`                       | POST        | `{ "data": { "reset_token" }, "meta": { "expires_in" } }`                                                                                            |
| `/auth/reset-password`                        | POST        | `{ "data": { "msg": "Password reset successfully" }, "meta": null }`                                                                                 |
| `/api/profile`                                | GET         | `{ "data": { 用户资料 }, "meta": { "msg" } }`                                                                                                        |
| `/api/decks`                                  | POST        | `{ "data": { "deck_id" }, "meta": { "msg" } }`                                                                                                       |
| `/api/decks`                                  | GET         | `{ "data": { "decks": [ … ] }, "meta": { "total", "msg" } }`                                                                                         |
| `/api/decks/{id}`                             | GET         | `{ "data": { 卡组 + 统计 }, "meta": { "msg" } }`                                                                                                     |
| `/api/decks/{id}`                             | PATCH       | `{ "data": { "deck_id" }, "meta": { "msg", "updated_at" } }`                                                                                         |
| `/api/decks/{id}`                             | DELETE      | `{ "data": { "deck_id" }, "meta": { "msg" } }`                                                                                                       |
| `/api/decks/{id}/facts/{op}`                  | POST        | 添加词条：body `facts[]` 每项可选 `tags`（名称）或 `tag_ids`（同条互斥）；`{ "data": { "fact_length" }, "meta": { "msg" } }`（响应不含标签）       |
| `/api/decks/{id}/card`                        | POST        | 为已有词条加卡：`{ "data": { "card_id" }, "meta": { "msg" } }`                                                                                       |
| `/api/decks/{id}/facts`                       | GET         | `{ "data": { "facts": [ … ] }, "meta": { "msg", "count", "has_more", "limit", "offset", "total" } }` — 默认 `limit` 50、`offset` 0                  |
| `/api/decks/{id}/facts/{factId}`              | GET         | `{ "data": { "fact": { …, "tags": [ … ] } }, "meta": { "msg" } }`                                                                                    |
| `/api/decks/{id}/facts/{factId}`              | PATCH       | `{ "data": { "fact_id" }, "meta": { "msg" } }`                                                                                                       |
| `/api/decks/{id}/facts/{factId}`              | DELETE      | `{ "data": { "fact_id" }, "meta": { "msg" } }`                                                                                                       |
| `/api/decks/{id}/card`                        | GET         | 可选查询 `tag_id`。形状不变：`{ "data": { "card": { id, fact_id, template, …, front[], back[] }, "urgency" }, "meta": { "msg", … } }`                |
| `/api/decks/{id}/card`                        | PATCH       | 间隔：`{ "data": { "last_review", "due_date", "new_interval" }, "meta": { "msg" } }`；可见性：`{ "data": { "hidden_status" }, "meta": { "msg" } }` |
| `/api/decks/{id}/cards`                       | GET         | 可选查询 `tag_id`。形状不变：`{ "data": { "total_cards", "hidden_count", "hidden_facts", "orphaned_hidden_cards" }, "meta": { "msg" } }`              |
| `/api/decks/{id}/cards/{cardId}`              | DELETE      | `{ "data": { "card_id" }, "meta": { "msg" } }`                                                                                                       |
| `/api/decks/{id}/reschedule`                  | POST        | `{ "data": { "cards_shifted", "days", "max_days_away" }, "meta": { "msg" } }`                                                                        |
| `/api/decks/catalog`                          | GET         | `{ "data": { "decks": [ … ] }, "meta": { "msg", "count", "total", "limit", "offset", "has_more" } }` — 默认 `limit` 50、`offset` 0；可选 `query` |
| `/api/decks/catalog/{id}`                     | GET         | `{ "data": { "id", "name", "description", "owner", "fields", "published_version", "fact_count", "deck_tag_names", "published_at" }, "meta": { "msg" } }` — 单条目录记录；不可导入时 **404** |
| `/api/decks/import`                           | POST        | **201** — `{ "data": { "id", "source_deck_id", "source_version", "imported_at" }, "meta": { "msg" } }`                                               |
| `/api/decks/{id}/publish`                     | POST        | `{ "data": { "published_version", "visibility" }, "meta": { "msg": "published" } }`                                                                 |
| `/api/decks/{id}/updates`                     | GET         | `{ "data": { "source_version", "latest_version", "added_facts", "removed_facts", "edited_facts", "media_changes" }, "meta": { "msg" } }`           |
| `/api/decks/{id}/sync`                        | POST        | `{ "data": { "source_version" }, "meta": { "msg": "synced" } }`                                                                                    |
| `/api/tags`                                   | POST        | `{ "data": { "tag": { id, name, description } }, "meta": { "msg" } }` — **201**                                                                    |
| `/api/tags`                                   | GET         | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                   |
| `/api/tags/{tagId}`                           | GET         | `{ "data": { "tag": { … } }, "meta": { "msg" } }`                                                                                                    |
| `/api/tags/{tagId}`                           | PATCH       | `{ "data": { "tag": { … } }, "meta": { "msg" } }`                                                                                                    |
| `/api/tags/{tagId}`                           | DELETE      | `{ "data": { "decks_untagged" }, "meta": { "msg" } }`                                                                                                |
| `/api/tags/{tagId}/facts`                     | GET         | `{ "data": { "facts": [ { "deck_id", "fact_id" }, … ] }, "meta": { "msg" } }`                                                                        |
| `/api/decks/{id}/tags/{tagId}`                | PUT, DELETE | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                   |
| `/api/decks/{id}/tags`                        | GET         | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                   |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | PUT, DELETE | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                   |
| `/api/decks/{id}/facts/{factId}/tags`         | GET         | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                   |
| `/api/media`                                  | POST        | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }`                                                           |
| `/api/media`                                  | GET         | `{ "data": [ MediaSwagger, … ], "meta": { "count", "has_more" } }`                                                                                   |
| `/api/media/{id}/meta`                        | GET         | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }`                                                           |
| `/api/media/{id}`                             | GET         | 下载媒体（二进制）                                                                                                                                   |
| `/api/media/{id}`                             | DELETE      | `{ "data": { "msg": "media deleted" } }`                                                                                                             |

上文各节含完整 JSON 示例。

---

## 后续步骤

- 通过 **[卡组共享](#卡组共享概述)** 分享卡组（发布 → 导入 → 查看更新 → 同步）
- 使用 **[标签](#4-标签)** 在卡组与词条维度整理内容
- 在 [卡片](#5-卡片) 中重复 **获取下一张最紧急卡片** 与 **复习卡片** 步骤以持续复习
- **离线同步** — 恢复联网后同步数据（规划中）
- **本地存储** — 缓存卡组与卡片供离线使用（规划中）
