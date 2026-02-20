# Backend Priority List

Prioritized list of backend issues and improvements to address.

---

- [ ] **1. Remove facts from `GET /api/decks/{id}` response**

  **Component**: `GetDeck` handler in `backend-api/deck/deck.go`

  `GET /api/decks/{id}` currently returns the full `facts` array in the response (line 324). This is inconsistent with `GET /api/decks`, which returns only deck metadata + stats per deck. Facts already have a dedicated endpoint at `GET /api/decks/{id}/facts`.

  **Fix**: Remove `"facts": facts` from the `GetDeck` response. The endpoint should return only deck metadata (name, owner, fields, templates, rate) and computed stats — same shape as each item in the list endpoint.
