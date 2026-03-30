🌐 [English](api.md) | [中文](api_zh.md)

---

# Quick Start Guide - Swagger UI Tutorial

This guide walks you through using the Retentio API via Swagger UI.

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
- [2. Decks](#2-decks)
  - [Create a Deck](#create-a-deck)
  - [Get a Single Deck](#get-a-single-deck)
  - [List All Decks](#list-all-decks)
  - [Update a Deck](#update-a-deck)
  - [Delete a Deck](#delete-a-deck)
  - [Reschedule deck](#reschedule-deck)
- [3. Facts](#3-facts)
  - [Add Facts](#add-facts)
  - [Get all facts](#get-all-facts)
  - [Get one fact](#get-one-fact)
  - [Update a fact](#update-a-fact)
  - [Delete a fact](#delete-a-fact)
- [4. Cards](#4-cards)
  - [Add a card for an existing fact (e.g. reversed)](#add-a-card-for-an-existing-fact-eg-reversed)
  - [Get Next Urgent Card](#get-next-urgent-card)
  - [Review a Card](#review-a-card)
  - [Hide a Card](#hide-a-card)
  - [Delete a Card](#delete-a-card)
  - [Get card stats](#get-card-stats)
- [5. Media (Audio / Images)](#5-media-audio--images)
  - [Upload media](#upload-media)
  - [List media](#list-media)
  - [Get media metadata](#get-media-metadata)
  - [Download media](#download-media)
  - [Delete media](#delete-media)
  - [List or lookup shared media (work in progress)](#list-or-lookup-shared-media-work-in-progress)
  - [Download shared media (work in progress)](#download-shared-media-work-in-progress)
  - [Admin shared media (work in progress)](#admin-shared-media-work-in-progress)
  - [Using media in facts (work in progress)](#using-media-in-facts)
- [Response examples reference](#response-examples-reference)
- [Next Steps](#next-steps)

---

## Prerequisites

- Open Swagger UI at:
  - **Local**: <http://localhost:8080/docs>
  - **Production**: <https://api.wordupx.com:8443/docs>

> **Timestamp convention:** All timestamps in the API use **UTC**.
> ISO 8601 strings use the `Z` suffix (e.g., `2026-02-08T12:00:00Z`).
> Unix timestamps are seconds since the Unix epoch
> (1970-01-01T00:00:00Z). Clients must convert to/from local time
> on their side.
>
> **ID format:** Deck, fact, and card IDs are random **lowercase alphanumeric** strings (no underscores or hyphens). Backend generates: **deck_id** 12 characters, **fact_id** and **card_id** 8 characters each. Media IDs (e.g. in `[audio:id]`) are 10 characters. Example IDs in this guide follow these lengths.

---

## API Reference

| Endpoint | Method | Description |
| ---------- | -------- | ------------- |
| `/auth/register` | POST | Register user |
| `/auth/login` | POST | Login |
| `/auth/logout` | POST | Logout (invalidate token) |
| `/auth/forgot-password` | POST | Request password reset token |
| `/auth/reset-password` | POST | Reset password with token |
| `/api/profile` | GET | Get current user profile |
| `/api/decks` | POST | Create deck |
| `/api/decks` | GET | List all decks |
| `/api/decks/{id}` | GET | Get deck details |
| `/api/decks/{id}` | PATCH | Update deck |
| `/api/decks/{id}` | DELETE | Delete deck |
| `/api/decks/{id}/facts/{operation}` | POST | Add facts (operation: `append`, `prepend`, `shuffle`, `spread`). Body: `facts` (required) and optional `template`. To add a card for an existing fact, use POST `/api/decks/{id}/card` instead. |
| `/api/decks/{id}/facts` | GET | Get all facts |
| `/api/decks/{id}/facts/{factId}` | GET | Get a specific fact |
| `/api/decks/{id}/facts/{factId}` | PATCH | Update a fact |
| `/api/decks/{id}/facts/{factId}` | DELETE | Delete a fact |
| `/api/decks/{id}/card` | GET | Get most urgent card |
| `/api/decks/{id}/card` | POST | Add one card from an existing fact (e.g. reversed). Body: `fact_id`, `template`, optional `operation`. |
| `/api/decks/{id}/card` | PATCH | Update card interval or visibility (by card_id) |
| `/api/decks/{id}/cards` | GET | Get card stats (total, hidden count, hidden facts) |
| `/api/decks/{id}/cards/{cardId}` | DELETE | Delete a single card (fact and other cards unchanged) |
| `/api/decks/{id}/reschedule` | POST | Reschedule deck cards (shift due dates by N days) |
| `/api/media` | POST | Upload media (audio/image) |
| `/api/media` | GET | List user's media (sync manifest) |
| `/api/media/shared` | GET | List or lookup shared media (`?word=...&lang=...`) |
| `/api/media/shared/{id}` | GET | Download shared media file |
| `/api/media/{id}/meta` | GET | Get media metadata (no file body) |
| `/api/media/{id}` | GET | Download media file |
| `/api/media/{id}` | DELETE | Delete media |
| `/api/admin/media/shared` | POST | **(Admin)** Upload shared media |
| `/api/admin/media/shared/{id}` | DELETE | **(Admin)** Delete shared media |
| `/api/admin/decks/import` | POST | **(Admin)** Import shared deck (zip with manifest) |

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

## 2. Decks

### Create a Deck

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
    "deck_id": "a1b2c3d4e5f6"
  },
  "meta": {
    "msg": "Deck created successfully"
  }
}
```

> 📝 Save the `deck_id` - you'll need it for the next steps.
> **Why no template on deck?** Templates are not stored on the deck. When you add facts, you can pass an optional `template` (see [Add Facts](#add-facts)). By default you get **one card per fact** (front = first entry, back = rest). To get **sibling cards** (multiple cards from the same fact), send a 3D template—see below.

---

### Get a Single Deck

**Endpoint:** `GET /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

**Response:**

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

### List All Decks

**Endpoint:** `GET /api/decks`

**Response:**

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
> By default you get **one card per fact** (see [Template: default and sibling cards](#template-default-and-sibling-cards)). To add another card for a fact (e.g. reversed), use `POST /api/decks/{id}/card` with body `{"fact_id": "<factId>", "template": [[1], [0]]}`. The backend returns 400 if that template already exists for the fact.
>
> To calculate a progress percentage on the client side: `reviewed_cards / cards_count * 100`.

### Update a Deck

**Endpoint:** `PATCH /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

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
    "deck_id": "a1b2c3d4e5f6"
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

- `id`: `a1b2c3d4e5f6` (your deck ID)

> This permanently deletes the deck and all its associated facts and cards.

**Response:**

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

### Reschedule deck

**Endpoint:** `POST /api/decks/{id}/reschedule`

Shifts due dates and last_review of all cards in the deck by N days (1–365). Only allowed when the deck has overdue cards.

**Request:**

```json
{ "days": 5 }
```

**Response:**

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

## 3. Facts

### Add Facts

**Endpoint:** `POST /api/decks/{id}/facts/{operation}`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)
- `operation`: `append`

**Request Body:** An array of fact items (each with `entries`) and optional `template`. Each **entry** is an object with optional `text`, `audio`, `image`, `video` (at least one required). The server generates a unique fact ID for each fact and creates one or more **cards** per fact depending on `template` (see **Template: default and sibling cards** below).

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

Example with media and multiple example sentences (each with its own audio):

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

#### Template: default and sibling cards

A **template** defines how a card shows a fact’s entries: **front** (question) and **back** (answer), each as a list of entry indices.

- **One card** is described by a **2D** value: `[[front indices], [back indices]]`.  
  Example: `[[0], [1]]` → front = entry 0, back = entry 1.  
  Example: `[[0], [1, 2, 3]]` → front = entry 0, back = entries 1, 2, 3.

- **Default when `template` is omitted:**  
  Every fact gets **one card** with the default layout: front = entry `0`, back = all others `[1, 2, …]`. So you don’t need to send `template` for simple “first entry = question, rest = answer” cards.

- **Sibling cards** are multiple cards from the **same** fact (e.g. word→translation and translation→word). To create them in one request, send a **3D** `template`: an **array of 2D templates**. The server creates one card per 2D template **for every fact** in the request.  
  Example: three cards per fact (entry 0→rest, entry 1→rest, entry 2→rest) for 3-entry facts:

```json
"template": [
  [[0], [1, 2]],
  [[1], [0, 2]],
  [[2], [0, 1]]
]
```

So: **2D** = one card (one front/back split); **3D** = multiple cards per fact (sibling cards). If you send a single 2D template (e.g. `[[1], [0]]` for reversed only), the API also accepts it: it is treated as an array of one template, so every fact gets one reversed card.

Example — every fact gets two sibling cards (normal and reversed):

```json
"template": [ [[0], [1]], [[1], [0]] ]
```

Each fact gets one card with front=0/back=1 and one with front=1/back=0. To add a reversed card only for some facts, add those extra cards later with `POST /api/decks/{id}/card`.

> **Understanding the request:**
>
> - **`entries`**: Array of entry objects. Each entry has optional `text`, `audio`, `image`, `video` (at least one required). Entry `i` corresponds to deck column `i`; use `fields[i]` as its label. Putting text and audio in the same entry (e.g. `{ "text": "I go to school.", "audio": "ex1id" }`) keeps that audio clearly associated with that sentence.
> - **`fields`** (optional): Column names for this fact; entry `i` is shown under `fields[i]`. If omitted, use the deck's default `fields`. When provided, length must equal `len(entries)`.
> - **`template`** (optional): When empty or omitted, each fact gets **one card** with default `[[0], [1, 2, ...]]`. When provided, it must be a **3D** array: a list of 2D templates. **Every** fact gets one card per 2D template in that list (sibling cards). Each 2D template must be valid for every fact (same number of entries); indices must be in range, disjoint, and cover all entries.

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

### Get all facts

**Endpoint:** `GET /api/decks/{id}/facts`

**Response:**

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

### Get one fact

**Endpoint:** `GET /api/decks/{id}/facts/{factId}`

**Response:**

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

### Update a fact

**Endpoint:** `PATCH /api/decks/{id}/facts/{factId}`

**Parameters:** `id` (deck ID), `factId` (fact ID from GET facts or add-facts).

**Request Body:** Optional `entries` (array of entry objects with optional `text`, `audio`, `image`, `video`) and `fields`. If `entries` is provided it replaces the fact's entries; if `fields` is provided its length must equal `len(entries)`.

```json
{
  "entries": [{ "text": "Apple" }, { "text": "りんご" }],
  "fields": ["English", "Japanese"]
}
```

**Response:**

```json
{
  "data": { "fact_id": "x9k2m4np" },
  "meta": { "msg": "Fact updated successfully" }
}
```

### Delete a fact

**Endpoint:** `DELETE /api/decks/{id}/facts/{factId}`

**Parameters:** `id` (deck ID), `factId` (fact ID).

Permanently deletes the fact and all cards derived from it.

**Response:**

```json
{
  "data": { "fact_id": "x9k2m4np" },
  "meta": { "msg": "Fact deleted successfully" }
}
```

---

## 4. Cards

### Add a card for an existing fact (e.g. reversed)

By default there is **one card per fact**. To add a second card for a fact (e.g. a reversed card so the back side is shown first), use **POST /api/decks/{id}/card** with body `fact_id` and `template`. This is a separate endpoint from adding facts.

**Endpoint:** `POST /api/decks/{id}/card`

**Parameters:**

- `id`: your deck ID

**Request Body:**

```json
{
  "fact_id": "x9k2m4np",
  "template": [[1], [0]]
}
```

- **`fact_id`** (required): The fact's ID (from `GET /api/decks/{id}/facts` or the add-facts response).
- **`template`** (required): `[[front indices], [back indices]]` defining how the card shows the fact's entries. For a 2-entry fact: `[[0],[1]]` = front entry 0, back entry 1; `[[1],[0]]` = reversed. All indices must be in `0..(n-1)`, disjoint, and cover every entry. The backend returns 400 if this exact template already exists for another card of this fact.
- **`operation`** (optional): `append`, `prepend`, `shuffle`, or `spread` — where to place the new card among unseen cards. Default is `append`.

**Response:**

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

### Get Next Urgent Card

**Endpoint:** `GET /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

**Response shape:** `front` and `back` are arrays of **entry objects** in **template order** (one object per fact entry index on that side). Each object matches a fact **entry**: optional **`field`** (label) and optional **`text`**, **`audio`**, **`image`**, **`video`** string keys (omitted when empty). Text and its pronunciation clip are explicit siblings on the same object (e.g. `"text": "Hello"` and `"audio": "https://…/api/media/…"`). For media keys, values are **full media URLs** when the server can determine a base URL. Use each URL with the same `Authorization: Bearer <token>` to download the file.

Each JSON example below has a matching integration test in [`api/tests/integration/card_test.go`](../../api/tests/integration/card_test.go): `TestGetNextCard` (with field names) and `TestNextCardUrgencySelection` (no field names, text+audio+image, multi-front, front-only, split template `[[0,1],[2,3]]`, and full URL host).

**Response (no field names):**

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

**Response (with field names):**

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

**Response (one entry with text + audio + image):**

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

**Response (multiple entries on front — e.g. two example sentences with text + audio each):**

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

**Front-only card (template with empty back, e.g. `[[0], []]`):**

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

**Card with multiple entries and media (template [[0, 1], [2, 3]]; media keys hold full URLs):**

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

> Save the `card.id` — you'll need it when updating the card (step 6).

---

### Review a Card

After viewing a card, you need to update its interval based on how well you remembered it.

**Endpoint:** `PATCH /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

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

### Hide a Card

If you want to temporarily hide a card from reviews:

**Endpoint:** `PATCH /api/decks/{id}/card`

**Parameters:**

- `id`: `a1b2c3d4e5f6`

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

### Delete a Card

Permanently remove a single card from a deck. The fact and any other cards for that fact (e.g. a sibling/reversed card) are unchanged.

**Endpoint:** `DELETE /api/decks/{id}/cards/{cardId}`

**Parameters:**

- `id`: deck ID (e.g. `a1b2c3d4e5f6`)
- `cardId`: card ID (from get-next-card response or card stats)

**Request Body:** None.

**Response:**

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

### Get card stats

**Endpoint:** `GET /api/decks/{id}/cards`

**Response:**

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

## 5. Media (Audio / Images)

You can attach audio, images, and video to facts. Fact fields reference media by ID using markers `[audio:id]`, `[image:id]`, and `[video:id]`.

**Size limits:** Images max **5 MB**; audio and video max **200 MB** each. Env overrides: `MEDIA_MAX_SIZE_IMAGE`, `MEDIA_MAX_SIZE_VIDEO`, `MEDIA_MAX_SIZE_AUDIO`.

**Formats and conversion:** Supported input: image (JPEG, PNG, GIF, HEIC, HEIF, WebP), audio (MPEG/MP3, WAV, OGG, MP4/AAC), video (MP4, QuickTime, WebM). Only **PNG, HEIC, HEIF** are converted to WebP and **WAV** to AAC; all other formats are stored as-is. Download returns the stored file (binary). **Size limits:** images 5 MB, audio and video 200 MB each.

### Upload media

**Endpoint:** `POST /api/media` — multipart/form-data.

| Field        | Required | Description |
| ------------ | -------- | ----------- |
| `file`       | Yes      | The media file (image, audio, or video). |
| `client_id`  | No       | Client-generated ID for idempotent upload; if the media already exists for this user, the server returns 201 with the existing record. |

**Response:**

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

### List media

**Endpoint:** `GET /api/media` — returns the current user's media (paginated).

| Query   | Description |
| ------- | ----------- |
| `since` | Optional. Unix timestamp (number); return only media created after this time. |
| `limit` | Optional. Max items (default 200, max 1000). |
| `offset`| Optional. Number of items to skip (default 0). |

**Response:**

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

### Get media metadata

**Endpoint:** `GET /api/media/{id}/meta`

Returns metadata only (id, owner, filename, mime, size, checksum, created_at), no file body.

### Download media

**Endpoint:** `GET /api/media/{id}`

Returns the media file (binary) for user-owned media by ID. Requires `Authorization: Bearer <token>`. Response headers include `Content-Type`, `Content-Length`, and `ETag` (same as `checksum`). Send `If-None-Match: <ETag>` to get `304 Not Modified` when the file is unchanged. The **Get Next Card** response puts full URLs in the `audio`, `image`, and `video` fields of each front/back entry (e.g. `https://api.wordupx.com:8443/api/media/{id}`); use that URL with the same auth header to load the file.

### Delete media

**Endpoint:** `DELETE /api/media/{id}`

**Response:**

```json
{
  "data": { "msg": "media deleted" }
}
```

### List or lookup shared media (work in progress)

**Endpoint:** `GET /api/media/shared` — list shared pronunciation assets; optional `?word=...&lang=...` to lookup.

### Download shared media (work in progress)

**Endpoint:** `GET /api/media/shared/{id}` — download shared media file by ID.

### Admin shared media (work in progress)

**Endpoints:** `POST /api/admin/media/shared` (upload), `DELETE /api/admin/media/shared/{id}` (delete). Admin-only.

### Using media in facts

Each entry is an object with optional `text`, `audio`, `image`, `video`. Use a dedicated entry for media (e.g. `{ "audio": "abc123" }`) or combine with text in one entry (e.g. `{ "text": "Example sentence.", "audio": "ex1id" }`) so the audio is clearly for that sentence. Use optional `template` for custom front/back layout per fact; omit for default (front = first entry, back = rest).

For full design (upload, delete, display, sync), see **[Media Upload design doc](../design-doc/media-upload.md)**.

---

## Response examples reference

| Endpoint | Method | Response shape |
| -------- | ------ | ---------------- |
| `/auth/register` | POST | `{ "data": { … }, "meta": { "msg": "..." } }` — see [Create a User](#create-a-user) |
| `/auth/login` | POST | `{ "data": { "token", "expires" }, "meta": { "expires" } }` |
| `/auth/logout` | POST | `{ "data": { "msg": "Logged out successfully" }, "meta": null }` |
| `/auth/forgot-password` | POST | `{ "data": { "reset_token" }, "meta": { "expires_in" } }` |
| `/auth/reset-password` | POST | `{ "data": { "msg": "Password reset successfully" }, "meta": null }` |
| `/api/profile` | GET | `{ "data": { user profile }, "meta": { "msg" } }` |
| `/api/decks` | POST | `{ "data": { "deck_id" }, "meta": { "msg" } }` |
| `/api/decks` | GET | `{ "data": { "decks": [ … ] }, "meta": { "total", "msg" } }` |
| `/api/decks/{id}` | GET | `{ "data": { deck + stats }, "meta": { "msg" } }` |
| `/api/decks/{id}` | PATCH | `{ "data": { "deck_id" }, "meta": { "msg", "updated_at" } }` |
| `/api/decks/{id}` | DELETE | `{ "data": { "deck_id" }, "meta": { "msg" } }` |
| `/api/decks/{id}/facts/{op}` | POST | Add facts: `{ "data": { "fact_length" }, "meta": { "msg" } }` |
| `/api/decks/{id}/card` | POST | Add card from existing fact: `{ "data": { "card_id" }, "meta": { "msg" } }` |
| `/api/decks/{id}/facts` | GET | `{ "data": { "facts": [ … ] }, "meta": { "msg" } }` |
| `/api/decks/{id}/facts/{factId}` | GET | `{ "data": { "fact": { … } } }` |
| `/api/decks/{id}/facts/{factId}` | PATCH | `{ "data": { "fact_id" }, "meta": { "msg" } }` |
| `/api/decks/{id}/facts/{factId}` | DELETE | `{ "data": { "fact_id" }, "meta": { "msg" } }` |
| `/api/decks/{id}/card` | GET | `{ "data": { "card": { id, fact_id, template, …, front[], back[] }, "urgency" }, "meta": { "msg", … } }` |
| `/api/decks/{id}/card` | PATCH | Interval: `{ "data": { "last_review", "due_date", "new_interval" }, "meta": { "msg" } }`; visibility: `{ "data": { "hidden_status" }, "meta": { "msg" } }` |
| `/api/decks/{id}/cards` | GET | `{ "data": { "total_cards", "hidden_count", "hidden_facts", "orphaned_hidden_cards" }, "meta": { "msg" } }` |
| `/api/decks/{id}/cards/{cardId}` | DELETE | `{ "data": { "card_id" }, "meta": { "msg" } }` |
| `/api/decks/{id}/reschedule` | POST | `{ "data": { "cards_shifted", "days", "max_days_away" }, "meta": { "msg" } }` |
| `/api/media` | POST | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }` |
| `/api/media` | GET | `{ "data": [ MediaSwagger, … ], "meta": { "count", "has_more" } }` |
| `/api/media/shared` | GET | List or lookup shared media (query: `word`, `lang`) |
| `/api/media/shared/{id}` | GET | Download shared media (binary) |
| `/api/media/{id}/meta` | GET | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }` |
| `/api/media/{id}` | GET | Download media (binary) |
| `/api/media/{id}` | DELETE | `{ "data": { "msg": "media deleted" } }` |
| `/api/admin/media/shared` | POST | **(Admin)** Upload shared media |
| `/api/admin/media/shared/{id}` | DELETE | **(Admin)** Delete shared media |
| `/api/admin/decks/import` | POST | **(Admin)** Import shared deck |

Full JSON examples for each are in the sections above.

---

## Next Steps

- Keep reviewing cards by repeating steps 5-6
- **Tagging system** — organize decks and facts with tags (planned)
- **Offline sync** — sync data when back online (planned)
- **Local storage** — cache decks and cards for offline use (planned)
