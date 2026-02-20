# Per-Key Redis Storage for Facts and Cards

Refactor facts and cards from monolithic JSON arrays to individual Redis keys. The current design stores all facts (and all
cards) for a deck as a single JSON blob, making every single-entity operation O(n). Moving to per-key storage reduces
`GetFact`, `UpdateFact`, and `UpdateCard` to O(1).

---

## Current Architecture

### Redis layout

| Key | Type | Content |
| --- | --- | --- |
| `deck:{id}:facts` | String | `[{"id":"abc","fields":["Apple","苹果"]}, ...]` (entire array) |
| `deck:{id}:cards` | String | `[{"fact_id":"abc","template_index":0, ...}, ...]` (entire array) |

### The problem: monolithic read-modify-write

Every operation that touches a single fact or card must:

1. `GET` the entire JSON array from Redis
2. `json.Unmarshal` the full array into memory
3. Linear scan to find the target element
4. Modify one element
5. `json.Marshal` the entire array
6. `SET` the entire blob back to Redis

This is O(n) for what should be O(1) work, and the non-atomic read-modify-write creates race conditions under concurrent
access.

### Complexity before refactor

| Handler | Complexity | Notes |
| --- | --- | --- |
| `GetFact` | O(f) | Deserializes all facts, linear scan |
| `UpdateFact` | O(f) | Full read-modify-write |
| `DeleteFact` | O(f+c) | Rebuilds both arrays |
| `UpdateCard` | O(c) | Full read-modify-write on hottest path |
| `GetNextCard` | O(c) | Must scan all cards for max urgency |
| `AddFact` | O(f+c) | Appends to both arrays |
| `GetDecks` | O(n*(f+c)) | Fetches all facts+cards for all decks |

---

## New Architecture

### Struct changes

`Fact` is unchanged (already has `ID` field). `Card` gains a new `ID` field:

```go
type Card struct {
    ID            string  `json:"id"`             // nanoid, assigned on creation
    FactID        string  `json:"fact_id"`
    TemplateIndex int     `json:"template_index"`
    LastReview    int64   `json:"last_review"`
    DueDate       int64   `json:"due_date"`
    Hidden        bool    `json:"hidden"`
    MinInterval   float64 `json:"min_interval"`
    MaxInterval   float64 `json:"max_interval"`
    CreatedAt     int64   `json:"created_at"`
}
```

### Redis layout (after migration)

| Key | Type | Content |
| --- | --- | --- |
| `deck:{id}:facts` | **Set** | Set of fact IDs |
| `fact:{factId}` | String | `{"id":"abc","fields":["Apple","苹果"]}` |
| `deck:{id}:cards` | **Set** | Set of card IDs |
| `card:{cardId}` | String | `{"id":"xyz","fact_id":"abc", ...}` |

### Redis command complexity reference

| Command | Time Complexity |
| --- | --- |
| `GET` | O(1) |
| `SET` | O(1) |
| `DEL` | O(1) per key |
| `MGET` | O(k) — k = number of keys |
| `SMEMBERS` | O(n) — n = set cardinality |
| `SISMEMBER` | O(1) |
| `SADD` | O(1) per member |
| `SREM` | O(1) per member |
| `SCARD` | O(1) |
| `EXISTS` | O(1) |
| `TxPipeline` | Batches commands into one round-trip; total = sum of individual commands |

### Complexity after refactor

