# Study

🌐 [中文](knowledge_base_study_zh.md) · [Knowledge base](knowledge_base.md)

Study fetches the card that should be seen now, asks for recall, checks the back, grades with “when should this appear again”, and fetches another card immediately. A fact tag can narrow the queue. The user can hide a card, or delete that card and leave the fact in place.

The on-screen progress is how many due cards this session cleared. There is no “finished” screen. The server keeps returning the most urgent card, so once due cards are caught up the user can still press Next for as long as a card comes back. The server’s exact pick order is not visible in the client.

Quality review of an imported deck is QA mode, not this screen. See [Facts, tags, and collaboration](knowledge_base_content.md).

## A card

`Card` (`lib/models/card.dart`) is the study unit.

| Field | Meaning |
| ----- | ------- |
| `id` | Key for grade, hide, and delete |
| `fact_id` | The fact, used by edit and report |
| `front` / `back` | Slots. Each slot has a column name and items: text / audio / json / image / video |
| `template` | Which fact-entry indexes this card puts on the front and the back |
| `due_date` | Next due time, Unix seconds, written by the server. The client does not store a separate interval |
| `last_review` | Previous review, Unix seconds |
| `hidden` | A hidden card must not be shown |
| `created_at` | Unix seconds |

The payload may include `urgency`. The slider ignores it and recomputes from timestamps.

## One review

```text
Enter study
  → load the deck’s fact tags and GET the next card (optional tag_id)
Card present
  → front
  → Show Answer only flips
  → drag the interval on the back
  → Next PATCHes card_id + interval (seconds, rounded) + last_review (client UTC seconds now)
  → success: session count +1, show the prefetched card or GET again, flip back to front
  → failure: stay on this card, toast, do not increment
No card
  → whole deck: this deck has no cards
  → tag filter: this tag has no cards; the filter can be cleared
```

Other actions:

| Action | Result |
| ------ | ------ |
| Hide | Same transition as Next, but the body is `hidden: true`. Success advances and counts |
| Delete this card | `DELETE` that card, then fetch the next one. Does not increment. The fact and sibling cards remain |
| Save a fact edit | Fetch again. If there was already no card, the session count resets |
| Change tag | Clear the session count, current card, prefetch, and progress denominator, then fetch with the new tag |

One PATCH is either `interval` + `last_review` or `hidden`, never both.

Prefetch: `next_card` on the fetch is kept ready. It is dropped when it is the same card or hidden. A successful submit with a valid prefetch swaps the card without a full-screen load. If the server reorders the queue underneath, the card on screen stays; only the prefetched follower changes.

Next with no card does not PATCH.

`DeckStudyReviewAgainRequested` resets the session and fetches again. No control sends that event.

## Interval slider

The slider exists only on the back. There are no preset buttons. It is continuous, about 100 steps. The left label is the short interval, the right label the long one.

Current interval = `due_date - last_review`. If that is ≤ 0, the computed range is 0 and the UI sets the slider max to min + 1.

Otherwise `base = max(300, current interval)` (anything under 5 minutes is treated as 5 minutes), and urgency is `(now - last_review) / base`:

- Due (urgency ≥ 1): short = 0.5× base, middle = 2×, long = 4×.
- Not yet due: a linear blend from 1× base toward those factors. At urgency 0 all three positions are the base itself.
- The slider starts on the middle step. If rounding collapses the ends, the long end becomes 4× the short end.

Labels collapse seconds into seconds, minutes, hours, days, months (30 days), and years (12 months).

The client submits the chosen seconds. The server writes the new `due_date` from that interval. That formula is not in the client.

Deck `minInterval`, `defInterval`, and `maxInterval` do not feed the slider.

## Empty queue, hide, tags, holiday

- No card object, or `card: []`, means no card.
- A returned card with `hidden: true` is discarded, including as prefetch.
- A tag filter passes `tag_id` to both the next-card call and stats. An empty tag queue uses its own empty state.
- Holiday reschedule: `POST /api/decks/{id}/reschedule` is only a path constant and an error string. Study never calls it. `meta.reschedule_suggested` on the card payload is not parsed.

## Progress numbers

The study bar is “due cards cleared this session / due count frozen at the start of this session”.

- The denominator freezes at the first due count after enter, or after a tag change.
- The numerator is the larger of “frozen minus live due” and “successful submits this session”, capped by the denominator. A later rise in the server’s due count does not zero the bar.
- Successful grades and successful hides count. Deletes and failed submits do not.

The statistics screen is separate. It loads per-deck review counts for 7 / 30 / 90 / 365 UTC days, then shows today, total, active days, daily average, and weekday totals.

The deck-list bar is “cards already seen / all cards”, `(cardsCount - unseenCards) / cardsCount`, not due progress. The list also shows total reviews, due count, and fact count. Hidden-card count exists on stats and is not shown in study.

## Offline

Grade and hide are synchronous PATCHes. Failure stops on the card. There is no local queue and no later upload. See [Data and media](knowledge_base_data.md).

## Code

`lib/features/deck_study/`, `lib/screen/deck/deck_view_screen.dart`, `lib/screen/deck/deck_widgets/deck_view_body.dart`, `lib/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart`, `lib/features/deck_study/domain/value_objects/review_interval_range.dart`, `lib/screen/deck/formatters/review_interval_label.dart`, `lib/services/apis/card_service.dart`, `lib/services/apis/review_stats_service.dart`.
