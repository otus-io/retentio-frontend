🌐 [English](QUICKSTART.md) | [中文](QUICKSTART_zh.md)

---

# 快速入门指南 - Swagger UI 教程

本指南将帮助您通过 Swagger UI 使用 WordUpX API。

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
  - **生产环境**: <https://api.wordupx.com/docs>

> **时间戳规范：** API 中所有时间戳均使用 **UTC** 时区。
> ISO 8601 字符串使用 `Z` 后缀（例如 `2026-02-08T12:00:00Z`）。
> Unix 时间戳为自 Unix 纪元（1970-01-01T00:00:00Z）以来的秒数。
> 客户端需自行进行本地时间的转换。

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
    "deck_id": "a1b2c3"
  },
  "meta": {
    "msg": "Deck created successfully"
  }
}
```

> 📝 保存 `deck_id` - 后续步骤需要用到。
> **为什么卡组没有 template？** 模板不存储在卡组上。添加词条时可传入可选参数 `template`（每个词条一个 `[[正面索引], [背面索引]]`）。服务端将该布局写入每张**卡片**的 `template`。**默认不生成兄弟卡（反向卡）**，每词条仅一张卡（正面第一条、背面其余）。省略 `template` 即使用该默认。

---

### 获取单个卡组

**接口:** `GET /api/decks/{id}`

**参数:**

- `id`: `a1b2c3`（您的卡组 ID）

**响应:**

```json
{
  "data": {
    "id": "a1b2c3",
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
        "id": "a1b2c3",
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
> 卡组卡片总数默认等于词条数：**每词条一张卡，默认不生成兄弟卡**。若需为某词条增加第二张卡（如反向卡），请调用 `POST /api/decks/{id}/card`，body 传 `{"fact_id": "<factId>", "template": [[1], [0]]}`。若该 template 已存在则返回 400。
>
> 客户端计算学习进度百分比：`reviewed_cards / cards_count * 100`。

### 更新卡组

**接口:** `PATCH /api/decks/{id}`

**参数:**

- `id`: `a1b2c3`（您的卡组 ID）

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
    "deck_id": "a1b2c3"
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

- `id`: `a1b2c3`（您的卡组 ID）

> 此操作会永久删除卡组及其所有关联的词条和卡片。

**响应:**

```json
{
  "data": {
    "deck_id": "a1b2c3"
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

- `id`: `a1b2c3`（您的卡组 ID）
- `operation`: `append`

**请求体：** 词条数组（每项含 `entries`）及可选的 `template`。服务端为每个词条生成唯一 ID，并为每个词条创建**一张卡片**（默认不生成反向/兄弟卡）。卡片的正/背面布局由 `template[i]` 指定（词条索引 `i`），省略或长度不足时使用默认 `[[0], [1, 2, ...]]`。

```json
{
  "facts": [
    { "entries": ["Apple", "りんご"] },
    { "entries": ["Book", "本"] },
    { "entries": ["Water", "水"] },
    { "entries": ["Hello", "こんにちは"] },
    { "entries": ["Thank you", "ありがとう"] },
    { "entries": ["Good morning", "おはよう"] },
    { "entries": ["Cat", "猫"] },
    { "entries": ["Dog", "犬"] },
    { "entries": ["House", "家"] },
    { "entries": ["Car", "車"] },
    { "entries": ["Friend", "友達"] },
    { "entries": ["School", "学校"] },
    { "entries": ["Teacher", "先生"] },
    { "entries": ["Student", "学生"] },
    { "entries": ["Food", "食べ物"] },
    { "entries": ["Time", "時間"] },
    { "entries": ["Love", "愛"] },
    { "entries": ["Peace", "平和"] },
    { "entries": ["Beautiful", "美しい"] },
    { "entries": ["Happy", "幸せ"] }
  ]
}
```

可选 **`template`**：布局数组，与词条一一对应。每项为 `[[正面索引], [背面索引]]`（如 `[[0], [1]]`）。省略或长度不足时，对应词条使用默认布局。例如两个词条、第二个为反向：

```json
"template": [ [[0], [1]], [[1], [0]] ]
```

> **理解请求体：**
>
> - **`entries`**：该词条的内容（与卡组列一一对应），如 `["Apple", "りんご"]`。
> - **`fields`**（可选）：该词条各列的显示名称；第 `i` 个条目对应 `fields[i]`。省略则使用卡组默认 `fields`。若提供，长度须与 `entries` 一致（如三列可为 `["Word", "Translation", "Example sentence"]`）。
> - **`template`**（可选）：按词条的布局。每词条一个 `[][]int`；省略或 `i >= len(template)` 时使用默认 `[[0], [1, 2, ...]]`。使用三维数组（每词条一个布局）是为了让不同词条可有不同正/背面布局，并为将来「一词条多张卡」（如主卡 + 反向 + 第三种变体）预留扩展；当前接口仍为每词条只创建一张卡。

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
      { "id": "x9k2m4np", "entries": ["Apple", "りんご"], "fields": ["English", "Japanese"] },
      { "id": "f2abc", "entries": ["Book", "本"] }
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
      "entries": ["Apple", "りんご"],
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
  "entries": ["Apple", "りんご"],
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
    "card_id": "newcard123"
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

- `id`: `a1b2c3`（您的卡组 ID）

**响应（无字段名 — 当卡组或词条未配置字段名时，段中 `field` 为空字符串）：**

```json
{
  "data": {
    "card": {
      "id": "card_nolabel",
      "fact_id": "f_nolabel",
      "template": [[0], [1]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [{"field": "", "type": "text", "value": "Apple"}],
      "back": [{"field": "", "type": "text", "value": "苹果"}]
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
      "front": [{"field": "Word", "type": "text", "value": "Apple"}],
      "back": [{"field": "Translation", "type": "text", "value": "苹果"}]
    },
    "urgency": 2.598
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

`front` 和 `back` 为段对象数组。每段包含 **`field`**（标签或空字符串）、**`type`**（`text`、`audio`、`image` 或 `video`）和 **`value`**（文本内容或媒体 id）。可直接据此渲染卡片，无需再请求 fact。

**仅正面卡片（背面为空，如 template `[[0], []]`）：**

```json
{
  "data": {
    "card": {
      "id": "c_front_only",
      "fact_id": "f1",
      "template": [[0], []],
      "last_review": 0,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [{"field": "Question", "type": "text", "value": "Only front text"}],
      "back": []
    },
    "urgency": 1.0
  },
  "meta": { "msg": "Next urgent card retrieved successfully" }
}
```

**含音频、图片与视频段的卡片（每种内容类型单独一段）：**

```json
{
  "data": {
    "card": {
      "id": "c_media",
      "fact_id": "f_media1",
      "template": [[0, 1], [2, 3]],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        {"field": "Front", "type": "text", "value": "Word"},
        {"field": "Pronunciation", "type": "audio", "value": "abc123"}
      ],
      "back": [
        {"field": "Picture", "type": "image", "value": "def456"},
        {"field": "Clip", "type": "video", "value": "vid789"},
        {"field": "Back", "type": "text", "value": "Translation"}
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

- `id`: `a1b2c3`（您的卡组 ID）

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

- `id`: `a1b2c3`

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

- `id`：卡组 ID（如 `a1b2c3`）
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
      { "id": "f_h1", "entries": ["Hidden word", "隠れた語"], "fields": ["English", "Japanese"] }
    ],
    "orphaned_hidden_cards": 0
  },
  "meta": { "msg": "Card stats retrieved successfully" }
}
```

---

## 5. 媒体（音频 / 图片）

可为词条附加音频、图片和视频。词条字段通过标记 `[audio:id]`、`[image:id]` 和 `[video:id]` 按 ID 引用媒体。

### 上传媒体

**接口：** `POST /api/media` — multipart/form-data，字段 `file`。

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

**接口：** `GET /api/media` — 返回当前用户的媒体（同步清单）。

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

按 ID 返回用户拥有的媒体文件（二进制）。

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

在 `entries` 中加入标记，例如 `["Word", "[audio:abc123]", "[image:def456]", "[video:vid789]", "Translation"]`。可选用 `template` 指定每词条的正/背面布局；省略则使用默认（正面第一条、背面其余）。仅以纯文本展示词条时（如列表中），界面显示为 `audio:id`、`image:id`、`video:id`（无方括号）。存储与 API 使用 `[type:id]`。

完整设计（上传、删除、展示、同步）见 **[媒体上传设计文档](../design-doc/media-upload.md)**。

---

## 响应示例速查

上述各节均包含完整 JSON 示例。接口与响应结构对应关系与 [Response examples reference](QUICKSTART.md#response-examples-reference)（英文版）一致，此处不重复列表。

---

## 后续步骤

- 重复步骤 5-6 继续复习卡片
- **标签系统** — 用标签管理卡组与词条（规划中）
- **离线同步** — 恢复联网后同步数据（规划中）
- **本地存储** — 缓存卡组与卡片供离线使用（规划中）