| Handler | Before | After | Redis commands (after) | Round-trips |
| --- | --- | --- | --- | --- |
| `GetFact` | O(f) | **O(1)** | `SISMEMBER` O(1) + `GET` O(1) | 3 (GET deck + SISMEMBER + GET fact) |
| `UpdateFact` | O(f) | **O(1)** | `SISMEMBER` O(1) + `GET` O(1) + `SET` O(1) | 4 (GET deck + SISMEMBER + GET fact + SET fact) |
| `UpdateCard` | O(c) | **O(1)** | `SISMEMBER` O(1) + `GET` O(1) + `SET` O(1) | 4 (GET deck + SISMEMBER + GET card + SET card) |
| `DeleteFact` | O(f+c) | O(c) | `SREM` O(1) + `SMEMBERS` O(c) + `MGET` O(c) + pipeline `DEL`×t O(t) + `SREM`×t O(t) | 4 (GET deck + SREM + LoadCards + TxPipeline) |
| `AddFact` | O(f+c) | O(c) | `SMEMBERS` O(c) + `MGET` O(c) + pipeline `SET`×(f'+c) + `SADD`×(f'+c) | 3 (GET deck + LoadCards + TxPipeline) |
| `GetNextCard` | O(c) | O(c) | `SMEMBERS` O(c) + `MGET` O(c) + `SET` O(1) | 4 (GET deck + SMEMBERS + MGET + SET card) |
| `RescheduleDeck` | O(c) | O(c) | `SMEMBERS` O(c) + `MGET` O(c) + pipeline `SET`×c | 3 (GET deck + LoadCards + TxPipeline) |
| `GetFacts` | O(f) | O(f) | `SMEMBERS` O(f) + `MGET` O(f) | 3 (GET deck + SMEMBERS + MGET) |
| `GetCards` | O(f+c) | O(f+c) | `SMEMBERS` O(c) + `MGET` O(c) + `SMEMBERS` O(f) + `MGET` O(f) | 3 (GET deck + LoadCards + LoadFacts) |
| `GetDeck` | O(f+c) | **O(c)** | `SCARD` O(1) + `SMEMBERS` O(c) + `MGET` O(c) | 4 (GET deck + SCARD + LoadCards(2)) |
| `CreateDeck` | O(1) | O(1) | `SET` O(1) + `SADD` O(1) | 1 (TxPipeline) |
| `UpdateDeck` | O(1) | O(1) | `GET` O(1) + `SET` O(1) | 2 (GET + SET) |
| `DeleteDeck` | O(f+c) | O(f+c) | `SMEMBERS`×2 O(f+c) + pipeline `DEL`×(f+c+4) + `SREM` O(1) | 4 (GET deck + SMEMBERS×2 + TxPipeline) |
| `GetDecks` | O(n*(f+c)) | O(n*(f+c)) | `SMEMBERS` O(n) + `MGET` O(n) + pipeline `SCARD`×2n + per-deck `LoadCards` | 3+n (SMEMBERS + MGET + Pipeline + n×LoadCards) |

Where: f = facts in deck, c = cards in deck, n = number of decks, f' = new facts added, t = templates per deleted fact (usually 1-2).

---

## Handlers to Update

### [`backend-api/deck/fact.go`](backend-api/deck/fact.go)

| Handler | Change |
| --- | --- |
| `AddFact` | `SADD deck:{id}:facts` + `SET fact:{id}` per new fact. Cards still use monolithic array in Phase 1; per-key in Phase 2. |
| `GetFacts` | `SMEMBERS deck:{id}:facts` + `MGET fact:{id1}, fact:{id2}, ...` |
| `GetFact` | `SISMEMBER` for existence + `GET fact:{factId}` |
| `UpdateFact` | `SISMEMBER` + `GET fact:{factId}` + `SET fact:{factId}` |
| `DeleteFact` | `DEL fact:{factId}` + `SREM deck:{id}:facts`. Card cleanup via scan until Phase 2 adds secondary index. |

### [`backend-api/deck/card.go`](backend-api/deck/card.go)

| Handler | Change |
| --- | --- |
| `GetNextCard` | `SMEMBERS` + `MGET` to load all cards. Write-back of `MinInterval`/`MaxInterval` becomes single `SET card:{id}`. |
| `UpdateCard` | `GET card:{cardId}` + `SET card:{cardId}`. Lookup by card ID instead of `(factID, templateIndex)`. `last_review` required for interval updates. |
| `GetCards` | `SMEMBERS` + `MGET` for cards; facts via `SMEMBERS` + `MGET`. |
| `RescheduleDeck` | `SMEMBERS` + `MGET`, shift timestamps, pipeline `SET` each card back. |

### [`backend-api/deck/deck.go`](backend-api/deck/deck.go)

| Handler | Change |
| --- | --- |
| `CreateDeck` | Remove initialization of empty `"[]"` for facts/cards (empty Sets need no initialization). |
| `GetDecks` | Use pipeline `SCARD` for fact/card counts, `SMEMBERS` + `MGET` for full card data (stats computation). |
| `GetDeck` | `SCARD` for fact count, `SMEMBERS` + `MGET` for cards (stats only). Does not return facts or cards in response. |
| `DeleteDeck` | `SMEMBERS` both sets, pipeline `DEL` all individual fact/card keys + the sets themselves. |

