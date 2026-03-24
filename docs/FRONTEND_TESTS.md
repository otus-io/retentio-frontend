# Frontend Tests

Blackbox tests for the Retentio Flutter frontend. These tests verify the behavior of developer-written code without modifying it. Developers should update their implementation to make tests pass.

## Running Tests

```bash
# From repository root (where pubspec.yaml lives)
flutter test
```

### Test report

To run tests and save a report to `test/reports/`:

```bash
flutter test --reporter expanded 2>&1 | tee test/reports/report_$(date +%Y%m%d_%H%M%S).txt
```

Or for JSON output:

```bash
flutter test --reporter json > test/reports/report_$(date +%Y%m%d_%H%M%S).json
```

Or run specific test files:

```bash
flutter test test/models/card_test.dart
flutter test test/utils/debounce_util_test.dart
```

## Test Structure

All tests are under `test/`:

### Unit Tests

- **models/** - Model parsing (fromJson, toJson) and getters
- **utils/** - Utility classes (DebounceUtil, etc.)
- **extensions/** - Widget and context extensions
- **services/** - API constants, storage exceptions
- **routers/** - Route definitions
- **providers/** - State classes and notifiers

### Widget Tests

- **screen/home/** - HomeScreen rendering, text, icons, locale
- **screen/login/** - LoginScreen form fields, buttons, theme toggle, language dropdown
- **screen/login/widgets/** - ForgotPassword form, validation, email input
- **screen/register/** - RegisterScreen form fields, keyboard types, obscured passwords
- **screen/profile/** - ProfileScreen user info, settings items, logout dialog
- **screen/deck/** - DeckDetailScreen stats display, button states; DeckLearnScreen async states
- **screen/decks/** - DecksScreen loading/error state, AppBar
- **widgets/** - BottomPopup show/dismiss, CommonRefresher loading/empty/child states

### Helpers & Reports

- **helpers/** - Test helpers (InMemoryHydratedStorage, test widget wrappers)
- **reports/** - Generated test reports (gitignored)

## Test Philosophy

These are blackbox tests: they assert on the public API and observable behavior of each unit. No changes are made to the implementation under test. If a test fails, the developer should fix their code to satisfy the expected behavior.
