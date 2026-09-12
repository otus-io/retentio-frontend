# Flutter app — manual test checklist

🌐 English | [中文](manual_test_checklist_zh.md)

Paste this file into a **GitHub Issue** to get clickable checkboxes (`- [ ]` / `- [x]`). Viewing the file in the repo only renders boxes; toggling them requires editing the file or using an issue/PR.

**Prerequisites:** iOS and/or Android device or emulator · known API via `API_ENV` / `API_HOST` · at least two accounts (Author A, Importer B).

---

## 0. Setup & smoke

- [ ] `flutter doctor` is clean enough to run
- [ ] App launches (`flutter run` and/or release build)
- [ ] Cold start shows login (or restores session if already logged in)
- [ ] No crash on first frame
- [ ] App talks to the intended API env (`debug` / `dev` / `release`)

---

## 1. Authentication

### Login (`/login`)

- [ ] Valid credentials → success, lands on Decks tab
- [ ] Wrong password → shows server message (e.g. Invalid credentials), stays on login
- [ ] Empty fields → validation / blocked submit
- [ ] Loading state disables controls; no double-submit
- [ ] Password visibility toggle works (if present)
- [ ] Toolbar theme toggle works on login
- [ ] Toolbar language switch (EN / 中 / 日) updates strings immediately
- [ ] Register link opens register screen
- [ ] Forgot password opens forgot-password flow

### Register (`/register`)

- [ ] Happy path: email, username, password, confirm → success
- [ ] Empty fields → fill-all-fields error
- [ ] Password mismatch → error
- [ ] Duplicate username/email → readable API error
- [ ] Back to login works

### Forgot / reset password

- [ ] Forgot password: submit email → confirmation (“if account exists…”)
- [ ] Open reset link with `?token=` → set new password → can log in
- [ ] Missing/invalid token → clear error
- [ ] After reset, old password fails; new password works

### Verify email (`/verify-email?token=`)

- [ ] Valid token → success
- [ ] Missing token → missing-token error
- [ ] Invalid/expired token → error + path back to login

### Session / auth gate

- [ ] Logged-in user opening `/login` redirects to main
- [ ] Logged-out user cannot open `/study` (redirect to login)
- [ ] Kill app while logged in → session restored
- [ ] Logout → token cleared; Decks/Profile show lock placeholder
- [ ] Expired JWT → session-expired messaging / forced re-login (if reproducible)

---

## 2. Main navigation (tabs)

Tabs: **Decks** | **Discover** | **Profile**

- [ ] Tab switch works; list scroll position preserved where expected
- [ ] Guest / logged-out: Discover still accessible
- [ ] Guest: Decks & Profile show lock + Log in CTA → login
- [ ] After login from placeholder, expected tab content appears
- [ ] Discovery detail can be opened without auth (browse)
- [ ] Back from study / discovery detail returns sensibly

---

## 3. Profile

- [ ] Loads user header (username / email)
- [ ] Loading then content; error state + Retry works
- [ ] Change language: English / 日本語 / 简体中文 — strings update app-wide
- [ ] Change theme: Light / Dark / Sepia / System — applies immediately
- [ ] Theme persists after app restart
- [ ] Tags row opens Tags screen
- [ ] Logout: Cancel keeps session; Confirm logs out
- [ ] App version label visible at bottom

---

## 4. Tags (Profile → Tags)

- [ ] Empty state + create first tag
- [ ] Create tag (name required, optional description)
- [ ] Duplicate name → error
- [ ] Edit tag name/description
- [ ] Delete tag → removed from list
- [ ] Search filters by name/description
- [ ] Open tag → tagged facts list
- [ ] Tag picker from deck/fact editors: search, multi-select, create inline, Done

---

## 5. Decks list

- [ ] Empty state: No decks available
- [ ] Pull-to-refresh reloads
- [ ] Load-more / pagination works with many decks
- [ ] Error + Retry when API fails
- [ ] FAB opens Create Deck
- [ ] Draggable FAB position persists (`fab_decks`)
- [ ] Deck card shows name and stats (due / new / progress) correctly
- [ ] Tap deck → Study screen for that deck
- [ ] Published source: publish/update control + badge when unpublished changes exist
- [ ] Imported deck: check-updates control + badge when updates available
- [ ] Badges clear after publish/sync
- [ ] App background → foreground: sharing status polling resumes

---

## 6. Create / edit / delete deck

### Create

- [ ] Name required
- [ ] At least two column headers required; empty headers blocked
- [ ] Add / remove / reorder fields
- [ ] Cards-per-day rate picker updates interval hint
- [ ] Attach deck tags on create
- [ ] Save → deck appears in list; open study works

### Edit (Deck menu → Edit Deck)

- [ ] Rename deck → AppBar title updates
- [ ] Change rate
- [ ] Add / rename / reorder / remove fields (source decks)
- [ ] Imported deck edit restrictions honored
- [ ] Tag add/remove on deck
- [ ] Leave without save → deck unchanged

### Delete

- [ ] Confirm cancel → not deleted
- [ ] Confirm delete → leaves study, removed from list
- [ ] Published source → cannot delete; error toast shown

---

## 7. Study session (SRS)

- [ ] Loading → first due/urgent card
- [ ] Empty deck: no-cards messaging
- [ ] All caught up: message + Review Again
- [ ] Front only until reveal
- [ ] Flip / Show answer → back side
- [ ] Interval slider (Hard ↔ Easy) shows interval label on thumb
- [ ] Submit interval → next card; today’s-due progress advances
- [ ] Session progress does not incorrectly reset mid-session
- [ ] Hide card → skipped; not returned as next urgent
- [ ] Delete card → confirm copy correct; only that card removed; fact/other cards remain
- [ ] Tag filter: filter by deck tag → matching cards only; clear filter
- [ ] Tag filter empty → no-cards-for-tag message + Clear filter
- [ ] API error → toast; can recover
- [ ] Back to Decks; list stats refresh reasonably

