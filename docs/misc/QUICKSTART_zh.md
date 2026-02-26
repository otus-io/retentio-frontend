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
- [2. 创建卡组](#2-创建卡组)
- [3. 查看卡组详情](#3-查看卡组详情)
  - [获取单个卡组](#获取单个卡组)
  - [获取所有卡组](#获取所有卡组)
  - [更新卡组](#更新卡组)
  - [删除卡组](#删除卡组)
- [4. 添加词条](#4-添加词条)
- [5. 获取下一张最紧急卡片](#5-获取下一张最紧急卡片)
- [6. 复习卡片](#6-复习卡片)
- [7. 隐藏卡片（可选）](#7-隐藏卡片可选)
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
| `/api/decks` | POST | 创建卡组 |
| `/api/decks` | GET | 获取所有卡组 |
| `/api/decks/{id}` | GET | 获取卡组详情 |
| `/api/decks/{id}` | PATCH | 更新卡组 |
| `/api/decks/{id}` | DELETE | 删除卡组 |
| `/api/decks/{id}/facts/{operation}` | POST | 添加词条 (operation: `append`, `prepend`, `shuffle`, `spread`) |
| `/api/decks/{id}/facts` | GET | 获取所有词条 |
| `/api/decks/{id}/facts/{factId}` | GET | 获取单个词条 |
| `/api/decks/{id}/facts/{factId}` | PATCH | 更新词条 |
| `/api/decks/{id}/facts/{factId}` | DELETE | 删除词条 |
| `/api/decks/{id}/card` | GET | 获取最紧急卡片 |
| `/api/decks/{id}/card` | PATCH | 更新卡片间隔或可见性（按 card_id 查找） |
| `/api/decks/{id}/cards` | GET | 获取卡片统计（总数、隐藏数量、隐藏事实） |

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

## 2. 创建卡组

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

---

## 3. 查看卡组详情

您可以查看单个卡组或列出所有卡组。两个接口的响应都包含一个 `stats` 对象，提供卡片统计信息。

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
> 卡片总数取决于词条数以及每个词条的 **scheme**：scheme 的个位为 0 表示一张卡，为 1 表示两张卡（主卡 + 反向卡）。例如 20 个词条均使用 scheme `10` → 20 张卡；10 个词条用 `11`、10 个用 `10` → 30 张卡。
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

---

## 4. 添加词条

**接口:** `POST /api/decks/{id}/facts/{operation}`

**参数:**

- `id`: `a1b2c3`（您的卡组 ID）
- `operation`: `append`

**请求体:**

```json
{
  "facts": [
    { "entries": ["Apple", "りんご"], "scheme": 10 },
    { "entries": ["Book", "本"], "scheme": 10 },
    { "entries": ["Water", "水"], "scheme": 10 },
    { "entries": ["Hello", "こんにちは"], "scheme": 10 },
    { "entries": ["Thank you", "ありがとう"], "scheme": 10 },
    { "entries": ["Good morning", "おはよう"], "scheme": 10 },
    { "entries": ["Cat", "猫"], "scheme": 10 },
    { "entries": ["Dog", "犬"], "scheme": 10 },
    { "entries": ["House", "家"], "scheme": 10 },
    { "entries": ["Car", "車"], "scheme": 10 },
    { "entries": ["Friend", "友達"], "scheme": 10 },
    { "entries": ["School", "学校"], "scheme": 10 },
    { "entries": ["Teacher", "先生"], "scheme": 10 },
    { "entries": ["Student", "学生"], "scheme": 10 },
    { "entries": ["Food", "食べ物"], "scheme": 10 },
    { "entries": ["Time", "時間"], "scheme": 10 },
    { "entries": ["Love", "愛"], "scheme": 10 },
    { "entries": ["Peace", "平和"], "scheme": 10 },
    { "entries": ["Beautiful", "美しい"], "scheme": 10 },
    { "entries": ["Happy", "幸せ"], "scheme": 10 }
  ]
}
```

> **理解词条级别的 `entries` 和 `scheme`：**
>
> - **`entries`**：该词条的内容（与卡组列一一对应），如英语/日语为 `["Apple", "りんご"]`。
> - **`scheme`**：两位数字表示布局。**十位** = 正面显示的条目数（1–9），**个位** = 是否生成反向卡（0 = 一张卡，1 = 两张卡：主卡 + 反向）。例如：`10` = 正面 1 条、无反向卡；`11` = 正面 1 条、有反向卡；`20` = 正面 2 条、无反向卡。须满足 `0 < split <= len(entries)`。

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

---

## 5. 获取下一张最紧急卡片

**接口:** `GET /api/decks/{id}/card`

**参数:**

- `id`: `a1b2c3`（您的卡组 ID）

**响应:**

```json
{
  "data": {
    "card": {
      "id": "xyz12345",
      "fact_id": "x9k2m4np",
      "is_sibling": false,
      "last_review": 1763269701,
      "due_date": 1763269702,
      "hidden": false,
      "created_at": 1763269700
    },
    "urgency": 2598
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

> 请保存 `card.id` — 更新卡片时（步骤 6）需要用到。

---

## 6. 复习卡片

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

## 7. 隐藏卡片（可选）

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

## 后续步骤

- 重复步骤 5-6 继续复习卡片
- 创建更多不同字段配置的卡组
- 在 Swagger UI 中探索其他接口
