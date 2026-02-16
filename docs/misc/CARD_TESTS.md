# Card Integration Tests

All tests are in `backend-api/tests/integration/card_test.go`.

Run: `go test ./tests/integration/... -v`

## UpdateUrgentCard (`PATCH /api/decks/{id}/urgent-card`)

### TestUpdateCard
| Case | Status |
|---|---|
| Update card interval successfully | 200 |
| Unauthorized access (wrong owner) | 403 |
| Unknown fact_id | 404 |
| Missing auth token | 401 |
| Non-existent deck | 404 |
| Update visibility successfully | 200 |

### TestUpdateCardIntervalValidation
| Case | Status |
|---|---|
| Reject interval below MinInterval | 400 |
| Reject interval above MaxInterval | 400 |
| Reject zero interval | 400 |
| Reject negative interval | 400 |
| Mark card as seen after interval update | 200 |
| Reject request with no recognized fields | 400 |

### TestUpdateCardVisibility
| Case | Status |
|---|---|
| Unhide a previously hidden card | 200 |
| Reject empty request body | 400 |

### TestUpdateCardBasicVerification
| Case | Validates |
|---|---|
| Interval update | `due_date == last_review + interval`, `last_review ≈ now`, Redis matches response |
| Visibility update | `hidden_status` set, no interval fields in response, timestamps unchanged |

### TestUpdateCardFactIDVerification
| Case | Status |
|---|---|
| Matching fact_id succeeds | 200 |
| Unknown fact_id returns not found | 404 |
| Missing fact_id returns error | 400 |

## GetCards (`GET /api/decks/{id}/cards/{operation}`)

### TestGetCards
| Case | Status |
|---|---|
| Get all cards successfully | 200 |
| Empty array for deck with no cards | 200 |
| Unauthorized access | 403 |
| Missing auth token | 401 |
| Non-existent deck | 404 |

### TestGetCardsInvalidOperation
| Case | Status |
|---|---|
| Invalid operation returns error | 400 |

### TestGetCardsHiddenFilter
| Case | Validates |
|---|---|
| hidden-cards operation returns only hidden cards | Correct count and fact IDs |

## GetUrgentCard (`GET /api/decks/{id}/urgent-card`)

### TestGetNextUrgentCard
| Case | Status |
|---|---|
| Get urgent card successfully | 200 |
| Deck with no cards | 404 |
| Unauthorized access | 403 |
| Missing auth token | 401 |
| Non-existent deck | 404 |

### TestNextUrgentCardUrgencySelection
| Case | Validates |
|---|---|
| Most overdue card selected | Highest urgency wins |
| Skip hidden cards | Hidden cards excluded from selection |
| Correct interval calculations (overdue) | `min=0.5x`, `max=4x` of interval |
| Persist MinInterval/MaxInterval to Redis | Values saved after GetNext |
| Correct intervals (not-yet-due, urgency < 1) | Scaled by strength factor |
| All cards hidden returns message | 200 with explanation |
| Minimum interval of 60s enforced | Clamps interval < 60 to 60 |
| Suggest rescheduling (overdue > 1 day) | `reschedule_suggested: true` in meta |
| No reschedule suggestion (overdue < 1 day) | Field absent from meta |
| No reschedule fields (no overdue cards) | Field absent from meta |

## GetHiddenCards (`GET /api/decks/{id}/hidden-cards`)

### TestGetHiddenCards
| Case | Validates |
|---|---|
| Returns hidden cards with stats | Correct count, percentage, fact fields |
| Unauthorized access | 403 |

## Review Cycle (GetUrgentCard + UpdateUrgentCard)

### TestFullReviewCycle
- Add 3 facts, get urgent card, review it, verify next card is different, verify reviewed card is "seen" in Redis.

### TestReviewCycleMinInterval
- 4 rounds always choosing `min_interval`. Verifies `due_date`, `last_review`, and Redis each round. Interval shrinks: 500 → 250 → 125 → 62.

### TestReviewCycleMaxInterval
- 4 rounds always choosing `max_interval`. Verifies `due_date`, `last_review`, and Redis each round. Interval grows: 4000 → 16000 → 64000 → 256000.

### TestMultiCardUrgencyOrdering
- 3 cards with distinct urgencies. Reviews in order: most urgent → least urgent. Verifies each round picks the correct next card.

### TestReviewDoesNotCorruptOtherCards
- Reviews 1 card, verifies the other 2 cards have unchanged `LastReview`, `DueDate`, `MinInterval`, `MaxInterval`, and `Hidden` in Redis.

### TestHideUnhideMidCycle
- Hides card 0 mid-session, verifies GetNext switches to card 1. Unhides card 0, verifies GetNext returns card 0 again.

### TestCardIndexCorrectness
- Cross-verifies `card_index` matches `fact_id` in Redis, round-trip GetNext+Update modifies correct card, card_index consistent after AddFact with spread, idempotent without mutations, correct with multiple templates.

## RescheduleDeck (`POST /api/decks/{id}/reschedule`)

### TestRescheduleDeck
| Case | Status |
|---|---|
| Reschedule all cards by N days | 200 |
| days=0 | 400 |
| Negative days | 400 |
| days > 365 | 400 |
| Unauthorized access | 403 |
| Non-existent deck | 404 |
| Shift exceeds days away | 400 |
