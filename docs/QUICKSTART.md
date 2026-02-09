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
| `/api/decks/{id}` | PATCH | Update deck |
| `/api/decks/{id}` | DELETE | Delete deck |
| `/api/decks/{id}/facts/{operation}` | POST | Add facts (operation: `append`, `prepend`, `shuffle`, `spread`) |
| `/api/decks/{id}/facts` | GET | Get all facts |
| `/api/decks/{id}/facts/{factIndex}` | GET | Get a specific fact |
| `/api/decks/{id}/facts/{factIndex}` | PATCH | Update a fact |
| `/api/decks/{id}/facts/{factIndex}` | DELETE | Delete a fact |
| `/api/decks/{id}/next-due-card` | GET | Get next due card |
| `/api/decks/{id}/cards/{operation}` | GET | Get cards (`all-cards`, `hidden-cards`) |
| `/api/decks/{id}/cards/{cardIndex}/{operation}` | PATCH | Update card (`update-interval`, `update-visibility`) |
| `/api/decks/{id}/hidden-cards` | GET | Get hidden cards with details |

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

> **Understanding `templates`:**
>
> Templates define how facts are turned into cards. Each template is an array of field indices that determines which fields appear on the front and back of a card.
>
> - `fields` defines the available columns: index `0` = "English", index `1` = "Japanese"
> - `[0, 1]` means: show **English** (front) → **Japanese** (back)
>
> You can add multiple templates to create cards in both directions:
>
> ```json
> "templates": [
>   [0, 1],
>   [1, 0]
> ]
> ```
>
> - `[0, 1]` → English → Japanese (reading the English word, recall the Japanese)
> - `[1, 0]` → Japanese → English (reading the Japanese word, recall the English)
>
> With 2 templates, each fact generates **2 cards** — one for each direction.

> **Understanding `rate`:**
>
> Rate controls how many **new cards are introduced per day**. The system spaces out new cards evenly throughout the day:
>
> - `gap = 86400 seconds (1 day) / rate`
> - Example: `rate: 20` → new card every **72 minutes** (86400 / 20 = 4320 seconds)
> - Example: `rate: 10` → new card every **144 minutes** (86400 / 10 = 8640 seconds)
>
> A higher rate means more new cards per day; a lower rate provides a gentler learning pace.

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

## 3. View Deck Details

You can view a single deck or list all your decks. Both responses include a `stats` object with card statistics.

### Get a Single Deck

**Endpoint:** `GET /api/decks/{id}`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)

**Response:**

