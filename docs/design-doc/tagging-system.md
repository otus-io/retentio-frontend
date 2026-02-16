# Tagging System

A many-to-many classification system for WordUpX that allows users to organize, filter, and cross-reference decks using tags. Unlike a folder structure (one-to-many), tags let a single deck belong to multiple categories simultaneously -- a Chinese-English translation deck can be tagged under both "Chinese" and "English", and a History and Philosophy of Art deck can appear under "Art", "History", and "Philosophy".

---

## Current Architecture: How Decks, Facts, and Cards Work

Before designing the tagging system, this section documents the existing data model and how the three core entities relate to each other.

### Entity overview

A **Deck** is a collection of vocabulary pairs with a spaced-repetition schedule. A **Fact** is a single vocabulary entry (e.g., `["Apple", "苹果"]`). A **Card** is a reviewable flashcard generated from a fact + template combination.

```
Deck "GRE Vocabulary" (id: abc-123)
  │
  ├── Fields: ["English", "Chinese"]
  ├── Templates: [[0,1], [1,0]]      ← two directions: EN→ZH, ZH→EN
  ├── Rate: 10                        ← new cards per day
  │
  ├── Facts (deck:abc-123:facts):
  │     index 0: ["Apple", "苹果"]
  │     index 1: ["Dog", "狗"]
  │     index 2: ["Cat", "猫"]
  │
  └── Cards (deck:abc-123:cards):
        card 0: {fact_index: 0, template_index: 0, ...}  ← "Apple" EN→ZH
        card 1: {fact_index: 0, template_index: 1, ...}  ← "Apple" ZH→EN
        card 2: {fact_index: 1, template_index: 0, ...}  ← "Dog" EN→ZH
        card 3: {fact_index: 1, template_index: 1, ...}  ← "Dog" ZH→EN
        card 4: {fact_index: 2, template_index: 0, ...}  ← "Cat" EN→ZH
        card 5: {fact_index: 2, template_index: 1, ...}  ← "Cat" ZH→EN
```

### Structs

```go
// deck/deck.go
type Deck struct {
    Name      string    `json:"name"`
    Owner     string    `json:"owner"`
    Fields    []string  `json:"fields"`      // e.g. ["English", "Chinese"]
    Templates [][]int   `json:"templates"`   // e.g. [[0,1], [1,0]]
    Rate      int       `json:"rate"`        // new cards per day
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// deck/fact.go
type Fact []string  // e.g. ["Apple", "苹果"] -- just a raw string slice

// deck/card.go
type Card struct {
    FactIndex     int     `json:"fact_index"`      // index into the facts array
    TemplateIndex int     `json:"template_index"`  // index into Deck.Templates
    LastReview    int64   `json:"last_review"`     // unix timestamp
    DueDate       int64   `json:"due_date"`        // unix timestamp
    Hidden        bool    `json:"hidden"`          // user can hide mastered cards
    MinInterval   float64 `json:"min_interval"` // min interval for next review
    MaxInterval   float64 `json:"max_interval"` // max interval for next review
    CreatedAt     int64   `json:"created_at"`      // unix timestamp
}
```

### Redis storage

| Key | Type | Content |
|-----|------|---------|
| `deck:{deckId}` | String | Deck JSON (name, owner, fields, templates, rate, timestamps) |
| `deck:{deckId}:facts` | String | JSON array of facts: `[["Apple","苹果"], ["Dog","狗"], ...]` |
| `deck:{deckId}:cards` | String | JSON array of cards: `[{fact_index:0, ...}, ...]` |
| `user:{username}:decks` | Set | Set of deck IDs owned by this user |

### How facts and cards are linked

Cards reference facts by **array index**. `Card.FactIndex = 2` means "this card tests the fact at position 2 in the `deck:{id}:facts` array." When a template is `[0,1]`, it means "show field 0 (English) on the front and field 1 (Chinese) on the back."

Each fact generates one card per template. A deck with 100 facts and 2 templates has 200 cards.

### Key operations

**Adding facts** (`POST /api/decks/{id}/facts/{operation}`):

