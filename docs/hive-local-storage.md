# Local-first study (Hive) — v1

Study/review always runs on device. After **import**, all facts for that deck are downloaded locally; **audio and images** are fetched by media ID; **video is not downloaded by default**. Media download failures do not block import, study, or local-readiness status. Card schedule stays local.

中文版：[hive-local-storage_zh.md](hive-local-storage_zh.md)

| Data | Source of truth |
|------|-----------------|
| Cards (`dueDate`, `lastReview`, `hidden`, template) | Device |
| Facts, media bytes | Server → sync down |
| Deck meta (name, fields, …) | Server when editing; cached locally |

---

## 1. Import deck → download all data locally

After a successful **import** (catalog / share import API), download all of that deck's facts into local storage (Hive + app documents). Fetch **audio and images** by media ID from fact `entries` (video skipped by default). Media failures do not block import, study, or marking the deck locally ready.

```text
Import succeeds (online) → get import deck id
  → cache deck meta in local_decks
  → pull all facts (paged) → local_facts
  → download audio and images by media ID → app documents (video skipped by default)
  → seed local_cards for studyable facts (first time only: may take server card ids / initial dueDate)
  → mark deck as locally ready (syncedAt)
```

**Existing users who already have imported decks:** on login / app start (online), find imported decks that are **not** yet fully local and **auto-download** them in the background (same pipeline as above). Show progress; study stays on local data once ready. Owned (non-import) decks can stay on-demand via use case 3 unless product later requires the same auto-pull.

This is the **initial full pull**. Later content updates still use use case 3 (and must not overwrite local schedules). Author publish → importer `POST …/sync` remains a separate online sharing flow; after that sync succeeds, run use case 3 (or a full re-pull) for facts/media.

---

## 2. Review a card (always local)

```text
Open study → next card by max urgency (same GetNextCard rules) from local_cards (+ fact/media for display)
Rate / hide → update local_cards → append review_outbox → next card
No GET/PATCH …/card on the tap
```

Works offline if cards + facts (+ media) are already synced (use case 1 or 3).

---

## 3. Sync from server (facts + media only)

Pull **only** facts and media. Do **not** download card schedule / card payloads from the server (`GET …/card`, cards list as schedule source, etc.).

```text
Pull-to-refresh / resume / stale deck open (online)
  → if online: run use case 5 first (flush review outbox)
  → upsert local_facts (+ deck meta cache)
  → download audio and images by media ID to app documents (video skipped by default)
  → if facts were added/removed: create/drop matching local_cards rows locally
       (keep existing dueDate/lastReview; do not take schedule from server)
```

Not part of this sync: any server **card** data as source of truth, import `POST …/sync`, replacing review history.

**If content pull happens before flush:** local schedules stay intact (device is source of truth). Pending `review_outbox` rows remain and still flush later. Only risk is add/drop of card rows for deleted facts — so flush first when online; drop outbox rows whose `cardId` no longer exists after fact sync.

---

## 4. Edit deck / facts (online only)

```text
Online: existing APIs → on success, run use case 3 for that deck
Offline: disable add/edit/delete deck & facts (“You’re offline”)
```

No offline edit outbox. Publish/import/contributions stay online-only as today.

---

## 5. Sync card reviews to the server

Every review is written to Hive + `review_outbox` immediately (use case 2). Push to the server in **batches**, not per tap.

| Trigger | Why |
|---------|-----|
| Outbox count **≥ N** reviews (v1 default **N = 100**) | After reviewing many times — fewer HTTP calls mid-session |
| User **leaves study** (pop route / end session) | Don’t wait for N if the session was short |
| App **background** / next **foreground** while online | Safety if the process is killed later |
| **Connectivity restored** | Drain anything queued while offline |

```text
Flush online → FIFO typed PATCH per outbox row (Idempotency-Key = operation_id) → delete on success
Never block the review UI on network
```

v1 does **not** flush on a timer while the user is actively studying (avoids jank); ≥ N + session end is enough.

---

## Matrix

| Action | Online | Offline |
|--------|--------|---------|
| Import → full local download (1) | Yes (required) | Import blocked; use last local if already downloaded |
| Auto-download existing imports (1) | Background on login/start | Skip until online |
| Review / next card (2) | Local | Local |
| Sync facts + media (3) | Yes | Use last local |
| Edit deck / facts / media upload (4) | API → then use case 3 | Blocked |
| Flush review outbox (5) | Background batch | Queued |

---

## Storage

| Store | Contents |
|-------|----------|
| `local_decks` / `local_facts` / `local_cards` | Meta, content, schedule |
| `review_outbox` | Pending review PATCHes (write in 2, flush in 5) |
| Media files (documents dir) | Bytes by media id |

User-scoped. On logout: **do not unconditionally delete** pending `review_outbox` rows. Prompt to sync now, retain for same-account re-login, or explicitly discard unsent reviews. Clear Hive boxes and media only when the outbox is empty or the user confirms discard. New Hive boxes only — not `hydrated_box`.

**Code:** `LocalDeckStore` + `ContentSync` (1, 3) + local `DeckStudyRepository` (2) + offline UI gates (4) + outbox flusher (5).

---

## Build order

1. Use case 1 import + auto-download existing imports → verify full deck on device  
2. Use case 3 facts/media sync → verify offline content refresh  
3. Use case 2 local study + outbox write → verify session with card HTTP blocked  
4. Use case 5 outbox flush → verify server gets reviews  
5. Use case 4 offline gates + post-edit use case 3  

**Accept:** local scheduler matches server `GetNextCard` (urgency + `card_id` tie-break) at the same timestamp; large first sync / import download needs progress; multi-device / web as below; content pull never clobbers unflushed local schedules.

---

## Multi-device and computer (web)

### Two phones / tablets, same account, same deck

| What | v1 behavior |
|------|-------------|
| Facts / media | Both devices pull the same content (use case 1 / 3) |
| Reviews | Each device keeps its own `local_cards` + outbox until flush (use case 5) |
| Conflict | Last successful `PATCH …/card` per card wins on the server. The other device does **not** re-download schedule (by design). So device B’s local due dates can disagree with the server and with device A until you define a later “adopt server schedule” path |

**v1 product stance:** OK for light multi-device use if the user mostly studies on one device at a time and flushes often (leave study / N=100 / reconnect). Concurrent heavy review on two devices is **best-effort** — no merge UI in v1.

### Computer (web / desktop)

This doc is for the **Flutter app** (Hive on device). `retentio-webapp` does not share that Hive store.

| Option | Meaning |
|--------|---------|
| A (v1 default) | Web stays **server-driven study** (today’s `GET/PATCH …/card`). Mobile stays local-first. Same account can diverge: web updates server schedule; mobile ignores schedule on content sync |
| B (later) | Web gets its own local store (e.g. IndexedDB) + same outbox rules |
| C (later) | Optional “pull schedule from server once” on mobile after web study, to realign |

Until B/C exist, prefer **one primary study device**, or accept that web reviews won’t reshape the phone’s local queue automatically.

**Related:** [offline_learning_cache_plan.md](offline_learning_cache_plan.md); [api.md](api.md); `hydrated_storage.dart`; `features/deck_study/`; typed PATCH wrapper for outbox flush (not `CardService.updateCard`'s `bool?`).
