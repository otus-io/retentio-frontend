🌐 [English](QUICKSTART.md) | [中文](QUICKSTART_zh.md)

---

# Quick Start Guide - Swagger UI Tutorial

This guide walks you through using the WordUpX API via Swagger UI.

## Prerequisites

- Open Swagger UI at:
  - **Local**: http://localhost:8080/docs
  - **Production**: https://api.wordupx.com/docs

---

## API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/register` | POST | Register user |
| `/auth/login` | POST | Login |
| `/api/decks` | POST | Create deck |
| `/api/decks` | GET | List all decks |
| `/api/decks/{id}` | GET | Get deck details |
| `/api/decks/{id}/facts/{operation}` | POST | Add facts (operation: `append`) |
| `/api/decks/{id}/facts` | GET | Get all facts |
| `/api/decks/{id}/next-due-card` | GET | Get next due card |
| `/api/decks/{id}/cards/{cardIndex}/{operation}` | PATCH | Update card (`update-interval`, `update-visibility`) |

---

## 1. Authentication

### Create a User

**Endpoint:** `POST /auth/register`

```json
{
  "email": "swagger@example.com",
  "password": "123456",
  "username": "swagger"
}
```

### Login

**Endpoint:** `POST /auth/login`

```json
{
  "password": "123456",
  "username": "swagger"
}
```

**Response:**

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

### Authorize

1. Click the **"Authorize"** button (top right corner of Swagger UI)
2. Paste the token from the login response
3. Click **"Authorize"** to save

Now all subsequent requests will include your authentication token.

---

## 2. Create a Deck

**Endpoint:** `POST /api/decks`

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

**Response:**

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

> 📝 Save the `deck_id` - you'll need it for the next steps.

---

## 3. Add Facts

**Endpoint:** `POST /api/decks/{id}/facts/{operation}`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)
- `operation`: `append`

**Request Body:**

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

**Response:**

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

## 4. Get Next Due Card

**Endpoint:** `GET /api/decks/{id}/next-due-card`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)

**Response:**

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

## 5. Review a Card

After viewing a card, you need to update its interval based on how well you remembered it.

**Endpoint:** `PATCH /api/decks/{id}/cards/{cardIndex}/update-interval`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)
- `cardIndex`: `0` (from the `card_index` in step 4)
- `operation`: `update-interval`

**Request Body:**

```json
{
  "interval": 600
}
```

> 💡 **How the interval slider works:**
>
> In the app, users select an interval using a slider:
> - **Left end** = `min_interval` (e.g., `150` seconds) → Card was difficult, review sooner
> - **Right end** = `max_interval` (e.g., `1200` seconds) → Card was easy, review later
> - **Middle** = `def_interval` (e.g., `600` seconds) → Card was okay
>
> The interval value is in seconds.

**Response:**

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

## 6. Hide a Card (Optional)

If you want to temporarily hide a card from reviews:

**Endpoint:** `PATCH /api/decks/{id}/cards/{cardIndex}/update-visibility`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05`
- `cardIndex`: `0`
- `operation`: `update-visibility`

**Request Body:**

```json
{
  "hidden": true
}
```

**Response:**

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

## Next Steps

- Keep reviewing cards by repeating steps 6-7
- Create more decks with different field configurations
- Explore other endpoints in Swagger UI