---

## API Changes

### Endpoint rename

| Before | After |
| --- | --- |
| `GET /api/decks/{id}/urgent-card` | `GET /api/decks/{id}/card` |
| `PATCH /api/decks/{id}/urgent-card` | `PATCH /api/decks/{id}/card` |
| `GetUrgentCard` | `GetNextCard` |
| `UpdateUrgentCard` | `UpdateCard` |

### `UpdateCard` request body

The request body changes from `fact_id` + `template_index` to `card_id`, and requires `last_review` for interval updates:

**Before:**

```json
{ "fact_id": "abc123", "template_index": 0, "interval": 3600 }
```

**After (interval update — all three fields required):**

```json
{ "card_id": "xyz789", "interval": 3600, "last_review": 1704067200 }
```

**Visibility update (only card_id + hidden):**

```json
{ "card_id": "xyz789", "hidden": true }
```

- `card_id` is returned by `GetNextCard`, so the frontend always has it available at review time.
- `last_review` is a required unix timestamp for interval updates (client-supplied review time for offline sync). Must not be in the future. Not accepted with `hidden` updates.

All other API contracts remain unchanged.

---

## Migration Script

A one-time script converts existing Redis data from monolithic arrays to per-key storage.

### Per deck (atomic via TxPipeline)

1. Check if `deck:{id}:facts` is a String (old) or Set (already migrated)
2. Load and parse the JSON array of facts
3. For each fact: `SET fact:{factId} <factJSON>`, `SADD deck:{id}:facts factId`
4. Load and parse the JSON array of cards
5. For each card: generate nanoid, `SET card:{cardId} <cardJSON>`, `SADD deck:{id}:cards cardId`
6. `DEL` the old String keys

### Safety properties

- **Atomic per deck**: TxPipeline ensures all-or-nothing per deck
- **Idempotent**: Checks key type before converting; skips already-migrated decks
- **Reversible**: Keep Redis backup before running

---

## Redis Operation Reference

Key helper functions in `common/common.go`:

```go
func DeckKey(deckID string) string    { return fmt.Sprintf("deck:%s", deckID) }
func DeckFactsKey(deckID string) string { return fmt.Sprintf("deck:%s:facts", deckID) }
func DeckCardsKey(deckID string) string { return fmt.Sprintf("deck:%s:cards", deckID) }
func FactKey(factID string) string    { return fmt.Sprintf("fact:%s", factID) }
func CardKey(cardID string) string    { return fmt.Sprintf("card:%s", cardID) }
```

### `LoadFacts` — bulk retrieve all facts for a deck

Redis complexity: `SMEMBERS` O(f) + `MGET` O(f) = **O(f)**, 2 round-trips

```go
// fact.go:40-70
factIDs, err := common.RedisClient.SMembers(common.Ctx, common.DeckFactsKey(deckID)).Result()
// ...
keys := make([]string, len(factIDs))
for i, id := range factIDs {
    keys[i] = common.FactKey(id)
}
vals, err := common.RedisClient.MGet(common.Ctx, keys...).Result()
```

Pattern: `SMEMBERS deck:{id}:facts` → `MGET fact:{id1} fact:{id2} ...`

### `LoadCards` — bulk retrieve all cards for a deck

Redis complexity: `SMEMBERS` O(c) + `MGET` O(c) = **O(c)**, 2 round-trips

```go
// card.go:34-64
cardIDs, err := common.RedisClient.SMembers(common.Ctx, common.DeckCardsKey(deckID)).Result()
// ...
keys := make([]string, len(cardIDs))
for i, id := range cardIDs {
    keys[i] = common.CardKey(id)
}
vals, err := common.RedisClient.MGet(common.Ctx, keys...).Result()
```

Pattern: `SMEMBERS deck:{id}:cards` → `MGET card:{id1} card:{id2} ...`

### `SaveCards` — overwrite all cards for a deck

Redis complexity: `DEL` O(1) + c × (`SET` O(1) + `SADD` O(1)) = **O(c)**, 1 round-trip (pipelined)

