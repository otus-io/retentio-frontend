# Data and media

🌐 [中文](knowledge_base_data_zh.md) · [Knowledge base](knowledge_base.md)

The client is online-first. Decks, facts, due times, tags, the catalog, contributions, statistics, and media bytes are authoritative on the server. The device keeps the session, preferences, discovery favorites, the contribution outbox, and temporary media downloaded for playback.

`local_decks`, `local_facts`, `local_cards`, and `review_outbox` from `offline_learning_cache_plan.md` and `hive-local-storage.md` are not implemented under `lib/`.

## Three layers

| Layer | Holds | If the network drops |
| ----- | ----- | -------------------- |
| Remote API | Business data | Fetch and grade fail. A failed fetch usually looks like “no card”, not a dedicated offline message |
| Memory | Deck list, current study card, prefetch, filter, player | Gone when the process ends. Sign-out invalidates the deck list and profile |
| Device | Table below | Still there. Images and audio already downloaded may still open. Video is not cached as a file |

### Device keys

| Store | Key | Contents |
| ----- | --- | -------- |
| SharedPreferences | `token` / `isLogin` | Session |
| SharedPreferences | `localeCode` | Locale |
| Hive `hydrated_box` | `ThemeModeNotifier` | light / dark / sepia / system |
| SharedPreferences | `discovery_favorite_ids` | Favorite source-deck ids |
| SharedPreferences | `retentio_pending_contribs_v2:{deckId}` | Pending contributions |
| SharedPreferences | `retentio_sent_contribs_v1:{deckId}` | Sent history, at most 200 |
| SharedPreferences | `qa_columns_{deckId}` | QA column checks |
| SharedPreferences | `deck_typography_*_{deckId}` | Front, back, and ruby sizes for that deck |
| Temp `audio/` | By remote URL | Audio playback cache. Under 256 bytes is treated as invalid |
| Temp | Image cache | Study images. Requests send the bearer token |
| Temp | `fact_voice_*` | A recording not uploaded yet |

## Environment and auth

`--dart-define=API_ENV=debug|dev|release`. When omitted, a release build uses release and any other build uses dev. `--dart-define=API_HOST=` wins over the table.

| `API_ENV` | Host |
| --------- | ---- |
| `debug` | `http://localhost:8080` |
| `dev` | `https://10.0.0.145:8443` |
| `release` | `https://api.retentio.app:8443` |

When a token exists, requests send `Authorization: Bearer <token>`. Image and video playback attach the same header themselves. A 401 clears the token and restores the session. See [Account and navigation](knowledge_base_auth.md).

There is no global retry queue. The image loader retries a few times on its own. Concurrent downloads of the same audio share one request.

## Endpoints the client actually calls

Several “frontend not started” rows in `docs/api_progress_tracker.md` are stale. These are the calls `lib/` makes.

| Domain | Actions |
| ------ | ------- |
| Auth | `POST /auth/register`, `/auth/login`, `/auth/logout`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/verify-email`, `/auth/resend-verification` |
| Profile | `GET /api/profile` |
| Decks | `GET/POST /api/decks`, `GET/PATCH/DELETE /api/decks/{id}` |
| Study | `GET/PATCH /api/decks/{id}/card`; `DELETE /api/decks/{id}/cards/{cardId}`; `GET /api/decks/{id}/cards?stats_only=true` (optional `tag_id`) |
| Facts | `POST /api/decks/{id}/facts/append`; `GET/PATCH /api/decks/{id}/facts/{factId}`; `GET /api/decks/{id}/facts/ids` |
| Media | `POST /api/media`. Playback URLs are built as `/api/media/{id}`, with an optional `?v=` on update diffs |
| Tags | CRUD on `/api/tags`; attach, detach, and list deck tags and fact tags |
| Catalog | `GET /api/decks/catalog`, `GET /api/decks/catalog/{id}`, `POST /api/decks/import` |
| Sync | `GET /api/decks/{id}/updates`, `GET …/updates/facts/{factId}`, `POST …/sync` |
| Publish | `POST /api/decks/{id}/publish`, `GET …/publish-preview` |
| Contributions | Submit report / edit / add / fact_tags / deck_tags; `GET …/contributions`; accept; `PATCH` status |
| Statistics | `GET /api/decks/{id}/reviews/by-day?days=` |
| QA | `GET/PUT …/facts/{factId}/quality`; `GET …/quality/stats` |

Defined but not used by study or the outbox: the paged fact list, `/reschedule`, field-rename contributions, and template contributions.

## How media moves

Pick a file, the gallery, or the microphone → size and type check → hang the local path on the add/edit row → upload when the fact is saved → replace the path with a media id → the server places that media into card slots when a card is served.

Starting a recording pauses card audio so the microphone can take the audio session.

During study:

- Images use an authenticated cache. Failure shows a load-failed state.
- Audio is downloaded into the temp directory before play. Card fetch and prefetch try to warm this cache and stay silent on failure. A failed load is only the control’s unavailable state.
- Video streams the network URL with the bearer token and does not write a local file. It pauses on flip or leave.

A card item of type `json` is not rendered.

## Failures the user can see

| Case | What happens |
| ---- | ------------ |
| Grade or hide fails | Error toast, current card stays |
| Next-card fetch fails | Usually the empty-card copy, not a “network error” |
| Fact upload or save fails | A snack. How much of the form remains depends on that screen |
| Contributions | Device-only until the user opens the outbox. Success and failure both toast |
| 401 | The login flow, without its own global toast |

## Code

`lib/services/env.dart`, `lib/services/api.dart`, `lib/services/apis/`, `lib/pre_config.dart`, `lib/features/deck_study/data/repositories/deck_study_legacy_service_repository.dart`, `lib/screen/deck/fact_add_composer/media_handling_coordinator.dart`, `lib/utils/audio_cache_utils.dart`, `lib/features/contributions/pending_contributions_store.dart`.
