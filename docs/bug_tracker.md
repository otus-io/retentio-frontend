# Bug Tracker

Known bugs and their status. Ordered by severity.

---

## BUG-001: Orphaned cards after template update

**Status**: Open
**Severity**: High -- can cause runtime panic
**Component**: Backend -- `UpdateDeck` handler in [`backend-api/deck/deck.go`](../backend-api/deck/deck.go)

### Description

When a user updates a deck's templates (e.g., from `[[0,1],[1,0]]` to `[[0,1]]`), the handler replaces the template array but does not clean up cards that reference the removed template. Those orphaned cards remain in `deck:{id}:cards` with a `template_index` that no longer exists.

### Impact

- `GetNextUrgentCard` can pick an orphaned card as the highest-urgency card, then access `deckObj.Templates[card.TemplateIndex]` with an out-of-bounds index -- **runtime panic** (or garbage data if the index happens to be in range of a different template)
- Orphaned cards inflate `due_cards`, `unseen_cards`, and `cards_count` in stats
- Orphaned cards are included in `GetCards` responses, confusing the frontend
- `RescheduleDeck` shifts orphaned cards along with valid ones

### Reproduction

1. Create a deck with `templates: [[0,1],[1,0]]`
2. Add facts -- this creates 2 cards per fact (one per template)
3. Update the deck with `templates: [[0,1]]`
4. Call `GET /api/decks/{id}/next-urgent-card`
5. If an orphaned card (template_index=1) has the highest urgency, the handler panics or returns wrong data

### Root cause

`UpdateDeck` (deck.go lines 386-498) replaces `deckObj.Templates` without checking if existing cards reference template indices that no longer exist. No card cleanup or creation is performed.

### Fix

When templates change in `UpdateDeck`:

1. Load the current cards array
2. **Remove orphaned cards**: filter out cards where `TemplateIndex >= len(newTemplates)`
3. **Create new cards**: if new templates were added (index >= old template count), generate one card per existing fact for each new template
4. Save cards atomically with the deck update

```go
// Pseudocode for UpdateDeck template reconciliation
if len(updateReq.Templates) > 0 && templatesChanged(oldTemplates, updateReq.Templates) {
    cards := loadCards(deckID)
    facts := loadFacts(deckID)
    oldCount := len(oldTemplates)
    newCount := len(updateReq.Templates)

    // Remove orphaned cards
    validCards := []Card{}
    for _, card := range cards {
        if card.TemplateIndex < newCount {
            validCards = append(validCards, card)
        }
    }

    // Create cards for new templates
    for ti := oldCount; ti < newCount; ti++ {
        for _, fact := range facts {
            validCards = append(validCards, Card{
                FactIndex:     fact.index,  // or FactID after migration
                TemplateIndex: ti,
                // ... schedule fields
            })
        }
    }

    saveCards(deckID, validCards)
}
```

### Notes

- This fix should be coordinated with the Fact ID migration (see [`re-architect-fact-identity.md`](design-doc/re-architect-fact-identity.md)) since both touch card creation/deletion logic. If done after the migration, use `FactID` instead of `FactIndex`.
- New cards created for added templates need scheduling (DueDate/LastReview) consistent with the deck's Rate and the spread algorithm.
