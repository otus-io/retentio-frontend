# Card Rescheduling (Vacation Mode)

## Design

Shift **all cards** in a deck by N days (adding `N * 86400` seconds to both `DueDate` and `LastReview`). Shifting both fields preserves the interval (`DueDate - LastReview`) and keeps urgency calculations consistent. One endpoint:

- `POST /api/decks/{id}/reschedule` -- reschedule a single deck

Request body:

```json
{ "days": 5 }
```

Returns the number of cards shifted and a summary.

### Why shift all cards (not just overdue)?

Shifting only overdue cards breaks the relative ordering between shifted and non-shifted cards. For example, a card due on day 3 (shifted to day 8) would end up scheduled after a card due on day 7 (unshifted), even though the day-3 card was originally first. Shifting all cards preserves the relative spacing -- it's equivalent to "pausing time" during the holiday.

*We need to think about difference between preserving the review order ? * 

## Request Struct

```go
type RescheduleRequest struct {
    Days int `json:"days"`
}
```

Validation: `days` must be >= 1 and <= 365, **and** must not exceed the detected absence (see Max Shift Validation below).

## Why per-deck only (no global reschedule)

A user may be active on some decks but absent from others. A global `POST /api/reschedule` that shifts all decks by the same N days would incorrectly shift decks the user is still actively studying. Per-deck rescheduling lets the user (or frontend) decide which decks need shifting and by how many days independently. If multiple decks need rescheduling, the frontend calls the per-deck endpoint once for each, potentially with different `days` values.

## Max Shift Validation

The handler enforces that the user cannot shift by more days than they have actually been away. The absence is computed from the **earliest overdue card** (`DueDate <= now`):

```
maxDaysAway = (now - min(DueDate where DueDate <= now)) / 86400
```

Rules:
- If no overdue cards exist, return 400: "No overdue cards found, rescheduling is not needed"
- If `maxDaysAway < 1`, clamp to 1
- If `days > maxDaysAway`, return 400: "Cannot shift by N days — you have only been away for M days"

The response includes `max_days_away` in the data payload so the frontend can display the cap to the user.

## Handler: `RescheduleDeck`

- Parse `days` from request body
- Load deck (verify ownership) and its cards from Redis
- Compute earliest overdue and validate `days <= maxDaysAway`
- Compute `shift = int64(days) * 86400`
- For every card: `card.DueDate += shift`, `card.LastReview += shift`
- Save cards back to Redis
- Respond with `{ "data": { "cards_shifted": N, "days": D, "max_days_away": M }, "meta": { "msg": "..." } }`

## Holiday Detection

When a user returns after an absence, the system should detect how long they've been away and suggest rescheduling. Two approaches were considered:

### Approach 1: Earliest overdue DueDate (chosen)

Find the card with the smallest `DueDate` where `DueDate <= now`:

```
awayDays = (now - min(DueDate where DueDate <= now)) / 86400
```

This is the simplest and most reliable approach. The concern that pre-existing overdue cards could inflate the count is mitigated by the fact that **each reschedule resets the slate**. If the user reschedules every time they return, the earliest overdue card always reflects the current absence accurately.

This also handles intermittent usage correctly:

- Day 0: User leaves. Cards start going overdue.
- Day 3: User returns, reschedules by 3 days. All cards shift forward. Clean slate.
- Day 3-8: User leaves again.
- Day 8: User returns. Earliest overdue card is from day 3. System detects 5 days. Correct.

### Approach 2: Most recent LastReview of seen cards (rejected)

Find the most recent `LastReview` among reviewed cards (`DueDate - LastReview != 1`):

```
lastActivity = max(LastReview where DueDate - LastReview != 1)
awayDays = (now - lastActivity) / 86400
```

**Problem**: If the user briefly opens the app mid-holiday and reviews just 1 card, the `lastActivity` resets and underestimates the total absence. Most overdue cards still accumulated over the full period, but the system only detects the time since that last single review.

### Delivery approach

Detection is **per-deck**, embedded in the `GetNextUrgentCard` response metadata. The handler already iterates all cards in the deck to find the highest-urgency card; we piggyback on that same loop to track `earliestOverdue` at zero additional cost. The frontend already calls this endpoint when opening a deck, so it gets holiday detection for free without an extra API round-trip. Include:

```json
{
  "meta": {
    "overdue_cards": 47,
    "earliest_overdue_due_date": 1770950000,
    "suggested_reschedule_days": 8,
    "reschedule_suggested": true
  }
}
```

Trigger threshold: `suggested_reschedule_days > 1` (more than 1 day away). The suggested value is the exact detected absence in days, pre-filled for the user to confirm or adjust.

### User flow

When the frontend detects `reschedule_suggested: true`, it presents a prompt with two choices:

1. **Reschedule** -- *"Shift my schedule back N days"*
   - Pre-fills with `suggested_reschedule_days`, user can adjust
   - Calls `POST /api/decks/{id}/reschedule`
   - Cards spread back out over time, manageable daily load

2. **Catch up** -- *"I'll study through them"*
   - Dismiss the prompt, no API call
   - User reviews the overdue pile at their own pace via the normal urgency-based flow
   - The most overdue cards surface first naturally

Example prompt: *"Welcome back! You have 47 overdue cards -- it looks like you've been away for about 8 days. Would you like to reschedule your cards, or catch up by studying?"*

The choice is per-session and non-blocking -- if the user dismisses, they can always manually reschedule later from deck settings.

## Routes

```go
apiRouter.HandleFunc("/decks/{id}/reschedule", deck.RescheduleDeck).Methods("POST", "OPTIONS")
```

## Tests

### Reschedule handlers
- `TestRescheduleDeck`: verify all cards shifted by correct amount, both DueDate and LastReview
- `TestRescheduleDeck` sub-tests: invalid days (0, -1, 366), unauthorized access, non-existent deck, shift exceeds days away
- Verify unseen invariant is preserved (`DueDate - LastReview` stays the same after shift)

### Holiday detection in GetNextUrgentCard
- `should suggest rescheduling when earliest overdue > 1 day`: cards overdue by 3 days, verify `reschedule_suggested: true`, `suggested_reschedule_days: 3`
- `should not suggest rescheduling when overdue by less than 1 day`: card overdue by seconds, verify `reschedule_suggested: false`
- `should not include reschedule fields when no cards are overdue`: all cards in the future, verify `reschedule_suggested` is absent from meta
