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
  - [Deck sharing (overview)](#deck-sharing-overview)
  - [Deck catalog](#deck-catalog)
  - [Publish a deck](#publish-a-deck)
  - [Import a published deck](#import-a-published-deck)
  - [Get import updates (diff)](#get-import-updates-diff)
  - [Sync an imported deck](#sync-an-imported-deck)
  - [Sharing: extended deck & fact behavior](#sharing-extended-deck--fact-behavior)
- [3. Facts](#3-facts)
  - [Add Facts](#add-facts)
  - [Get all facts](#get-all-facts)
  - [Get one fact](#get-one-fact)
  - [Update a fact](#update-a-fact)
  - [Delete a fact](#delete-a-fact)
- [4. Tags](#4-tags)
  - [Create a tag](#create-a-tag)
  - [List your tags](#list-your-tags)
  - [List tags for deck or fact pickers](#list-tags-for-deck-or-fact-pickers)
  - [Get one tag](#get-one-tag)
  - [Update a tag](#update-a-tag)
  - [Delete a tag](#delete-a-tag)
  - [Associate a tag with a deck](#associate-a-tag-with-a-deck)
  - [Remove a tag from a deck](#remove-a-tag-from-a-deck)
  - [List tags on a deck](#list-tags-on-a-deck)
  - [Associate a tag with a fact](#associate-a-tag-with-a-fact)
  - [Remove a tag from a fact](#remove-a-tag-from-a-fact)
  - [List tags on a fact](#list-tags-on-a-fact)
  - [List facts that have a tag](#list-facts-that-have-a-tag)
- [5. Cards](#5-cards)
  - [Add a card for an existing fact (e.g. reversed)](#add-a-card-for-an-existing-fact-eg-reversed)
  - [Get Next Urgent Card](#get-next-urgent-card)
  - [Review a Card](#review-a-card)
  - [Hide a Card](#hide-a-card)
  - [Delete a Card](#delete-a-card)
  - [Get card stats](#get-card-stats)
- [6. Media (Audio / Images)](#6-media-audio--images)
  - [Upload media](#upload-media)
  - [List media](#list-media)
  - [Get media metadata](#get-media-metadata)
  - [Download media](#download-media)
  - [Delete media](#delete-media)
  - [Using media in facts](#using-media-in-facts)
- [Response examples reference](#response-examples-reference)
- [Next Steps](#next-steps)

---

## Prerequisites

- Open Swagger UI at:
  - **Local**: <http://localhost:8080/docs>
  - **Production**: <https://api.retentio.app:8443/docs>

> **Timestamp convention:** All timestamps in the API use **UTC**.
> ISO 8601 strings use the `Z` suffix (e.g., `2026-02-08T12:00:00Z`).
> Unix timestamps are seconds since the Unix epoch
> (1970-01-01T00:00:00Z). Clients must convert to/from local time
> on their side.
>
> **ID format:** Deck, fact, card, and **tag** IDs are random **lowercase alphanumeric** strings (no underscores or hyphens). Backend generates: **deck_id** 12 characters; **fact_id**, **card_id**, and **tag_id** 8 characters each. Media IDs (e.g. in `[audio:id]`) are 10 characters. Example IDs in this guide follow these lengths.

---

## API Reference

| Endpoint                                      | Method | Description                                                                                                                                                                                     |
| --------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/auth/register`                              | POST   | Register user                                                                                                                                                                                   |
| `/auth/login`                                 | POST   | Login                                                                                                                                                                                           |
| `/auth/logout`                                | POST   | Logout (invalidate token)                                                                                                                                                                       |
| `/auth/forgot-password`                       | POST   | Request password reset token                                                                                                                                                                    |
| `/auth/reset-password`                        | POST   | Reset password with token                                                                                                                                                                       |
| `/api/profile`                                | GET    | Get current user profile                                                                                                                                                                        |
| `/api/decks`                                  | POST   | Create deck. Body: `name`, **`fields`** (≥1 column name, required), **`rate`** (required, 1–1000), optional **`tags`**.                                                                         |
| `/api/decks`                                  | GET    | List all decks                                                                                                                                                                                  |
| `/api/decks/{id}`                             | GET    | Get deck details. Source decks include `visibility`, `published_version`. Import decks include `source_deck_id`, `source_version`, `imported_at`.              |
| `/api/decks/{id}`                             | PATCH  | Update deck. Source: optional `visibility` before first publish. Import: **`rate` only** (not `name`, `fields`, or `visibility`).                                                              |
| `/api/decks/{id}`                             | DELETE | Delete deck. **409** if source deck has `published_version > 0`. Import decks revoke media grants on delete.                                                                                    |
| `/api/decks/import`                           | POST   | **(Sharing)** Create an import study copy from a published public source deck. Body: `source_deck_id`. **201**.                                                  |
| `/api/decks/catalog`                          | GET    | **(Sharing)** List public published source decks (importable catalog). **No login required.** Query: `limit`, `offset`, optional `query` (name, description, owner, deck tag names). Newest publish first. Import via `POST /api/decks/import` requires JWT. |
| `/api/decks/catalog/{id}`                     | GET    | **(Sharing)** Get one public published source deck by source deck ID (same row shape as list entries). **No login required.** **404** if not importable. |
| `/api/decks/{id}/publish`                     | POST   | **(Sharing)** Author: snapshot working copy into next `published_version`. First publish requires `visibility: "public"`. **200**.                             |
| `/api/decks/{id}/updates`                     | GET    | **(Sharing)** Importer: diff between pinned `source_version` and source’s latest publish. Import deck only.                                                       |
| `/api/decks/{id}/sync`                        | POST   | **(Sharing)** Importer: accept a newer snapshot (optional `target_version`). Import deck only. **200**.                                                         |
| `/api/decks/{id}/feedback`                    | POST   | **(Sharing)** Importer: submit fact feedback / proposal to the source deck author. Body on **import** deck id. **201**. **429** when daily limit (20/source/day) exceeded. |
| `/api/decks/{id}/feedback`                    | GET    | **(Sharing)** Author: list feedback inbox on **source** deck id. Query: `limit`, `offset`, optional `status`, `fact_id`. |
| `/api/decks/{id}/feedback/{feedbackId}`       | PATCH  | **(Sharing)** Author: update feedback `status` (`open`, `resolved`, `dismissed`). Source deck only. |
| `/api/decks/{id}/feedback/{feedbackId}/accept` | POST | **(Sharing)** Author: apply `proposed_entries` to working copy; sets status `accepted`. Does not publish. Source deck only. |
| `/api/decks/{id}/facts/{operation}`           | POST   | Add facts (operation: `append`, `prepend`, `shuffle`, `spread`). Body: `facts` (required), optional `template`, and optional **`tags`** or **`tag_ids`** per fact item (mutually exclusive per item; `tags` = names auto-created if missing, `tag_ids` = existing IDs). Column labels live on the deck (`PATCH /api/decks/{id}` → `fields`), not on each fact. To add a card for an existing fact, use POST `/api/decks/{id}/card` instead. **403** on imported decks. |
| `/api/decks/{id}/facts`                       | GET    | List facts (paged): default `limit` **50**, `offset` **0**; max `limit` **200**. `meta`: `count`, `has_more`, `limit`, `offset`, `total`. |
| `/api/decks/{id}/facts/{factId}`              | GET    | Get a specific fact                                                                                                                                                                             |
| `/api/decks/{id}/facts/{factId}`              | PATCH  | Update a fact’s `entries` only (column names are edited on the deck). **403** on imported decks.                                                                                                                               |
| `/api/decks/{id}/facts/{factId}`              | DELETE | Delete a fact. **403** on imported decks.                                                                                                                                                       |
| `/api/decks/{id}/card`                        | GET    | Get most urgent card. Optional query: `tag_id` to restrict selection to cards whose facts have this tag in this deck.                                                                        |
| `/api/decks/{id}/card`                        | POST   | Add one card from an existing fact (e.g. reversed). Body: `fact_id`, `template`, optional `operation`.                                                                                          |
| `/api/decks/{id}/card`                        | PATCH  | Update card interval or visibility (by card_id)                                                                                                                                                 |
| `/api/decks/{id}/cards`                       | GET    | Get `stats` + `cards`. Optional `tag_id` filters both; without `tag_id`, `stats` match `GET /api/decks/{id}`.                                                                                   |
| `/api/decks/{id}/cards/{cardId}`              | DELETE | Delete a single card (fact and other cards unchanged)                                                                                                                                           |
| `/api/decks/{id}/reschedule`                  | POST   | Reschedule deck cards (shift due dates by N days)                                                                                                                                               |
| `/api/tags`                                   | POST   | Create a tag (`name`, optional `description`). **201** on success.                                                                                                                              |
| `/api/tags`                                   | GET    | List all tags for the current user. Each tag includes `deck_count`, `fact_count`, `used_on`. Optional query: `used_on=deck` (user-wide) or `used_on=fact&deck_id={id}` (deck-scoped fact picker).             |
| `/api/tags/{tagId}`                           | GET    | Get one tag                                                                                                                                                                                     |
| `/api/tags/{tagId}`                           | PATCH  | Update tag `name` and/or `description` (partial)                                                                                                                                                |
| `/api/tags/{tagId}`                           | DELETE | Delete tag and all deck/fact associations                                                                                                                                                       |
| `/api/tags/{tagId}/facts`                     | GET    | List `{deck_id, fact_id}` pairs for facts tagged with this tag (all your decks)                                                                                                                 |
| `/api/decks/{id}/tags/{tagId}`                | PUT    | Associate an existing tag with a deck (no body)                                                                                                                                                 |
| `/api/decks/{id}/tags/{tagId}`                | DELETE | Remove tag from deck                                                                                                                                                                            |
| `/api/decks/{id}/tags`                        | GET    | List tags on a deck                                                                                                                                                                             |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | PUT    | Associate an existing tag with a fact (no body)                                                                                                                                                 |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | DELETE | Remove tag from fact                                                                                                                                                                            |
| `/api/decks/{id}/facts/{factId}/tags`         | GET    | List tags on one fact only                                                                                                                                                                      |
| `/api/media`                                  | POST   | Upload media (audio/image)                                                                                                                                                                      |
| `/api/media`                                  | GET    | List user's media (sync manifest)                                                                                                                                                               |
| `/api/media/{id}/meta`                        | GET    | Get media metadata (no file body)                                                                                                                                                               |
| `/api/media/{id}`                             | GET    | Download media file                                                                                                                                                                             |
| `/api/media/{id}`                             | DELETE | Delete media                                                                                                                                                                                    |

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

### Deck, facts, and cards (relationship)

A **deck** is the study container: metadata (`name`, `fields`, `rate`, owner) plus two membership lists — which **facts** belong to the deck and which **cards** you review. **Facts** hold the vocabulary content (`entries`: text and optional media ids). **Cards** are the schedulable review units: each card points at one fact via `fact_id` and stores a **template** (which entry indices are front vs back) plus spaced-repetition state (`due_date`, `last_review`, `hidden`).

Column labels (`English`, `Japanese`, …) live on the **deck** only (`fields`). Facts do not store column names; entry index `0` is the first column, `1` the second, and so on.

| Concept | Role | Typical API |
|--------|------|-------------|
| **Deck** | Container + column schema + daily `rate` | `POST/GET/PATCH/DELETE /api/decks/{id}` |
| **Fact** | Immutable-ish content you learn (entries) | `POST …/facts/{operation}`, `GET/PATCH/DELETE …/facts/{factId}` |
| **Card** | One reviewable direction/layout for a fact | Created with facts (default template) or `POST …/card`; reviewed via `GET/PATCH …/card` |

#### Cardinality

- One deck → many facts (set membership).
- One deck → many cards (set membership).
- One fact in a deck → **one or more** cards (default: one card; **sibling** cards = same fact, different `template`, e.g. reversed).
- One card → exactly one `fact_id` (must stay in the deck’s fact set).

#### Lifecycle (source deck)

1. Create deck → empty fact/card sets.
2. Add facts → new `fact:{id}` rows + new card(s) per fact + `SADD` into deck sets.
3. Study → `GET …/card` picks the most urgent card in the deck; response joins card + fact + template.
4. Delete fact → removes that fact and **all** cards in the deck that reference it.
5. Delete card → removes only that card; fact and other cards for the same fact remain.

**Imported decks ([sharing](#deck-sharing-overview)):** fact **bodies** are read-only (pinned snapshot); deck metadata is mostly snapshot-driven — importers may **`PATCH` only `rate`** on the import deck. The importer still owns a **separate card set** with full card `PATCH` / hide / delete behavior. Tags on import decks are importer-scoped labels — see [§4 Tags](#4-tags).

---

### Create a Deck

**Endpoint:** `POST /api/decks`

```json
{
  "fields": ["English", "Japanese"],
  "name": "English Japanese IELTS Deck",
  "description": "Core vocabulary for IELTS speaking practice",
  "rate": 20,
  "tags": ["IELTS", "vocabulary"]
}
```

Optional **`description`** — short summary for you (and, after publish, for catalog importers). Max **500** characters; omit or `""` for none. Invalid control characters → **400**.

#### Optional tags (on create)

The request may include optional deck tags in **one** of two forms (not both):

| Field | Type | Use when |
|-------|------|----------|
| **`tags`** | tag **names** (`string[]`) | Bulk import / scripts — missing names are auto-created |
| **`tag_ids`** | existing tag **IDs** (`string[]`) | TagPicker UI — tags must already exist (`POST /api/tags`) |

Omit both fields or use `[]` for an untagged deck. Sending **`tags` and `tag_ids` together** → **400** `provide either tags or tag_ids, not both`.

##### `tags` (names)

| Behavior | Detail |
|----------|--------|
| **Validation** | Same name rules as [`POST /api/tags`](#create-a-tag). Invalid names → **400**. |
| **Reuse** | Existing user tags (by normalized name) are reused. |
| **Create** | Missing names are auto-created; counts toward **1000 tags per user**. |
| **Dedup** | Duplicate names in the same request (e.g. `"Noun"` and `" noun "`) collapse to one association. |

##### `tag_ids` (existing IDs)

| Behavior | Detail |
|----------|--------|
| **Validation** | Each id must be non-empty; unknown id → **404** `tag not found`. |
| **Ownership** | Tag must belong to the current user. |
| **Create** | Never auto-creates tags. |
| **Dedup** | Duplicate ids in the same request collapse to one association. |

##### Both forms

| Behavior | Detail |
|----------|--------|
| **Limit** | At most **100** distinct tags on the deck after resolution → **400** `maximum tags per deck reached`. |
| **Storage** | Tags are not stored in deck JSON; use [`GET /api/decks/{id}/tags`](#list-tags-on-a-deck) after create. |
| **Create response** | Returns only `deck_id` — not tag objects. |

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
> **`fields`:** Required — at least one column name (same order as `entries` indices when studying). Empty array → **400** `fields must contain at least one column name`.
> **`rate`:** Required — integer 1–1000. Omitted → **400**.
> To rename columns on a **source** deck later, **`PATCH /api/decks/{id}`** with a non-empty `fields` array that **replaces** the list.
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
    "description": "Core vocabulary for IELTS speaking practice",
    "owner": "swagger",
    "fields": ["English", "Japanese"],
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
    "updated_at": "2026-02-08T12:00:00Z",
    "visibility": "public",
    "published_version": 2
  },
  "meta": {
    "msg": "Deck retrieved successfully"
  }
}
```

**Source deck (author)** — optional fields when you own the canonical deck:

| Field | Description |
| ----- | ----------- |
| `visibility` | `private` (default) or `public`. Who may import once published. |
| `published_version` | Latest published snapshot version. `0` = never published. |
| `description` | Optional blurb (omitted when empty). On import decks, pinned from the source snapshot (updated on sync). |

**Import deck (subscriber)** — optional fields when `source_deck_id` is set:

| Field | Description |
| ----- | ----------- |
| `source_deck_id` | Author’s source deck ID (12 characters). |
| `source_version` | Pinned snapshot version for fact/media reads. |
| `imported_at` | ISO 8601 timestamp when the import was created. |

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
        "fields": ["English", "Japanese"],
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
> | Field   | Description                                     |
> | ------- | ----------------------------------------------- |
> | `total` | Total number of decks owned by the current user |
> | `msg`   | Status message                                  |

<!-- -->

> **Understanding `stats`:**
>
> | Field              | Description                                                      |
> | ------------------ | ---------------------------------------------------------------- |
> | `cards_count`      | Total number of cards in the deck                                |
> | `facts_count`      | Total number of facts in the deck                                |
> | `unseen_cards`     | New cards that have never been reviewed                          |
> | `reviewed_cards`   | Cards that have been studied at least once                       |
> | `due_cards`        | Cards currently due for review (due_date <= now)                 |
> | `hidden_cards`     | Cards hidden from review by the user                             |
> | `new_cards_today`  | Cards that were added today (since midnight)                     |
> | `last_reviewed_at` | Unix timestamp of the most recent review (`0` if never reviewed) |
> | `orphaned_hidden_cards` | Hidden cards whose `fact_id` is missing from the deck (omitted when `0`) |
>
> Stats are computed on-the-fly. For a freshly created empty deck,
> all values are `0`. After adding facts, `cards_count` and
> `unseen_cards` will increase. As you review cards,
> `reviewed_cards` grows and `unseen_cards` decreases.
>
> By default you get **one card per fact** (see [Template: default and sibling cards](#template-default-and-sibling-cards)). To add another card for a fact (e.g. reversed), use `POST /api/decks/{id}/card` with body `{"fact_id": "<factId>", "template": [[1], [0]]}`. The backend returns 400 if that template already exists for the fact.
>
> To calculate a progress percentage on the client side: `reviewed_cards / cards_count * 100`.
>
> List entries use the same optional sharing fields as [Get a Single Deck](#get-a-single-deck) (`visibility` / `published_version` on source decks; `source_deck_id` / `source_version` / `imported_at` on imports).

### Update a Deck

**Endpoint:** `PATCH /api/decks/{id}`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

**Request Body:**

```json
{
  "name": "Updated Deck Name",
  "description": "Updated summary for catalog and importers",
  "fields": ["English", "Japanese"],
  "rate": 30,
  "visibility": "public"
}
```

> **Source decks:** all keys except `name` are optional. **`description`** may be set or cleared (`""`); max **500** characters. Changing only the description requires a subsequent **`POST /publish`** to appear in the catalog snapshot. **`name`** is required on every request.
> **`visibility`** (`private` \| `public`) applies to **source decks only**, and only while `published_version == 0`. After the first successful publish, visibility is **immutable** (omit the field or repeat the current value → **400** if you send a different value).
> If **`fields`** is sent as a **non-empty** array on a source deck, it **replaces** the deck’s column-name list (any length ≥ 1). Omit `fields` or send an empty array to leave column names unchanged.
> **`rate`** must be between 1 and 1000 when provided.
>
> **Imported decks** (`source_deck_id` set): only **`rate`** may change. **`rate`** is **required** on every PATCH (e.g. `{ "rate": 30 }` only). Do **not** send **`name`**, **`description`**, or **`fields`** (even unchanged values) → **400** `cannot change name on an imported deck` / `cannot change description on an imported deck` / `cannot change fields on an imported deck`. Non-empty **`visibility`** → **400**. Deck title, description, and column schema follow the pinned snapshot and are refreshed from the author on [sync](#sync-an-imported-deck).

When **`rate`** is present and **differs** from the stored deck rate, the server applies a **gap-only restagger** to **unseen** cards (`DueDate - LastReview == 1`): unseen rows are ordered by **introduction queue** (`DueDate` ascending, then `card_id`); the **first** in that order (earliest due) keeps its timestamps; each following unseen gets `DueDate` spaced by **`86400 / new_rate`** seconds from the previous unseen’s `DueDate` (same gap definition as new-card introduction). **Seen** cards are unchanged. Deck JSON and card keys are updated in **one** Redis transaction. If `rate` is omitted or unchanged, card timestamps are not rewritten.

See [rate-change-update.md](rate-change-update.md) for the full design.

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

> This permanently deletes the deck and all its associated facts and cards (importer-owned keys only for import decks; versioned snapshots and the author’s working copy are not removed).

| Deck kind | Delete behavior |
| --------- | ---------------- |
| **Source** with `published_version == 0` | Allowed (**200**). |
| **Source** with `published_version > 0` | **409** — `published decks cannot be deleted`. |
| **Import** | Allowed (**200**). Revokes `user:{you}:readable_media_versions` grants created for this import. |

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

## Deck sharing (overview)

User-to-user deck sharing lets an **author** publish versioned snapshots of a deck so other users can **import** a personal study copy. Each import is a **new deck** owned by the importer with its own cards and scheduling; **facts and embedded media** are read-only and resolved through pinned snapshot versions.

See [deck-sharing-feature.md](deck-sharing-feature.md) for the full design.

### Concepts

| Term | Meaning |
| ---- | ------- |
| **Source deck** | Author’s working copy (`source_deck_id` empty). Full fact/media CRUD. |
| **Publish** | Snapshot working copy → immutable `v1`, `v2`, … (`published_version`). |
| **Import deck** | New deck owned by importer; `source_deck_id` + pinned `source_version`. |
| **Working copy** | Live `fact:{id}` / `media:{id}` — visible to author only until published. |
| **Snapshot** | `deck:{src}:snapshot:v{N}` manifest + versioned `fact:{id}:v{N}` / `media:{id}:v{N}`. |

**Rules:**

- First publish must use **`visibility: "public"`** (imports require a public, published source).
- After first publish, **visibility cannot change** and the **source deck cannot be deleted** (**409**).
- Author edits to the working copy are **invisible** to importers until the author publishes again.
- Importers **opt in** to updates via `GET …/updates` + `POST …/sync` (no auto-sync).
- Republish uses **copy-on-write**: only facts/media whose content changed get a new version in the manifest; unchanged rows reuse prior versions (so update diffs list only real changes).

Most sharing routes require **`Authorization: Bearer <token>`** (same as other `/api` routes). **`GET /api/decks/catalog`** and **`GET /api/decks/catalog/{id}`** are exceptions: anyone may browse the catalog without logging in; [import](#import-a-published-deck) still requires a valid JWT.

---

### Deck catalog

**Endpoint:** `GET /api/decks/catalog`

**Who:** Anyone (no `Authorization` header required). Log in to [import](#import-a-published-deck) a deck from the catalog.

**Purpose:** Browse **importable** source decks — public, published, not import rows — before calling [Import a published deck](#import-a-published-deck). Results are ordered **newest publish first** (Redis `catalog:decks` ZSET, updated on each successful publish).

**Query parameters:**

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `limit` | `50` | Page size (max **200**). |
| `offset` | `0` | Number of matching rows to skip. |
| `query` | *(empty)* | Optional case-insensitive substring filter on **deck name**, **description**, **owner username**, or **deck tag names** from the latest snapshot. |

Example: `GET /api/decks/catalog?limit=20&offset=0&query=JLPT`

**Success (200):**

```json
{
  "data": {
    "decks": [
      {
        "id": "a1b2c3d4e5f6",
        "name": "JLPT N5 Core",
        "description": "Core vocabulary for JLPT N5",
        "owner": "alice",
        "fields": ["English", "Japanese"],
        "published_version": 3,
        "fact_count": 120,
        "deck_tag_names": ["JLPT N5", "verbs"],
        "published_at": "2026-05-22T12:00:00Z"
      }
    ]
  },
  "meta": {
    "msg": "ok",
    "count": "1",
    "total": "1",
    "limit": "50",
    "offset": "0",
    "has_more": "false"
  }
}
```

| Field | Meaning |
| ----- | ------- |
| `id` | Source deck ID — pass as `source_deck_id` to `POST /api/decks/import`. |
| `name`, `description`, `fields` | From the latest published snapshot manifest (`description` omitted when empty). |
| `owner` | Author username. |
| `published_version` | Latest published snapshot version on the source. |
| `fact_count` | Number of facts in that snapshot. |
| `deck_tag_names` | Tag names on the deck in that snapshot (omitted when empty). |
| `published_at` | UTC timestamp when that snapshot was created. |

**Inclusion rules** (same as import eligibility):

- Source deck only (`source_deck_id` empty).
- `visibility` is **`public`**.
- `published_version > 0`.

Unpublished or non-public decks do not appear. Private decks never appear even if published.

**Errors:**

| Status | Typical cause |
| ------ | ------------- |
| **500** | Server error listing catalog (`Error listing catalog decks`). |

#### Get one catalog deck

**Endpoint:** `GET /api/decks/catalog/{id}`

**Who:** Anyone (no `Authorization` header required).

**Purpose:** Load **one** importable catalog row by **source deck ID** — same fields as a list entry (`id`, `name`, `description`, `owner`, `fields`, `published_version`, `fact_count`, `deck_tag_names`, `published_at`). Use for catalog detail pages or direct links without paging the full list.

**Path parameter:** `{id}` — source deck ID (same value as `source_deck_id` for `POST /api/decks/import`).

Example: `GET /api/decks/catalog/a1b2c3d4e5f6`

**Success (200):**

```json
{
  "data": {
    "id": "a1b2c3d4e5f6",
    "name": "JLPT N5 Core",
    "description": "Core vocabulary for JLPT N5",
    "owner": "alice",
    "fields": ["English", "Japanese"],
    "published_version": 3,
    "fact_count": 120,
    "deck_tag_names": ["JLPT N5", "verbs"],
    "published_at": "2026-05-22T12:00:00Z"
  },
  "meta": {
    "msg": "ok"
  }
}
```

Field meanings match the [list catalog](#deck-catalog) table. **`description`** comes from the latest published snapshot; if the snapshot has none, the server falls back to the source deck’s stored description.

**Inclusion rules:** Same as the list — public, published source deck only. Private, unpublished, or import rows → **404**.

**Errors:**

| Status | Typical cause |
| ------ | ------------- |
| **404** | `Deck not found in catalog` — ID missing, not public, not published, or is an import row. |
| **500** | Server error loading catalog deck (`Error loading catalog deck`). |

---

### Publish a deck

**Endpoint:** `POST /api/decks/{id}/publish`

**Who:** Owner of a **source** deck (not an import row).

**Request body:**

```json
{
  "visibility": "public"
}
```

| Case | `visibility` in body |
| ---- | -------------------- |
| **First publish** (`published_version == 0`) | **Required** — must be `"public"`. |
| **Republish** (`published_version > 0`) | Omit, or send exactly the stored value. A different value → **400** `cannot change visibility after publishing`. |

**Success (200):**

```json
{
  "data": {
    "published_version": 2,
    "visibility": "public"
  },
  "meta": {
    "msg": "published"
  }
}
```

**Server behavior:** Increments `published_version`, writes `deck:{id}:snapshot:v{N}`, copy-on-write versioned facts/media, updates deck `visibility` on first publish.

**Errors:**

| Status | Typical `msg` |
| ------ | ------------- |
| **400** | `first publish requires visibility public`, `invalid visibility`, `cannot change visibility after publishing`, `cannot publish an imported deck` |
| **403** | `Not authorized` |
| **404** | `Deck not found` |
| **409** | `no changes to publish` (working copy identical to previous snapshot) |

---

### Import a published deck

**Endpoint:** `POST /api/decks/import`

**Who:** Any authenticated user (need not own the source). Use [Deck catalog](#deck-catalog) to find a `source_deck_id`, or pass an ID you already know.

**Request body:**

```json
{
  "source_deck_id": "a1b2c3d4e5f6"
}
```

`source_deck_id` is required (empty → **400** `source_deck_id is required`).

**Success (201):**

```json
{
  "data": {
    "id": "z9y8x7w6v5u4",
    "source_deck_id": "a1b2c3d4e5f6",
    "source_version": 3,
    "imported_at": "2026-05-22T12:00:00.000000000Z"
  },
  "meta": {
    "msg": "imported"
  }
}
```

Use **`data.id`** as the import deck ID for study and for `GET/POST …/updates` and `…/sync`.

**Requirements on source:**

- Deck exists.
- `published_version > 0`.
- `visibility` is **`public`** (effective visibility).
- Source is not itself an import (`cannot import an imported deck`).
- Importer is not the source owner (`cannot import your own deck`).

**Errors:**

| Status | Typical `msg` |
| ------ | ------------- |
| **404** | `source deck not found` |
| **403** | `source deck is not importable`, `source deck has not been published`, `cannot import an imported deck`, `cannot import your own deck` |
| **400** | Other validation failures |

---

### Import update workflow (preview + apply)

After import, keep the deck aligned with the author's publishes using two endpoints on the same **`{importId}`**:

1. **`GET /api/decks/{importId}/updates`** — preview what changed (read-only diff from pinned `source_version` to the source's latest `published_version`).
2. **`POST /api/decks/{importId}/sync`** — apply those changes (mutates the import deck to the target snapshot).

**Typical flow:**

| Step | Action |
| ---- | ------ |
| 1 | `GET …/updates` — show `added_facts`, `removed_facts`, `edited_facts`, `media_changes`. |
| 2 | If `source_version == latest_version`, stop (already up to date; diff arrays are empty). |
| 3 | If the importer accepts, `POST …/sync` with an **empty body** or `{ "target_version": 0 }`. |

**You do not need to copy `latest_version` from the GET response into sync.** When `target_version` is omitted or `0`, the server advances the import deck to the source's current `published_version` (same value as `latest_version` in the updates response).

Pass **`target_version` explicitly** only when syncing to a **specific intermediate publish**, not the newest one — e.g. pinned at 3, author published 5, but you want version 4 only. Then send `{ "target_version": 4 }`. The value must satisfy `source_version < target_version <= source.published_version`. Note: `GET …/updates` always diffs pinned → **latest**; it does not preview a partial sync to an intermediate version.

---

### Get import updates (diff)

**Endpoint:** `GET /api/decks/{importId}/updates`

**Who:** Owner of an **import** deck.

**Request:** No body.

**Success (200):** Diff from the import’s pinned `source_version` to the source’s latest `published_version`.

```json
{
  "data": {
    "source_version": 3,
    "latest_version": 5,
    "added_facts": [{ "fact_id": "abcd1234" }],
    "removed_facts": [{ "fact_id": "efgh5678" }],
    "edited_facts": [
      {
        "fact_id": "ijkl9012",
        "before": { "id": "ijkl9012", "entries": [{ "text": "old" }, { "text": "old2" }] },
        "after": { "id": "ijkl9012", "entries": [{ "text": "new" }, { "text": "old2" }] }
      }
    ],
    "media_changes": [
      {
        "media_id": "pron123456",
        "before_hash": "sha256:abc…",
        "after_hash": "sha256:def…",
        "before_bytes": 12345,
        "after_bytes": 23456
      }
    ],
    "change_summary": ""
  },
  "meta": {
    "msg": "ok"
  }
}
```

When already up to date: `source_version == latest_version` and diff arrays are empty.

`edited_facts` lists only facts whose **versioned content** differs between snapshots (not every fact in the deck).

**Errors:**

| Status | Typical `msg` |
| ------ | ------------- |
| **400** | `updates are only available for imported decks`, or source missing |
| **403** | `Not authorized` |
| **404** | `Deck not found` |

---

### Sync an imported deck

**Endpoint:** `POST /api/decks/{importId}/sync`

**Who:** Owner of the import deck.

**Request body (optional):**

```json
{
  "target_version": 5
}
```

| Field | Behavior |
| ----- | -------- |
| Omitted or `0` | Advance to the source’s current `published_version`. **Default for the preview → sync workflow** — no need to pass `latest_version` from `GET …/updates`. |
| `target_version` | Must satisfy `source_version < target_version <= source.published_version`. Use only to land on a specific intermediate publish, not the newest. |

**Success (200):**

```json
{
  "data": {
    "source_version": 5
  },
  "meta": {
    "msg": "synced"
  }
}
```

**Server behavior:** Bumps pinned version; rebuilds import fact set from target manifest; removes importer cards for deleted facts; adds cards for new facts; updates `user:{importer}:readable_media_versions` grants. Also copies **`name`**, **`fields`**, and **`rate`** from the target snapshot manifest into the import deck row (overwriting any prior importer `rate` set via PATCH).

**Errors:**

| Status | Typical `msg` |
| ------ | ------------- |
| **400** | `not an imported deck`, `invalid target version`, … |
| **403** | `Not authorized` |
| **404** | `Deck not found` |

---

### Sharing: extended deck & fact behavior

#### PATCH deck on import decks

| Field | Import deck |
| ----- | ----------- |
| **`rate`** | **Required.** Only mutable deck field. Must be 1–1000. Changing rate restaggers **unseen** cards the same way as on source decks (see [Update a Deck](#update-a-deck)). |
| **`name`** | Locked to snapshot / sync. Must be **omitted** (non-empty value → **400** `cannot change name on an imported deck`). |
| **`fields`** | Locked. Must be **omitted** (non-empty array → **400** `cannot change fields on an imported deck`). |
| **`visibility`** | Not applicable. Non-empty value → **400** `cannot change visibility on an imported deck`. |

Omitting **`rate`** on an import deck PATCH → **400** `Rate is required for imported deck updates`.

#### Facts on import decks

| Method | Path | Import deck |
| ------ | ---- | ------------- |
| GET | `/api/decks/{id}/facts`, `…/facts/{factId}`, next-card | Snapshot `entries` from the pinned version. |
| POST / PATCH / DELETE | facts routes | **403** `cannot modify facts on an imported deck` |

#### Feedback (import → author)

| Method | Path | Who |
| ------ | ---- | --- |
| POST | `/api/decks/{importDeckId}/feedback` | Import deck owner. Body: `fact_id` (required), optional `category` (`translation` \| `audio` \| `typo` \| `other`, default `other`), `message` (required if `proposed_entries` omitted; 1–2000 chars), optional `entry_index`, optional `proposed_entries` (same shape as fact PATCH `entries`; must differ from snapshot). **201** returns `feedback_id`, `source_deck_id`, `fact_id`, `status`. **429** after 20 submissions per source deck per UTC day. |
| GET | `/api/decks/{sourceDeckId}/feedback` | Source deck owner only. Optional query: `status`, `fact_id`, `limit`, `offset`. |
| PATCH | `/api/decks/{sourceDeckId}/feedback/{feedbackId}` | Source deck owner. Body: `{ "status": "resolved" \| "dismissed" \| "open" }`. |
| POST | `/api/decks/{sourceDeckId}/feedback/{feedbackId}/accept` | Source deck owner. Requires `proposed_entries` on the feedback row. Updates author **working copy**. Author must still **POST /publish** and importers **POST /sync**. |

#### Cards on import decks

Same as a normal owned deck: `GET/POST/PATCH/DELETE` card routes work; scheduling and templates are importer-specific.

#### Media for importers

- Importers download author media via `GET /api/media/{id}` when `(media_id, version)` is granted in `user:{username}:readable_media_versions` (member format `mediaId@version`).
- Bytes are served from the **versioned** blob, not the author’s working copy.
- If multiple grants exist for the same `media_id`, use query **`?v=<version>`** (required when ambiguous).
- Importers cannot upload or delete another user’s working-copy media.

#### Tags on import decks

Tag associations are keyed by the **importer** (independent from the author). Fact tag mutations that imply editing read-only fact bodies may still be restricted; see tag routes in [§4 Tags](#4-tags).

---

## 3. Facts

### Add Facts

**Endpoint:** `POST /api/decks/{id}/facts/{operation}`

> **Imported decks:** **403** `cannot modify facts on an imported deck`. Use [Sync an imported deck](#sync-an-imported-deck) to accept new content from the author.

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)
- `operation`: `append`

**Request Body:** An object with a required **`facts`** array and optional **`template`**. Each fact item has required **`entries`** and optional **`tags`** or **`tag_ids`** (not both on the same item). Each **entry** is an object with optional `text`, `audio`, `image`, `video`, `json` (at least one content field required across the fact). **`fields` are not sent per fact** — use **`GET /api/decks/{id}`** (or PATCH the deck) for the deck’s `fields` list; that list supplies labels when studying (e.g. next-card `field` on each entry). The server generates a unique fact ID for each fact and creates one or more **cards** per fact depending on `template` (see **Template: default and sibling cards** below).

#### Optional tags (per fact)

Each element of **`facts`** may include optional tags in **one** of two forms on that item (not both):

| Field | Type | Use when |
|-------|------|----------|
| **`tags`** | tag **names** (`string[]`) | Bulk import / scripts — missing names are auto-created |
| **`tag_ids`** | existing tag **IDs** (`string[]`) | TagPicker UI — tags must already exist (`POST /api/tags`) |

Omit both fields or use `[]` for facts that should have no tags. Sending **`tags` and `tag_ids` on the same fact item** → **400** `provide either tags or tag_ids, not both`.

##### `tags` (names)

| Behavior | Detail |
|----------|--------|
| **Scope** | Tags apply **per fact** in the batch (fact A can have tags while fact B has none). |
| **Validation** | Same name rules as [`POST /api/tags`](#create-a-tag) (letters, numbers, spaces, `-`, `'`; max 50 characters). Invalid names → **400**. |
| **Reuse** | If a name already exists for your user (after normalization), that tag is reused. |
| **Create** | Missing names are auto-created for your user, then linked to the new fact. Counts toward the **1000 tags per user** limit. Distinct fact tags across the deck (union of all facts) capped at **200** → **400** `maximum fact tags per deck reached`. |
| **Dedup** | Duplicate names on the **same** fact (e.g. `"Noun"` and `" noun "`) are collapsed to one association. |

##### `tag_ids` (existing IDs)

| Behavior | Detail |
|----------|--------|
| **Validation** | Each id must be non-empty; unknown id → **404** `tag not found`. |
| **Ownership** | Tag must belong to the current user. |
| **Create** | Never auto-creates tags. |
| **Dedup** | Duplicate ids on the **same** fact collapse to one association. |

##### Both forms

| Behavior | Detail |
|----------|--------|
| **Storage** | Tags are **not** embedded in the fact JSON in Redis; associations are stored separately and returned on GET. |
| **Add response** | `POST …/facts/{operation}` returns only `fact_length` — **not** tag objects. Use [`GET /api/decks/{id}/facts`](#get-all-facts) or [Get one fact](#get-one-fact) to read tags after create. |
| **Update** | [`PATCH /api/decks/{id}/facts/{factId}`](#update-a-fact) does **not** accept `tags` or `tag_ids`; add or remove tags with the [fact tag `PUT`/`DELETE`](#associate-a-tag-with-a-fact) routes or tag at create time. |

```json
{
  "facts": [
    { "entries": [{ "text": "Apple" }, { "text": "りんご" }], "tags": ["food", "noun"] },
    { "entries": [{ "text": "Book" }, { "text": "本" }] },
    { "entries": [{ "text": "Water" }, { "text": "水" }], "tags": ["noun"] },
    { "entries": [{ "text": "School" }, { "text": "学校" }] }
  ]
}
```

Example with media and multiple example sentences (each with its own audio). Put this object inside `"facts": [ … ]` in the full request. Ensure the deck’s `fields` (via **`PATCH /api/decks/{id}`**) has **seven** names in the same order as these seven entries so labels match when you study.

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
  ]
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
{
  "template": [
    [[0], [1, 2]],
    [[1], [0, 2]],
    [[2], [0, 1]]
  ]
}
```

So: **2D** = one card (one front/back split); **3D** = multiple cards per fact (sibling cards). If you send a single 2D template (e.g. `[[1], [0]]` for reversed only), the API also accepts it: it is treated as an array of one template, so every fact gets one reversed card.

Example — every fact gets two sibling cards (normal and reversed):

```json
{
  "template": [
    [[0], [1]],
    [[1], [0]]
  ]
}
```

Each fact gets one card with front=0/back=1 and one with front=1/back=0. To add a reversed card only for some facts, add those extra cards later with `POST /api/decks/{id}/card`.

> **Understanding the request:**
>
> - **`entries`**: Array of entry objects. Each entry has optional `text`, `audio`, `image`, `video`, `json` (at least one entry in the fact must have content). Entry index `i` lines up with **`deck.fields[i]`** for display labels when studying (see **Get Next Urgent Card**). Putting text and audio in the same entry (e.g. `{ "text": "I go to school.", "audio": "ex1id" }`) keeps that audio clearly associated with that sentence.
> - **`tags`** (optional, per fact): Array of tag **name** strings. Omit for untagged facts. See [Optional tags (per fact)](#optional-tags-per-fact) above.
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

The add-facts response does **not** echo created fact IDs or tag assignments. After a successful create, call **GET** facts (or GET one fact) if you need `id` and `tags` on each fact.

### Get all facts

**Endpoint:** `GET /api/decks/{id}/facts`

**Query parameters (optional):** `limit` (default **50**, max **200**) and `offset` (default **0**). Omitted keys use those defaults; **`meta` echoes `limit` and `offset`** together with `count`, `has_more`, and `total` (deck fact count).

| Name | Description |
|------|-------------|
| `limit` | Page size. Invalid or non-positive values → default **50**; above max → **200**. |
| `offset` | Facts to skip after stable sort by fact **`id`**. Negative → **0**. |

**Request example** (first page; omit query string to use default `limit` and `offset`):

```http
GET /api/decks/{id}/facts?limit=50&offset=0
Authorization: Bearer <token>
```

**Response example** (two facts on first page; same `meta` shape when `limit`/`offset` are omitted from the URL):

```json
{
  "data": {
    "facts": [
      {
        "id": "x9k2m4np",
        "entries": [{ "text": "Apple" }, { "text": "りんご" }],
        "tags": [
          { "id": "a1b2c3d4", "name": "food", "description": "" },
          { "id": "f6e5d4c3", "name": "noun", "description": "Parts of speech" }
        ]
      },
      {
        "id": "b00k1ab2",
        "entries": [{ "text": "Book" }, { "text": "本" }],
        "tags": []
      }
    ]
  },
  "meta": {
    "msg": "Facts retrieved successfully",
    "count": 2,
    "has_more": false,
    "limit": 50,
    "offset": 0,
    "total": 2
  }
}
```

Each fact always includes **`tags`**: an array of `{ "id", "name", "description" }` objects (empty array when none). A fact can have **many** tags; the list is sorted by **tag name** in list/detail responses. Tags are not stored inside the fact record in Redis; the API resolves them from per-user association keys. **Column labels are not returned on each fact** — use the deck’s **`fields`** from **`GET /api/decks/{id}`** (same order as `entries` indices).

### Get one fact

**Endpoint:** `GET /api/decks/{id}/facts/{factId}`

**Response:**

```json
{
  "data": {
    "fact": {
      "id": "x9k2m4np",
      "entries": [{ "text": "Apple" }, { "text": "りんご" }],
      "tags": [
        { "id": "a1b2c3d4", "name": "food", "description": "" },
        { "id": "f6e5d4c3", "name": "noun", "description": "Parts of speech" }
      ]
    }
  },
  "meta": { "msg": "Fact retrieved successfully" }
}
```

### Update a fact

**Endpoint:** `PATCH /api/decks/{id}/facts/{factId}`

**Parameters:** `id` (deck ID), `factId` (fact ID from GET facts or add-facts).

**Request Body:** Optional **`entries`** only — array of entry objects with optional `text`, `audio`, `image`, `video`, `json`. When provided, it replaces the fact’s entries. To rename or reorder **column labels**, use **`PATCH /api/decks/{id}`** with a new `fields` array (not this endpoint).

> **Imported decks:** **403** `cannot modify facts on an imported deck`. Use [Sync an imported deck](#sync-an-imported-deck) to accept new content from the author, or `POST …/feedback` to propose corrections to the author.

```json
{
  "entries": [{ "text": "Apple" }, { "text": "りんご" }]
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

> **Imported decks:** **403** `cannot modify facts on an imported deck`.

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

## 4. Tags

Tags are **per user**: you create them with `POST /api/tags`, then attach them to **decks** and/or **facts** with `PUT` routes (no JSON body on those `PUT`s). You can also pass optional **`tags`** (name strings) in the same request when:

- **[Creating a deck](#create-a-deck)** (`POST /api/decks`) — see [Optional tags (on create)](#optional-tags-on-create).
- **[Adding facts](#add-facts)** (`POST /api/decks/{id}/facts/{operation}`) — optional `tags` on each fact item; see [Optional tags (per fact)](#optional-tags-per-fact).

The server creates missing tags and links them in that request. Same tag can label many decks and many facts. For key layout and naming rules, see **[Tagging system design doc](tagging-system.md)**.

**Limits:** up to **1000** distinct tags per user; up to **100** deck-level tags per deck; up to **200** distinct fact tags per deck (union across all facts in that deck). Tag **names** allow Unicode letters and numbers, spaces, hyphen (`-`), and apostrophe (`'`); leading/trailing space is trimmed and internal runs of spaces collapse to one. Uniqueness is enforced on a **normalized** form (trim → collapse spaces → lowercase). **`tag_id`** is 8 lowercase alphanumeric characters.

Errors use `{ "msg": "..." }` (e.g. **409** `tag name already exists`, **400** validation or limits).

### Create a tag

**Endpoint:** `POST /api/tags`

```json
{
  "name": "Food Recipes",
  "description": "Cooking vocabulary"
}
```

**Response (201):**

```json
{
  "data": {
    "tag": {
      "id": "Kt8QmNz2",
      "name": "Food Recipes",
      "description": "Cooking vocabulary"
    }
  },
  "meta": { "msg": "Tag created successfully" }
}
```

### List your tags

**Endpoint:** `GET /api/tags`

Returns every tag you own (up to 1000). Order follows **sorted tag id** (not alphabetical by name)—sort client-side by `name` if you need that.

Each list item includes **usage metadata** (additive; older clients can ignore these fields):

| Field | Type | Description |
|-------|------|-------------|
| `deck_count` | int | Number of decks this tag is associated with |
| `fact_count` | int | Number of facts (across all your decks) with this tag |
| `used_on` | string[] | `"deck"` if `deck_count > 0`; `"fact"` if `fact_count > 0`; `[]` if the tag has no associations yet |

`POST /api/tags`, `GET /api/tags/{tagId}`, and deck/fact association responses still return only `{ id, name, description }`.

**Response:**

```json
{
  "data": {
    "tags": [
      {
        "id": "Kt8QmNz2",
        "name": "GRE",
        "description": "",
        "deck_count": 2,
        "fact_count": 0,
        "used_on": ["deck"]
      },
      {
        "id": "p4q5r6s7",
        "name": "verb",
        "description": "Part of speech",
        "deck_count": 0,
        "fact_count": 48,
        "used_on": ["fact"]
      },
      {
        "id": "z9y8x7w6",
        "name": "Japanese",
        "description": "JLPT prep",
        "deck_count": 1,
        "fact_count": 12,
        "used_on": ["deck", "fact"]
      },
      {
        "id": "a1b2c3d4",
        "name": "new-tag",
        "description": "",
        "deck_count": 0,
        "fact_count": 0,
        "used_on": []
      }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### List tags for deck or fact pickers

Use the optional **`used_on`** query parameter when building a tag search/autocomplete for **decks** or **facts**. Tags are still one shared library per user; this filter only narrows the list for UI.

| Request | Purpose |
|---------|---------|
| `GET /api/tags` | Tag management — show all tags |
| `GET /api/tags?used_on=deck` | Deck picker (user-wide: any deck + unused) |
| `GET /api/tags?used_on=deck&deck_id={id}` | Deck picker scoped to one deck (optional) |
| `GET /api/tags?used_on=fact&deck_id={id}` | Fact picker (**deck_id required**) — tags on facts in that deck + unused |

`deck_id` is **required** when `used_on=fact`. Omitting `deck_id` with `used_on=fact` returns **400**. `used_on=deck` without `deck_id` remains user-wide (backward compatible).

**Filter rules:**

| `used_on` | Tag is included when… |
|-----------|------------------------|
| *(omitted)* | Always (no filter) |
| `deck` | `deck_count > 0`, **or** the tag is unused (`deck_count === 0` and `fact_count === 0`) |
| `fact` | Tag is on a fact in the given deck (`deck_id` required), **or** the tag is unused |

- **Deck-only** tags appear in `?used_on=deck` but not `?used_on=fact`.
- **Fact-only** tags appear in `?used_on=fact&deck_id={id}` for the deck where those facts live, not in user-wide lists (`used_on=fact` without `deck_id` is rejected).
- **Unused** tags (created via `POST /api/tags` but not yet linked) appear in **both** filters until first association.

**Invalid filter** — e.g. `GET /api/tags?used_on=invalid` → **400**:

```json
{ "msg": "invalid used_on filter" }
```

**Example (deck picker):**

```http
GET /api/tags?used_on=deck HTTP/1.1
Authorization: Bearer <token>
Accept: application/json
```

**Listing tags on a specific deck or fact** still uses scoped routes (no `used_on` query):

| Goal | Endpoint |
|------|----------|
| Tags on one deck | `GET /api/decks/{id}/tags` |
| Tags on one fact | `GET /api/decks/{id}/facts/{factId}/tags` |
| All facts with a tag (cross-deck) | `GET /api/tags/{tagId}/facts` |
| Facts with nested `tags` (bulk) | `GET /api/decks/{id}/facts` |

### Get one tag

**Endpoint:** `GET /api/tags/{tagId}`

**Response:** `{ id, name, description }` under `data.tag`, with `meta.msg`. Usage fields (`deck_count`, `fact_count`, `used_on`) are only on `GET /api/tags` list items.

### Update a tag

**Endpoint:** `PATCH /api/tags/{tagId}`

Optional fields (omit what you do not want to change):

```json
{
  "name": "Renamed Tag",
  "description": "Updated note"
}
```

**Response:** `data.tag` with the updated tag.

### Delete a tag

**Endpoint:** `DELETE /api/tags/{tagId}`

Removes the tag, its name index entry, and all **deck** and **fact** associations for that tag.

**Response:**

```json
{
  "data": { "decks_untagged": 3 },
  "meta": { "msg": "Tag deleted successfully" }
}
```

(`decks_untagged` counts decks that had this tag on the forward index before deletion.)

### Associate a tag with a deck

**Endpoint:** `PUT /api/decks/{id}/tags/{tagId}`

No request body. Requires you to own the deck and the tag. Idempotent if already associated.

**Response:** `data.tags` is the **full** set of tags on the deck **after** this association (same shape as `GET /api/decks/{id}/tags`). Example after adding one tag when the deck already had two others:

```json
{
  "data": {
    "tags": [
      { "id": "a1b2c3d4", "name": "GRE", "description": "" },
      { "id": "m9n8p7q6", "name": "Verbal", "description": "" },
      { "id": "Kt8QmNz2", "name": "Vocabulary", "description": "Core words" }
    ]
  },
  "meta": { "msg": "Tags updated successfully" }
}
```

### Remove a tag from a deck

**Endpoint:** `DELETE /api/decks/{id}/tags/{tagId}`

**Response:** same envelope as the PUT above (`data.tags` = tags remaining on the deck).

### List tags on a deck

**Endpoint:** `GET /api/decks/{id}/tags`

**Response:** same `data.tags` array as PUT/DELETE. Example with multiple tags on one deck:

```json
{
  "data": {
    "tags": [
      { "id": "a1b2c3d4", "name": "GRE", "description": "" },
      { "id": "m9n8p7q6", "name": "Verbal", "description": "" },
      { "id": "Kt8QmNz2", "name": "Vocabulary", "description": "Core words" }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### Associate a tag with a fact

**Endpoint:** `PUT /api/decks/{id}/facts/{factId}/tags/{tagId}`

No body. The tag must already exist (`POST /api/tags`). Fact must belong to the deck.

**Response:** full tag list for that fact after the `PUT` (multiple tags possible):

```json
{
  "data": {
    "tags": [
      { "id": "Kt8QmNz2", "name": "verb", "description": "Part of speech" },
      { "id": "r5s6t7u8", "name": "hard", "description": "" }
    ]
  },
  "meta": { "msg": "Tags updated successfully" }
}
```

### Remove a tag from a fact

**Endpoint:** `DELETE /api/decks/{id}/facts/{factId}/tags/{tagId}`

**Response:** same as PUT (`data.tags` for that fact).

### List tags on a fact

**Endpoint:** `GET /api/decks/{id}/facts/{factId}/tags`

**Response:** same `data.tags` shape (optional lightweight alternative to loading the full fact). Example with two tags:

```json
{
  "data": {
    "tags": [
      { "id": "Kt8QmNz2", "name": "verb", "description": "Part of speech" },
      { "id": "r5s6t7u8", "name": "hard", "description": "" }
    ]
  },
  "meta": { "msg": "Tags retrieved successfully" }
}
```

### List facts that have a tag

**Endpoint:** `GET /api/tags/{tagId}/facts`

**Response:** every fact (across your decks) that has this tag—multiple rows are common:

```json
{
  "data": {
    "facts": [
      { "deck_id": "dk7xm2n9pq4w", "fact_id": "f4k2m9x1" },
      { "deck_id": "dk7xm2n9pq4w", "fact_id": "n3p4q5r6" },
      { "deck_id": "ab12cd34ef56", "fact_id": "s7t8u9v0" }
    ]
  },
  "meta": { "msg": "Facts retrieved successfully" }
}
```

---

## 5. Cards

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

**Query (optional):**

| Query    | Description |
|----------|-------------|
| `tag_id` | Tag ID. When provided, next-card selection only considers cards whose `fact_id` belongs to facts tagged with this tag in the same deck. |

Example: `GET /api/decks/{id}/card?tag_id=Kt8QmNz2`

**Parameters:**

- `id`: `a1b2c3d4e5f6` (your deck ID)

**Response shape:** `front` and `back` are arrays of **entry objects** in **template order** (one object per fact entry index on that side). Each object matches a fact **entry**: optional **`field`** (label) and optional **`text`**, **`audio`**, **`image`**, **`video`**, **`json`** string keys (omitted when empty). When present, **`field`** comes from the deck’s **`fields`** list (`fields[i]` for entry index `i`); if the deck has fewer names than entries, some objects may omit `field`. Text and its pronunciation clip are explicit siblings on the same object (e.g. `"text": "Hello"` and `"audio": "https://.../api/media/…"`). For media keys, values are **full media URLs** when the server can determine a base URL. Use each URL with the same `Authorization: Bearer <token>` to download the file.

Each JSON example below has a matching integration test in [`api/tests/integration/card_test.go`](../api/tests/integration/card_test.go): `TestGetNextCard` (with field names from the deck) and `TestNextCardUrgencySelection` (no field names when deck labels are missing/short, text+audio+image, multi-front, front-only, split template `[[0,1],[2,3]]`, and full URL host).

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
      "front": [{ "text": "Apple" }],
      "back": [{ "text": "苹果" }]
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
      "front": [{ "field": "Word", "text": "Apple" }],
      "back": [{ "field": "Translation", "text": "苹果" }]
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
      "back": [{ "field": "Translation", "text": "你好" }]
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
      "back": [{ "field": "Translation", "text": "翻译" }]
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
      "front": [{ "field": "Question", "text": "Only front text" }],
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
      "template": [
        [0, 1],
        [2, 3]
      ],
      "last_review": 1763269700,
      "due_date": 1763269800,
      "hidden": false,
      "created_at": 1763269600,
      "front": [
        { "field": "Front", "text": "Word" },
        {
          "field": "Pronunciation",
          "audio": "https://api.retentio.app:8443/api/media/abc123"
        }
      ],
      "back": [
        {
          "field": "Picture",
          "image": "https://api.retentio.app:8443/api/media/def456"
        },
        {
          "field": "Clip",
          "video": "https://api.retentio.app:8443/api/media/vid789",
          "text": "Translation"
        }
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

**Query (optional):**

| Query    | Description |
|----------|-------------|
| `tag_id` | Tag ID. When provided, only cards whose `fact_id` belongs to facts tagged with this tag **in the same deck** are included in `stats`, counts, and lists. `stats.facts_count` is the number of tagged facts in this deck (not the full deck fact count). |

Example: `GET /api/decks/{id}/cards?tag_id=Kt8QmNz2`

**Response:**

`data.stats` uses the same shape as `GET /api/decks/{id}` (`cards_count`, `facts_count`, `unseen_cards`, `reviewed_cards`, `due_cards`, `hidden_cards`, `new_cards_today`, `last_reviewed_at`, optional `orphaned_hidden_cards`). Without `tag_id`, `stats` match `GET /api/decks/{id}` for the same deck; with `tag_id`, stats cover only cards for facts tagged in that deck. Response also includes `cards` (full card array).

```json
{
  "data": {
    "stats": {
      "cards_count": 20,
      "facts_count": 15,
      "unseen_cards": 5,
      "reviewed_cards": 15,
      "due_cards": 7,
      "hidden_cards": 3,
      "new_cards_today": 2,
      "last_reviewed_at": 1710000000,
      "orphaned_hidden_cards": 1
    },
    "cards": [
      {
        "id": "cd1ef2gh",
        "fact_id": "h1d2e3n4",
        "template": [[0], [1]],
        "last_review": 1710000000,
        "due_date": 1710500000,
        "hidden": true,
        "created_at": 1709000000
      }
    ]
  },
  "meta": { "msg": "Card stats retrieved successfully" }
}
```

---

## 6. Media (Audio / Images)

You can attach audio, images, and video to facts. Each **entry** object uses string values for media IDs on keys `audio`, `image`, `video`, and `json` (not bracket markers in JSON).

**Size limits:** Images max **5 MB**; audio and video max **200 MB** each. Env overrides: `MEDIA_MAX_SIZE_IMAGE`, `MEDIA_MAX_SIZE_VIDEO`, `MEDIA_MAX_SIZE_AUDIO`.

**Formats:** Supported input: image (JPEG, PNG, GIF, HEIC, HEIF, WebP), audio (MPEG/MP3, WAV, OGG, MP4/AAC), video (MP4, QuickTime, WebM), and JSON (`application/json`). Files are stored as uploaded without transcoding. Download returns the stored file (binary).

### Upload media

**Endpoint:** `POST /api/media` — multipart/form-data.

| Field       | Required | Description                                                                                                                            |
| ----------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `file`      | Yes      | The media file (image, audio, or video).                                                                                               |
| `client_id` | No       | Client-generated ID for idempotent upload; if the media already exists for this user, the server returns 201 with the existing record. |

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

| Query    | Description                                                                   |
| -------- | ----------------------------------------------------------------------------- |
| `since`  | Optional. Unix timestamp (number); return only media created after this time. |
| `limit`  | Optional. Max items (default 50, max 200).                                    |
| `offset` | Optional. Number of items to skip (default 0).                                |

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

Returns metadata only (id, owner, filename, mime, size, checksum, created_at), no file body. **Owners** receive working-copy metadata. **Importers** with a deck-sharing grant receive **versioned** snapshot metadata (same grant and **`?v=`** rules as download).

### Download media

**Endpoint:** `GET /api/media/{id}`

Returns the media file (binary) for user-owned media by ID. Requires `Authorization: Bearer <token>`. Response headers include `Content-Type`, `Content-Length`, and `ETag` (same as `checksum`). Send `If-None-Match: <ETag>` to get `304 Not Modified` when the file is unchanged. The **Get Next Card** response puts full URLs in the `audio`, `image`, and `video` fields of each front/back entry (e.g. `https://api.retentio.app:8443/api/media/{id}`); use that URL with the same auth header to load the file.

**Deck sharing (importers):** If you imported a deck, you may download the author’s media when your account has a grant `mediaId@version` from that snapshot. The server serves **versioned** bytes. Append **`?v=<version>`** when the API returns multiple possible versions for the same `media_id` (some fact responses include `?v=` on media URLs automatically).

### Delete media

**Endpoint:** `DELETE /api/media/{id}`

**Response:**

```json
{
  "data": { "msg": "media deleted" }
}
```

### Using media in facts

Each entry is an object with optional `text`, `audio`, `image`, `video`. Use a dedicated entry for media (e.g. `{ "audio": "abc123" }`) or combine with text in one entry (e.g. `{ "text": "Example sentence.", "audio": "ex1id" }`) so the audio is clearly for that sentence. Use optional `template` for custom front/back layout per fact; omit for default (front = first entry, back = rest).

For full design (upload, delete, display, sync), see **[Media Upload design doc](media-upload.md)**.

---

## Response examples reference

| Endpoint                                      | Method      | Response shape                                                                                                                                             |
| --------------------------------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/auth/register`                              | POST        | `{ "data": { … }, "meta": { "msg": "..." } }` — see [Create a User](#create-a-user)                                                                        |
| `/auth/login`                                 | POST        | `{ "data": { "token", "expires" }, "meta": { "expires" } }`                                                                                                |
| `/auth/logout`                                | POST        | `{ "data": { "msg": "Logged out successfully" }, "meta": null }`                                                                                           |
| `/auth/forgot-password`                       | POST        | `{ "data": { "reset_token" }, "meta": { "expires_in" } }`                                                                                                  |
| `/auth/reset-password`                        | POST        | `{ "data": { "msg": "Password reset successfully" }, "meta": null }`                                                                                       |
| `/api/profile`                                | GET         | `{ "data": { user profile }, "meta": { "msg" } }`                                                                                                          |
| `/api/decks`                                  | POST        | `{ "data": { "deck_id" }, "meta": { "msg" } }`                                                                                                             |
| `/api/decks`                                  | GET         | `{ "data": { "decks": [ … ] }, "meta": { "total", "msg" } }`                                                                                               |
| `/api/decks/{id}`                             | GET         | `{ "data": { deck + stats }, "meta": { "msg" } }`                                                                                                          |
| `/api/decks/{id}`                             | PATCH       | `{ "data": { "deck_id" }, "meta": { "msg", "updated_at" } }`                                                                                               |
| `/api/decks/{id}`                             | DELETE      | `{ "data": { "deck_id" }, "meta": { "msg" } }`                                                                                                             |
| `/api/decks/{id}/facts/{op}`                  | POST        | Add facts: body `facts[]` with optional `tags` (names) per item; `{ "data": { "fact_length" }, "meta": { "msg" } }` (no tags in response)                  |
| `/api/decks/{id}/card`                        | POST        | Add card from existing fact: `{ "data": { "card_id" }, "meta": { "msg" } }`                                                                                |
| `/api/decks/{id}/facts`                       | GET         | `{ "data": { "facts": [ … ] }, "meta": { "msg", "count", "has_more", "limit", "offset", "total" } }` — defaults `limit` 50, `offset` 0 |
| `/api/decks/{id}/facts/{factId}`              | GET         | `{ "data": { "fact": { …, "tags": [ … ] } }, "meta": { "msg" } }`                                                                                          |
| `/api/decks/{id}/facts/{factId}`              | PATCH       | `{ "data": { "fact_id" }, "meta": { "msg" } }`                                                                                                             |
| `/api/decks/{id}/facts/{factId}`              | DELETE      | `{ "data": { "fact_id" }, "meta": { "msg" } }`                                                                                                             |
| `/api/decks/{id}/card`                        | GET         | Optional query `tag_id`. Response shape unchanged: `{ "data": { "card": { id, fact_id, template, …, front[], back[] }, "urgency" }, "meta": { "msg", … } }` |
| `/api/decks/{id}/card`                        | PATCH       | Interval: `{ "data": { "last_review", "due_date", "new_interval" }, "meta": { "msg" } }`; visibility: `{ "data": { "hidden_status" }, "meta": { "msg" } }` |
| `/api/decks/{id}/cards`                       | GET         | Optional query `tag_id`. `{ "data": { "stats": { … }, "cards": [ … ] }, "meta": { "msg" } }` |
| `/api/decks/{id}/cards/{cardId}`              | DELETE      | `{ "data": { "card_id" }, "meta": { "msg" } }`                                                                                                             |
| `/api/decks/{id}/reschedule`                  | POST        | `{ "data": { "cards_shifted", "days", "max_days_away" }, "meta": { "msg" } }`                                                                              |
| `/api/decks/catalog`                          | GET         | `{ "data": { "decks": [ … ] }, "meta": { "msg", "count", "total", "limit", "offset", "has_more" } }` — defaults `limit` 50, `offset` 0; optional `query` |
| `/api/decks/catalog/{id}`                     | GET         | `{ "data": { "id", "name", "description", "owner", "fields", "published_version", "fact_count", "deck_tag_names", "published_at" }, "meta": { "msg" } }` — one catalog row; **404** if not importable |
| `/api/decks/import`                           | POST        | **201** — `{ "data": { "id", "source_deck_id", "source_version", "imported_at" }, "meta": { "msg" } }`                                                    |
| `/api/decks/{id}/publish`                     | POST        | `{ "data": { "published_version", "visibility" }, "meta": { "msg": "published" } }`                                                                      |
| `/api/decks/{id}/updates`                     | GET         | `{ "data": { "source_version", "latest_version", "added_facts", "removed_facts", "edited_facts", "media_changes" }, "meta": { "msg" } }`                   |
| `/api/decks/{id}/sync`                        | POST        | `{ "data": { "source_version" }, "meta": { "msg": "synced" } }`                                                                                            |
| `/api/tags`                                   | POST        | `{ "data": { "tag": { id, name, description } }, "meta": { "msg" } }` — **201**                                                                            |
| `/api/tags`                                   | GET         | `{ "data": { "tags": [ { id, name, description, deck_count, fact_count, used_on } ] }, "meta": { "msg" } }` — optional `used_on=deck` or `used_on=fact&deck_id={id}` |
| `/api/tags/{tagId}`                           | GET         | `{ "data": { "tag": { … } }, "meta": { "msg" } }`                                                                                                          |
| `/api/tags/{tagId}`                           | PATCH       | `{ "data": { "tag": { … } }, "meta": { "msg" } }`                                                                                                          |
| `/api/tags/{tagId}`                           | DELETE      | `{ "data": { "decks_untagged" }, "meta": { "msg" } }`                                                                                                      |
| `/api/tags/{tagId}/facts`                     | GET         | `{ "data": { "facts": [ { "deck_id", "fact_id" }, … ] }, "meta": { "msg" } }`                                                                              |
| `/api/decks/{id}/tags/{tagId}`                | PUT, DELETE | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                         |
| `/api/decks/{id}/tags`                        | GET         | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                         |
| `/api/decks/{id}/facts/{factId}/tags/{tagId}` | PUT, DELETE | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                         |
| `/api/decks/{id}/facts/{factId}/tags`         | GET         | `{ "data": { "tags": [ … ] }, "meta": { "msg" } }`                                                                                                         |
| `/api/media`                                  | POST        | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }`                                                                 |
| `/api/media`                                  | GET         | `{ "data": [ MediaSwagger, … ], "meta": { "count", "has_more" } }`                                                                                         |
| `/api/media/{id}/meta`                        | GET         | `{ "data": { id, owner, filename, mime, size, checksum, created_at }, "meta": { "msg" } }`                                                                 |
| `/api/media/{id}`                             | GET         | Download media (binary)                                                                                                                                    |
| `/api/media/{id}`                             | DELETE      | `{ "data": { "msg": "media deleted" } }`                                                                                                                   |

Full JSON examples for each are in the sections above.

---

## Next Steps

- Share decks with **[Deck sharing](#deck-sharing-overview)** (publish → import → review updates → sync)
- Organize content with **[Tags](#4-tags)** (deck- and fact-level associations)
- Keep reviewing cards by repeating the **Get Next Urgent Card** and **Review a Card** steps in [Cards](#5-cards)
- **Offline sync** — sync data when back online (planned)
- **Local storage** — cache decks and cards for offline use (planned)
