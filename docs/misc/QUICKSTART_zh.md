🌐 [English](QUICKSTART.md) | [中文](QUICKSTART_zh.md)

---

# 快速入门指南 - Swagger UI 教程

本指南将帮助您通过 Swagger UI 使用 WordUpX API。

## 前提条件

- 打开 Swagger UI：
  - **本地**: http://localhost:8080/docs
  - **生产环境**: https://api.wordupx.com/docs

---

## API 接口参考

| 接口 | 方法 | 说明 |
|------|------|------|
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
| `/api/decks/{id}/urgent-card` | GET | 获取最紧急卡片 |
| `/api/decks/{id}/urgent-card` | PATCH | 更新卡片间隔或可见性（按 fact_id 查找） |
| `/api/decks/{id}/cards/{operation}` | GET | 获取卡片 (`all-cards`, `hidden-cards`) |
| `/api/decks/{id}/hidden-cards` | GET | 获取已隐藏卡片详情 |

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
    "expires": "2026-02-14T14:05:20.826883808+09:00"
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
  "rate": 20,
  "templates": [
    [0, 1]
  ]
}
```

> **理解 `templates`（模板）：**
>
> 模板定义了如何将词条转化为卡片。每个模板是一个字段索引数组，决定了卡片正面和背面显示哪些字段。
>
> - `fields` 定义了可用的列：索引 `0` = "English"，索引 `1` = "Japanese"
> - `[0, 1]` 表示：正面显示 **English** → 背面显示 **Japanese**
>
> 您可以添加多个模板来创建双向卡片：
>
> ```json
> "templates": [
>   [0, 1],
>   [1, 0]
> ]
> ```
>
> - `[0, 1]` → 英语 → 日语（看英文，回忆日语）
> - `[1, 0]` → 日语 → 英语（看日语，回忆英文）
>
> 使用 2 个模板时，每个词条会生成 **2 张卡片** — 每个方向各一张。

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
    "templates": [[0, 1]],
    "facts": [],
    "rate": 20,
    "stats": {
      "cards_count": 0,
      "facts_count": 0,
      "unseen_cards": 0,
      "reviewed_cards": 0,
      "due_cards": 0,
      "hidden_cards": 0,
      "new_cards_today": 0
    }
  },
  "meta": {
    "created_at": "2026-02-08T12:00:00Z",
    "updated_at": "2026-02-08T12:00:00Z"
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
        "templates": [[0, 1]],
        "rate": 20,
        "stats": {
          "cards_count": 0,
          "facts_count": 0,
          "unseen_cards": 0,
          "reviewed_cards": 0,
          "due_cards": 0,
          "hidden_cards": 0,
          "new_cards_today": 0
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
> |------|------|
> | `total`（总数） | 当前用户拥有的卡组总数 |
> | `msg`（消息） | 状态信息 |

> **理解 `stats`（统计信息）：**
>
> | 字段 | 说明 |
> |------|------|
> | `cards_count`（卡片总数） | 卡组中的卡片总数 |
> | `facts_count`（词条总数） | 卡组中的词条总数 |
> | `unseen_cards`（未学习卡片） | 从未复习过的新卡片数量 |
> | `reviewed_cards`（已学习卡片） | 已学习过至少一次的卡片数量 |
> | `due_cards`（待复习卡片） | 当前待复习的卡片数量（due_date <= 当前时间） |
> | `hidden_cards`（已隐藏卡片） | 被用户隐藏的卡片数量 |
> | `new_cards_today`（今日新增卡片） | 今天添加的卡片数量（从午夜开始计算） |
>
> 统计信息是实时计算的。对于刚创建的空卡组，所有值都为 `0`。添加词条后，`cards_count` 和 `unseen_cards` 会增加。随着复习的进行，`reviewed_cards` 会增长，`unseen_cards` 会减少。
>
> 卡片总数取决于词条数和模板数：`cards_count = facts_count × 模板数量`。例如，20 个词条搭配 2 个模板（`[0,1]` 和 `[1,0]`）会生成 40 张卡片。
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
  "templates": [[0, 1], [1, 0]],
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

> 此操作会永久删除卡组及其所有关联的词条、卡片和模板。

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
    ["Apple", "りんご"],
    ["Book", "本"],
    ["Water", "水"],
    ["Hello", "こんにちは"],
    ["Thank you", "ありがとう"],
    ["Good morning", "おはよう"],
    ["Cat", "猫"],
    ["Dog", "犬"],
    ["House", "家"],
    ["Car", "車"],
    ["Friend", "友達"],
    ["School", "学校"],
    ["Teacher", "先生"],
    ["Student", "学生"],
    ["Food", "食べ物"],
    ["Time", "時間"],
    ["Love", "愛"],
    ["Peace", "平和"],
    ["Beautiful", "美しい"],
    ["Happy", "幸せ"]
  ]
}
```

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

