# Frontend–Backend Code Review

Review of the Flutter frontend against the Go backend API to ensure strict alignment.

## Summary

- **Critical issues**: 2 (fixed in this pass)
- **Minor / optional**: 4
- **Correct**: Auth, profile, decks (after fix), facts, cards, media (core), response parsing

---

## 1. Response Format

- **Backend**: Success = `{ "data": <payload>, "meta": <object> }`; Error = `{ "msg": "<string>" }`. No `code` field.
- **Frontend**: `ResBaseModel.fromJson` treats success as `data != null` and defaults `code` to 0 when data is present; `msg` from `msg` or `message`. **Correct.**
- **Fix applied**: `DioClient._handleError` previously passed `e.response?.data` (a Map for JSON errors) into `ResBaseModel(msg: ...)`, so backend error messages were not shown. It now extracts `msg` or `message` from the response body when present.

---

## 2. Auth

| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST /auth/register | body: username, password, email | body: email, username, password | OK |
| POST /auth/login | body: username, password; response data.token | Stores `(data as Map)['token']` | OK |
| POST /auth/logout | no body | no body | OK |
| POST /auth/forgot-password | body: email | body: email | OK |
| POST /auth/reset-password | body: token, new_password | body: token, new_password | OK |

---

## 3. Profile

- **Backend**: GET /api/profile → data: `{ username, email }`, meta: `created_at`.
- **Frontend**: Api.profile, ProfileNotifier uses `User.fromJson(res.data)` with username, email. **Correct.**

---

## 4. Decks

| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST /api/decks | body: **name**, **fields** (min 2), rate? (1–1000) | Was sending name, templates, rate; **fields** was commented out | **Fixed** |
| GET /api/decks | data.decks[]; each deck has **field** (not fields) in list response | Deck.fromJson uses `json['fields'] ?? json['field']` | OK |
| GET /api/decks/{id} | data: id, name, owner, **field**, rate, stats, created_at, updated_at | Same compatibility | OK |
| PATCH /api/decks/{id} | body: name?, fields?, rate? (fields length must match if sent) | Sends same params as create | OK after create fix |
| DELETE /api/decks/{id} | — | pathParams id | OK |

### Fixes applied

- Create/update deck payload now sends **name**, **fields**, **rate** only (no `templates`; backend derives templates from fields).
- Client-side validation: at least two fields required before submit.

---

## 5. Facts

| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST .../facts/{operation} | body: facts + template? (append/prepend/shuffle/spread) or fact_id + template [[front],[back]] (add_card; 400 if duplicate) | addFacts(...) / addCardForFact(deckId, factId, template: [[1],[0]]) | OK |
| GET .../facts | data.facts | data['facts'] → Fact.fromJson | OK |
| GET .../facts/{factId} | data.fact | data['fact'] → Fact.fromJson | OK |
| PATCH .../facts/{factId} | body: entries?, fields? | updateFact(deckId, factId, params) | OK |
| DELETE .../facts/{factId} | — | delete(Api.fact, pathParams) | OK |

Fact model: backend uses `entries` (required) and `fields` (optional). Frontend Fact.fromJson accepts `entries` or `fields`. **Correct.**

---

## 6. Cards

| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| GET .../card | data: { card, urgency } | CardDetail.fromJson(data) | OK |
| PATCH .../card | body: **card_id** required; either (**interval** + **last_review**) OR **hidden** (not both) | updateCard(deckId, { card_id, interval?, last_review?, hidden? }) | OK |
| GET .../cards | data: total_cards, hidden_count, hidden_facts, orphaned_hidden_cards? | CardStats.fromJson; orphaned_hidden_cards optional | OK |
| DELETE .../cards/{cardId} | — | pathParams id, cardId | OK |
| POST .../reschedule | body: days (1–365) | body: { days } | OK |

Card PATCH: frontend sends exactly one of (interval+last_review) or hidden, plus card_id, matching backend. **Correct.**

---

## 7. Media

| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST /api/media | multipart: file, optional client_id | uploadFile with filePath; **client_id not sent** | Minor gap |
| GET /api/media | query: since?, limit?, offset?; data: array, meta: count, has_more | list(since, limit, offset); res.data as List | OK |
| GET /api/media/{id} | binary body | getImageUint8ListFrom(path) | OK |
| DELETE /api/media/{id} | — | pathParams id | OK |

- **GET /api/media/{id}/meta**: backend exists; frontend does not call it. Optional if metadata-only is needed later.
- **GET /api/media/shared** and **GET /api/media/shared/{id}**: backend exists; frontend has no shared-media flow. OK to omit until feature is implemented.
- **MediaItem.created_at**: backend sends int64 (unix); frontend `(json['created_at'] as num?)?.toInt()`. **Correct.**

**Optional**: Use `Api.mediaById.replaceAll('{id}', mediaId)` in `MediaService.download` instead of hardcoding `/api/media/$mediaId` for consistency.

---

## 8. Paths and Constants

- **Api** (api.dart): All paths match backend (auth, profile, decks, card, cards, cardById, reschedule, facts, factsWithOperation, fact, media, mediaById). **Correct.**
- **Path params**: ApiService passes pathParams to DioClient; placeholders `{id}`, `{cardId}`, `factId`, `operation` are replaced. **Correct.**

---

## 9. Models vs Backend

- **Deck**: Backend list uses `field`; single deck uses `field`. Frontend uses `fields` ?? `field` and optional `templates` (defaults to []). **Correct.**
- **Card / Fact / CardDetail / CardStats**: Field names and shapes match backend. **Correct.**
- **MediaItem**: id, owner, filename, mime, size, checksum, created_at. **Correct.**
- **User**: username, email from profile data. **Correct.**

---

## 10. Not Implemented (By Design)

- **Admin**: POST /api/admin/media/shared, DELETE /api/admin/media/shared/{id}, POST /api/admin/decks/import — not in frontend. Documented as admin-only; add when building admin UI.

---

## Changes Made

1. **create_deck_provider.dart**
   - Create/update payload now sends only `name`, `fields`, `rate` (backend contract). Removed `templates` from payload.
   - Added validation: at least two fields required before submit.

2. **dio_client.dart**
   - For `DioExceptionType.badResponse`, error message is taken from response body `msg` or `message` when the body is a Map, so backend error text is shown correctly.

---

## Recommendation

- Run `flutter analyze` and `flutter test` after these changes.
- When adding media idempotent uploads, pass `client_id` in the multipart form in `uploadFile` (or a dedicated upload method that accepts optional `clientId`).
