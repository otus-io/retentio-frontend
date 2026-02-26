🌐 [English](QUICKSTART.md) | [中文](QUICKSTART_zh.md)

---

# Quick Start Guide - Swagger UI Tutorial

This guide walks you through using the WordUpX API via Swagger UI.

## Table of Contents

- [Prerequisites](#prerequisites)
- [API Reference](#api-reference)
- [1. Authentication](#1-authentication)
  - [Create a User](#create-a-user)
  - [Login](#login)
  - [Authorize](#authorize)
  - [Logout](#logout)
  - [Forgot Password](#forgot-password)
  - [Reset Password](#reset-password)
- [2. Create a Deck](#2-create-a-deck)
- [3. View Deck Details](#3-view-deck-details)
  - [Get a Single Deck](#get-a-single-deck)
  - [List All Decks](#list-all-decks)
  - [Update a Deck](#update-a-deck)
  - [Delete a Deck](#delete-a-deck)
- [4. Add Facts](#4-add-facts)
- [5. Get Next Urgent Card](#5-get-next-urgent-card)
- [6. Review a Card](#6-review-a-card)
- [7. Hide a Card (Optional)](#7-hide-a-card-optional)
- [Next Steps](#next-steps)

---

## Prerequisites

- Open Swagger UI at:
  - **Local**: <http://localhost:8080/docs>
  - **Production**: <https://api.wordupx.com/docs>

> **Timestamp convention:** All timestamps in the API use **UTC**.
> ISO 8601 strings use the `Z` suffix (e.g., `2026-02-08T12:00:00Z`).
> Unix timestamps are seconds since the Unix epoch
> (1970-01-01T00:00:00Z). Clients must convert to/from local time
> on their side.

---

## API Reference

| Endpoint | Method | Description |
| ---------- | -------- | ------------- |
| `/auth/register` | POST | Register user |
| `/auth/login` | POST | Login |
| `/auth/logout` | POST | Logout (invalidate token) |
| `/auth/forgot-password` | POST | Request password reset token |
| `/auth/reset-password` | POST | Reset password with token |
| `/api/decks` | POST | Create deck |
| `/api/decks` | GET | List all decks |
| `/api/decks/{id}` | GET | Get deck details |
| `/api/decks/{id}` | PATCH | Update deck |
| `/api/decks/{id}` | DELETE | Delete deck |
| `/api/decks/{id}/facts/{operation}` | POST | Add facts (operation: `append`, `prepend`, `shuffle`, `spread`) |
| `/api/decks/{id}/facts` | GET | Get all facts |
| `/api/decks/{id}/facts/{factId}` | GET | Get a specific fact |
| `/api/decks/{id}/facts/{factId}` | PATCH | Update a fact |
| `/api/decks/{id}/facts/{factId}` | DELETE | Delete a fact |
| `/api/decks/{id}/card` | GET | Get most urgent card |
| `/api/decks/{id}/card` | PATCH | Update card interval or visibility (by card_id) |
| `/api/decks/{id}/cards` | GET | Get card stats (total, hidden count, hidden facts) |

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
    "expires": "2026-02-14T05:05:20Z"
  }
}
```

### Authorize

1. Click the **"Authorize"** button (top right corner of Swagger UI)
2. Paste the token from the login response
3. Click **"Authorize"** to save

Now all subsequent requests will include your authentication token.

### Logout

**Endpoint:** `POST /auth/logout`

Requires the `Authorization: Bearer <token>` header. Invalidates the token so it can no longer be used.

**Response:**

```json
{
  "data": {
    "msg": "Logged out successfully"
  },
  "meta": null
}
```

### Forgot Password

**Endpoint:** `POST /auth/forgot-password`

```json
{
  "email": "swagger@example.com"
}
```

**Response:**

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

> The reset token expires after 15 minutes. In production, this token would be sent via email instead of in the response.

### Reset Password

**Endpoint:** `POST /auth/reset-password`

```json
{
  "token": "a3f8b2c1d4e5f6...",
  "new_password": "mynewpassword"
}
```

**Response:**

```json
{
  "data": {
    "msg": "Password reset successfully"
  },
  "meta": null
}
```

> After resetting, log in with your new password. The reset token is single-use and cannot be reused.

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
  "rate": 20
}
```

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
    "deck_id": "a1b2c3"
  },
  "meta": {
    "msg": "Deck created successfully"
  }
}
```

> 📝 Save the `deck_id` - you'll need it for the next steps.
> **Why no template on deck?** Decks no longer have a `template` (or `templates`) field. Layout and whether a fact gets a reverse card are controlled **per fact** via the fact's `scheme` when you add facts (see [Add Facts](#4-add-facts)). This lets you choose which facts are siblinged and how each fact's front/back split is defined, without one global setting for the whole deck.

---

## 3. View Deck Details

You can view a single deck or list all your decks. Both responses include a `stats` object with card statistics.

### Get a Single Deck

**Endpoint:** `GET /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)

**Response:**

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

### List All Decks

**Endpoint:** `GET /api/decks`

**Response:**

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

> **Understanding `meta` in GetDecks:**
>
> | Field | Description |
> | ------- | ------------- |
> | `total` | Total number of decks owned by the current user |
> | `msg` | Status message |

<!-- -->

> **Understanding `stats`:**
>
> | Field | Description |
> | ------- | ------------- |
> | `cards_count` | Total number of cards in the deck |
> | `facts_count` | Total number of facts in the deck |
> | `unseen_cards` | New cards that have never been reviewed |
> | `reviewed_cards` | Cards that have been studied at least once |
> | `due_cards` | Cards currently due for review (due_date <= now) |
> | `hidden_cards` | Cards hidden from review by the user |
> | `new_cards_today` | Cards that were added today (since midnight) |
> | `last_reviewed_at` | Unix timestamp of the most recent review (`0` if never reviewed) |
>
> Stats are computed on-the-fly. For a freshly created empty deck,
> all values are `0`. After adding facts, `cards_count` and
> `unseen_cards` will increase. As you review cards,
> `reviewed_cards` grows and `unseen_cards` decreases.
>
> The total cards in a deck depends on the number of facts and each
> fact's **scheme** `[split, sibling]`: second element 0 = one card, 1 = two cards (primary + sibling). So 20 facts with scheme `[1, 0]` each → 20 cards; 10 facts with `[1, 1]` and 10 with `[1, 0]` → 30 cards.
>
> To calculate a progress percentage on the client side: `reviewed_cards / cards_count * 100`.

### Update a Deck

**Endpoint:** `PATCH /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)

**Request Body:**

```json
{
  "name": "Updated Deck Name",
  "fields": ["English", "Japanese"],
  "rate": 30
}
```

> All fields are optional except `name`. If `fields` is provided,
> the count must match the existing number of fields.
> `rate` must be between 1 and 1000.

**Response:**

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

### Delete a Deck

**Endpoint:** `DELETE /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)

> This permanently deletes the deck and all its associated facts and cards.

**Response:**

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

## 4. Add Facts

**Endpoint:** `POST /api/decks/{id}/facts/{operation}`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)
- `operation`: `append`

**Request Body:**

```json
{
  "facts": [
    { "entries": ["Apple", "りんご"], "scheme": [1, 0] },
    { "entries": ["Book", "本"], "scheme": [1, 0] },
    { "entries": ["Water", "水"], "scheme": [1, 0] },
    { "entries": ["Hello", "こんにちは"], "scheme": [1, 0] },
    { "entries": ["Thank you", "ありがとう"], "scheme": [1, 0] },
    { "entries": ["Good morning", "おはよう"], "scheme": [1, 0] },
    { "entries": ["Cat", "猫"], "scheme": [1, 0] },
    { "entries": ["Dog", "犬"], "scheme": [1, 0] },
    { "entries": ["House", "家"], "scheme": [1, 0] },
    { "entries": ["Car", "車"], "scheme": [1, 0] },
    { "entries": ["Friend", "友達"], "scheme": [1, 0] },
    { "entries": ["School", "学校"], "scheme": [1, 0] },
    { "entries": ["Teacher", "先生"], "scheme": [1, 0] },
    { "entries": ["Student", "学生"], "scheme": [1, 0] },
    { "entries": ["Food", "食べ物"], "scheme": [1, 0] },
    { "entries": ["Time", "時間"], "scheme": [1, 0] },
    { "entries": ["Love", "愛"], "scheme": [1, 0] },
    { "entries": ["Peace", "平和"], "scheme": [1, 0] },
    { "entries": ["Beautiful", "美しい"], "scheme": [1, 0] },
    { "entries": ["Happy", "幸せ"], "scheme": [1, 0] }
  ]
}
```

> **Understanding fact-level `entries` and `scheme`:**
>
> - **`entries`**: The content values for this fact (one per deck column), e.g. `["Apple", "りんご"]` for English/Japanese.
> - **`scheme`**: A two-element array `[split, sibling]`. **split** = how many entries on the **front** (1 or more). **sibling** = 0 for one card, 1 for two cards (primary + reverse). Examples: `[1, 0]` = split at 1, no sibling; `[1, 1]` = split at 1, with sibling; `[2, 0]` = split at 2, no sibling. Must satisfy `0 < split <= len(entries)`.

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

## 5. Get Next Urgent Card

**Endpoint:** `GET /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)

**Response:**

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

> Save the `card.id` — you'll need it when updating the card (step 6).

---

## 6. Review a Card

After viewing a card, you need to update its interval based on how well you remembered it.

**Endpoint:** `PATCH /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3` (your deck ID)

**Request Body:**

```json
{
  "card_id": "xyz12345",
  "interval": 600,
  "last_review": 1763272400
}
```

> Use `card.id` from the GET response as `card_id`.
> `last_review` is a UTC Unix timestamp in seconds — typically
> `Math.floor(Date.now() / 1000)` on the client.

<!-- -->

> 💡 **Calculating min and max interval (client-side):**
>
> The server stores only `last_review` and `due_date` on each
> card. The frontend must derive the current interval and compute
> the allowed range before submitting. Do not send both `interval`
> and `hidden` in the same request.
>
> **Step 1 — Derive the current interval:**
>
> ```text
> current_interval = due_date - last_review    (minimum 60 seconds)
> ```
>
> For a brand-new card (`last_review = 0`), treat `current_interval` as 60 seconds.
>
> **Step 2 — Compute urgency:**
>
> ```text
> urgency = (now - last_review) / (due_date - last_review)
> ```
>
> **Step 3 — Compute min and max interval:**
>
> When the card is overdue (`urgency >= 1`):
>
> ```text
> min_interval = current_interval × 0.5
> max_interval = current_interval × 4.0
> ```
>
> When the card is not yet due (`urgency < 1`):
>
> ```text
> min_interval = current_interval × ((0.5 - 1) × urgency + 1)
> max_interval = current_interval × ((4.0 - 1) × urgency + 1)
> ```
>
> **Step 4 — Validate before sending:**
>
> The frontend must verify that the chosen `interval` satisfies
> `min_interval <= interval <= max_interval` before sending
> the PATCH request.

**Response:**

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

## 7. Hide a Card (Optional)

If you want to temporarily hide a card from reviews:

**Endpoint:** `PATCH /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3`

**Request Body:**

```json
{
  "card_id": "xyz12345",
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
    "msg": "Card visibility updated successfully"
  }
}
```

---

## Next Steps

- Keep reviewing cards by repeating steps 5-6
- Create more decks with different field configurations
- Explore other endpoints in Swagger UI