```json
{
  "data": {
    "id": "ab66b3d7-1094-4d05-8ba2-1f90d92f2d05",
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

### List All Decks

**Endpoint:** `GET /api/decks`

**Response:**

```json
{
  "data": {
    "decks": [
      {
        "id": "ab66b3d7-1094-4d05-8ba2-1f90d92f2d05",
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

> **Understanding `meta` in GetDecks:**
>
> | Field | Description |
> |-------|-------------|
> | `total` | Total number of decks owned by the current user |
> | `msg` | Status message |

> **Understanding `stats`:**
>
> | Field | Description |
> |-------|-------------|
> | `cards_count` | Total number of cards in the deck |
> | `facts_count` | Total number of facts in the deck |
> | `unseen_cards` | New cards that have never been reviewed |
> | `reviewed_cards` | Cards that have been studied at least once |
> | `due_cards` | Cards currently due for review (due_date <= now) |
> | `hidden_cards` | Cards hidden from review by the user |
> | `new_cards_today` | Cards that were added today (since midnight) |
>
> Stats are computed on-the-fly. For a freshly created empty deck, all values are `0`. After adding facts, `cards_count` and `unseen_cards` will increase. As you review cards, `reviewed_cards` grows and `unseen_cards` decreases.
>
> The total cards in a deck depends on the number of facts and templates: `cards_count = facts_count × number_of_templates`. For example, 20 facts with 2 templates (`[0,1]` and `[1,0]`) produces 40 cards.
>
> To calculate a progress percentage on the client side: `reviewed_cards / cards_count * 100`.

### Update a Deck

**Endpoint:** `PATCH /api/decks/{id}`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)

**Request Body:**

```json
{
  "name": "Updated Deck Name",
  "fields": ["English", "Japanese"],
  "templates": [[0, 1], [1, 0]],
  "rate": 30
}
```

> All fields are optional except `name`. If `fields` is provided, the count must match the existing number of fields. `rate` must be between 1 and 1000.

**Response:**

```json
{
  "data": {
    "deck_id": "ab66b3d7-1094-4d05-8ba2-1f90d92f2d05"
  },
  "meta": {
    "msg": "Deck updated successfully",
    "updated_at": "2026-02-08T13:00:00Z"
  }
}
```

### Delete a Deck

**Endpoint:** `DELETE /api/decks/{id}`

**Parameters:**
- `id`: `ab66b3d7-1094-4d05-8ba2-1f90d92f2d05` (your deck ID)

> This permanently deletes the deck and all its associated facts, cards, and templates.

**Response:**

```json
{
  "data": {
    "deck_id": "ab66b3d7-1094-4d05-8ba2-1f90d92f2d05"
  },
  "meta": {
    "msg": "Deck deleted successfully"
  }
}
```

---

## 4. Add Facts

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

## 5. Get Next Due Card

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
      "max_calculation": 1200,
      "created_at": 1763269700
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

## 6. Review a Card

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
> The submitted interval **must** be within the range `[min_interval, max_interval]`, or the API will reject it.

> 📖 **How the spaced repetition algorithm works:**
>
> The system uses an **urgency-based spaced repetition** algorithm. Here's the full flow:
>
> **1. Urgency — which card to show next**
>
> Every card has `last_review` and `due_date` timestamps. Urgency is calculated as:
>
> ```
> urgency = (now - last_review) / (due_date - last_review)
> ```
>
> - `urgency >= 1.0` → the card is **overdue** (past its due date)
> - `urgency < 1.0` → the card is **not yet due** but may still be shown
>
> The card with the **highest urgency** (that isn't hidden) is served as the next due card.
>
> **2. Interval calculation — how min/max/def are determined**
>
> The current interval is `due_date - last_review` (minimum 300 seconds). Three factors determine the next review range:
>
> | Factor | Value | Meaning |
> |--------|-------|---------|
> | `minFactor` | 0.5 | Hard — halve the interval |
> | `defFactor` | 2.0 | Okay — double the interval |
> | `maxFactor` | 4.0 | Easy — quadruple the interval |
>
> **When the card is overdue** (`urgency >= 1`):
>
> ```
> min_interval = current_interval × 0.5
> def_interval = current_interval × 2.0
> max_interval = current_interval × 4.0
> ```
>
> **When the card is not yet due** (`urgency < 1`), the factors are scaled down proportionally by urgency so that reviewing early yields a smaller growth:
>
> ```
> min_interval = current_interval × ((0.5 - 1) × urgency + 1)
> def_interval = current_interval × ((2.0 - 1) × urgency + 1)
> max_interval = current_interval × ((4.0 - 1) × urgency + 1)
> ```
>
> **3. Update — what happens when you submit an interval**
>
> When you send `{ "interval": 600 }`:
>
> ```
> last_review = now
> due_date    = now + interval
> ```
>
> The next time this card appears, the new interval range will be based on this updated interval. This means intervals **grow over time** — the better you know a card, the longer until you see it again.
>
> **4. Example walkthrough**
>
> | Step | Current interval | You choose | Next interval range |
> |------|-----------------|------------|---------------------|
> | 1st review | 300s (5 min) | 600s (default) | 300s – 2400s |
> | 2nd review | 600s (10 min) | 1200s (default) | 600s – 4800s |
> | 3rd review | 1200s (20 min) | 2400s (default) | 1200s – 9600s |
>
> Each time you pick the default, the interval **doubles**. Picking closer to the max makes it grow even faster (up to 4×), while picking closer to the min **shrinks** it (down to 0.5×).

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

## 7. Hide a Card (Optional)

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

- Keep reviewing cards by repeating steps 5-6
- Create more decks with different field configurations
- Explore other endpoints in Swagger UI
