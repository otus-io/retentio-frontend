# Bug Tracker

Known bugs and their status. Ordered by severity.

| Total bugs | Resolved | Unresolved | qktrn | Joe | AI |
| ---------: | -------: | ---------: | ----: | --: | -: |
|          2 |        2 |          0 |     1 |   1 | 0 |

_**Resolved** / **Unresolved** follow each bug’s **Status** (e.g. Fixed → resolved, Open → unresolved). **qktrn** / **Joe** / **AI** are **Discovered by** counts. Update this table when entries change._

---

## BUG-002: Login failures hid server error text (401 `msg` not surfaced)

**Status**: Fixed  
**Severity**: Low -- confusing UX and noisy logs; login still correctly failed  
**Component**: Frontend -- [`lib/services/dio_client/dio_client.dart`](../lib/services/dio_client/dio_client.dart),
[`lib/models/api_response.dart`](../lib/models/api_response.dart),
[`lib/services/apis/auth_service.dart`](../lib/services/apis/auth_service.dart)  
**Discovered by**: Joe

### Description

When `POST /auth/login` returned **401** with body `{"msg":"Invalid credentials"}` (as the API does in
[`retentio-backend/api/auth/auth.go`](../../retentio-backend/api/auth/auth.go) via `helpers.Msg(...)`), the app did not
reliably show that message to the user. Logs showed a long `DioException [bad response]` stack trace, and the login
snackbar could be empty or unhelpful because the UI read `result['message']` while the error envelope uses **`msg`**.

### Impact

- Users saw generic failure or empty snackbars instead of **Invalid credentials**
- `ApiResponse.fromJson` only read `message`, not `msg`, so successful parsing of error-shaped JSON was wrong when used
- `_handleError` checked `e.response is Map`; Dio’s `e.response` is a **`Response`**, not a `Map`, so the response **body
  was never parsed** and `ApiResponse.msg` often fell back to **Bad response** / **Unknown error**

### Reproduction (before fix)

1. Point the app at an API that returns Go `ExceptionResponse` errors (`json:"msg"`)
2. Submit wrong username/password on the login screen
3. Observe: Dio error spam in logs; snackbar not showing **Invalid credentials**

### Root cause

1. **Schema mismatch**: Backend `ExceptionResponse` uses field **`msg`**; `ApiResponse.fromJson` only mapped **`message`**.  
2. **Wrong type check**: Error handler used `e.response is Map` instead of reading **`e.response?.data`**.  
3. **Login result map**: `AuthService.login` returned only `data`; on failure there is no `data`, and **`message` was never
   set** from `res.msg` for `LoginController`’s `showSnack(context, result['message'])`.

### Fix

- **`ApiResponse.fromJson`**: Prefer `json['msg']`, then `json['message']`.  
- **`DioClient._handleError`**: If `e.response?.data` is a `Map`, set `msg` from `body['msg']` or `body['message']`.  
- **`AuthService.login`**: When there is no token, copy `res.msg` into the returned map as **`message`** for the login
  UI.

### Notes

- A **401** with **Invalid credentials** still means wrong username/password or unknown user on that server’s Redis; this
  bug was only about **surfacing** the server text, not about auth succeeding incorrectly.

---

## BUG-001: Orphaned cards after template update

**Status**: Resolved
**Severity**: High -- can cause runtime panic
**Component**: Backend -- `UpdateDeck` handler in [`backend-api/deck/deck.go`](../backend-api/deck/deck.go)  
**Discovered by**: qktrn

### Description

When a user updates a deck's templates (e.g., from `[[0,1],[1,0]]` to `[[0,1]]`), the handler replaces the template
array but does not clean up cards that reference the removed template. Those orphaned cards remain in `deck:{id}:cards`
with a `template_index` that no longer exists.

### Impact

- `GetNextUrgentCard` can pick an orphaned card as the highest-urgency card, then access
  `deckObj.Templates[card.TemplateIndex]` with an out-of-bounds index -- **runtime panic** (or garbage data if the index
  happens to be in range of a different template)
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

`UpdateDeck` (deck.go lines 386-498) replaces `deckObj.Templates` without checking if existing cards reference template
indices that no longer exist. No card cleanup or creation is performed.

### Fix

When templates change in `UpdateDeck`:

1. Load the current cards array
2. **Remove orphaned cards**: filter out cards where `TemplateIndex >= len(newTemplates)`
3. **Create new cards**: if new templates were added (index >= old template count), generate one card per existing fact
   for each new template
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

- This fix should be coordinated with the Fact ID migration (see
  [`re-architect-fact-identity.md`](design-doc/re-architect-fact-identity.md)) since both touch card creation/deletion
  logic. If done after the migration, use `FactID` instead of `FactIndex`.
- New cards created for added templates need scheduling (DueDate/LastReview) consistent with the deck's Rate and the
  spread algorithm.