1. Append new facts to the facts array
2. For each new fact, create one card per template, with `FactIndex = len(existingFacts) + i`
3. Spread/shuffle/append/prepend the new cards among unseen cards
4. Schedule the unseen cards with staggered `DueDate` values based on `Deck.Rate`
5. Save facts and cards atomically via Redis transaction

**Getting the next urgent card** (`GET /api/decks/{id}/next-urgent-card`):

1. Load all cards, compute urgency for each: `urgency = (now - LastReview) / (DueDate - LastReview)`
2. Pick the non-hidden card with the highest urgency
3. Look up `facts[card.FactIndex]` to get the vocabulary content
4. Look up `deck.Templates[card.TemplateIndex]` to determine front/back fields
5. Compute min/max/default intervals for the user's response
6. Return the card, fact, template, and interval options to the frontend

**Deleting a fact** (`DELETE /api/decks/{id}/facts/{factIndex}`):

1. Remove the fact from the array at the given index
2. Remove all cards that reference `FactIndex == deletedIndex`
3. **Decrement `FactIndex` for every card where `FactIndex > deletedIndex`** (because all later facts shifted down by one)
4. Save both arrays atomically

This index-shifting on deletion is the key fragility that the Fact ID migration (documented below) addresses.

**Reviewing a card** (`PATCH /api/decks/{id}/cards/{cardIndex}/update-interval`):

1. User sees the card, decides how well they know it, frontend sends an interval
2. Validate the interval is within the card's `[MinInterval, MaxInterval]` range
3. Set `card.DueDate = now + interval` and `card.LastReview = now`
4. Save cards back to Redis

---

## Benefits

1. **Flexible classification** -- A deck can belong to many categories at once. With folders, a History of Art deck must live in one place; with tags, it surfaces under Art, History, and Philosophy.
2. **Boolean search** -- Users can express complex queries: `Chinese AND English AND NOT History` to find exactly what they need.
3. **Per-user organization** -- Each user maintains their own tag system in their own language. Importing a public deck doesn't force someone else's categorization onto you.
4. **Aggregated statistics** -- Show combined stats (total due cards, overall progress) for a tag group, giving users a bird's-eye view of a learning goal.
5. **Public deck discovery (future)** -- Tags become the primary browse/search mechanism for community decks.
6. **Cross-deck vocabulary queries (Phase 2)** -- Fact-level tags enable queries like "show all verbs I'm learning" across every deck.

---

## Core Concepts

### Tags are per-user

Every user has their own set of tags. User A's "English" tag and User B's "English" tag are independent entities stored separately. This means:

- Users can organize in their own language and style
- No global tag namespace conflicts
- No one else's tagging choices pollute your system

### Tags vs. folders

