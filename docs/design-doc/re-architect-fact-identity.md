# Re-Architect: Fact Identity (Index to UUID)

Replace the fragile array-index-based fact references with stable UUIDs. This is a standalone architectural improvement that eliminates error-prone index-shifting on deletion and unblocks future features that need stable pointers to facts (tagging, bookmarks, sharing, cross-deck references).

- Consider using hash keys for the UUID
- Think about public decks, UUID might need to be longer

---

## Current Architecture

### How facts and cards are stored

A **Fact** is `type Fact []string` -- a raw string slice like `["Apple", "苹果"]`. Facts are stored as a JSON array in `deck:{deckId}:facts`. A **Card** references its fact by `FactIndex int`, which is the fact's position in that array.

```go
// deck/fact.go
type Fact []string

// deck/card.go
type Card struct {
    FactIndex     int     `json:"fact_index"`
    TemplateIndex int     `json:"template_index"`
    LastReview    int64   `json:"last_review"`
    DueDate       int64   `json:"due_date"`
    Hidden        bool    `json:"hidden"`
    MinInterval   float64 `json:"min_interval"`
    MaxInterval   float64 `json:"max_interval"`
    CreatedAt     int64   `json:"created_at"`
}
```

### Redis layout

| Key | Type | Example content |
|-----|------|-----------------|
| `deck:{id}:facts` | String | `[["Apple","苹果"], ["Dog","狗"], ["Cat","猫"]]` |
| `deck:{id}:cards` | String | `[{"fact_index":0, ...}, {"fact_index":1, ...}, ...]` |

### The problem: array indices are fragile

When a fact is deleted from the middle of the array, all subsequent facts shift down by one. Every card pointing to a shifted fact must have its `FactIndex` decremented. The current `DeleteFact` handler in [`backend-api/deck/fact.go`](backend-api/deck/fact.go) does this:

```go
// Lines 680-692 of fact.go -- the index-shifting logic
updatedCards := make([]Card, 0)
for _, card := range cards {
    if card.FactIndex < factIndex {
        updatedCards = append(updatedCards, card)
    } else if card.FactIndex > factIndex {
        card.FactIndex--
        updatedCards = append(updatedCards, card)
    }
    // Skip cards with the deleted fact index
}
```

**Example -- deleting "Dog" at index 1:**

```
BEFORE                              AFTER
facts: [                            facts: [
  [0] "Apple","苹果"                  [0] "Apple","苹果"    (unchanged)
  [1] "Dog","狗"       ← deleted      [1] "Cat","猫"        (was index 2!)
  [2] "Cat","猫"                    ]
]
                                    cards:
cards:                                {fact_index: 0}  "Apple" ✓
  {fact_index: 0}  "Apple"            {fact_index: 1}  must decrement 2→1
  {fact_index: 1}  "Dog"   ← removed
  {fact_index: 2}  "Cat"
```

This works, but:

1. **Every new feature** that references a fact (tags, bookmarks, shared links) would need the same shifting logic
2. **Concurrent modifications** could corrupt references if two operations shift indices simultaneously
3. **External references** (URLs, logs, analytics events) become invalid after any deletion
4. **Test fragility** -- tests must account for index shifting, making them harder to write and reason about

---

## New Architecture

### Struct changes

**Fact** -- from a raw string slice to a struct with a stable UUID:

```go
// deck/fact.go
type Fact struct {
    ID     string   `json:"id"`     // UUID, assigned on creation
    Fields []string `json:"fields"` // field values, e.g. ["Apple", "苹果"]
}
```

**Card** -- `FactIndex int` becomes `FactID string`:

```go
// deck/card.go
type Card struct {
    FactID        string  `json:"fact_id"`         // stable UUID reference
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

| Key | Type | Example content |
|-----|------|-----------------|
| `deck:{id}:facts` | String | `[{"id":"f-abc","fields":["Apple","苹果"]}, {"id":"f-def","fields":["Dog","狗"]}]` |
| `deck:{id}:cards` | String | `[{"fact_id":"f-abc", ...}, {"fact_id":"f-def", ...}]` |

### How deletion changes

**Before** (index-based): remove fact from array, scan all cards, decrement shifted indices.

**After** (UUID-based): remove fact from array, remove cards where `FactID == deletedFact.ID`. No shifting, no scanning unrelated cards.

```go
// New DeleteFact logic -- no index adjustment needed
updatedCards := make([]Card, 0, len(cards))
for _, card := range cards {
    if card.FactID != deletedFactID {
        updatedCards = append(updatedCards, card)
    }
}
```

### How fact lookup changes

**Before**: direct array index access -- `facts[card.FactIndex]` (O(1)).

**After**: build a map once per request, then look up by ID (O(1) amortized):

```go
// Build fact map (once per handler that needs it)
factMap := make(map[string]Fact, len(facts))
for _, f := range facts {
    factMap[f.ID] = f
}