```go
// card.go:68-84
pipe := common.RedisClient.TxPipeline()
cardsKey := common.DeckCardsKey(deckID)
pipe.Del(common.Ctx, cardsKey)
for _, card := range cards {
    cardJSON, _ := json.Marshal(card)
    pipe.Set(common.Ctx, common.CardKey(card.ID), string(cardJSON), 0)
    pipe.SAdd(common.Ctx, cardsKey, card.ID)
}
_, err := pipe.Exec(common.Ctx)
```

Pattern: `TxPipeline` → `DEL deck:{id}:cards` → per-card `SET card:{id}` + `SADD deck:{id}:cards`

### `AddFact` — store new facts and cards atomically

Redis complexity: `GET` O(1) + `LoadCards` O(c) + pipeline (`SET`+`SADD`)×f' + `DEL` O(1) + (`SET`+`SADD`)×c + `SET` O(1) = **O(f'+c)**, 3 round-trips

```go
// fact.go:346-380
pipe := common.RedisClient.TxPipeline()
factsKey := common.DeckFactsKey(deckID)
for _, fact := range newFacts {
    factJSON, _ := json.Marshal(fact)
    pipe.Set(common.Ctx, common.FactKey(fact.ID), string(factJSON), 0)
    pipe.SAdd(common.Ctx, factsKey, fact.ID)
}
cardsKey := common.DeckCardsKey(deckID)
pipe.Del(common.Ctx, cardsKey)
for _, card := range cards {
    cardJSON, _ := json.Marshal(card)
    pipe.Set(common.Ctx, common.CardKey(card.ID), string(cardJSON), 0)
    pipe.SAdd(common.Ctx, cardsKey, card.ID)
}
pipe.Set(common.Ctx, deckKey, updatedDeckData, 0)
_, err = pipe.Exec(common.Ctx)
```

Pattern: `TxPipeline` → per-fact `SET fact:{id}` + `SADD` → rebuild cards set → `SET deck:{id}`

### `GetFact` — O(1) single fact retrieval

Redis complexity: `GET` O(1) + `SISMEMBER` O(1) + `GET` O(1) = **O(1)**, 3 round-trips

```go
// fact.go:715-726
exists, err := common.RedisClient.SIsMember(common.Ctx, common.DeckFactsKey(deckID), factID).Result()
// ...
factData, err := common.RedisClient.Get(common.Ctx, common.FactKey(factID)).Result()
```

Pattern: `SISMEMBER deck:{id}:facts factId` → `GET fact:{factId}`

### `UpdateFact` — O(1) single fact update

Redis complexity: `GET` O(1) + `SISMEMBER` O(1) + `GET` O(1) + `SET` O(1) = **O(1)**, 4 round-trips

```go
// fact.go:517-550
exists, err := common.RedisClient.SIsMember(common.Ctx, common.DeckFactsKey(deckID), factID).Result()
// ...
factData, err := common.RedisClient.Get(common.Ctx, factKey).Result()
// ... modify factObj ...
err = common.RedisClient.Set(common.Ctx, factKey, updatedFactData, 0).Err()
```

Pattern: `SISMEMBER` → `GET fact:{id}` → modify → `SET fact:{id}`

### `DeleteFact` — remove fact and associated cards

Redis complexity: `GET` O(1) + `SREM` O(1) + `LoadCards` O(c) + pipeline `DEL` O(1) + t×(`DEL` O(1) + `SREM` O(1)) + `SET` O(1) = **O(c)**, 4 round-trips

```go
// fact.go:614-652
removed, err := common.RedisClient.SRem(common.Ctx, factsKey, factID).Result()
// ... load cards ...
pipe := common.RedisClient.TxPipeline()
pipe.Del(common.Ctx, common.FactKey(factID))
for _, card := range cards {
    if card.FactID == factID {
        pipe.Del(common.Ctx, common.CardKey(card.ID))
        pipe.SRem(common.Ctx, cardsKey, card.ID)
    }
}
pipe.Set(common.Ctx, deckKey, updatedDeckData, 0)
_, err = pipe.Exec(common.Ctx)
```

Pattern: `SREM deck:{id}:facts` → `TxPipeline` → `DEL fact:{id}` → per-card `DEL card:{id}` + `SREM` → `SET deck:{id}`

