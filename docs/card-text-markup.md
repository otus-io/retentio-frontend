# Card text markup (wiki-style ruby)

Card-facing text can include **inline readings** shown as **ruby** (small text above the main line). This works for:

- **Plain card fields** — any `text` item rendered by `CardText` (including facts typed in the app, not only JSON imports).
- **Transcript JSON** — when the sync file includes a `text` field whose **composed surface** matches the concatenation of timed `words`, the transcript view shows the same ruby while keeping **tap-to-seek** per word.

See also [audio_transcript_sync.md](audio_transcript_sync.md) for transcript format and timing.

## Format

Use **double brackets** and a **pipe** between the main script and the reading:

```text
[[<main>|<reading>]]
```

- **`<main>`** — Characters shown on the **bottom** line (e.g. kanji, hanzi). Must not contain `|` or `]`.
- **`<reading>`** — Shown on the **top** line (e.g. hiragana, katakana, pinyin with tone marks). Must not contain `]` (closing bracket of the pair). Must not contain `|` (the first `|` always ends `<main>`).

### Examples

- Japanese: `[[皆|みな]]さんは[[思|おも]]い`
- Chinese + pinyin: `[[中国|Zhōngguó]]你好`

Plain text outside `[[...|...]]` is unchanged. Multiple pairs can appear in one string.

### Why `[[` and not `[`?

Double brackets reduce accidental clashes with normal use of single square brackets (citations, notes, etc.).

## Composed surface (alignment)

The app builds a **composed** string by:

- Replacing each `[[main|reading]]` with **`main` only** (readings are not part of composed text).
- Leaving plain segments as-is.

**Transcript sync:** Timed `words` are concatenated in order. That string must **exactly equal** the composed string character-for-character. If it does not match, the UI **falls back** to plain per-word text (no ruby) for that transcript.

## Parsing rules (summary)

- Valid pair: `\[\[([^\]|]+)\|([^\]]+)\]\]` (see `lib/utils/wiki_ruby_markup.dart`).
- Empty `<main>` or empty `<reading>`: not treated as a valid pair; those characters remain **literal plain text**.
- Unclosed or partial markup (e.g. `[[no end`) is left as plain text.

## UI behavior

- **Ruby layout:** Reading above, main script below, in a `Wrap` with bottom alignment (`lib/screen/deck/card_widgets/card_wiki_ruby_layout.dart`).
- **Detection:** If the string does not contain a valid `[[...|...]]` pair, behavior is unchanged: a single centered `Text` widget (`lib/screen/deck/card_widgets/card_text.dart`).
- **Transcript:** Optional field `text` on `retentio-transcript-sync` JSON is stored as `TranscriptSync.annotatedSourceText` and used when alignment succeeds (`lib/models/transcript_sync.dart`, `lib/screen/deck/card_widgets/card_transcript_text.dart`).

## Related code

| Area | Location |
|------|----------|
| Parse + word alignment | `lib/utils/wiki_ruby_markup.dart` |
| Layout widgets | `lib/screen/deck/card_widgets/card_wiki_ruby_layout.dart` |
| Card fields | `lib/screen/deck/card_widgets/card_text.dart` |
| Transcript + seek | `lib/screen/deck/card_widgets/card_transcript_text.dart` |
| Tests | `test/utils/wiki_ruby_markup_test.dart`, `test/screen/deck/card_wiki_ruby_layout_test.dart`, `test/screen/deck/card_text_test.dart`, `test/screen/deck/card_transcript_text_test.dart` |

## Transcript JSON sketch

```json
{
  "format": "retentio-transcript-sync",
  "text": "[[皆|みな]]さんは",
  "words": [
    { "word": "皆さん", "start": 0.0, "end": 0.3 },
    { "word": "は", "start": 0.3, "end": 0.5 }
  ]
}
```

Here `text` composes to `皆さんは`, which matches `皆さん` + `は`.
