# Offline learning business rules

Chinese: [offline_learning_logic_zh.md](offline_learning_logic_zh.md)

This document describes the **implemented** offline-learning rules. Design background, API fields, and storage shapes are in [offline_learning_cache_plan.md](offline_learning_cache_plan.md). Code lives in `lib/features/offline_learning/`.

A downloaded deck is dealt and reviewed on device. Progress is stored locally first, then uploaded under the rules below. Decks that are not downloaded stay on the online APIs.

## Scope

Supported:

- Open, flip, review, and hide cards on a downloaded deck while offline.
- Filter by cached fact tags.
- Deck list shows only downloaded decks while offline, with locally computed stats.
- Upload reviews and hides, then refresh review counters.

Not supported:

- Creating, editing, or deleting decks or facts while offline.
- Uploading media, importing, or syncing shared decks while offline.
- Deleting a card while offline (the server delete must succeed first).
- Downloading video or JSON media.

## Account

Offline data is separated by login username. If the device has no username yet, the app fetches the profile while online and stores it. If the account cannot be identified while offline, offline mode stays off and study and the deck list use the online APIs.

After logout, a different account does not see the previous account’s decks or pending uploads.

## Download

A deck is available for offline study only after one download finishes. A failed attempt leaves it not ready. A later refresh failure does not revoke a deck that is already ready.

Triggers:

- After a successful Discover import, the app downloads the **imported deck** in the background. Import does not wait, and a download failure does not change the import result.
- Opening that deck’s study screen downloads it, or refreshes a ready deck at most once an hour. A refresh where some media file failed does not count, so the next opening refreshes again.
- Adding or editing a fact from the study screen refreshes the deck in the background. The next card shows at once from the current copy and is redrawn when the refresh finishes. A download already running may have listed the deck before the edit, so this refresh runs again after it instead of sharing it.
- While logged in, the main shell uploads progress only. It does not re-download every deck.

Each download:

1. Updates the deck name, fields, rate, source, and review counters. Existing tags are kept. If an upload refreshed the counters while the download ran, those newer counters are kept instead.
2. Pages through every fact and replaces facts with the same ID. Paging can skip facts when the deck changes meanwhile, so deletions use the full fact ID list: facts not in it are deleted on device. If that list cannot be read, no fact is deleted.
3. Replaces the schedule of every card with the server’s, except cards with unconfirmed local changes, pending uploads, or a local change made while the card list was loading. Cards no longer on the server are deleted with the same exceptions (a pending upload gets a 404 and removes its card).
4. Downloads audio and images referenced by facts. Files already on disk are skipped. One file failing is logged and skipped. Video and JSON are not downloaded; study still points them at network URLs, which do not open offline.

Concurrent downloads of the same deck share one run.

Removing a deck or clearing the account’s data first stops the running download at its next step (dropping a half-written media file) and waits for it, and no new download starts until the removal is done. Otherwise the download would write the deck back as ready.

## Deck list

- Online: show the server list. Stats for downloaded decks are replaced with the local computation (see Stats).
- Offline: list only downloaded decks.
- The network looks up but the server is unreachable: list downloaded decks when any exist; otherwise the list errors.
- If the offline store cannot be opened, fall back to the server list.
- After a successful server delete, remove that deck’s local copy and media files no other downloaded deck uses. A local cleanup failure does not undo the delete. A rejected delete keeps the local copy.

While offline, the app does not poll and does not show shared-deck update badges.

## Study

When the study screen opens, it chooses local or online for that deck and **does not switch for the rest of the visit**. If the download finishes only after the screen opened online, the user must leave and enter again to study from the local copy. Offline without a local copy, each next card checks again, so a copy finished meanwhile is used.

| On entry | Behavior |
| --- | --- |
| Downloaded | Deal locally. While online, a background refresh still updates facts, media, and cards (see Download); cards with local changes keep their schedule. |
| Not downloaded, online | Use the online next-card API. |
| Not downloaded, offline | Ask the user to connect and download. No card is dealt. |

The next card updates the screen from the local result immediately. The upload is not on that path.

Tags: while online, refresh and cache the deck’s tags. An empty online result, including a failed request, keeps the cache. Offline study uses the cache only. A tag filter keeps cards whose facts have that tag. An empty filtered set shows the empty-filter state, not the download prompt.