// Look up a card's fact
fact, ok := factMap[card.FactID]
if !ok {
    // handle missing fact
}
```

**Performance**: Building the map is O(n) where n = number of facts. For a deck with 1000 facts, this takes microseconds. The current code already loads the entire facts array into memory for every operation, so the only addition is one loop.

---

## API Changes

The current fact endpoints use array indices in the URL path:

```
GET    /api/decks/{id}/facts/{factIndex}
PATCH  /api/decks/{id}/facts/{factIndex}
DELETE /api/decks/{id}/facts/{factIndex}
```

After migration, these switch to fact UUIDs:

```
GET    /api/decks/{id}/facts/{factId}
PATCH  /api/decks/{id}/facts/{factId}
DELETE /api/decks/{id}/facts/{factId}
```

The `AddFact` endpoint (`POST /api/decks/{id}/facts/{operation}`) is unchanged since it doesn't take a fact identifier. The response now includes the generated fact IDs:

```json
{
  "data": {
    "facts": [
      {"id": "a1b2c3d4-...", "fields": ["Apple", "苹果"]},
      {"id": "e5f6g7h8-...", "fields": ["Dog", "狗"]}
    ]
  },
  "meta": {"msg": "spread facts successfully, added 2 facts"}
}
```

Card endpoints that reference cards by index (`PATCH /api/decks/{id}/cards/{cardIndex}/{operation}`) remain index-based for now, since card identity is a separate concern. The card's internal `fact_id` field changes from `fact_index` in the JSON response.

---

## Handlers to Update

Every handler that reads or writes facts/cards needs modification. Here is the complete list with what changes:

### [`backend-api/deck/fact.go`](backend-api/deck/fact.go)

| Handler | Change |
|---------|--------|
| `AddFact` | Generate UUID for each new fact. Set `FactID` on new cards instead of `FactIndex`. Return fact IDs in response. |
| `GetFacts` | No logic change (returns the array as-is), but response shape changes from `[["a","b"]]` to `[{"id":"...","fields":["a","b"]}]`. |
| `GetFact` | Parse `factId` (string) from URL instead of `factIndex` (int). Search facts array by ID instead of indexing. |
| `UpdateFact` | Parse `factId` from URL. Find fact by ID in the array, update its `Fields`. |
| `DeleteFact` | Parse `factId` from URL. Remove fact by ID. Filter cards by `FactID != deletedID`. **No index shifting.** |
| `SearchFacts` | Iterate `fact.Fields` instead of `fact[fieldIndex]`. Return results with IDs. |
| `SpreadCards` | No change (operates on Card slices, doesn't touch FactIndex/FactID). |

### [`backend-api/deck/card.go`](backend-api/deck/card.go)

| Handler | Change |
|---------|--------|
| `GetNextUrgentCard` | Build `factMap`, look up `factMap[card.FactID]` instead of `facts[card.FactIndex]`. Return `fact_id` instead of `fact_index` in response. |
| `GetCards` | No logic change, but serialized JSON now has `fact_id` instead of `fact_index`. |
| `GetHiddenCards` | Build `factMap`, look up hidden card facts by ID instead of index. |
| `UpdateCard` | No change (doesn't reference facts). |
| `RescheduleDeck` | No change (only modifies timestamps, doesn't reference facts). |

### [`backend-api/deck/stats.go`](backend-api/deck/stats.go)

| Handler | Change |
|---------|--------|
| `ComputeStats` | No change (counts cards by state, doesn't reference FactIndex). |

### [`backend-api/deck/deck.go`](backend-api/deck/deck.go)

| Handler | Change |
|---------|--------|
| `CreateDeck` | No change (initializes empty facts/cards arrays). |
| `GetDecks` | Facts are parsed into `[]Fact` structs instead of `[][]string`. Stats computation unchanged. |
| `GetDeck` | Same as `GetDecks` -- facts shape changes in response. |
| `UpdateDeck` | No change (doesn't touch facts/cards). |
| `DeleteDeck` | No change (deletes entire keys). |

### Frontend

| File | Change |
|------|--------|
| `frontend/lib/models/card.dart` | `factIndex` → `factId` (String). Update `fromJson`/`toJson`. |
| `frontend/lib/models/deck.dart` | If facts are exposed in deck detail, update the fact model from `List<String>` to a struct with `id` + `fields`. |
| `frontend/lib/services/apis/card_service.dart` | Response parsing: `fact_id` instead of `fact_index`. |

---

## Request/Response Type Changes

### AddFactRequest -- unchanged

```go
type AddFactRequest struct {
    Facts [][]string `json:"facts"` // user still sends raw field arrays
}
```

The server generates UUIDs internally. Users never need to provide fact IDs.

### UpdateFactRequest -- unchanged

```go
type UpdateFactRequest []string // user sends updated field values
```

The fact is identified by URL path (`/facts/{factId}`), not by the request body.

### Fact JSON in responses

**Before**: `[["Apple", "苹果"], ["Dog", "狗"]]`

**After**: `[{"id": "a1b2c3d4", "fields": ["Apple", "苹果"]}, {"id": "e5f6g7h8", "fields": ["Dog", "狗"]}]`

### Card JSON in responses

**Before**: `{"fact_index": 0, "template_index": 0, ...}`

**After**: `{"fact_id": "a1b2c3d4", "template_index": 0, ...}`

---

## Migration Script

A one-time script to convert existing Redis data from the old format to the new format. This must run before deploying the updated handlers.

### Pseudocode

```go
func MigrateFactsToUUID() error {
    // Get all deck IDs from all users
    // For each user: SMEMBERS user:{username}:decks → deckIDs

    for each deckID {
        // 1. Load old facts
        factsJSON := redis.Get("deck:{deckID}:facts")
        var oldFacts [][]string
        json.Unmarshal(factsJSON, &oldFacts)

        // 2. Convert to new format, tracking index→ID mapping
        indexToID := make(map[int]string)
        newFacts := make([]Fact, len(oldFacts))
        for i, fields := range oldFacts {
            id := uuid.New().String()
            indexToID[i] = id
            newFacts[i] = Fact{ID: id, Fields: fields}
        }

        // 3. Load cards and update references
        cardsJSON := redis.Get("deck:{deckID}:cards")
        var cards []Card  // still has old FactIndex field during migration
        json.Unmarshal(cardsJSON, &cards)

        for i := range cards {
            cards[i].FactID = indexToID[cards[i].FactIndex]
            cards[i].FactIndex = 0  // zero out old field
        }

        // 4. Save both atomically
        pipe := redis.TxPipeline()
        pipe.Set("deck:{deckID}:facts", json.Marshal(newFacts))
        pipe.Set("deck:{deckID}:cards", json.Marshal(cards))
        pipe.Exec()
    }
}
```

### Migration safety

- **Atomic per deck**: Each deck's facts + cards are updated in a single Redis transaction. If one deck fails, others are unaffected.
- **Idempotent**: If run twice, the second run would parse facts as `[]Fact` structs (new format) and skip conversion. The migration should check the format before converting.
- **Reversible**: Keep a backup of the Redis data before running. The old format can be reconstructed by stripping IDs and converting back to `[][]string`.
- **No downtime required**: Run the migration, then deploy the new code. During the gap, old code reads old-format data as usual. New code reads new-format data.

### Deployment order

1. **Backup** Redis data
2. **Run migration** script -- converts all existing facts/cards
3. **Deploy** updated backend handlers
4. **Deploy** updated frontend
5. **Verify** by spot-checking a few decks via API

---

## Tests to Update

### Unit tests ([`backend-api/tests/unit/`](backend-api/tests/unit/))

| Test file | Change |
|-----------|--------|
| `spread_test.go` | Update test Card structs: `FactIndex` → `FactID` with string values. `SpreadCards` logic is unchanged. |
| `stats_test.go` | Update test Card structs: `FactIndex` → `FactID`. `ComputeStats` logic is unchanged. |

### Integration tests ([`backend-api/tests/integration/`](backend-api/tests/integration/))

| Test file | Change |
|-----------|--------|
| `fact_test.go` | All fact operations: assert on `fact_id` (UUID string) instead of integer indices. `DeleteFact` tests no longer need to verify index shifting. |
| `card_test.go` | Card responses: assert `fact_id` field. `GetNextUrgentCard` returns `fact_id`. |
| `deck_test.go` | `GetDeck` response: facts are objects with `id` + `fields`, not raw arrays. |

### New tests

- `TestDeleteFactNoIndexShift`: Delete a fact in the middle, verify remaining cards still point to correct facts by UUID without any index adjustment.
- `TestMigrationScript`: Create old-format data, run migration, verify new-format output with correct UUID references.

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Fact type | `[]string` | `struct { ID string; Fields []string }` |
| Card→Fact reference | `FactIndex int` (array position) | `FactID string` (UUID) |
| Fact deletion | Remove + shift all higher indices in cards | Remove + filter cards by FactID |
| Fact lookup | `facts[index]` | `factMap[factID]` |
| API URL for single fact | `/facts/{factIndex}` (integer) | `/facts/{factId}` (UUID) |
| External references | Break on any deletion | Stable forever |
| Index-shifting code | ~12 lines in DeleteFact, must be replicated for any new feature | Eliminated entirely |
