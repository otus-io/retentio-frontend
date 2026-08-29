# Local-first learning cache plan

Chinese: [offline_learning_cache_plan_zh.md](offline_learning_cache_plan_zh.md)

The Flutter app uses local-first learning: deck metadata, facts, media, and card scheduling are downloaded to Hive in one pass; card delivery and review run locally using the same card-selection rules as the backend, without waiting on the network for every tap.

Review/hide actions are written to a local queue first, then synced in the background—progress is uploaded card-by-card via `PATCH /api/decks/{id}/card`, and after each batch finishes, `GET /api/decks/{id}` aligns stats; flushing is triggered when the queue reaches 100 entries or more, when leaving study, or when the network is restored, and server `cards[]` must not overwrite local scheduling.

**Goal:** By default, read cards from local Hive for learning whether or not the device is online; talk to the server only when downloading/updating facts and media, or when pushing local review progress. Learning can continue on downloaded decks with no network.

Build a standalone local-first learning path:

- During study, read cards from local Hive by default; the frontend scheduler computes the next card using the same rules as backend `GetNextCard`.
- Use existing list APIs on demand to download or refresh deck metadata, facts, and media; card scheduling is seeded only on first landing from `GET /api/decks/{id}/cards`.
- Review and hide operations land locally first, then enter the sync queue.
- When the pending sync queue reaches 100 entries or more, attempt automatic upload; below 100, do not auto-upload. Flushing can also happen when leaving the study page, on foreground/background transitions, or when the network is restored.
- **Card progress** → `PATCH /api/decks/{id}/card` (FIFO queue, review/hide one at a time).
- **Deck stats** → after a flush batch, `GET /api/decks/{id}` `stats` (do not overwrite Hive scheduling with `GET /cards` `cards[]`).
- Learning progress goes only through the local queue and upload; this plan does not cover content editing.

## Table of contents

