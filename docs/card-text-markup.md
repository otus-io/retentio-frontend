# Card text markup (wiki-style ruby)

Card-facing text can include **inline readings** shown as **ruby** (small text above the main line). This works for **plain card fields** — any `text` item rendered by `CardText` (including facts typed in the app).

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

## Parsing rules (summary)

- Valid pair: `\[\[([^\]|]+)\|([^\]]+)\]\]` (see `lib/utils/wiki_ruby_markup.dart`).
- Empty `<main>` or empty `<reading>`: not treated as a valid pair; those characters remain **literal plain text**.
- Unclosed or partial markup (e.g. `[[no end`) is left as plain text.

## UI behavior

- **Ruby layout:** Reading above, main script below, in a `Wrap` with bottom alignment (`lib/screen/deck/card_widgets/card_wiki_ruby_layout.dart`).
- **Detection:** If the string does not contain a valid `[[...|...]]` pair, behavior is unchanged: a single centered `Text` widget (`lib/screen/deck/card_widgets/card_text.dart`).

## Related code

| Area | Location |
|------|----------|
| Parse + word alignment | `lib/utils/wiki_ruby_markup.dart` |
| Layout widgets | `lib/screen/deck/card_widgets/card_wiki_ruby_layout.dart` |
| Card fields | `lib/screen/deck/card_widgets/card_text.dart` |
| Tests | `test/utils/wiki_ruby_markup_test.dart`, `test/screen/deck/card_wiki_ruby_layout_test.dart`, `test/screen/deck/card_text_test.dart` |