| Aspect | Folders (one-to-many) | Tags (many-to-many) |
|--------|----------------------|---------------------|
| A deck can belong to... | Exactly one folder | Many tags |
| Finding "Philosophy of Art" under Art | Yes (if you put it there) | Yes |
| Finding "Philosophy of Art" under Philosophy | No (it's in the Art folder) | Yes |
| User decision burden | Must choose one folder | Add all relevant tags |
| Reorganizing | Move = loses old location | Add/remove tags freely |

---

## Phase 1: Deck-Level Tags

### Tag data model

Tags are a proper entity, not just strings. Each tag has a unique ID, a name identifier, and an optional description.

```go
type Tag struct {
    ID          string `json:"id"`          // UUID, auto-generated
    Name        string `json:"name"`        // alphanumeric identifier, e.g. "FoodRecipes"
    Description string `json:"description"` // optional, user's note about this tag
    ParentID    string `json:"parent_id"`   // reserved for Phase 3 (hierarchical tags), empty for now
}
```

Why a `Description` field: tag names like "NLP" or "SRS" become cryptic months later. An optional description ("Natural Language Processing - graduate school coursework") costs nothing and helps the user remember why a tag exists.

### Tag name rules

- Alphanumeric characters only, no spaces: `FoodRecipes`, `GRE2026`, `ChineseEnglish`
- Case-insensitive storage (normalized to lowercase internally), case-preserving display
- Max 50 characters
- Must be unique per user (enforced on create)

### Association model

Tags and decks are linked through a separate association, not embedded in the Deck struct. This keeps the Deck model clean and makes boolean queries efficient.

**Conceptual schema** (implemented in Redis, not SQL):

```
Tags:       (UserID, TagID, Name, Description, ParentID)
DeckTags:   (UserID, DeckID, TagID)  -- unique on all three fields
```

### Redis key design

| Key | Type | Purpose |
|-----|------|---------|
| `user:{username}:tag:{tagId}` | String (JSON) | Tag entity (name, description, parentId) |
| `user:{username}:tags` | Set | Set of all tagIds for this user |
| `user:{username}:tagname:{name}` | String | TagId lookup by name (enforces name uniqueness) |
| `user:{username}:tag:{tagId}:decks` | Set | Deck IDs associated with this tag (reverse index) |
| `user:{username}:deck:{deckId}:tags` | Set | Tag IDs associated with this deck |

The dual index (`tag→decks` and `deck→tags`) gives us:

- **O(1)** to list a deck's tags -- `SMEMBERS user:{username}:deck:{deckId}:tags`, then load tag entities
- **O(1)** to list decks for a tag -- `SMEMBERS user:{username}:tag:{tagId}:decks`
- **O(1)** to list all user tags -- `SMEMBERS user:{username}:tags`
- **O(1)** to check name uniqueness -- `EXISTS user:{username}:tagname:{name}`

### Limits

- Max 20 tags per deck
- Max 100 unique tags per user
- Max 5 tags per public/shared deck (prevents over-tagging for discoverability)

### API design

**Tag CRUD:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/tags` | Create a new tag (body: `{name, description}`) |
| `GET` | `/api/tags` | List all tags for the current user |
| `GET` | `/api/tags/{tagId}` | Get a single tag |
| `PATCH` | `/api/tags/{tagId}` | Update tag name or description |
| `DELETE` | `/api/tags/{tagId}` | Delete tag and all its deck associations |

**Deck-tag associations:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `PUT` | `/api/decks/{deckId}/tags/{tagId}` | Associate a tag with a deck |
| `DELETE` | `/api/decks/{deckId}/tags/{tagId}` | Remove a tag from a deck |
| `GET` | `/api/decks/{deckId}/tags` | List all tags on a deck |

**Filtering with boolean logic:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/decks?include={id1},{id2}&exclude={id3}` | Boolean filter on decks |

Query parameters:

- `include` -- comma-separated tag IDs. Deck must have **ALL** of these (AND logic).
- `exclude` -- comma-separated tag IDs. Deck must have **NONE** of these (NOT logic).
- Both can be combined: `?include=chinese,english&exclude=history` means "Chinese AND English AND NOT History".
- OR logic: `?include=chinese&include=english` with repeated `include` params uses OR between groups (future consideration -- start with single `include` for AND-only).

**Aggregated stats:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tags/{tagId}/stats` | Combined DeckStats across all decks with this tag |

### Handler: `CreateTag`

- Validate name format (alphanumeric, no spaces, max 50 chars)
- Check uniqueness: `EXISTS user:{username}:tagname:{normalizedName}`
- Check user tag limit (max 100)
- Generate UUID, store tag JSON at `user:{username}:tag:{tagId}`
- `SADD user:{username}:tags {tagId}`
- `SET user:{username}:tagname:{normalizedName} {tagId}`
- Respond with created tag

### Handler: `DeleteTag`

- Load tag, verify it belongs to the requesting user
- `SMEMBERS user:{username}:tag:{tagId}:decks` to get all associated deck IDs
- For each deck: `SREM user:{username}:deck:{deckId}:tags {tagId}`
- `DEL user:{username}:tag:{tagId}:decks`
- `DEL user:{username}:tag:{tagId}`
- `SREM user:{username}:tags {tagId}`
- `DEL user:{username}:tagname:{name}`
- Respond with count of decks that were untagged

### Handler: `AddTagToDeck`

- Verify deck ownership and tag ownership
- Check deck tag limit (max 20)
- `SADD user:{username}:deck:{deckId}:tags {tagId}` (forward index)
- `SADD user:{username}:tag:{tagId}:decks {deckId}` (reverse index)
- Both SADD operations are idempotent -- adding the same association twice is a no-op, which enforces uniqueness without extra checks
- Respond with updated tag list for the deck

### Handler: `RemoveTagFromDeck`

- Verify deck ownership
- `SREM user:{username}:deck:{deckId}:tags {tagId}`
- `SREM user:{username}:tag:{tagId}:decks {deckId}`
- Respond with updated tag list for the deck

### Handler: `GetDecks` (extended with boolean filtering)

When `include` and/or `exclude` query params are present:

```
include logic (AND):
  For each tagId in include: SMEMBERS user:{username}:tag:{tagId}:decks
  Result = SINTER of all sets (deck must have ALL included tags)

exclude logic (NOT):
  For each tagId in exclude: SMEMBERS user:{username}:tag:{tagId}:decks
  ExcludeSet = SUNION of all sets (deck must not have ANY excluded tag)

Final = Result - ExcludeSet (SDIFF)
```

Redis supports `SINTER`, `SUNION`, and `SDIFF` natively, making boolean tag queries efficient. If no filter params are present, existing behavior is unchanged.

### Migration / backward compatibility

- Tags are a new, independent data structure. No changes to existing Deck JSON.
- No migration needed -- tags start empty for all users.
- The Deck struct is **not modified**. Tags are stored in the separate association keys, not embedded in deck JSON.

### Routes

```go
// Tag CRUD
apiRouter.HandleFunc("/tags", deck.CreateTag).Methods("POST", "OPTIONS")
apiRouter.HandleFunc("/tags", deck.GetUserTags).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/tags/{tagId}", deck.GetTag).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/tags/{tagId}", deck.UpdateTag).Methods("PATCH", "OPTIONS")
apiRouter.HandleFunc("/tags/{tagId}", deck.DeleteTag).Methods("DELETE", "OPTIONS")
apiRouter.HandleFunc("/tags/{tagId}/stats", deck.GetTagStats).Methods("GET", "OPTIONS")

