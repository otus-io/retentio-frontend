# Frontend Tests

Blackbox tests for the Wordupx Flutter frontend. These tests verify the behavior of developer-written code without modifying it. Developers should update their implementation to make tests pass.

## Running Tests

```bash
# From frontend directory
cd frontend
flutter test
```

### Test report

To run tests and save a report to `frontend/test/reports/`:

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

All tests are under `frontend/test/`:

- **models/** - Model parsing (fromJson, toJson) and getters
- **utils/** - Utility classes (DebounceUtil, etc.)
- **extensions/** - Widget and context extensions
- **services/** - API constants, storage exceptions
- **routers/** - Route definitions
- **providers/** - State classes and notifiers
- **helpers/** - Test helpers (e.g., InMemoryHydratedStorage)
- **reports/** - Generated test reports (gitignored)

## Test Philosophy

These are blackbox tests: they assert on the public API and observable behavior of each unit. No changes are made to the implementation under test. If a test fails, the developer should fix their code to satisfy the expected behavior.
