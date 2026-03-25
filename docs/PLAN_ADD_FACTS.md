# Plan: Add Facts (Flutter frontend)

Single-fact flow: one fact per submit, **dynamic entry rows** (default **2** rows; **+** adds a row, **−** removes a row). **At least one row** always (disable or hide **−** when only one row remains). **Optional field name** per row, plus text and media via `POST /api/media`. **Per row:** at most **one image, one video, and one audio** (re-picking a type replaces that slot). See [API.md](API.md) (Add Facts + §5 Media).

## Implementation checklist

- [ ] Add optional `pathParams` to `ApiService.post` and forward to `dioClient.post`
- [ ] Add `MediaService` (or `ApiService` wrapper) for `POST /api/media` via `dioClient.uploadFile`; parse `data.id`; optional `client_id` for idempotency
- [ ] Implement `CardService.addFacts(deckId, operation, body)` using `Api.factsWithOperation`
- [ ] `AddFactWidget` — single fact; **default 2 rows**, **min 1 row**; **+** / **−** to add/remove rows (**−** only when row count > 1); **optional field name** per row; content + media slots per row; upload then `addFacts`; wire menu; refresh providers
- [ ] ARB strings; client-side size limits (5 MB image, 200 MB audio/video); optional unit tests for body builder and upload errors

## Product constraints

- **Single fact per flow:** Body uses `facts: [ oneFact ]`. No bulk import of many facts; no shared upload queue across multiple facts in one action.
- **Per row (entry):** Row order → `entries[0]`, `entries[1]`, … At most **one image**, **one video**, and **one audio** per row (up to **three** media files). Re-picking the same type **replaces** that attachment. Matches `FactEntry` / API keys per entry.
- **Row count:** Start with **2** rows; **at least 1 row** per fact at all times. **+** appends a row; **−** removes the current row when **row count > 1** (never allow deleting the last row).
- **Field names:** Each row may have an **optional** name (label for `fields[i]`). Empty name → resolve at submit time (see request builder below).

## Context

- **Add facts:** `POST /api/decks/{id}/facts/{operation}` — body `{ "facts": [ { "entries": [...], "fields"?: [...] } ], "template"?: ... }`. Entry keys: optional `text`, `audio`, `image`, `video` (values are **media IDs**). Each entry needs at least one of those keys.
- **Media:** `POST /api/media` — multipart `file`, optional `client_id`; response `data.id` goes on the entry. Limits: images **5 MB**, audio/video **200 MB**.

### Existing code

- `Api.factsWithOperation`, `Api.media` — [lib/services/api.dart](../lib/services/api.dart)
- `FactEntry.toJson()` — [lib/models/fact.dart](../lib/models/fact.dart) (use after uploads resolve to IDs)
- `dioClient.uploadFile` — [lib/services/dio_client/dio_client.dart](../lib/services/dio_client/dio_client.dart) (do **not** use `uploadBytes` for `/api/media`; wrong form fields)
- `ApiService.post` — [lib/services/apis/api_service.dart](../lib/services/apis/api_service.dart) (add `pathParams` support)

## 1. HTTP layer

Extend `ApiService.post` with optional `Map<String, String>? pathParams` and pass through to `dioClient.post`.

## 2. Media upload service

- Call `dioClient.uploadFile(Api.media, ...)`, parse `data['id']`.
- Optionally add **client_id** to `FormData` (may require extending `uploadFile`).
- Validate file size before upload; localized errors.
- Picker: map MIME to `image` / `audio` / `video`; enforce per row **one of each** type (three slots max).

## 3. `CardService.addFacts`

`ApiService.post(Api.factsWithOperation, pathParams: { id, operation }, body: body)`.

### Request builder

- Row `i` → `entries[i]`; non-empty text → `{ "text": "..." }`.
- Upload pending files; merge at most one `image`, one `video`, and one `audio` id per entry. Parallel uploads within this fact OK; await all before add-facts.
- **`fields`:** Length must equal `entries.length` when sent. For each index `i`: use trimmed user **field name** if non-empty; else if `i < deck.fields.length` use `deck.fields[i]`; else a generated fallback (e.g. localized `"Field 1"` / `"列 1"` by index). **Omit** the `fields` key only if it is valid to rely on deck defaults (same length as `deck.fields`, no custom names, aligned with API — if in doubt, **always send** explicit `fields` for predictable behavior).
- Validate every entry has at least one of `text`, `audio`, `image`, `video`.
- **template:** omit for default `[[0],[1,2,...]]` unless product needs sibling cards later.

**Operation:** default `append`; optional UI for `prepend` / `shuffle` / `spread`.

## 4. UI

- Widget under [lib/screen/deck/widgets/](../lib/screen/deck/widgets/) (e.g. `AddFactWidget`):
  - **List of rows** in state: initial length **2**; **+** adds a row; **−** on each row removes that row when **total rows > 1** (hidden or disabled when only one row).
  - Each row: optional **field name** `TextField`, main **content** `TextField`, attach/remove for **image**, **video**, **audio**.
- Wire **PullDownMenuItem** in [lib/screen/deck/deck_study_screen.dart](../lib/screen/deck/deck_study_screen.dart).
- On success: `cardProvider.notifier.getCardDetail()` and `deckListProvider.notifier.onRefresh()`.

**Edge cases:** remove attachment clears pending file/id; upload failure blocks add-facts; optional `onSendProgress` for large video.

## 5. Localization and tests

- ARB: add fact, **add row** (+), **remove row** (−), optional field-name hint, attach types, upload failed, file too large, per-entry validation, generated field fallback label.
- Unit tests: form model → JSON `entries` (mocked media ids); optional assert upload targets `/api/media`.

## Out of scope

- Bulk facts or bulk media not tied to the single fact being composed.
- Shared / admin media endpoints (WIP in API).
- Full parity with an external media-upload design doc until reviewed alongside [API.md](API.md).