// Deck-tag associations
apiRouter.HandleFunc("/decks/{id}/tags/{tagId}", deck.AddTagToDeck).Methods("PUT", "OPTIONS")
apiRouter.HandleFunc("/decks/{id}/tags/{tagId}", deck.RemoveTagFromDeck).Methods("DELETE", "OPTIONS")
apiRouter.HandleFunc("/decks/{id}/tags", deck.GetDeckTags).Methods("GET", "OPTIONS")
```

### Tests

#### Unit tests
- Tag name validation: valid names, empty string, too long, spaces, special chars
- Name normalization: "FoodRecipes" and "foodrecipes" are treated as the same
- Association idempotency: adding the same tag-deck pair twice is a no-op

#### Integration tests
- `TestCreateTag`: create tag, verify stored in Redis with correct fields
- `TestCreateTagDuplicateName`: attempt to create two tags with same name, expect 409 Conflict
- `TestDeleteTag`: delete tag, verify removed from all associated decks
- `TestAddTagToDeck`: add tag, verify forward and reverse indexes
- `TestRemoveTagFromDeck`: remove tag, verify both indexes updated
- `TestFilterDecksInclude`: create decks with different tags, filter with AND logic
- `TestFilterDecksExclude`: filter with NOT logic
- `TestFilterDecksCombined`: filter with `include` AND `exclude` combined
- `TestGetTagStats`: create tagged decks with known card counts, verify aggregated stats
- `TestTagLimits`: exceed max tags per deck (20), exceed max tags per user (100)
- `TestTagOwnership`: user A cannot use user B's tags or tag user B's decks

---

## Public Deck Tag Sharing (Future -- when public decks are implemented)

When a user shares a deck publicly, their tags are visible for discovery. When another user imports a public deck, they can selectively adopt the creator's tags.

### Design principles

- **Creator's tags are read-only** -- shown on the public deck for search/browse, but the importing user doesn't have to accept them.
- **Selective import** -- On the import screen, the creator's tags are listed with checkboxes. The user picks which ones to copy into their own account.
- **Name merging** -- If the user already has a tag with the same name (case-insensitive), the imported deck is associated with the user's existing tag. No duplicate is created.
- **New tags created on demand** -- If the user selects a creator tag they don't have, a new tag is created in their account with the same name.
- **Public deck tag limit** -- Max 5 tags per public deck to prevent over-tagging for discoverability.

### Global search for public decks

When browsing public decks, search works across all creators' tags. Tags with the same name (case-insensitive) from different users are treated as equivalent for search purposes:

```
global:tagname:{normalizedName}:public_decks → Set of public deck IDs
```

This global index is maintained when a deck is published or unpublished.

### Import flow

1. User browses public decks, finds one they want
2. Import screen shows deck preview + creator's tags with checkboxes
3. User selects which tags to keep (defaults: all checked)
4. On confirm:
   - Deck is copied into user's account (new deck ID)
   - For each selected tag: find or create matching tag in user's account, associate with new deck
   - Unselected tags are simply not associated

---

## Prerequisite Migration: Fact Index to Fact ID

Phase 2 (fact-level tags) requires stable fact identifiers. This section documents why the current index-based architecture is fragile and what the migration entails. This migration is independent of the tagging system and improves the core architecture regardless -- it also unblocks future features like fact bookmarks, cross-deck fact references, and shared fact links.

### The problem: array indices are fragile

Facts are currently a raw `[]string` identified by position in a JSON array. Cards reference facts by array index. When a fact is deleted, all subsequent indices shift, and every card pointing to a shifted fact must be updated.

**Before deletion** (3 facts, 3 cards):

```
deck:abc:facts = [
  ["Apple", "苹果"],      ← index 0
  ["Dog", "狗"],           ← index 1
  ["Cat", "猫"],           ← index 2
]

