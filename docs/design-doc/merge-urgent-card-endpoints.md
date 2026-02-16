# Merge into /urgent-card with GET/PATCH

## Current State

```
GET   /api/decks/{id}/next-urgent-card     → GetNextUrgentCard
PATCH /api/decks/{id}/cards/{cardIndex}    → UpdateCard
```

## Target State

```
GET   /api/decks/{id}/urgent-card          → GetUrgentCard  (renamed)
PATCH /api/decks/{id}/urgent-card          → UpdateUrgentCard (new, finds card by fact_id+template_index)
```

The old `PATCH /cards/{cardIndex}` route is removed. The frontend doesn't call it yet (review buttons are still TODO), so there's no backward-compat concern.

## How PATCH finds the card

Instead of trusting a numeric index from the URL, the PATCH body includes `fact_id` (required) and `template_index` (default 0). The backend iterates the cards array to find the match:

```go
var targetIndex = -1
for i, c := range cards {
    if c.FactID == factID && c.TemplateIndex == templateIndex {
        targetIndex = i
        break
    }
}
if targetIndex == -1 {
    // 404: card not found
}
```

This is O(n) but the array is small (typically <200 cards per deck) and eliminates the stale-index risk entirely.

## File Changes

### 1. backend-api/deck/card.go

- **Rename** `GetNextUrgentCard` to `GetUrgentCard` and update its swagger route annotation from `/next-urgent-card` to `/urgent-card`
- **Create** `UpdateUrgentCard` handler:
  - Extracts `fact_id` (required), `template_index` (optional, default 0) from body
  - Extracts `interval` or `hidden` from body (same logic as current UpdateCard)
  - Loads deck, verifies ownership, loads cards
  - Finds card by `fact_id` + `template_index` match (loop)
  - Performs interval or visibility update
  - Saves back to Redis
- **Remove** old `UpdateCard` function and its request structs (`UpdateIntervalRequest`, `UpdateVisibilityRequest` can stay since they describe the body shape, or be replaced by the generic map approach already used)
- **Remove** the `fact_id` guard added in the previous iteration (it's now unnecessary -- the lookup itself is the guard)
- **Keep** `card_index` in the GET response (useful for debugging, and removing it is a separate concern)

### 2. backend-api/main.go (line 159-161)

Replace:

```go
apiRouter.HandleFunc("/decks/{id}/cards/{cardIndex}", deck.UpdateCard).Methods("PATCH", "OPTIONS")
apiRouter.HandleFunc("/decks/{id}/next-urgent-card", deck.GetNextUrgentCard).Methods("GET", "OPTIONS")
```

With:

```go
apiRouter.HandleFunc("/decks/{id}/urgent-card", deck.GetUrgentCard).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/decks/{id}/urgent-card", deck.UpdateUrgentCard).Methods("PATCH", "OPTIONS")
```

### 3. backend-api/tests/integration/card_test.go

- **Update all route strings**: `next-urgent-card` to `urgent-card`, remove `cards/{cardIndex}` references
- **Update all PATCH calls**: change URL from `/cards/N` to `/urgent-card`, body already has `fact_id`; add `template_index` where needed (0 for single-template decks)
- **Remove** `TestUpdateCard` table-driven test (tests the old `/cards/{cardIndex}` route) or rewrite it for the new route
- **Remove** `TestUpdateCardNonNumericIndex` (no more cardIndex in URL)
- **Update** `TestUpdateCardFactIDVerification` -- the "mismatch" case becomes a 404 (card not found) instead of 409 (conflict)
- **Add** test for `PATCH /urgent-card` with unknown `fact_id` returning 404

### 4. frontend/lib/services/apis/card_service.dart (line 21)

Change:

```dart
final res = await ApiService.get('/api/decks/$deckId/next-urgent-card');
```

To:

```dart
final res = await ApiService.get('/api/decks/$deckId/urgent-card');
```

### 5. frontend/lib/models/card.dart

`cardIndex` field can remain for now (it's still in the GET response). No change needed.

### 6. Swagger

- backend-api/swagger/card.go: Rename `GetNextUrgentCardResponse` to `GetUrgentCardResponse`, remove `UpdateCardResponse` or rename
- Regenerate swagger docs after changes

### 7. Docs (mechanical find-replace)

- docs/API_PROGRESS_TRACKER.md: Update route names
- docs/misc/QUICKSTART.md + QUICKSTART_zh.md: Update examples
- docs/misc/CARD_TESTS.md: Update test descriptions

## What stays the same

- `GET /api/decks/{id}/cards` -- card stats endpoint (consolidated from former operation-based endpoints)
- `POST /api/decks/{id}/reschedule` -- unchanged
- The `Card` struct, `CardDetail` model, urgency calculation logic -- all unchanged
