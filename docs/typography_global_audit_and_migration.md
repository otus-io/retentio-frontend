# Typography Global Audit & Migration (Branch-wide)

## Scope
- Pages: `login/register/home/profile/deck/decks`
- Shared components: `lib/widgets/*`
- Theme system: `lib/theme/*`
- Media controls text: `lib/video_player/*`

## What was done
1. Built a centralized typography token system:
   - `lib/theme/theme_typography_tokens.dart`
   - semantic text API (`ThemeData.semanticTypography`)
2. Refactored theme wiring to consume typography tokens:
   - `lib/theme/theme_typography.dart`
   - `lib/theme/theme_components.dart`
   - `lib/theme/app_theme.dart`
3. Unified page-level hierarchy in parallel areas:
   - Auth pages
   - Deck study pages
   - Deck list/create pages
   - Home/Profile pages
4. Reduced hardcoded sizes in shared components:
   - `AppButton` now maps sizes to semantic typography roles
   - `common_net_image` fallback text uses theme role instead of fixed size
   - `video_player` default text styles now use typography tokenized metrics
5. Updated fragile tests aligned to new UX behaviors:
   - delayed drag in deck create
   - visibility-based delete interaction
   - asynchronous deck list state checks

## Current hardcoded `fontSize` status
After migration, remaining `fontSize:` usage is intentionally functional:
- user-configurable deck card typography (`deck_card_typography.dart`)
- ruby proportional rendering fallback (`card_wiki_ruby_layout.dart`)
- collapsed field-label interpolation (`entry_row.dart`)

No remaining static presentation hardcodes in target page/component surfaces.

## Validation
- `flutter analyze` passed
- Passed test suites (targeted):
  - `test/screen/deck`
  - `test/screen/decks/deck_create_test.dart`
  - `test/screen/decks/deck_list_screen_test.dart`
  - `test/screen/decks/deck_list_screen_wordbook_test.dart`
  - `test/screen/home`
  - `test/screen/profile`
  - `test/features/auth`

## Notes
- Existing branch contains many unrelated in-flight changes. Typography migration avoided reverting unrelated work.
- New typography guide for contributors:
  - `lib/theme/README_typography.md`