---

## 8. Card content & fonts

### Text & ruby

- [ ] Plain text renders correctly
- [ ] Wiki ruby `[[漢字|かんじ]]` shows reading above base
- [ ] Mixed ruby + plain text wraps cleanly
- [ ] Invalid/partial markup shows as literal text (no crash)

### Media on card

- [ ] Audio play / pause / stop; no stuck overlap across cards
- [ ] Image loads; failed image shows load-failed state
- [ ] Video play; fullscreen enter/exit; controls usable
- [ ] Multiple media on one side; scrollable on small screens
- [ ] Short viewport / keyboard open: card + controls still usable

### Font sheet (Deck menu → Font)

- [ ] Front / Back tabs
- [ ] Typography controls update live preview
- [ ] Settings persist per deck and apply on study cards

---

## 9. Add / edit facts

### Add fact (Deck menu)

- [ ] Rows match deck fields; add/remove row where allowed
- [ ] Text-only save creates fact + cards
- [ ] Optional tags on fact
- [ ] Attach image (files + gallery)
- [ ] Attach video
- [ ] Attach / record audio (mic allow + deny)
- [ ] Long-press clears attachment
- [ ] Empty fact blocked with clear message
- [ ] After save, new cards appear in study (or after Review Again / reload)
- [ ] Imported deck: add goes through overlay / outbox path (not raw author write)

### Edit fact (Card menu)

- [ ] Edit text / media / tags; save reloads current card
- [ ] Ruby markup survives edit/display
- [ ] Source deck: direct save
- [ ] Imported deck: overlay + submit/stage to author
- [ ] Cancel discards unsaved changes

---

## 10. Discovery

### List

- [ ] Latest filter loads public decks
- [ ] Favorites filter: empty and populated states
- [ ] Search by name / author / tags
- [ ] Pull-to-refresh
- [ ] Error + Retry
- [ ] Card shows fact count, owner, relative time, imported/unavailable badges

### Detail (`/discovery/:id`)

- [ ] Loads fields, description, fact count
- [ ] Favorite / unfavorite (heart)
- [ ] Guest: Import prompts login
- [ ] Logged-in: Import → success toast → deck list refresh
- [ ] Go study opens imported deck
- [ ] Cannot import own deck → message
- [ ] Duplicate import → message
- [ ] Unavailable / not found → error UI + Retry
- [ ] After author re-publishes, importer sees update badge (cross-account)

---

## 11. Publish (source deck only)

- [ ] First publish → deck appears in Discovery
- [ ] Re-publish with changes → version / update preview as designed
- [ ] Re-publish with no changes → no-changes error (or equivalent)
- [ ] Publish refreshes Discovery
- [ ] List badge for unpublished changes clears after publish

---

## 12. Import collaboration

### Importer (imported deck)

- [ ] Deck menu shows Pending outbox + Check updates (no Publish / Contributions inbox)
- [ ] Edit fact / add fact / tag changes create pending items
- [ ] Outbox: Pending vs Sent tabs
- [ ] Select all / send selected / dismiss / clear
- [ ] Partial send failure messaging
- [ ] Report issue (Audio / Content / Other); Other requires details
- [ ] Check updates: summary; expand detail; accept/keep decisions; sync
- [ ] After sync, study matches decisions; list badge clears

### Author (published source)

- [ ] Deck menu: Contributions inbox
- [ ] List open contributions; load more
- [ ] Preview before/after text & audio
- [ ] Accept / Dismiss / Resolve
- [ ] Accepted changes on source; re-publish visible to importers

---

## 13. Cross-cutting UX / errors

- [ ] Airplane mode → network error copy; Retry recovers
- [ ] Localized API errors (not raw JSON) for common failures
- [ ] Toasts do not block the UI indefinitely
- [ ] Bottom sheets dismiss (drag / barrier / back)
- [ ] Destructive dialogs require confirm
- [ ] System back / iOS swipe-back does not strand navigation
- [ ] Smoke Light / Dark / Sepia / System × EN / JA / ZH on login, decks, study, discovery, profile

---

## 14. Device & build matrix

- [ ] iPhone or Simulator (portrait)
- [ ] Android phone or Emulator (portrait)
- [ ] Landscape: study card + media still usable
- [ ] Permission prompts: mic, photos (as used)
- [ ] Debug build smoke
- [ ] Release build smoke (`--release --dart-define=API_ENV=release`)
- [ ] Fresh install vs upgrade (session / FAB / font prefs)

---

## 15. End-to-end scenarios

- [ ] **Author lifecycle:** Register → create deck → add facts (text + audio + image + ruby) → study reviews → publish → edit facts → re-publish
- [ ] **Importer lifecycle:** Discover → favorite → import → study → edit/report → send contributions → author accept → importer check updates & sync
- [ ] **Auth recovery:** Forgot password → reset → login; verify email link; logout/login; session restore
- [ ] **Tags:** Create tags → attach to deck & facts → filter study by tag → manage from Profile
- [ ] **Empty / edge:** Empty decks, all caught up, hide cards, delete last card, delete deck

---

## 16. QA mode (imported decks, `docs/qa-mode.md`)

- [ ] Deck menu shows **QA mode** on imported decks only
- [ ] Columns already verified by a human start checked; columns without text/audio are disabled
- [ ] **Verified** confirm sheet lists the checked field names + PUT JSON; sending saves quality
- [ ] Quality API failures only toast inside QA mode — study, edit and sync keep working
- [ ] Column **Edit** → save sends a `fact_edit` contribution immediately (nothing left in the outbox)