**接口:** `GET /api/decks/{id}/urgent-card`

**参数:**
- `id`: `a1b2c3`（您的卡组 ID）

**响应:**

```json
{
  "data": {
    "card": {
      "fact_id": "x9k2m4np",
      "template_index": 0,
      "last_review": 1763269701,
      "due_date": 1763269702,
      "hidden": false,
      "min_interval": 150,
      "max_interval": 1200,
      "created_at": 1763269700
    },
    "card_index": 0,
    "urgency": 2598
  },
  "meta": {
    "msg": "Next urgent card retrieved successfully"
  }
}
```

---

## 6. 复习卡片

查看卡片后，您需要根据记忆程度更新复习间隔。

**接口:** `PATCH /api/decks/{id}/urgent-card`

**参数:**
- `id`: `a1b2c3`（您的卡组 ID）

**请求体:**

```json
{
  "fact_id": "x9k2m4np",
  "interval": 600
}
```

> 💡 **滑动条选择间隔：**
>
> 在应用中，用户通过滑动条选择复习间隔：
> - **左端** = `min_interval`（如 `150` 秒）→ 卡片较难，较快复习
> - **右端** = `max_interval`（如 `1200` 秒）→ 卡片较简单，稍后复习
>
> 间隔值的单位是秒。
> 提交的间隔**必须**在 `[min_interval, max_interval]` 范围内，否则 API 会拒绝请求。

> 📖 **间隔复习算法详解：**
>
> 系统使用**基于紧迫度的间隔复习**算法。完整流程如下：
>
> **1. 紧迫度（Urgency）— 决定下一张显示哪张卡片**
>
> 每张卡片都有 `last_review`（上次复习时间）和 `due_date`（到期时间）。紧迫度的计算方式：
>
> ```
> urgency = (now - last_review) / (due_date - last_review)
> ```
>
> - `urgency >= 1.0` → 卡片已**逾期**（已过到期时间）
> - `urgency < 1.0` → 卡片**尚未到期**，但仍可能被显示
>
> 系统会将**紧迫度最高**的未隐藏卡片作为下一张最紧急卡片。
>
> **2. 间隔计算 — min/max 是如何确定的**
>
> 当前间隔为 `due_date - last_review`（最小 60 秒）。两个因子决定下次复习的范围：
>
> | 因子 | 值 | 含义 |
> |------|-----|------|
> | `minFactor` | 0.5 | 较难 — 间隔减半 |
> | `maxFactor` | 4.0 | 简单 — 间隔翻四倍 |
>
> **当卡片已逾期**（`urgency >= 1`）：
>
> ```
> min_interval = 当前间隔 × 0.5
> max_interval = 当前间隔 × 4.0
> ```
>
> **当卡片尚未到期**（`urgency < 1`），因子会按紧迫度等比缩小，提前复习时增长幅度较小：
>
> ```
> min_interval = 当前间隔 × ((0.5 - 1) × urgency + 1)
> max_interval = 当前间隔 × ((4.0 - 1) × urgency + 1)
> ```
>
> **3. 更新 — 提交间隔后会发生什么**
>
> 当您发送 `{ "interval": 600 }` 时：
>
> ```
> last_review = now（当前时间）
> due_date    = now + interval
> ```
>
> 下次该卡片出现时，新的间隔范围将基于更新后的间隔计算。这意味着间隔会**随时间增长** — 您对一张卡片越熟悉，再次看到它的时间间隔就越长。
>
> **4. 示例演示**
>
> | 步骤 | 当前间隔 | 您的选择 | 下次间隔范围 |
> |------|---------|---------|-------------|
> | 第 1 次复习 | 60 秒（1 分钟） | 120 秒（中间值） | 60 秒 – 480 秒 |
> | 第 2 次复习 | 120 秒（2 分钟） | 240 秒（中间值） | 120 秒 – 960 秒 |
> | 第 3 次复习 | 240 秒（4 分钟） | 480 秒（中间值） | 240 秒 – 1920 秒 |
>
> 选择接近最大值会使增长更快（最多 4 倍），而选择接近最小值则会**缩短**间隔（最低 0.5 倍）。

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

**接口:** `PATCH /api/decks/{id}/urgent-card`

**参数:**
- `id`: `a1b2c3`

**请求体:**

```json
{
  "fact_id": "x9k2m4np",
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