deck:abc:cards = [
  {fact_index: 0, ...},   ← "Apple"
  {fact_index: 1, ...},   ← "Dog"
  {fact_index: 2, ...},   ← "Cat"
]
```

**After deleting "Dog" at index 1** -- "Cat" shifts from index 2 to index 1:

```
deck:abc:facts = [
  ["Apple", "苹果"],      ← index 0 (unchanged)
  ["Cat", "猫"],           ← index 1 (was 2, shifted!)
]

deck:abc:cards = [
  {fact_index: 0, ...},   ← "Apple" ✓
  {fact_index: 1, ...},   ← must be decremented from 2→1 to still point to "Cat"
]
```

The current code handles this by looping through all cards and adjusting indices on every deletion. This works but is error-prone, and any new feature that references a fact externally (tags, bookmarks, shared links) would need the same adjustment logic -- a growing maintenance burden.

### The fix: stable UUIDs

With stable IDs, deletions don't affect any references:

```
deck:abc:facts = [
  {"id": "f-001", "fields": ["Apple", "苹果"]},
  {"id": "f-002", "fields": ["Dog", "狗"]},
  {"id": "f-003", "fields": ["Cat", "猫"]},
]

deck:abc:cards = [
  {fact_id: "f-001", ...},   ← "Apple"
  {fact_id: "f-002", ...},   ← "Dog"
  {fact_id: "f-003", ...},   ← "Cat"
]
```

After deleting "Dog" (`f-002`): cards for `f-001` and `f-003` are untouched. Tag references, bookmarks, or any other pointer to `f-003` remain valid. No index shifting, no adjustment loops.

### Struct changes

**Fact** -- from `type Fact []string` to a struct:

```go
type Fact struct {
    ID     string   `json:"id"`     // UUID, assigned on creation
    Fields []string `json:"fields"` // field values, e.g. ["Apple", "苹果"]
}
```

**Card** -- `FactIndex int` becomes `FactID string`:

```go
type Card struct {
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

### What changes in the codebase

| Area | Before | After |
|------|--------|-------|
| Fact type | `type Fact []string` | `type Fact struct { ID, Fields }` |
| Card.FactIndex | `int` (array position) | `string` (UUID) → renamed to `FactID` |
| Fact lookup in handlers | `facts[card.FactIndex]` | Build `map[string]Fact` from array, then `factMap[card.FactID]` |
| Fact deletion | Remove from array + loop all cards to decrement shifted indices | Remove from array + delete cards with matching FactID, no shifting |
| AddFact handler | Append to array, derive index from `len(facts)-1` | Append with `uuid.New().String()` as ID |
| GetNextUrgentCard | `facts[card.FactIndex]` | Map lookup by FactID |
| Frontend Card model | `factIndex` field | `factId` field |
| Integration tests | Assert on array indices | Assert on UUIDs |

**Performance**: Array index lookup is O(1); map lookup is also O(1) after building the map, which is O(n) per request. For a deck with 1000 facts this takes microseconds. The current code already loads the entire facts array into memory, so the only addition is one `for` loop to build the map.

### Migration steps

1. Update `Fact` type and `Card` struct in Go backend
2. Write a migration script/handler that iterates all decks in Redis:
   - Load `deck:{id}:facts` (old format: `[["Apple","苹果"], ...]`)
   - Assign a UUID to each fact, convert to new format: `[{"id":"...","fields":["Apple","苹果"]}, ...]`
   - Load `deck:{id}:cards`, replace each `fact_index: N` with `fact_id: facts[N].ID`
   - Save both back to Redis
3. Update all backend handlers that reference `FactIndex` to use `FactID`
4. Update Flutter `Card` model (`factIndex` → `factId`) and `Fact` handling
5. Run migration on production Redis before deploying the new handler code

### Timing

This migration can be done at any point. It is required before Phase 2 (fact-level tags) but is beneficial on its own -- it eliminates the fragile index-shifting logic and unblocks any future feature that needs a stable reference to a fact. It is **not** required for Phase 1 (deck-level tags).

---

## Phase 2: Fact-Level Tags

Fact-level tags depend on the Fact ID migration above. Once facts have stable UUIDs, they can be tagged and referenced across decks.

### Fact-tag association (Redis keys)

| Key | Type | Purpose |
|-----|------|---------|
| `user:{username}:tag:{tagId}:facts` | Set | Fact references (`{deckId}:{factId}`) with this tag |
| `user:{username}:fact:{deckId}:{factId}:tags` | Set | Tag IDs on this fact |

The `user:{username}:tags` set is shared with deck-level tags -- a single tag namespace per user.

### Fact-level tag API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `PUT` | `/api/decks/{id}/facts/{factId}/tags/{tagId}` | Add a tag to a fact |
| `DELETE` | `/api/decks/{id}/facts/{factId}/tags/{tagId}` | Remove a tag from a fact |
| `GET` | `/api/decks/{id}/facts/{factId}/tags` | List tags on a fact |
| `GET` | `/api/tags/{tagId}/facts` | All facts with this tag across all user's decks |

### What fact-level tags enable

- **Part-of-speech categorization**: Tag facts as "verb", "noun", "adjective" to study by grammar category
- **Difficulty marking**: Tag facts as "hard", "confusing", "easy" for targeted review
- **Thematic grouping**: "food", "travel", "academic" tags work across decks
- **Custom study lists**: Assemble ad-hoc study sessions from facts across multiple decks based on tags
- **Cross-deck search**: "Show me every fact tagged `hard` across all my decks" -- a single API call

### Why not card-level tags

Cards are scheduling artifacts (fact + template + review state). A single fact with two templates produces two cards (e.g., English-to-Chinese and Chinese-to-English). Tagging at the card level would only add value when the **direction matters** (e.g., "recognition is easy but production is hard"). This is a niche use case better solved by the scheduling algorithm itself -- cards the user struggles with naturally get shorter intervals. Fact-level tagging covers the vast majority of vocabulary categorization needs.

---

## Phase 3: Hierarchical Tags (Future)

Tags can be organized in a tree structure using the `ParentID` field on the Tag entity. This allows grouping related tags under parent categories.

### Example

```
Language (parent)
  ├── Chinese
  ├── English
  ├── Japanese
  └── Spanish

Science (parent)
  ├── Biology
  ├── Chemistry
  └── Physics
```

Selecting "Science" in a filter would implicitly include all decks tagged with Biology, Chemistry, or Physics. Querying `English AND NOT Language` would return decks tagged "English" that are NOT under the Language parent -- for example, "English Kings and Queens" but not "English-Chinese Vocabulary".

### Why defer this

- Recursive resolution (walking the tree to collect all descendant tags) adds query complexity
- Moving a tag to a different parent requires re-indexing
- Depth limits and UI for tree navigation need careful design
- Flat tags cover 80%+ of use cases; hierarchy signals can emerge organically from naming conventions (e.g., `lang-english`, `lang-chinese`)

### Implementation sketch

- `Tag.ParentID` is already reserved in the Phase 1 struct (empty string = top-level)
- Add: `user:{username}:tag:{tagId}:children` → Set of child tag IDs
- Filter resolution: when a tag has children, recursively collect all descendant tag IDs, then union their deck sets before applying AND/NOT logic
- API: `PATCH /api/tags/{tagId}` with `{parent_id: "..."}` to move a tag in the tree
- UI: collapsible tree view in tag management screen; indented chips in the filter bar

---

## Architecture Overview

```
Phase 1 (Deck Tags):

  POST /tags  {name: "GRE", description: "Graduate Record Exam prep"}
       |
       +-- user:{user}:tag:{tagId} --- {id, name, description, parentId}
       +-- user:{user}:tags ---------- {tagId1, tagId2, ...}
       +-- user:{user}:tagname:gre --- tagId

  PUT /decks/{deckId}/tags/{tagId}
       |
       +-- user:{user}:deck:{deckId}:tags --- {tagId1, tagId2}   (forward)
       +-- user:{user}:tag:{tagId}:decks ---- {deckId1, deckId2} (reverse)

  GET /decks?include={tagA},{tagB}&exclude={tagC}
       |
       +-- SINTER(tag:A:decks, tag:B:decks)  →  matchSet
       +-- SUNION(tag:C:decks)                →  excludeSet
       +-- SDIFF(matchSet, excludeSet)        →  final deck IDs
       +-- Load matching decks

Phase 2 (Fact Tags):

  PUT /decks/{deckId}/facts/{factId}/tags/{tagId}
       |
       +-- user:{user}:fact:{deckId}:{factId}:tags --- {tagId}
       +-- user:{user}:tag:{tagId}:facts ------------- {deckId:factId}

Phase 3 (Hierarchical Tags):

  PATCH /tags/{tagId}  {parent_id: parentTagId}
       |
       +-- user:{user}:tag:{parentTagId}:children --- {tagId}
       +-- Filter resolution: recursively collect descendant tags
```

---

## Frontend Considerations

### Phase 1 UI

- **Tag chips** on deck cards in the list view (small colored badges below deck name)
- **Tag filter bar** above the deck list (horizontally scrollable chips, tap to toggle, supports multi-select for AND/NOT)
- **Search input** for text-based boolean queries: `chinese english -history` (minus prefix = NOT)
- **Tag editor** on deck create/edit screen (autocomplete dropdown from user's existing tags)
- **Tag management screen** (create, rename, describe, delete tags; view tag tree in Phase 3)
- **Aggregated stats row** when a tag filter is active (e.g., "GRE: 3 decks, 47 due, 68% done")

### Phase 2 UI

- **Tag chips** on fact rows in the fact list view
- **Tag editor** on fact detail/edit screen
- **Cross-deck tag browser** -- tap a tag to see all facts across all decks
- **Tag-based study mode** -- start a review session scoped to a tag, pulling due cards from all matching decks

### Public deck import UI (future)

- **Tag preview** on public deck page showing creator's tags (max 5)
- **Selective import dialog** with checkboxes for each creator tag
- **Merge indicator** showing which tags already exist in the user's account
