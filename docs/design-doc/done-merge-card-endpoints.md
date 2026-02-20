# Merge Card Endpoints into GET/PATCH /card

Consolidated the card review endpoints into a single REST resource at `/api/decks/{id}/card`.

## Endpoints

```text
GET   /api/decks/{id}/card   → GetNextCard   (returns the next card to review)
PATCH /api/decks/{id}/card   → UpdateCard    (updates interval or visibility by card_id)
```

## How PATCH finds the card

The PATCH body includes `card_id` (required). The backend does an O(1) `SISMEMBER` check against the deck's card set,
then `GET`/`SET` on the individual card key:

```go
isMember, _ := common.RedisClient.SIsMember(ctx, common.DeckCardsKey(deckID), cardID).Result()
cardData, _ := common.RedisClient.Get(ctx, common.CardKey(cardID)).Result()
// ... modify ...
common.RedisClient.Set(ctx, common.CardKey(cardID), updatedData, 0)
```

## Request body

Interval update (`last_review` is required — unix timestamp from the client):

```json
{ "card_id": "xyz789", "interval": 3600, "last_review": 1704067200 }
```

Visibility toggle:

```json
{ "card_id": "xyz789", "hidden": true }
```

## Routes

```go
apiRouter.HandleFunc("/decks/{id}/card", deck.GetNextCard).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/decks/{id}/card", deck.UpdateCard).Methods("PATCH", "OPTIONS")
```

## What stays the same

- `GET /api/decks/{id}/cards` -- card stats endpoint
- `POST /api/decks/{id}/reschedule` -- unchanged
- The `Card` struct, urgency calculation logic -- all unchanged
