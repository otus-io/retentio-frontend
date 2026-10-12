# Retentio business knowledge base

🌐 [中文](knowledge_base_zh.md)

The in-app brand is **Rete** (`kAppName` in `lib/constants.dart`, and `appTitle` in the en / zh / ja catalogs). The repository is Retentio.

These pages record the business rules the Flutter client implements today. Where a server-side formula is not visible to the client, the text says so. If `api_progress_tracker.md`, `offline_learning_cache_plan.md`, `hive-local-storage.md`, or `plan_add_facts.md` disagree with this knowledge base, follow this knowledge base and the code. The API progress tracker in particular marks several client calls as missing that the services already make.

## Product

Rete is an online-first spaced-repetition vocabulary client. A user owns decks. A deck is made of facts. The server turns each fact into study cards through a template. A study session fetches the most urgent card, shows the front for recall, flips to the back, and submits a next interval chosen on a slider. An author can publish a source deck. Someone else imports a private copy, studies and edits that copy, then sends edits to the author as contributions. After a later publish, the importer reviews the diff and accepts each change or keeps the local version.

Fetching a card, grading it, editing a fact, and uploading media all go over HTTP. A review round cannot finish offline. The device persists the session, preferences, discovery favorites, and the contribution outbox.

## Domains

| Document | Question it answers |
| -------- | ------------------- |
| [Account and navigation](knowledge_base_auth.md) | Who can open which screen, and how a session is kept |
| [Decks and discovery](knowledge_base_decks.md) | Deck life cycle from create through publish, import, and sync |
| [Study](knowledge_base_study.md) | One review, and how interval and progress are chosen |
| [Facts, tags, and collaboration](knowledge_base_content.md) | How content is written, filtered, and shared between importer and author |
| [Data and media](knowledge_base_data.md) | Where data lives, how media moves, and what remains offline |

## Objects

```text
User
 └─ source deck (empty sourceDeckId)
     ├─ column names (fields), daily new-card cap (rate)
     ├─ Fact (one row of entries: text / image / audio / video)
     ├─ Card (study unit pointing at factId; front and back filled by the server)
     └─ published snapshot → CatalogDeck
            └─ someone imports → copy (new id, pinned sourceDeckId + sourceVersion)
```

Tags belong to the user and can be attached to a deck or a fact. The study filter uses fact tags only.

Adding a fact does not send a template, so the server decides how many cards a fact becomes. The usual case is one card. The model allows sibling cards. Deleting one card leaves the fact and its other cards in place. The client has no template editor and no delete-fact action.

## Two kinds of deck

| | Source deck | Imported copy |
| --- | --- | --- |
| Test | `sourceDeckId` is empty | `sourceDeckId` is set |
| Rename and edit columns | Allowed | UI locks them; save sends `rate` only |
| Publish | Allowed, and the UI always sends `public` | Not allowed |
| Delete | Blocked in the client once `publishedVersion > 0` | Allowed |
| Contributions | Inbox, for a published source | Outbox |
| QA | Not in the menu | In the menu |
| Updates | Publish preview for unpublished edits | Diff against the source; accept or keep local |

An imported deck is never treated as a published source, even if `publishedVersion` is set.

## One review

1. Open a deck. Ask the server for the most urgent card. A fact tag may narrow the queue.
2. Read the front. Show Answer only flips the card.
3. On the back, pick the next interval in seconds. Short, middle, and long are `current interval (at least 5 minutes) × how overdue the card is`. Deck `minInterval`, `defInterval`, and `maxInterval` are not read. Details are in [Study](knowledge_base_study.md).
4. Next submits `interval` plus the client’s `last_review`. The server writes the new due time.
5. On success the prefetched next card is shown. On failure the current card stays.

Hide is a separate submit (`hidden: true`). It cannot share a request with an interval.

## Rules that cross domains

- Route access follows `AuthBloc` status `authenticated`, not the `isLogin` flag alone.
- Paths that skip login: `/login`, `/register`, `/reset-password`, `/verify-email`, and any `/discovery/` detail. The shell `/` and study `/study` require login.
- There is no refresh token. A 401 clears the local token, restores the session, and sends protected routes back to login.
- An unverified email does not block login. The profile screen can resend the mail.
- Registration does not sign the user in.
- Discovery favorites stay on the device.
- An importer’s edit lands on their copy immediately. Sending it to the author is a manual outbox action.
- The client has no offline review queue and no holiday-reschedule screen. `/reschedule` exists as a path constant and an error string.

## Not in the client

- Offline study of a whole deck, a local scheduler, or a review upload queue
- Child decks
- Choosing prepend / shuffle / spread when adding a fact, or editing the card template
- Deleting a fact, or editing the profile (`PATCH /api/profile` is not called)
- Rankings
- A “already imported” mark on catalog cards
- Choosing private vs public at create time (publish hard-codes public)

## Code map

| Area | Path |
| ---- | ---- |
| Startup and shell | `lib/main.dart`, `lib/pre_config.dart` |
| Routes | `lib/routers/routers.dart`, `lib/routers/app_pages.dart` |
| Auth | `lib/features/auth/` |
| Deck list and discovery | `lib/screen/decks/`, `lib/features/discovery/` |
| Study | `lib/features/deck_study/`, `lib/screen/deck/` |
| Facts and contributions | `lib/screen/deck/fact_widgets/`, `lib/features/contributions/` |
| QA | `lib/screen/qa/` |
| API | `lib/services/api.dart`, `lib/services/apis/` |
