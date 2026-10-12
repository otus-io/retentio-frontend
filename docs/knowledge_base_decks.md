# Decks and discovery

🌐 [中文](knowledge_base_decks_zh.md) · [Knowledge base](knowledge_base.md)

A learner manages their decks and opens study. An author edits a source deck and publishes it. An importer receives a copy pinned to a published version: progress stays on the copy, and a later source publish is optional to follow. A signed-out person can open one public deck’s detail from a link. Import and study still require login.

The client has no child decks.

## What a deck holds

`Deck` (`lib/models/deck.dart`) is one row in the user’s library.

| Field | Meaning |
| ----- | ------- |
| `id`, `name` | Identity and label |
| `owner` | Username and email. The client does not authorize from this; failures come back as API errors |
| `fields` | Fact column names. Only a source deck can edit or reorder them |
| `rate` | Daily new-card cap. Create defaults to 30. The UI clamps to 1–1000 |
| `minInterval`, `defInterval`, `maxInterval` | On the model. The study slider does not read them |
| `stats` | Card count, fact count, unseen, reviewed, due, hidden, new cards today, review counts |
| `sourceDeckId` | Non-empty means an imported copy |
| `sourceVersion` | Published version the copy is pinned to. 0 on a source deck |
| `publishedVersion` | Latest published version of a source deck. 0 means never published |
| `visibility` | The model has `private` / `public`. Create does not send it. Publish always sends `public` |

A `CatalogDeck` is not the library row. It is the public snapshot: name, optional description, owner username, columns, version, fact count, deck-tag names, published time. Its `id` is the source deck id.

Import returns the new deck id, the source id, the pinned version, and the import time.

## List and create

My decks come from `GET /api/decks`. The client does not sort. The API does not paginate; the list treats a page shorter than 20 as the end. Empty and error states are both shown. Error can be retried.

Tapping a card opens `/study` with that `Deck`.

Create opens from the list FAB:

- Trimmed name must be non-empty.
- At least two columns, each trimmed name non-empty. Columns can be added, removed, and reordered. At two columns, remove is disabled.
- `rate` defaults to 30.
- `POST /api/decks` sends name, columns, and rate.
- Optional tags are applied by diff after the deck exists.

## Edit and delete

Edit deck in the study menu reuses the create form.

- Source deck: name, columns, rate, and tags. `PATCH /api/decks/{id}`.
- Imported copy: name and columns are disabled. The save body is `rate` only. Tag changes become a pending contribution, not a direct edit of the source.

Delete is in the study menu and asks for confirmation.

- A source deck with `publishedVersion > 0`: the client refuses without calling delete. The server refuses as well.
- A never-published source deck, or an imported copy: delete is allowed. Success refreshes the list and leaves study.

## Publish

Entry points are the share control on a source-deck card, and the study menu.

- First publish: `POST /api/decks/{id}/publish` with `visibility` fixed to `public`.
- Already published: load `publish-preview`, show what changed since the last snapshot, then publish.
- Success refreshes discovery and shows the version.
- For a published source, the client polls the preview about every 60 seconds. Unpublished edits flash a badge. Polling pauses in the background and resumes in the foreground.

An imported deck cannot be published. The server rejects a publish with no changes; the client shows that error.

## Discovery and import

Discovery loads `GET /api/decks/catalog` with search and paging. Filters are Latest and Favorites.

Favorites are on-device (`discovery_favorite_ids` in `SharedPreferences`, source deck ids). The favorites filter refetches each id and filters the query locally. It is not server-paged.

Detail `GET /api/decks/catalog/{id}` is readable signed out: name, author, fact count, published time, version, columns, deck tags, description.

Import:

- Signed out → login.
- Signed in → `POST /api/decks/import` with `source_deck_id`.
- Success: toast, refresh my decks, the button becomes Study. Study loads the new deck again.
- Failure: show the API message. Known cases include importing your own deck, an unpublished source, and importing twice. The client does not pre-check “already imported”.
- Leaving the detail and returning does not remember the import. A second import fails on the server.

Catalog cards have slots for “imported” and “unavailable”. The list does not fill them, so every card is drawn as not imported.

## Updates on an imported copy

Entry points are the list refresh affordance and Check updates in the menu. `GET …/updates?summary=1`.

- No updates: “up to date”, sync disabled.
- Updates: version range and counts. One fact can be opened for detail.
- An edit or delete conflict is `accept` or `keep`.
- Sync: `POST …/sync` with the target version and those decisions. Success refreshes the list.

“Has updates” means the source version is newer than the pin, or a change count in the summary is non-zero. A new publish does not rewrite copies by itself.

Imported decks poll the summary about every 60 seconds and badge the list when updates exist.

## Code

`lib/models/deck.dart`, `lib/models/catalog_deck.dart`, `lib/models/publish_preview.dart`, `lib/models/deck_updates.dart`, `lib/screen/decks/`, `lib/features/discovery/`, `lib/services/apis/deck_service.dart`, `lib/services/apis/deck_catalog_service.dart`, `lib/services/apis/deck_publish_service.dart`.