Dealing uses only cards that still match a local fact. Front and back are built on the spot from the card template, the fact, and the deck fields. They are not stored as a separate display row. Audio and images prefer the local file, then the network URL.

## Card selection

Same rules as backend `GetNextCard`:

- Skip hidden cards, and cards whose interval (due − last review) is ≤ 0.
- Urgency = elapsed time ÷ interval, computed as 32-bit floats.
- Higher urgency is dealt first. Equal urgency uses the smaller ID.
- The following card in that order is prefetched for the UI.
- If last review is in the future, clamp it to now, keep the interval, then rank the card.

Review: last review is the earlier of the requested time and now. The new due time is last review + interval. Hide: mark that card hidden. Both write locally at once and append one pending upload each. Review and hide are never sent in the same request.

## Stats

For a downloaded deck these numbers are recomputed locally and update as soon as the user reviews or hides:

- Card count, fact count, unseen, reviewed, due, hidden, new cards today, last reviewed at.
- Unseen: not hidden, and the interval is exactly 1 second.
- Due: not hidden, and due time ≤ now.
- New today: the create day (UTC) is today.

Lifetime and today review counts are not recomputed from local cards. They are the counters from the last server alignment, plus not-yet-uploaded reviews for this deck. After a UTC day boundary, and until the next alignment, today’s count starts at 0 and adds only pending reviews created today.

Stats include every local card. Dealing drops cards with no matching fact, so the two can disagree.

## Sync

Each pending upload has a sequence number. Earlier actions are sent first. The request carries `Idempotency-Key` (that record’s ID).

When uploads run:

- After a review or hide: only when pending records are ≥ 100.
- Also without waiting for 100: entering the logged-in main shell, entering study, pausing or resuming the app, the network returning, and leaving those screens.
- Tapping the sync status: upload immediately and ignore backoff.
- Offline: skip the upload.

Per record:

| Result | What happens |
| --- | --- |
| Success | Remove it from the queue. If that card has no newer pending upload, replace the local schedule or hidden flag with the server response and clear the unconfirmed mark. |
| 401 | Stop the rest of this batch. Status becomes “Re-login required”. Records already sent are removed, and this batch does not refresh review counters. |
| 400 | Mark it failed and continue with other cards’ records. |
| 404 | Remove the record and the local card, then continue. |
| Network error | Back off this record (30s, 2m, 10m, 30m, 2h, then stay at 2h) and stop the batch. |
| Other HTTP | Back off this record the same way and continue with other cards’ records. After 8 HTTP errors it is marked failed. |

Records are FIFO per card: a failed record, or one waiting out its backoff, holds back every later record of the same card, so a newer schedule never lands before an older one. Other cards keep uploading.

The server ignores `Idempotency-Key`, so a review whose request failed with a network error may already be applied. Before resending such a review, the app reads the server card list (once per deck per batch). If the server card already has that review’s schedule, the record is confirmed from it and not sent again, so the review is not counted twice. Otherwise, or if the list cannot be read, it is resent.

Failed records are not sent again automatically. From the “Sync failed” status the user can **retry** (send them now, followed by the records they held back) or **discard** them (local card changes are kept, and the held records upload as usual). A card with nothing else queued loses its unconfirmed mark, so later downloads update its schedule again.

For each deck that had a success in the batch, the app fetches deck detail once and updates only the lifetime and today review counts. If that request fails, the deck is retried on the next upload run while the app stays open. The server card list does not replace local schedules.

Status shown in the UI (hidden once synced), in this order:

1. Re-login required
2. Sync failed (a failed record is in the queue, or the upload threw)
3. Offline
4. Syncing
5. Pending sync
6. Synced

Network failures, and HTTP errors still in backoff, stay on “Pending sync” or “Offline”. They do not show “Sync failed”.

## Logout

Empty queue: delete that account’s offline data and media, then log out.

When the queue is not empty, ask:

- **Sync and log out**: upload now. If the queue empties, clear data and log out. If anything remains, ask whether to keep or discard.
- **Keep and log out**: leave the data on device. The same account uploads it again after the next login.
- **Discard and log out**: delete the data, including reviews that were not uploaded.
- **Cancel**: do not log out.

Before deleting, the app stops running downloads and uploads and waits for the request in flight, so they cannot write deleted data back. Removing a deck does the same for that deck.

An offline-store error does not block logout.