- [Initial scope](#initial-scope)
- [User flows](#user-flows)
  - [Download](#download)
  - [Study](#study)
  - [Sync](#sync)
    - [Deck stats (DeckStats)](#deck-stats-deckstats)
  - [Badges](#badges)
- [Architecture](#architecture)
- [Local storage](#local-storage)
  - [Offline deck](#offline-deck)
  - [Offline fact](#offline-fact)
  - [Offline card](#offline-card)
  - [Sync queue](#sync-queue)
- [Local card delivery rules](#local-card-delivery-rules)
- [Backend APIs](#backend-apis)
  - [Download and refresh (existing)](#download-and-refresh-existing)
  - [Review progress (existing)](#review-progress-existing)
- [Sync rules](#sync-rules)
- [Media cache](#media-cache)
- [Security](#security)
- [Code placement](#code-placement)
- [Testing](#testing)
- [Appendix: object shape reference](#appendix-object-shape-reference)
  - [Deck](#deck)
  - [Fact / Entry](#fact--entry)
  - [Card](#card)
  - [Media](#media)
  - [Tag](#tag)
  - [Contribution (feedback)](#contribution-feedback)
  - [Offline Hive vs API shape mapping](#offline-hive-vs-api-shape-mapping)

---

## Initial scope

The first phase covers offline learning and review-progress sync only; offline editing is out of scope (limited value).

Supported:

- Open downloaded decks.
- View front/back, flip.
- Submit review interval.
- Hide the current card.
- Filter by downloaded **fact tags** (same as `GET /api/decks/{id}/card?tag_id=`).
- Show pending-sync status.
- When the pending sync queue reaches 100 entries or more, auto-upload review progress and align server deck stats.

Not supported:

- Offline create/delete decks.
- Offline add/delete facts.
- Offline media upload.
- Offline import/sync shared decks.
- Offline delete cards.

Create/delete, media upload, and shared-deck sync involve server IDs, permissions, and version conflicts; they are excluded from the first phase.

## User flows

### Download

Download entry points in two places:

- In Discover, tapping “Import” downloads offline learning data for the deck.
- When tapping a deck to study, check and backfill local cache.

Download policy:

- Text is required.
- Audio and images download by default (use media **IDs** from fact `entries`, not HTTPS URLs from `GET /card`).
- Video is off by default.
- After download completes, the deck shows “Available offline”.
- Download failure does not block import or study entry; the page only shows cache status.

First landing (assemble local learning package; no new backend API):

1. `GET /api/decks/{id}`: deck metadata; `fields` live here, not on facts.
2. `GET /api/decks/{id}/facts?limit=&offset=`: paginated facts (default 50, max 200, `meta.has_more`).
3. `GET /api/decks/{id}/cards`: seed local card scheduling (`id` / `fact_id` / `template` / `last_review` / `due_date` / `hidden` / `created_at`). This API has **no** `front` / `back` / `urgency`.
4. Download files locally by fact media ID.

After that, content refresh pulls facts and media only; **do not** treat server card scheduling as source of truth again.

### Study

When entering the study page:

1. With a local learning package: prefer local card delivery. When online, refresh facts/media in the background only; do not overwrite local `due_date` / `last_review`.
2. No local package and online: use existing `GET /api/decks/{id}/card`.
3. No local package and offline: prompt that a network download is required.

Offline review must not wait on the network. After the user taps next, the UI updates immediately.

Local study queries read Hive directly—no local HTTP server, no `127.0.0.1`.

`DeckStudyBloc` continues to consume Flutter `CardDetail`. That object is a **study-time derived DTO**; do not store it as a Hive row. Build `CardDetail` on the fly from local `Card` + `Fact` + `deck.fields` (see below).

### Sync

After the user reviews a card, the client writes directly to the local sync queue. **Upload to the server uses only** `PATCH /api/decks/{id}/card`; `GET /api/decks/{id}/card` is for online card delivery when there is no local package and is not part of progress sync.

Auto-upload when: pending sync queue is 100 entries or more **and** the device is online. Below 100, do not auto-upload even when online.

After the threshold, sync can be triggered on network restore, app launch, return to foreground, leaving study, or manual retry. **One flush has two steps:** (1) FIFO `PATCH` each review/hide in the queue; (2) after that batch’s PATCHes finish, `GET /api/decks/{id}` and align server counters such as `total_reviews` / `total_reviews_today` from response `stats` (see “Deck stats”). Other triggers (e.g. leaving study) use the same two steps.

First-phase flush reuses existing `PATCH /api/decks/{id}/card` (same split as `DeckStudyLegacyServiceRepository.submitCard`):

- Review: `{ "card_id", "interval", "last_review" }` (cannot include `hidden` at the same time).
- Hide: `{ "card_id", "hidden" }` (cannot include `last_review`).

The server truncates `interval` to `int64`; if `last_review > now`, the server clamps to `now`, then `due_date = last_review + interval`. Local client updates should use the same rules.

Current PATCH has **no** server-side idempotency. Each PATCH during flush must carry `Idempotency-Key: {operation_id}` (or equivalent header/field—coordinate with backend); the queue uses `operation_id` so each event succeeds at most once; retries must not double-count `total_reviews`.

Sync failure does not block study; only status updates:

- `Offline study`
- `Pending sync`
- `Syncing`
- `Sync failed`
- `Re-login required`

### Deck stats (DeckStats)

`PATCH /api/decks/{id}/card` returns **only** scheduling fields for one card, **not** full `DeckStats`. Stats fall into two groups with different offline/local-first handling:

| Field | Server source | Local / local-first |
| --- | --- | --- |
| `due_cards`, `unseen_cards`, `reviewed_cards`, `hidden_cards`, `new_cards_today`, `last_reviewed_at`, `cards_count` | `ComputeStats` over the card list (see appendix) | **Recompute locally**: Hive `offline_cards` (+ local `facts_count`) with the same rules; update immediately after each review/hide. With `tag_id`, filter `fact_id` by fact tags first, then compute |
| `total_reviews`, `total_reviews_today` | **Separate Redis counters**; increment only on successful PATCH **interval** (hide does not count as review) | Can optimistically show locally during study; **after a queue flush batch** (including ≥100 trigger) must `GET /api/decks/{id}` for `stats` alignment. Optional per-PATCH +1 estimate during flush, but post-flush GET is authoritative |
| `facts_count` | Size of fact set | Count of local `offline_facts` |

**Relationship to PATCH / GET:**

- After review/hide: local card row + local **scheduling** stats recompute immediately; **counter** stats may lag until flush batch completes.
- **Flush trigger** (queue ≥ 100, leave study, foreground/background, network restore, manual retry): PATCH queue first → then `GET /api/decks/{id}` sync `stats` (at least `total_reviews*`; optionally verify `due_cards` etc. match local recompute).
- `GET /api/decks/{id}/cards` response includes `stats` + `cards[]`: if using this API for stats, **read `stats` only**; **do not** overwrite local scheduling in Hive with `cards[]` for cards not yet flushed.
- Study page “due / progress bar”: use local `ComputeStats`; no GET for live due.

**UI guidance:**

| Scenario | Approach |
| --- | --- |
| Study page live due / progress bar | Local `ComputeStats(local_cards)`, refresh after each review |
| Deck list “due” | Local recompute; after flush batch, optionally verify with `GET /decks` `stats.due_cards` |
| Deck list “total reviews / reviews today” | **After flush batch** `GET /decks/{id}` update `stats.total_reviews*` (same timing as ≥100 sync trigger) |

### Badges

Badges indicate user-actionable update state only, not learning-progress sync.

| Type | Trigger | Shown offline? |
| --- | --- | --- |
| Update available | Imported deck `source_version` < source deck `published_version` | No |

Card, fact, and deck JSON have **no** `server_version`. Import updates use existing source / published version APIs; do not invent generic `version` / `content_hash` polling.

Update check triggers:

- Enter deck page.
- App returns to foreground.
- Network goes from offline to online.
- Low-frequency background check on study page.

When offline, do not request and do not show “update available” badge.

## Architecture

```text
[Discover - Import] --------+
                              |
[Tap deck to study] ----------+--> [Offline package check]
                                   |
                  +----------------+----------------+
                  |                                 |
             [Local cache]                    [No cache, online]
                  |                                 |
                  v                                 v
               [Hive] <------------- [GET deck/facts/cards]
                  |                         [GET media]
                  v
           [OfflineScheduler]
                  |
                  v
        [Derive CardDetail]
                  |
                  v
            [DeckStudyBloc]
                  |
                  v
            [Study page]

[Review/Hide]
     |
     v
[Update local Card] -> [StudySyncQueue] -> [Queue ≥ 100 and online]
                                              -> [PATCH queue FIFO]
                                              -> [GET /decks/{id} align stats]
```

Learning path:

- `LocalOfflineLearningDataSource`: read/write offline deck, fact, and card in local Hive (backend `Deck` / `Fact` / `Card` shapes).
- `RemoteOfflinePackageDataSource`: when online, download or refresh via existing GET APIs; do not call `GET /api/decks/{id}/card` to populate cache.
- `OfflineScheduler`: run frontend `GetNextCard` selection logic.
- `StudySyncQueue`: record pending review and hide events.
- `OfflineFirstDeckStudyRepository`: unified entry for local read, content refresh, card delivery, and sync; converts local rows to `CardDetail` when dealing cards.

Key points:

- Change `DeckStudyBloc` as little as possible; it still consumes `CardDetail`.
- Keep `DeckStudyRepository` interface stable.
- Add `OfflineFirstDeckStudyRepository` to replace the old remote-only implementation.
- Do not change BLoC, Cubit, or Riverpod state directly from the API layer.

## Local storage

Do not put the offline learning package in the existing `hydrated_box`. It is business data and needs its own boxes.

The web frontend may use React Query for server cache; on the Flutter app side, Hive and Repository are authoritative.

New Hive boxes:

```text
offline_decks
offline_facts
offline_cards
offline_tags
offline_media
offline_sync_queue
offline_sync_meta
```

All keys are account-scoped:

```text
{accountId}:deck:{deckId}
{accountId}:fact:{factId}
{accountId}:card:{cardId}
{accountId}:sync:{operationId}
```

This avoids reading another account’s cache after switching accounts.

### Offline deck

Field names align with backend `deck.Deck`. Column names are on the deck, not on facts. Imported decks use `source_version` against source deck `published_version`.

```json
{
  "account_id": "user-1",
  "id": "deck-1",
  "name": "Japanese N5",
  "fields": ["Question", "Answer"],
  "rate": 20,
  "source_deck_id": "",
  "source_version": 0,
  "downloaded_at": 1776153600,
  "last_synced_at": 1776157200,
  "card_count": 1200,
  "media_bytes": 52428800,
  "has_pending_operations": false
}
```

### Offline fact

Aligns with backend `deck.Fact` and `GET /api/decks/{id}/facts`: `id`, `entries`, `tags` in the HTTP response. `entries` match Flutter `FactEntry` / backend `Entry`. Media fields store **IDs**; empty strings may be omitted. Do not store `fields` (on deck) or `server_version`.

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "id": "fact-1",
  "entries": [
    {
      "text": "猫",
      "audio": "media-1"
    }
  ],
  "tags": [
    { "id": "tag-1", "name": "N5" }
  ]
}
```

### Offline card

Aligns with backend `deck.Card` and Flutter `Card` scheduling fields, plus a local dirty flag.

**Do not** write the full `GET /api/decks/{id}/card` `CardDetail` into Hive:

- `CardDetail` is `{ "card": { ... }, "urgency": ... }`; in `next_card`, `urgency` is nested on the card object.
- `front` / `back` are computed from facts + `template` + `deck.fields`, and the API rewrites media IDs to HTTPS URLs—unsuitable for offline.
- `urgency`, `tag_ids`, `server_version` are not on `Card`. Tags live on facts.

```json
{
  "account_id": "user-1",
  "deck_id": "deck-1",
  "id": "card-1",
  "fact_id": "fact-1",
  "template": [[0], [1]],
  "last_review": 1776150000,
  "due_date": 1776236400,
  "hidden": false,
  "created_at": 1776150000,
  "dirty": true
}
```

`template` must be kept: `[[front entry indices], [back entry indices]]`, same as backend `ValidTemplate` (two disjoint segments covering `0..n-1`). Without `template`, front/back cannot be recomputed after fact updates.

Derive Flutter `CardDetail` at study time (for BLoC / UI, not persisted):

```text
fact = Hive fact by card.fact_id
front, back = ApplyTemplateToEntryObjects(fact.entries, card.template, deck.fields)
  Each slot: { field?, text?, audio?, image?, video?, json? } (one object may hold multiple types)
  Flutter CardSlot.fromJson collapses to { field, items: [{type, value}] }
urgency = (now - last_review) / (due_date - last_review)
CardDetail = { card: { ...card, front, back }, urgency }
```

Do not send `Card.toJson()` (items shape) back to the server.

### Sync queue

Store review results as an event queue, not final state only. Each entry maps to one PATCH.

```json
{
  "operation_id": "op-01J...",
  "account_id": "user-1",
  "device_id": "device-a",
  "client_sequence": 1024,
  "deck_id": "deck-1",
  "card_id": "card-1",
  "type": "review",
  "payload": {
    "interval": 86400,
    "last_review": 1776157200
  },
  "created_at": 1776157200,
  "attempts": 0,
  "next_retry_at": 1776157200,
  "status": "pending",
  "last_error": null
}
```

First-phase queue types:

| Type | PATCH body | Purpose |
| --- | --- | --- |
| `review` | `{ card_id, interval, last_review }` | Sync review interval and review time |
| `hide` | `{ card_id, hidden }` | Sync hidden state |

## Local card delivery rules

Current `GET /api/decks/{id}/card` uses backend `GetNextCard` to pick the most urgent card and returns `next_card` when a second exists.
Offline, this API is not called; port the **same** selection logic to the frontend—do not approximate with “due cards only”.

Implementation (see `retentio-backend/api/deck/card.go`):

1. Load all local cards for the deck.
2. If the study page has `tag_id`: keep only cards whose `fact_id` is in that tag’s fact set (same as `UserTagFactsKey` / `?tag_id=`). Cards do not have `tag_ids`.
3. Skip `hidden == true`.
4. If `due_date - last_review <= 0`: treat as corrupt data like the backend; do not deal that card (backend returns 400).
5. `now = unix seconds`.
6. `urgency = (now - last_review) / (due_date - last_review)` (`float32` division).
7. Among remaining cards, take the card with **strictly maximum** urgency; **on tie, pick lexicographically smaller `card_id`** (client and backend must match; after loading from Hive, sort by `card_id` ascending then iterate; backend `GetNextCard` should sort candidates the same way before selection).
8. Second-highest urgency is lookahead (response `next_card`); if tied with first, again pick lexicographically smaller `card_id`, and it must differ from the main card.
9. If no non-hidden cards remain: end study (backend returns `card` as `[]`).

Not-yet-due cards **may** be dealt: the backend does not require `due_date <= now`. When nothing is more urgent, it deals the highest-urgency not-yet-due card.

Unseen cards: `due_date - last_review == 1`. Unseen cards in the overflow queue may have future `last_review`; when `GetNextCard` deals them, it clamps `last_review` to `now` and writes back. Local dealing should clamp the current card the same way.

After review submit, update local card immediately (consistent with PATCH semantics):

Review:

```text
if last_review > now: last_review = now
due_date = last_review + int64(selectedInterval)
dirty = true
```

Hide:

```text
hidden = true
dirty = true
```

Then enqueue for sync. Card update and queue write must share one local transactional semantics so a killed app does not leave half-written state. After hide, the scheduler skips `hidden == true` cards.

## Backend APIs

First phase adds **no** `GET /offline-package` or `POST /api/sync/study-events`. Use existing APIs to assemble download and progress flush.

### Download and refresh (existing)

| API | Purpose |
| --- | --- |
| `GET /api/decks/{id}` | Deck metadata and `fields` |
| `GET /api/decks/{id}/facts` | Paginated facts: `limit` / `offset`, `meta.has_more`; each row has `id`, `entries`, `tags` |
| `GET /api/decks/{id}/cards` | First-time seed of local `Card` scheduling; response is `stats` + `cards`, no front/back |
| `GET /api/decks/{id}/card` | Online study only when no local package; **do not** use to populate Hive (media rewritten to URLs) |
| `GET /api/media/{id}` | Download bytes by media ID from facts |

`GET /facts` has no cursor. Client paginates with `offset` until `has_more == false`, then marks the deck locally ready—avoid half-success.

### Review progress (existing)

```http
PATCH /api/decks/{id}/card
```

Successful review response:

```json
{
  "data": {
    "last_review": 1776157200,
    "due_date": 1776243600,
    "new_interval": 86400
  }
}
```

Successful hide response:

```json
{
  "data": {
    "hidden_status": true
  }
}
```

No `server_version`, no full card in the response. Client confirms local row with these fields, then removes the queue entry.

**Flush-layer PATCH wrapper:** Existing `CardService.updateCard` returns `Future<bool?>`, which cannot distinguish HTTP status from body. The sync flusher must use (or add) a wrapper returning a **typed result** with at least: `httpStatus`, `isSuccess`, `responseData` (`last_review` / `due_date` / `new_interval` or `hidden_status`), `operationId` (for reconciliation). The flusher then distinguishes: success (remove queue entry), 401 (pause flush, keep queue), 400 (mark `failed`, keep payload), 404 (mark `remote_deleted`, remove queue entry), other (backoff retry). Online `DeckStudyLegacyServiceRepository` may keep the bool wrapper, but the outbox flusher must use the typed path.

If batch idempotent sync is added later, introduce `POST /api/sync/study-events` (`operation_id` dedup); until then do not rely on server idempotency.

## Sync rules

Queue processing:

1. Take events with `pending` and `next_retry_at <= now`.
2. Upload in ascending `client_sequence` order.
3. Each maps to one `PATCH /api/decks/{id}/card` (review and hide separate), request header `Idempotency-Key: {operation_id}`.
4. From typed PATCH result: HTTP 2xx and `operation_id` not yet processed → confirm local card with response fields, remove queue entry.
5. **After all PATCHes in the batch complete**: `GET /api/decks/{id}`, update locally cached `total_reviews` / `total_reviews_today` (and other stats fields used in deck list); **do not** overwrite Hive scheduling with `GET /cards` `cards[]`.
6. Network errors: exponential backoff `30s -> 2m -> 10m -> 30m -> 2h`.
7. 401: pause sync, do not delete queue.
8. 400: mark `failed`, keep payload.
9. 404: mark local card `remote_deleted`, remove queue entry, stop dealing.

Conflict handling:

| Scenario | Handling |
| --- | --- |
| Same event retry | Client `operation_id` dedup + PATCH `Idempotency-Key`; server must not double-count `total_reviews` for the same key |
| Same device ordering | Ascending `client_sequence` |
| Multiple devices review same card | Server: last successful PATCH wins; other device does not pull scheduling back |
| Fact deleted, card missing | PATCH 404 → local `remote_deleted`, stop dealing, drop queue entry |
| Stale content | Pull fact/media delta only; do not overwrite local scheduling |

## Media cache

Media lives on the filesystem separately:

```text
documents/offline_media/{accountId}/{deckId}/{mediaId}.{ext}
```

Hive stores index only:

- `media_id` (original ID from fact `entries.audio` / `image` / `video` / `json`)
- `local_path`
- `content_type`
- `bytes`
- `sha256`
- `download_status`
- `last_accessed_at`

Rules:

- Text-only study is the floor; media failure must not block study.
- Download to temp file first; replace final file only after hash passes.
- Audio and images cached per deck directory.
- Video off by default.
- When deleting an offline deck, delete only media exclusive to that deck.

## Security

The offline learning package contains user content; before persisting:

- Use Hive AES encryption for offline business boxes (current Hive default is unencrypted; new work required).
- Store encryption key in secure storage, not `SharedPreferences`. Project does not yet use `flutter_secure_storage`; new dependency—evaluate separately.
- Keys and data isolated per account.
- **Logout policy (pending sync queue):** If `offline_sync_queue` / `review_outbox` is non-empty, **do not delete unconditionally**. v1 default: prompt user with “Sync now and log out”, “Keep pending data and log out (same account can flush after re-login)”, or “Discard unsynced reviews and log out”. Clear that account’s Hive offline boxes and media cache only when the queue is empty or the user explicitly chooses discard.
- On 401, pause queue; resume sync after re-login.

## Code placement

New module:

```text
lib/features/offline_learning/
  data/
    datasources/
      local_offline_learning_data_source.dart
      remote_offline_package_data_source.dart
      study_sync_data_source.dart
    repositories/
      offline_learning_repository_impl.dart
  domain/
    entities/
      offline_deck.dart
      offline_card.dart
      study_sync_operation.dart
    repositories/
      offline_learning_repository.dart
    services/
      offline_scheduler.dart
      offline_sync_service.dart
  presentation/
    bloc/
      offline_sync_bloc.dart
      offline_sync_event.dart
      offline_sync_state.dart
```

Core integration:

- Add `OfflineFirstDeckStudyRepository`.
- It implements existing `DeckStudyRepository`, derives `CardDetail` from Hive when dealing cards, and must preserve `DeckStudyBloc`’s existing next-card prefetch (lookahead) behavior or UX regresses.
- `deck_study` is not registered in `get_it` yet (`lib/core/di/app_service_locator.dart` only registers `auth`); register it first so DI can inject Repository by network state.

Shared utilities:

```text
lib/core/network/connectivity_service.dart
lib/core/storage/offline_hive_boxes.dart
lib/core/storage/account_scope.dart
```

## Testing

Unit tests:

- Hidden cards are not dealt.
- `due_date - last_review <= 0` treated as corrupt.
- Fact tag filter (by `fact_id`, not card `tag_ids`).
- Urgency formula and `card_id` lexicographic tie-break.
- Not-yet-due cards can still be dealt when nothing is more urgent.
- Unseen card interval is 1; future `last_review` clamped to now.
- Frontend scheduler picks same card as backend `GetNextCard` at same time on same card set (including `card_id` tie-break).
- Queue serialization; review/hide PATCH body split; hide sets local `hidden = true` and queue entry in same transaction.
- Retry backoff and `operation_id` dedup; same `operation_id` retry carries same `Idempotency-Key`; `total_reviews` must not increment twice.
- Account isolation.
- Import deck badge uses `source_version` / `published_version`.

Repository tests:

- With local cards, study does not call `GET /card`.
- Offline falls back to local.
- After review, local `last_review` / `due_date` update immediately.
- Card state and queue written together.
- After PATCH success, confirm local from response fields; do not pull `GET /cards` to overwrite scheduling.
- 401 does not drop queue.

BLoC / widget tests:

- Prompt download when no offline package.
- After offline review, next card shows immediately.
- Sync failure does not block study.
- After account switch, previous account cache not visible.
- Update badge only when online detects imported deck update.

Acceptance criteria:

- Airplane mode: downloaded deck supports 100 consecutive cards.
- Review tap to UI update under 100 ms.
- Kill process and reopen: pending sync events not lost.
- Same `operation_id` triggered multiple times does not duplicate PATCH; retry does not double-count `total_reviews`.
- After PATCH success, local `last_review` / `due_date` / `hidden` match response.
- Same card set and same `now`: local scheduler matches `GetNextCard` next card.
- Undownloaded deck must not show as offline-ready.

---

## Appendix: object shape reference

Fields below align with current backend `retentio-backend/api/deck/` and Flutter `lib/models/`. Offline Hive should prefer **Redis truth shapes** (fact media IDs, card scheduling, deck `fields`), not URLs or `CardDetail` derived from `GET /card`.

### Deck

**Redis storage** (`deck:{id}`, `deck.Deck`):

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Deck name |
| `description` | string? | Optional description |
| `owner` | string | Username (imported decks show source author at API layer) |
| `fields` | string[] | Column names; label source for fact `entries[i]` |
| `rate` | int | New-card introduction rate (1–1000) |
| `created_at` | ISO8601 | Created at |
| `updated_at` | ISO8601 | Updated at |
| `visibility` | string? | Source deck: `private` / `public` |
| `published_version` | int? | Source deck: latest published snapshot version, `0` = never published |
| `source_deck_id` | string? | Imported deck: source deck id |
| `source_version` | int? | Imported deck: pinned source snapshot version |
| `imported_at` | ISO8601? | Imported deck: import time |

**`GET /api/decks/{id}` computed fields** (not in Redis `Deck` JSON):

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | Path parameter |
| `stats` | DeckStats | See table below |
| `latest_source_version` | int | Imported deck only: source deck current `published_version` |
| `source_update_available` | bool | Imported deck only: `source_version < latest_source_version` |

**DeckStats** (`stats`, computed from cards + fact count):

| Field | Type | Description |
| --- | --- | --- |
| `cards_count` | int | Total cards |
| `facts_count` | int | Total facts |
| `unseen_cards` | int | Unseen: `due_date - last_review == 1` and not hidden |
| `reviewed_cards` | int | Seen (including hidden) |
| `due_cards` | int | Due: `due_date <= now` and not hidden |
| `hidden_cards` | int | Hidden count |
| `new_cards_today` | int | Created today (UTC day) |
| `last_reviewed_at` | int64 | Last review time (Unix seconds) |
| `total_reviews` | int64 | Cumulative review count (PATCH interval counter) |
| `total_reviews_today` | int64 | Reviews today (UTC day bucket) |

**Offline / local-first**: scheduling fields recomputed locally; `total_reviews*` aligned via `GET /decks/{id}` `stats` after queue flush batch (including ≥100 trigger) completes PATCH (see “Deck stats (DeckStats)”).

**Flutter `Deck`** (`lib/models/deck.dart`) also parses `min_interval` / `def_interval` / `max_interval`, but the backend **does not return** these today; review slider range is client-computed from urgency (`ReviewIntervalRange`).

**Offline Hive suggestion**: store `id`, `name`, `fields`, `rate`, `source_deck_id`, `source_version`, plus local `downloaded_at` / `last_synced_at` metadata. Do not use generic `server_version`.

```json
{
  "id": "deck-1",
  "name": "Japanese N5",
  "fields": ["Word", "Translation"],
  "rate": 20,
  "source_deck_id": "",
  "source_version": 0,
  "published_version": 0,
  "visibility": "private"
}
```

### Fact / Entry

**Entry** (`deck.Entry`, one slot):

| Field | Type | Description |
| --- | --- | --- |
| `text` | string? | Text |
| `audio` | string? | Media **ID** (not URL) |
| `image` | string? | Media ID |
| `video` | string? | Media ID |
| `json` | string? | JSON attachment media ID |
| | | Empty strings omitted in JSON; at least one slot must have content |

**Fact** (Redis `fact:{id}` or import snapshot / overlay):

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | 8-char nanoid |
| `entries` | Entry[] | Fact content |

**HTTP response** (`GET /api/decks/{id}/facts`, `GET …/facts/{factId}`) adds on `Fact`:

| Field | Type | Description |
| --- | --- | --- |
| `tags` | Tag[] | Response only; **not written** to Redis `fact:{id}` |

**No** per-fact `fields`; column names are in `deck.fields[i]`.

Imported deck facts come from author snapshot; importer private edits use overlay (`FactOverlayKey`) without changing the shared snapshot.

**Offline Hive suggestion**: `id`, `entries` (raw media IDs), `tags` (cached from GET facts). On fact update, upsert by id; do not overwrite card scheduling.

```json
{
  "id": "fact-1",
  "entries": [
    { "text": "猫", "audio": "aud001" },
    { "text": "ねこ" }
  ],
  "tags": [
    { "id": "tag-1", "name": "N5", "description": "" }
  ]
}
```

### Card

**Redis storage** (`card:{id}`, `deck.Card`)—scheduling source of truth:

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | 8-char nanoid |
| `fact_id` | string | Linked fact id |
| `template` | int[][] | `[[front entry indices], [back entry indices]]`; two disjoint segments covering `0..n-1` |
| `last_review` | int64 | Unix seconds |
| `due_date` | int64 | Unix seconds |
| `hidden` | bool | Hidden flag |
| `created_at` | int64 | Unix seconds |

**`GET /api/decks/{id}/cards`**: returns `{ stats, cards: Card[] }`. `cards` match Redis shape; **no** `front` / `back` / `urgency`.

**`GET /api/decks/{id}/card`**: temporarily attaches on `Card`:

| Field | Type | Description |
| --- | --- | --- |
| `front` | FaceEntry[] | From template + fact + deck.fields |
| `back` | FaceEntry[] | Same; `back` may be `[]` for front-only cards |
| `urgency` | float32 | **Only** at response top level (main card) or inside `next_card` object |

**FaceEntry** (front/back slot; one object may hold multiple media types):

| Field | Type | Description |
| --- | --- | --- |
| `field` | string? | Column name (omit if none) |
| `text` | string? | Text |
| `audio` | string? | Media ID or **full HTTPS URL** (GET /card rewrites) |
| `image` | string? | Same |
| `video` | string? | Same |
| `json` | string? | Same |

**Flutter `CardDetail`** (`lib/models/card.dart`, study DTO, **not stored in Hive**):

```json
{
  "card": {
    "id": "card-1",
    "fact_id": "fact-1",
    "template": [[0], [1]],
    "last_review": 1776150000,
    "due_date": 1776236400,
    "hidden": false,
    "created_at": 1776150000,
    "front": [{ "field": "Word", "items": [{ "type": "text", "value": "猫" }] }],
    "back": [{ "field": "Translation", "items": [{ "type": "text", "value": "ねこ" }] }]
  },
  "urgency": 0.8
}
```

Flutter collapses FaceEntry to `{ field, items: [{type, value}] }`; offline should store Redis `Card` + local `dirty`, derive `CardDetail` when dealing.

**PATCH `/api/decks/{id}/card`**:

- Review: `{ "card_id", "interval", "last_review" }` → `{ last_review, due_date, new_interval }`
- Hide: `{ "card_id", "hidden" }` → `{ hidden_status }`
- Mutually exclusive in one request; `interval` truncated to int64; if `last_review > now`, server clamps to `now`

Cards have **no** `tag_ids`; tags are on facts; selection uses `?tag_id=` to filter the `fact_id` set.

### Media

**Metadata** (Redis `media:{id}`, `deck.Media`):

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | Media id |
| `owner` | string | Uploader username |
| `deck_id` | string? | Linked deck |
| `filename` | string | Original filename |
| `mime` | string | MIME type |
| `size` | int64 | Bytes |
| `checksum` | string | Checksum |
| `created_at` | int64 | Unix seconds |

**Download**: `GET /api/media/{id}` (import snapshot may add `?v=` version). Response body is bytes; metadata via `GET /api/media` list or upload response.

**Fact references**:

- Owned media: bare id, e.g. `"audio": "aud001"`
- Imported shared media: id prefixed `shared:` (e.g. `shared:abc123`), used when parsing marker `[audio:shared:xxx]`
- **Offline cache key** uses bare id; do not store HTTPS URLs from `GET /card`

**Offline file index** (Hive `offline_media`, not a backend object):

| Field | Description |
| --- | --- |
| `media_id` | Raw id from fact |
| `local_path` | `documents/offline_media/...` |
| `content_type` | MIME |
| `bytes` | Size |
| `sha256` | Checksum |
| `download_status` | pending / ready / failed |
| `last_accessed_at` | Unix seconds |

### Tag

**Tag** (`deck.Tag`, nested in fact/deck tag API responses):

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | Tag id |
| `name` | string | Display name |
| `description` | string | Description |

**TagListItem** (`GET /api/tags` list row, two extra counts):

| Field | Type | Description |
| --- | --- | --- |
| `deck_count` | int | Linked deck count |
| `fact_count` | int | Linked fact count |
| `used_on` | string[] | `"deck"` and/or `"fact"` |

**Association model** (Redis sets, not on Card):

- Deck tags: `user:{username}:deck:{deckId}:tags`
- Fact tags: `user:{username}:fact:{deckId}:{factId}:tags`
- Facts by tag: `user:{username}:tag:{tagId}:facts` → `"deckId:factId"` refs

**Card filter**: `GET /api/decks/{id}/card?tag_id=` and `GET /api/decks/{id}/cards?tag_id=` use the same fact-set filter; replicate offline.

On create/link: `tags` (names, may auto-create) and `tag_ids` (existing ids) are **mutually exclusive**.

### Contribution (feedback)

Proposals from importers to the **source deck**; author handles in source deck inbox. First-phase offline plan **does not** sync contributions; included for shared/import cross-reference.

**Contribution** (Redis, `deck.Contribution`):

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | Contribution id |
| `source_deck_id` | string | Source deck (author) |
| `import_deck_id` | string | Importer deck |
| `fact_id` | string? | Related fact |
| `reporter` | string | Submitter username |
| `source_version` | int | Source snapshot version at submit |
| `type` | string | See table below |
| `message` | string? | Note (≤2000 chars) |
| `status` | string | `open` / `accepted` / `resolved` / `dismissed` |
| `created_at` | ISO8601 | |
| `updated_at` | ISO8601 | |
| `resolved_at` | ISO8601? | |
| `accepted_at` | ISO8601? | |
| `dedupe_target` | string? | Dedup key |

**Payload fields by `type`**:

| type | Main fields |
| --- | --- |
| `fact_edit` | `entry_index?`, `reported_fact`, `proposed_entries`, `media_attachments?` |
| `fact_add` | `proposed_entries`, `media_attachments?` |
| `fact_tag_update` | `reported_tags?`, `add_tags`, `remove_tags` |
| `deck_tag_update` | `add_tags`, `remove_tags` |
| `template_add` | `template` |
| `field_rename` | `reported_fields`, `proposed_fields` |
| `report` | `message` (report only, no structured diff) |

**Nested types**:

- **ReportedFact**: `{ id, entries[] }` — frozen “before” snapshot at submit
- **proposed_entries**: `Entry[]` — importer’s proposed “after”
- **MediaChange** (derived diff, inbox filter): `{ type, action, entry_index }`, `type` = audio/image/video/json, `action` = add/edit/remove
- **MediaAttachment**: `{ attachment_id, source_media_id, references[], filename?, mime?, size?, checksum?, preview_path?, available? }`
- **MediaAttachmentRef**: `{ entry_index, field }`
- **AcceptedMediaMappingEntry**: after accept `{ author_media_id, checksum? }`

**ContributionListItem** (`GET /api/decks/{sourceDeckId}/contributions` row) = `Contribution` + optional **edit**:

```json
{
  "edit": {
    "deck_id": "source-deck-1",
    "fact_id": "fact-1",
    "get_fact_path": "/api/decks/source-deck-1/facts/fact-1",
    "patch_fact_path": "/api/decks/source-deck-1/facts/fact-1"
  }
}
```

**Flutter** maps to `DeckContribution` / `ContributionMediaAttachment` (`lib/models/deck_contribution.dart`).

### Offline Hive vs API shape mapping

| Object | Store in offline Hive | Do not store |
| --- | --- | --- |
| Deck | Redis/API deck fields + local sync metadata | Generic `server_version` |
| Fact | `id`, `entries` (media IDs), `tags` | Per-fact `fields` |
| Card | Redis `Card` + `dirty` | `front`, `back`, `urgency`, `tag_ids` |
| CardDetail | Do not store; derive at study time | HTTPS media URLs from GET /card |
| Media | Local file + index row | Full download URL as primary key |
| Tag | `id`, `name`, `description` | Tags on Card |
| Contribution | Not cached in first phase | — |

**Code index**: `retentio-backend/api/deck/{deck,fact,card,media,tag,contribution}.go`; Flutter `lib/models/{deck,fact,card,tag,deck_contribution}.dart`.
