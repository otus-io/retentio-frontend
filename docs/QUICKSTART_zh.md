🌐 [English](QUICKSTART.md) | [中文](QUICKSTART_zh.md)

---

# 快速入门指南 - Swagger UI 教程

本指南将帮助您通过 Swagger UI 使用 WordUpX API。

## 前提条件

- 后端服务器运行在 `http://localhost:8080`
- 打开 Swagger UI：http://localhost:8080/docs

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

## 总结

| 步骤 | 接口 | 说明 |
|------|------|------|
| 1 | `POST /auth/register` | 创建账号 |
| 2 | `POST /auth/login` | 获取令牌 |
| 3 | Authorize 按钮 | 在 Swagger 中设置令牌 |
| 4 | `POST /api/decks` | 创建卡组 |
| 5 | `POST /api/decks/{id}/facts/append` | 添加词条到卡组 |
| 6 | `GET /api/decks/{id}/next-due-card` | 获取下一张待复习卡片 |
| 7 | `PATCH /api/decks/{id}/cards/{cardIndex}/update-interval` | 复习卡片 |
| 8 | `PATCH /api/decks/{id}/cards/{cardIndex}/update-visibility` | 隐藏/显示卡片 |

---

## 后续步骤

- 重复步骤 6-7 继续复习卡片
- 创建更多不同字段配置的卡组
- 在 Swagger UI 中探索其他接口
