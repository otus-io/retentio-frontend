# Facts, tags, and collaboration

🌐 [中文](knowledge_base_content_zh.md) · [Knowledge base](knowledge_base.md)

A fact is one content row in a deck. A card is the study face the server cuts from that fact with a template. Tags group facts and narrow study. An importer edits their own copy, then manually sends those edits to the author. The author accepts or dismisses them from the inbox.

## How a fact becomes cards

A fact has an `id` and `entries`. Each entry may hold `text`, `audio`, `image`, `video`, and `json`. The add form uses one row per deck column. If the deck has no column names, the form uses two fixed rows.

The add request sends neither `template` nor column names. The usual server result is one card: front is entry 0, back is the rest. The client does not prove that is the only template. The model allows several cards per fact.

Study shows the card’s slots as the server filled them. The client does not assemble the card from the fact at display time.

## Adding a fact

The entry point is the study menu. Every row needs body text or an attachment. Recording blocks submit.

Each row holds at most one image, one video, and one audio. Picking a file checks size first: images 5 MB, audio and video 200 MB. A wrong type or a missing file is not uploaded.

On submit:

1. A local file is `POST /api/media`. The returned media id is written into the entry.
2. Optional `tag_ids` go with the fact.
3. `POST /api/decks/{id}/facts/append`. The operation is fixed to append.
4. Success refreshes the deck list and, when needed, the study queue, then clears the form.

Error copy knows `prepend`, `shuffle`, and `spread`. The UI cannot choose them. There is also no add/remove-row control from the old add-facts plan.

On an imported copy, the client diffs fact ids around the submit, stores the new id as a pending `add`, and says it is in the outbox. The fact already exists on the copy. Sending it to the author is a second step.

## Edit, hide, delete

Edit is on the card menu and opens the current card’s `factId`. It loads the fact, the deck’s column names, and the fact’s tags. Row count is at least the deck’s column count. Extra fact entries are kept.

Save uploads new local media, then PATCHes the entries. Column names are included only when their count matches the entries. Tag diffs run after the save and do not roll the body back if they fail. On an imported copy the edit also stores a pending `edit`. A tag change stores a separate pending `factTags`.

| Action | What it removes |
| ------ | --------------- |
| Delete card | That card only |
| Hide card | Nothing. The card leaves the study queue |
| Delete fact | No such action |
| Delete deck | Allowed for an unpublished source or an imported copy. Not for a published source |

The card menu does not check authorship. The API decides who may write. The client does not prove that a read-only copy is rejected.

## Ruby markup

Body text may contain `[[base|reading]]`. The editor can wrap a selection that way. Either side may be empty while editing. In study, text that looks like this markup draws the reading above the base. Other text is plain. Front, back, and ruby sizes can be tuned per deck and are stored on the device.

Implementation: `lib/utils/wiki_ruby_markup.dart`. If `docs/card-text-markup.md` disagrees with the code, follow the code.

## Tags

Tags belong to the user and attach to a deck or a fact.

| Attached to | Where | Effect on study |
| ----------- | ----- | --------------- |
| Fact | Add or edit fact | The study filter lists only these. The chosen tag limits the due queue |
| Deck | Create or edit deck | Not a study filter. Shown on the catalog detail |

On add, `tag_ids` travel with append. On edit, tags are applied after the fact save.

Changing deck tags on an imported copy becomes a pending `deckTags` contribution. It does not edit the author’s deck directly.

Profile opens a tag manager: create, rename, delete.

## Contributions

Two roles:

- The importer edits their copy, and the edit is live immediately. Pending items sit in `retentio_pending_contribs_v2:{deckId}` on the device. The same kind and fact id overwrite each other. The outbox submits only what the user checks. Sent items are kept, up to 200.
- The author opens the inbox on a published source deck. It loads `open` items. Actions are accept, dismiss (`dismissed`), or resolve (`resolved`). After accept, the list reloads.

| Kind | How the importer creates it | Can the author accept it? |
| ---- | --------------------------- | ------------------------- |
| `fact_add` | Add a fact on the copy | Yes |
| `fact_edit` | Edit a fact on the copy | Yes |
| `fact_tags` / `deck_tags` | Change fact tags or deck tags. The outbox sends tag names | Yes |
| `report` | Card menu submits directly. Not in the outbox | No. Dismiss or resolve only |
| `field_rename`, `template` | Present on the model. The outbox cannot submit them | — |

Report appears only on an imported deck’s card menu. Categories are audio, content, and other. Other requires a note. The note is one message, at most 200 characters. The author sees the message and a fact preview.

The pending queue is not a transaction. If the process dies while items are being marked sent, unmarked staged items can be lost.

## QA

QA is only in the imported-deck menu. It does not use the interval queue. It walks the fact-id list in order.

Each column can be checked. A column face is scoreable when its text or audio is non-empty. A check PUTs the whole quality document: checked faces become a human score of 10; unchecking removes that human score. Advance is allowed when every scoreable column is checked, or when the fact has no scoreable column.

Editing a fact inside QA submits a `fact_edit` contribution immediately and marks the matching local pending edit as sent.

The quality API is for QA only. The study queue does not read scores.

## Code

`lib/models/fact.dart`, `lib/models/tag.dart`, `lib/models/deck_contribution.dart`, `lib/models/fact_quality.dart`, `lib/screen/deck/fact_widgets/`, `lib/screen/deck/fact_add_composer/`, `lib/features/contributions/pending_contributions_store.dart`, `lib/screen/deck/deck_widgets/pending_contributions_outbox_sheet.dart`, `lib/screen/deck/deck_widgets/contributions_inbox_sheet.dart`, `lib/screen/qa/`, `lib/services/apis/tag_service.dart`, `lib/services/apis/fact_quality_service.dart`.
