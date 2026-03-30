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
- [3. 词条](#3-词条)
  - [添加词条](#添加词条)
  - [获取所有词条](#获取所有词条)
  - [获取单个词条](#获取单个词条)
  - [更新词条](#更新词条)
  - [删除词条](#删除词条)
- [4. 卡片](#4-卡片)
  - [为已有词条添加一张卡（如反向卡）](#为已有词条添加一张卡如反向卡)
  - [获取下一张最紧急卡片](#获取下一张最紧急卡片)
  - [复习卡片](#复习卡片)
  - [隐藏卡片](#隐藏卡片)
  - [删除卡片](#删除卡片)
  - [获取卡片统计](#获取卡片统计)
- [5. 媒体（音频 / 图片）](#5-媒体音频--图片)
  - [上传媒体](#上传媒体)
  - [列出媒体](#列出媒体)
  - [获取媒体元数据](#获取媒体元数据)
  - [下载媒体](#下载媒体)
  - [删除媒体](#删除媒体)
  - [列出或查询共享媒体（开发中）](#列出或查询共享媒体开发中)
  - [下载共享媒体（开发中）](#下载共享媒体开发中)
  - [管理端共享媒体（开发中）](#管理端共享媒体开发中)
  - [在词条中使用媒体（开发中）](#在词条中使用媒体开发中)
- [响应示例速查](#响应示例速查)
- [后续步骤](#后续步骤)

---

## 前提条件

- 打开 Swagger UI：
  - **本地**: <http://localhost:8080/docs>
  - **生产环境**: <https://api.wordupx.com:8443/docs>

> **时间戳规范：** API 中所有时间戳均使用 **UTC** 时区。
> ISO 8601 字符串使用 `Z` 后缀（例如 `2026-02-08T12:00:00Z`）。
> Unix 时间戳为自 Unix 纪元（1970-01-01T00:00:00Z）以来的秒数。
> 客户端需自行进行本地时间的转换。
>
> **ID 格式：** 卡组、词条、卡片 ID 均为随机 **小写字母数字** 字符串（无下划线或连字符）。后端生成：**deck_id** 12 位、**fact_id** 与 **card_id** 各 8 位。媒体 ID（如 `[audio:id]` 中的 id）为 10 位。本指南中的示例 ID 均符合上述长度。

---

## API 接口参考

| 接口 | 方法 | 说明 |
| ------ | ------ | ------ |
| `/auth/register` | POST | 注册用户 |
| `/auth/login` | POST | 登录 |
| `/auth/logout` | POST | 登出（使令牌失效） |
| `/auth/forgot-password` | POST | 请求密码重置令牌 |
| `/auth/reset-password` | POST | 使用令牌重置密码 |
| `/api/profile` | GET | 获取当前用户资料 |
| `/api/decks` | POST | 创建卡组 |
| `/api/decks` | GET | 获取所有卡组 |
| `/api/decks/{id}` | GET | 获取卡组详情 |
| `/api/decks/{id}` | PATCH | 更新卡组 |
| `/api/decks/{id}` | DELETE | 删除卡组 |
| `/api/decks/{id}/facts/{operation}` | POST | 添加词条：operation 为 append/prepend/shuffle/spread。请求体：facts（必填）及可选 template。为已有词条添加一张卡请使用 POST `/api/decks/{id}/card`。 |
| `/api/decks/{id}/facts` | GET | 获取所有词条 |
| `/api/decks/{id}/facts/{factId}` | GET | 获取单个词条 |
| `/api/decks/{id}/facts/{factId}` | PATCH | 更新词条 |
| `/api/decks/{id}/facts/{factId}` | DELETE | 删除词条 |
| `/api/decks/{id}/card` | GET | 获取最紧急卡片 |
| `/api/decks/{id}/card` | POST | 为已有词条添加一张卡（如反向卡）。请求体：fact_id、template，可选 operation。 |
| `/api/decks/{id}/card` | PATCH | 更新卡片间隔或可见性（按 card_id） |
| `/api/decks/{id}/cards` | GET | 获取卡片统计 |
| `/api/decks/{id}/cards/{cardId}` | DELETE | 删除单张卡片（词条及其他卡片不变） |
| `/api/decks/{id}/reschedule` | POST | 假期模式：按天数平移卡片复习计划 |
| `/api/media` | POST | 上传媒体（音频/图片） |
| `/api/media` | GET | 列出用户媒体（同步清单） |
| `/api/media/shared` | GET | 列出或查询共享媒体（`?word=...&lang=...`） |
| `/api/media/shared/{id}` | GET | 下载共享媒体文件 |
| `/api/media/{id}/meta` | GET | 获取媒体元数据（不含文件体） |
| `/api/media/{id}` | GET | 下载媒体文件 |
| `/api/media/{id}` | DELETE | 删除媒体 |
| `/api/admin/media/shared` | POST | **（管理端）** 上传共享媒体 |
| `/api/admin/media/shared/{id}` | DELETE | **（管理端）** 删除共享媒体 |
| `/api/admin/decks/import` | POST | **（管理端）** 导入共享卡组（zip + manifest） |

> **说明：** 管理端媒体相关接口为**开发中**，行为可能变更。

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

### 创建卡组

**接口:** `POST /api/decks`

```json
{
  "fields": [
    "English",
    "Japanese"
  ],
  "name": "English Japanese IELTS Deck",
  "rate": 20
}
```

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
    "field": ["English", "Japanese"],
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
  },
  "meta": {
    "msg": "Deck retrieved successfully"
  }
}
```

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
        "field": ["English", "Japanese"],
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
> | 字段 | 说明 |
> | ------ | ------ |
> | `total`（总数） | 当前用户拥有的卡组总数 |
> | `msg`（消息） | 状态信息 |

<!-- -->

> **理解 `stats`（统计信息）：**
>
> | 字段 | 说明 |
> | ------ | ------ |
> | `cards_count`（卡片总数） | 卡组中的卡片总数 |
> | `facts_count`（词条总数） | 卡组中的词条总数 |
> | `unseen_cards`（未学习卡片） | 从未复习过的新卡片数量 |
> | `reviewed_cards`（已学习卡片） | 已学习过至少一次的卡片数量 |
> | `due_cards`（待复习卡片） | 当前待复习的卡片数量（due_date <= 当前时间） |
> | `hidden_cards`（已隐藏卡片） | 被用户隐藏的卡片数量 |
> | `new_cards_today`（今日新增卡片） | 今天添加的卡片数量（从午夜开始计算） |
> | `last_reviewed_at`（上次复习时间） | 最近一次复习的 Unix 时间戳（未复习过则为 `0`） |
>
> 统计信息是实时计算的。对于刚创建的空卡组，所有值都为 `0`。
> 添加词条后，`cards_count` 和 `unseen_cards` 会增加。
> 随着复习的进行，`reviewed_cards` 会增长，`unseen_cards` 会减少。
>
> 默认每词条一张卡（见 [模板：默认与兄弟卡](#模板默认与兄弟卡)）。若需为某词条再增加一张卡（如反向卡），请调用 `POST /api/decks/{id}/card`，body 传 `{"fact_id": "<factId>", "template": [[1], [0]]}`。若该 template 已存在则返回 400。
>
> 客户端计算学习进度百分比：`reviewed_cards / cards_count * 100`。

### 更新卡组

**接口:** `PATCH /api/decks/{id}`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**请求体:**

```json
{
  "name": "更新后的卡组名称",
  "fields": ["English", "Japanese"],
  "rate": 30
}
```

> 除 `name` 外，所有字段都是可选的。如果提供了 `fields`，数量必须与现有字段数匹配。`rate` 必须在 1 到 1000 之间。

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

> 此操作会永久删除卡组及其所有关联的词条和卡片。

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

## 3. 词条

### 添加词条

**接口:** `POST /api/decks/{id}/facts/{operation}`

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）
- `operation`: `append`

**请求体：** 词条数组（每项含 `entries`）及可选的 `template`。每条 **entry** 为对象，含可选字段 `text`、`audio`、`image`、`video`（至少填一项）。服务端为每个词条生成唯一 ID，并根据 `template` 为每个词条创建一张或多张卡片（见下方 **模板：默认与兄弟卡**）。

```json
{
  "facts": [
    { "entries": [{ "text": "Apple" }, { "text": "りんご" }] },
    { "entries": [{ "text": "Book" }, { "text": "本" }] },
    { "entries": [{ "text": "Water" }, { "text": "水" }] },
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
  ],
  "fields": ["Word", "Translation", "Pronunciation", "Picture", "Clip", "Example 1", "Example 2"]
}
```

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
"template": [
  [[0], [1, 2]],
  [[1], [0, 2]],
  [[2], [0, 1]]
]
```

因此：**二维** = 一张卡（一种正/背面划分）；**三维** = 每词条多张卡（兄弟卡）。若只传一个二维模板（如仅反向 `[[1], [0]]`），API 也接受：会视为「仅含一个模板」的数组，即每个词条一张反向卡。

示例：每个词条两张兄弟卡（正常 + 反向）：

```json
"template": [ [[0], [1]], [[1], [0]] ]
```

每个词条会得到正面=0/背面=1 与正面=1/背面=0 各一张。若只想为部分词条增加反向卡，可稍后对单个词条调用 `POST /api/decks/{id}/card` 添加。

> **理解请求体：**
>
> - **`entries`**：entry 对象数组。每个 entry 含可选 `text`、`audio`、`image`、`video`（至少一项）。第 `i` 个 entry 对应第 `i` 列，可用 `fields[i]` 作为标签。在同一 entry 中同时写文本与音频（如 `{ "text": "I go to school.", "audio": "ex1id" }`）可明确该音频对应该句。
> - **`fields`**（可选）：该词条各列的显示名称；第 `i` 个条目对应 `fields[i]`。省略则使用卡组默认 `fields`。若提供，长度须与 `entries` 一致。
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

### 获取所有词条

**接口：** `GET /api/decks/{id}/facts`

**响应示例：**

```json
{
  "data": {
    "facts": [
      { "id": "x9k2m4np", "entries": [{ "text": "Apple" }, { "text": "りんご" }], "fields": ["English", "Japanese"] },
      { "id": "b00k1ab2", "entries": [{ "text": "Book" }, { "text": "本" }] }
    ]
  },
  "meta": { "msg": "Facts retrieved successfully" }
}
```

### 获取单个词条

**接口：** `GET /api/decks/{id}/facts/{factId}`

**响应示例：**

```json
{
  "data": {
    "fact": {
      "id": "x9k2m4np",
      "entries": [{ "text": "Apple" }, { "text": "りんご" }],
      "fields": ["English", "Japanese"]
    }
  }
}
```

### 更新词条

**接口：** `PATCH /api/decks/{id}/facts/{factId}`

**参数：** `id`（卡组 ID）、`factId`（词条 ID，来自 GET 词条或添加词条响应）。

**请求体：** 可选 `entries` 与 `fields`。若提供 `entries` 则替换该词条内容；若提供 `fields`，其长度须与 `entries` 一致。

```json
{
  "entries": [{ "text": "Apple" }, { "text": "りんご" }],
  "fields": ["English", "Japanese"]
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

## 4. 卡片

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

**参数:**

- `id`: `a1b2c3d4e5f6`（您的卡组 ID）

**响应结构：** `front` 与 `back` 为**词条对象数组**，顺序按 **template**（每个对象对应 template 在该侧的一个词条索引）。每个对象与事实中的**词条（entry）**一致：可选 **`field`**（标签），以及可选的 **`text`**、**`audio`**、**`image`**、**`video`** 字符串键（无内容则省略）。正文与对应读音音频在同一对象上并列（例如 `"text": "Hello"` 与 `"audio": "https://…/api/media/…"`），对应关系明确。`audio` / `image` / `video` 在服务端能解析 base URL 时为**完整媒体 URL**（如 `https://api.wordupx.com:8443/api/media/abc123`）。使用该 URL 并携带相同 `Authorization: Bearer <token>` 即可下载。

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
      "front": [
        {"text": "Apple"}
      ],
      "back": [
        {"text": "苹果"}
      ]
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
      "front": [
        {"field": "Word", "text": "Apple"}
      ],
      "back": [
        {"field": "Translation", "text": "苹果"}
      ]
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
      "back": [
        {"field": "Translation", "text": "你好"}
      ]
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
      "back": [
        {"field": "Translation", "text": "翻译"}
      ]
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
      "front": [
        {"field": "Question", "text": "Only front text"}
      ],
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
      "template": [[0, 1], [2, 3]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        {"field": "Front", "text": "Word"},
        {"field": "Pronunciation", "audio": "https://api.wordupx.com:8443/api/media/abc123"}
      ],
      "back": [
        {"field": "Picture", "image": "https://api.wordupx.com:8443/api/media/def456"},
        {"field": "Clip", "video": "https://api.wordupx.com:8443/api/media/vid789", "text": "Translation"}
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

**响应示例：**

```json
{
  "data": {
    "total_cards": 20,
    "hidden_count": 3,
    "hidden_facts": [
      { "id": "h1d2e3n4", "entries": ["Hidden word", "隠れた語"], "fields": ["English", "Japanese"] }
    ],
    "orphaned_hidden_cards": 0
  },
  "meta": { "msg": "Card stats retrieved successfully" }
}
```

---

## 5. 媒体（音频 / 图片）

可为词条附加音频、图片和视频。每条 entry 为对象，含可选 `text`、`audio`、`image`、`video`；可单独用一项媒体（如 `{ "audio": "abc123" }`），或与文本合在同一 entry（如 `{ "text": "例文。", "audio": "ex1id" }`）以明确该音频对应该句。

**大小限制：** 图片最大 **5 MB**；音频与视频各最大 **200 MB**。可通过环境变量覆盖：`MEDIA_MAX_SIZE_IMAGE`、`MEDIA_MAX_SIZE_VIDEO`、`MEDIA_MAX_SIZE_AUDIO`。

**格式与转换：** 支持的输入：图片（JPEG、PNG、GIF、HEIC、HEIF、WebP），音频（MPEG/MP3、WAV、OGG、MP4/AAC），视频（MP4、QuickTime、WebM）。仅 **PNG、HEIC、HEIF** 会转换为 WebP，**WAV** 会转换为 AAC；其余格式原样存储。下载时返回存储后的文件（二进制）。

### 上传媒体

**接口：** `POST /api/media` — multipart/form-data。

| 字段         | 必填 | 说明 |
| ------------ | ---- | ---- |
| `file`       | 是   | 媒体文件（图片、音频或视频）。 |
| `client_id`  | 否   | 客户端生成的 ID，用于幂等上传；若该用户下该媒体已存在，则返回 201 及已有记录。 |

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

| 查询参数   | 说明 |
| ---------- | ---- |
| `since`    | 可选。Unix 时间戳；仅返回该时间之后创建的媒体。 |
| `limit`    | 可选。每页条数（默认 200，最大 1000）。 |
| `offset`   | 可选。跳过条数（默认 0）。 |

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

按 ID 返回用户拥有的媒体文件（二进制）。需在请求头中携带 `Authorization: Bearer <token>`。响应头包含 `Content-Type`、`Content-Length` 和 `ETag`（与 `checksum` 一致）。请求头中携带 `If-None-Match: <ETag>` 可在文件未变更时获得 `304 Not Modified`。**获取下一张卡片** 接口会在每个正面/背面词条对象的 `audio`、`image`、`video` 字段中给出完整 URL（如 `https://api.wordupx.com:8443/api/media/{id}`）；使用该 URL 并携带相同认证头即可加载文件。

### 删除媒体

**接口：** `DELETE /api/media/{id}`

**响应：**

```json
{
  "data": { "msg": "media deleted" }
}
```

### 列出或查询共享媒体（开发中）

**接口：** `GET /api/media/shared` — 列出共享发音资源；可选查询参数 `?word=...&lang=...` 进行查询。

### 下载共享媒体（开发中）

**接口：** `GET /api/media/shared/{id}` — 按 ID 下载共享媒体文件。

### 管理端共享媒体（开发中）

**接口：** `POST /api/admin/media/shared`（上传）、`DELETE /api/admin/media/shared/{id}`（删除）。仅管理端。

### 在词条中使用媒体（开发中）

每条 entry 为对象，含可选 `text`、`audio`、`image`、`video`。可选用 `template` 指定每词条的正/背面布局；省略则使用默认（正面第一条、背面其余）。

完整设计（上传、删除、展示、同步）见 **[媒体上传设计文档](../design-doc/media-upload.md)**。

---

## 响应示例速查

上述各节均包含完整 JSON 示例。接口与响应结构对应关系与 [Response examples reference](api.md#response-examples-reference)（英文版）一致，此处不重复列表。

---

## 后续步骤

- 重复步骤 5-6 继续复习卡片
- **标签系统** — 用标签管理卡组与词条（规划中）
- **离线同步** — 恢复联网后同步数据（规划中）
- **本地存储** — 缓存卡组与卡片供离线使用（规划中）
