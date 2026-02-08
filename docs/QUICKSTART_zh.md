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
| `/api/decks` | POST | 创建卡组 |
| `/api/decks` | GET | 获取所有卡组 |
| `/api/decks/{id}` | GET | 获取卡组详情 |
| `/api/decks/{id}/facts/{operation}` | POST | 添加词条 (operation: `append`) |
| `/api/decks/{id}/facts` | GET | 获取所有词条 |
| `/api/decks/{id}/next-due-card` | GET | 获取下一张待复习卡片 |
| `/api/decks/{id}/cards/{cardIndex}/{operation}` | PATCH | 更新卡片 (`update-interval`, `update-visibility`) |

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
    "deck_id": "ab66b3d7-1094-4d05-8ba2-1f90d92f2d05"
  },
  "meta": {
    "msg": "Deck created successfully"
  }
}
```

> 📝 保存 `deck_id` - 后续步骤需要用到。

---

## 3. 添加词条

**接口:** `POST /api/decks/{id}/facts/{operation}`

**参数:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05`（您的卡组 ID）
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

## 4. 获取下一张待复习卡片

**接口:** `GET /api/decks/{id}/next-due-card`

**参数:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05`（您的卡组 ID）

**响应:**

```json
{
  "data": {
    "card": {
      "fact_index": 0,
      "template_index": 0,
      "last_review": 1763269701,
      "due_date": 1763269702,
      "hidden": false,
      "min_calculation": 150,
      "max_calculation": 1200
    },
    "card_index": 0,
    "def_interval": 600,
    "due_cards": 1,
    "fact": ["Apple", "りんご"],
    "hidden_cards": 0,
    "max_interval": 1200,
    "min_interval": 150,
    "template": [0, 1],
    "total_cards": 20,
    "urgency": 2598
  },
  "meta": {
    "now": "1763272299"
  }
}
```

---

## 5. 复习卡片

查看卡片后，您需要根据记忆程度更新复习间隔。

**接口:** `PATCH /api/decks/{id}/cards/{cardIndex}/update-interval`

**参数:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05`（您的卡组 ID）
- `cardIndex`: `0`（来自第 4 步的 `card_index`）
- `operation`: `update-interval`

**请求体:**

```json
{
  "interval": 600
}
```

> 💡 **滑动条选择间隔：**
>
> 在应用中，用户通过滑动条选择复习间隔：
> - **左端** = `min_interval`（如 `150` 秒）→ 卡片较难，较快复习
> - **右端** = `max_interval`（如 `1200` 秒）→ 卡片较简单，稍后复习
> - **中间** = `def_interval`（如 `600` 秒）→ 卡片难度适中
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
> 系统会将**紧迫度最高**的未隐藏卡片作为下一张待复习卡片。
>
> **2. 间隔计算 — min/max/def 是如何确定的**
>
> 当前间隔为 `due_date - last_review`（最小 300 秒）。三个因子决定下次复习的范围：
>
> | 因子 | 值 | 含义 |
> |------|-----|------|
> | `minFactor` | 0.5 | 较难 — 间隔减半 |
> | `defFactor` | 2.0 | 适中 — 间隔翻倍 |
> | `maxFactor` | 4.0 | 简单 — 间隔翻四倍 |
>
> **当卡片已逾期**（`urgency >= 1`）：
>
> ```
> min_interval = 当前间隔 × 0.5
> def_interval = 当前间隔 × 2.0
> max_interval = 当前间隔 × 4.0
> ```
>
> **当卡片尚未到期**（`urgency < 1`），因子会按紧迫度等比缩小，提前复习时增长幅度较小：
>
> ```
> min_interval = 当前间隔 × ((0.5 - 1) × urgency + 1)
> def_interval = 当前间隔 × ((2.0 - 1) × urgency + 1)
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
> | 第 1 次复习 | 300 秒（5 分钟） | 600 秒（默认） | 300 秒 – 2400 秒 |
> | 第 2 次复习 | 600 秒（10 分钟） | 1200 秒（默认） | 600 秒 – 4800 秒 |
> | 第 3 次复习 | 1200 秒（20 分钟） | 2400 秒（默认） | 1200 秒 – 9600 秒 |
>
> 每次选择默认值，间隔就会**翻倍**。选择接近最大值会使增长更快（最多 4 倍），而选择接近最小值则会**缩短**间隔（最低 0.5 倍）。

**响应:**

```json
{
  "data": {
    "last_review": 1763272400,
    "due_date": 1763273000,
    "new_interval": 600,
    "hidden_status": false
  },
  "meta": {
    "msg": "Card updated successfully"
  }
}
```

---

## 6. 隐藏卡片（可选）

如果您想暂时从复习中隐藏某张卡片：

**接口:** `PATCH /api/decks/{id}/cards/{cardIndex}/update-visibility`

**参数:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05`
- `cardIndex`: `0`
- `operation`: `update-visibility`

**请求体:**

```json
{
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
    "msg": "Card updated successfully"
  }
}
```

---

## 后续步骤

- 重复步骤 6-7 继续复习卡片
- 创建更多不同字段配置的卡组
- 在 Swagger UI 中探索其他接口