### `GetNextCard` — scan all cards, write back min/max interval

Redis complexity: `GET` O(1) + `LoadCards` O(c) + `SET` O(1) = **O(c)**, 4 round-trips

```go
// card.go:229-316
cards, err := LoadCards(deckID)         // SMEMBERS + MGET
// ... find most urgent card, compute minInterval/maxInterval ...
cardJSON, _ := json.Marshal(*nextUrgentCard)
err = common.RedisClient.Set(common.Ctx, common.CardKey(nextUrgentCard.ID), string(cardJSON), 0).Err()
```

Pattern: `LoadCards` (O(c) scan) → `SET card:{id}` (O(1) write-back)

### `UpdateCard` — O(1) card update by card_id

Redis complexity: `GET` O(1) + `SISMEMBER` O(1) + `GET` O(1) + `SET` O(1) = **O(1)**, 4 round-trips

```go
// card.go:441-496
isMember, err := common.RedisClient.SIsMember(common.Ctx, common.DeckCardsKey(deckID), cardID).Result()
// ...
cardData, err := common.RedisClient.Get(common.Ctx, cardKey).Result()
// ... modify card (interval or visibility) ...
err = common.RedisClient.Set(common.Ctx, cardKey, updatedCardData, 0).Err()
```

Pattern: `SISMEMBER deck:{id}:cards cardId` → `GET card:{cardId}` → modify → `SET card:{cardId}`

### `RescheduleDeck` — shift all cards forward by N days

Redis complexity: `GET` O(1) + `LoadCards` O(c) + pipeline c × `SET` O(1) = **O(c)**, 3 round-trips

```go
// card.go:565-613
cards, err := LoadCards(deckID)         // SMEMBERS + MGET
// ...
pipe := common.RedisClient.TxPipeline()
for i := range cards {
    cards[i].DueDate += shift
    cards[i].LastReview += shift
    cardJSON, _ := json.Marshal(cards[i])
    pipe.Set(common.Ctx, common.CardKey(cards[i].ID), string(cardJSON), 0)
}
_, err = pipe.Exec(common.Ctx)
```

Pattern: `LoadCards` → `TxPipeline` → per-card `SET card:{id}`

### `CreateDeck` — store deck and register to user

Redis complexity: `SET` O(1) + `SADD` O(1) = **O(1)**, 1 round-trip (pipelined)

```go
// deck.go:122-129
pipe := common.RedisClient.TxPipeline()
pipe.Set(common.Ctx, deckKey, deckJSON, 0)
pipe.SAdd(common.Ctx, fmt.Sprintf("user:%s:decks", username), deckID)
_, err = pipe.Exec(common.Ctx)
```

Pattern: `TxPipeline` → `SET deck:{id}` + `SADD user:{name}:decks`

### `GetDecks` — retrieve all decks with counts

Redis complexity: `SMEMBERS` O(n) + `MGET` O(n) + pipeline 2n × `SCARD` O(1) + n × `LoadCards` O(c) = **O(n*c)**, 3+n round-trips

```go
// deck.go:163-196
deckIDs, err := common.RedisClient.SMembers(common.Ctx, fmt.Sprintf("user:%s:decks", username)).Result()
// ...
decksData, err := common.RedisClient.MGet(common.Ctx, keys...).Result()

countPipe := common.RedisClient.Pipeline()
for i, id := range deckIDs {
    factsCountCmds[i] = countPipe.SCard(common.Ctx, common.DeckFactsKey(id))
    cardsCountCmds[i] = countPipe.SCard(common.Ctx, common.DeckCardsKey(id))
}
_, _ = countPipe.Exec(common.Ctx)
```

Pattern: `SMEMBERS user:{name}:decks` → `MGET deck:{id1} ...` → `Pipeline SCARD` for fact/card counts

### `GetDeck` — retrieve single deck with stats (no facts/cards in response)

Redis complexity: `GET` O(1) + `SCARD` O(1) + `LoadCards` O(c) = **O(c)**, 4 round-trips

```go
// deck.go:302-314
deckData, err := common.RedisClient.Get(common.Ctx, deckKey).Result()
// ...
factsCount, err := common.RedisClient.SCard(common.Ctx, common.DeckFactsKey(deckID)).Result()
cards, err := LoadCards(deckID)   // SMEMBERS + MGET
stats := ComputeStats(cards, int(factsCount))
```

Pattern: `GET deck:{id}` → `SCARD deck:{id}:facts` → `LoadCards` → `ComputeStats`

### `UpdateDeck` — read-modify-write single deck key

Redis complexity: `GET` O(1) + `SET` O(1) = **O(1)**, 2 round-trips

```go
// deck.go:362-445
deckData, err := common.RedisClient.Get(common.Ctx, deckKey).Result()
// ... modify deckObj ...
err = common.RedisClient.Set(common.Ctx, deckKey, updatedDeckData, 0).Err()
```

Pattern: `GET deck:{id}` → modify → `SET deck:{id}`

### `DeleteDeck` — remove deck and all associated data

Redis complexity: `GET` O(1) + `SMEMBERS` O(f) + `SMEMBERS` O(c) + pipeline (f+c+4)×`DEL` O(1) + `SREM` O(1) = **O(f+c)**, 4 round-trips

```go
// deck.go:488-539
deckData, err := common.RedisClient.Get(common.Ctx, deckKey).Result()
// ...
factIDs, err := common.RedisClient.SMembers(common.Ctx, common.DeckFactsKey(deckID)).Result()
cardIDs, err := common.RedisClient.SMembers(common.Ctx, common.DeckCardsKey(deckID)).Result()

pipe := common.RedisClient.TxPipeline()
pipe.Del(common.Ctx, deckKey)
pipe.Del(common.Ctx, fmt.Sprintf("%s:templates", deckKey))
pipe.Del(common.Ctx, common.DeckFactsKey(deckID))
pipe.Del(common.Ctx, common.DeckCardsKey(deckID))
for _, fid := range factIDs { pipe.Del(common.Ctx, common.FactKey(fid)) }
for _, cid := range cardIDs { pipe.Del(common.Ctx, common.CardKey(cid)) }
pipe.SRem(common.Ctx, fmt.Sprintf("user:%s:decks", username), deckID)
_, err = pipe.Exec(common.Ctx)
```

Pattern: `GET deck:{id}` → `SMEMBERS` both sets → `TxPipeline DEL` all keys + `SREM` from user set

### Migration script (`cmd/migrate/main.go`)

Redis complexity per deck: `GET` O(1) + `DEL` O(1) + f×(`SET` O(1) + `SADD` O(1)) + `GET` O(1) + `DEL` O(1) + c×(`SET` O(1) + `SADD` O(1)) = **O(f+c)**, 4 round-trips (2×GET + 2×TxPipeline)

```go
// migrateFacts: read old string, split into per-key
data, err := common.RedisClient.Get(ctx, factsKey).Result()
var facts []deck.Fact
json.Unmarshal([]byte(data), &facts)
pipe := common.RedisClient.TxPipeline()
pipe.Del(ctx, factsKey)
for _, f := range facts {
    fJSON, _ := json.Marshal(f)
    pipe.Set(ctx, common.FactKey(f.ID), string(fJSON), 0)
    pipe.SAdd(ctx, factsKey, f.ID)
}
_, err = pipe.Exec(ctx)

// migrateCards: same pattern, also generates IDs for old-format cards
data, err := common.RedisClient.Get(ctx, cardsKey).Result()
var cards []deck.Card
json.Unmarshal([]byte(data), &cards)
pipe := common.RedisClient.TxPipeline()
pipe.Del(ctx, cardsKey)
for i := range cards {
    if cards[i].ID == "" { cards[i].ID, _ = deck.GenerateCardID() }
    cJSON, _ := json.Marshal(cards[i])
    pipe.Set(ctx, common.CardKey(cards[i].ID), string(cJSON), 0)
    pipe.SAdd(ctx, cardsKey, cards[i].ID)
}
_, err = pipe.Exec(ctx)
```

Pattern: `GET` old String → parse JSON array → `TxPipeline` → `DEL` old key → per-entity `SET` + `SADD`

---

## Deployment Order

1. Backup Redis data
2. Run migration script
3. Deploy updated backend
4. Deploy updated frontend (UpdateCard now sends `card_id` to `/card`)
5. Verify by spot-checking decks via API
