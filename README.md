# Retentio (Flutter)

🌐 English | [中文](docs/readme_zh.md)

Flutter client for Retentio. Entrypoint: `lib/main.dart`. Dependencies and SDK versions: `pubspec.yaml`.

## Catalog

### Flutter commands

Run from the repository root (`retentio-frontend/`).

#### Devices

```bash
flutter devices
```

| Command | Purpose |
| ------- | ------- |
| `flutter doctor` | Check toolchain and platform setup |
| `flutter emulators` | List available emulators |
| `flutter emulators --launch <emulator_id>` | Start an emulator |

#### Run

```bash
flutter pub get
flutter run
flutter run -d <device_id>              # device ID or name from flutter devices
flutter run -d <device_id> --dart-define=API_ENV=release
flutter run -d <device_id> --release --dart-define=API_ENV=release
```

| Flag | Meaning |
| ---- | ------- |
| `-d <device_id>` | Target a specific device |
| `--release` | Flutter release build mode (optimized, no debug tooling) |
| `--dart-define=API_ENV=<env>` | API host mapping: `debug`, `dev`, or `release` (see table below) |
| `--dart-define=API_HOST=<url>` | Override API base URL (takes precedence over `API_ENV`) |

#### Build

```bash
flutter build apk --release --dart-define=API_ENV=release
flutter build appbundle --release --dart-define=API_ENV=release
flutter build ipa --release --dart-define=API_ENV=release
```

#### API environment (`lib/services/env.dart`)

| `API_ENV` | Host | Default when omitted |
| --------- | ---- | -------------------- |
| `debug` | `http://localhost:8080` | — |
| `dev` | `https://10.0.0.145:8443` | `flutter run` and other non-release builds |
| `release` | `https://api.retentio.app:8443` | `--release` / product builds (`flutter build ipa`, Xcode Archive) |

Extended reference: [docs/flutter_commands.md](docs/flutter_commands.md) ([中文](docs/flutter_commands_zh.md)).

### Documentation

| Document | Description |
| -------- | ----------- |
| [docs/flutter_commands.md](docs/flutter_commands.md) | Flutter CLI commands (devices, run, build, `API_ENV`) |
| [docs/api.md](docs/api.md) | Frontend API usage ([中文](docs/api_zh.md)) |
| [docs/frontend_tests.md](docs/frontend_tests.md) | Test commands and layout ([中文](docs/frontend_tests_zh.md)) |
| [docs/contributing.md](docs/contributing.md) | Code conduct and PR guidelines ([中文](docs/contributing_zh.md)) |
| [docs/pre_commit_hook.md](docs/pre_commit_hook.md) | Pre-commit hook setup ([中文](docs/pre_commit_hook_zh.md)) |
| [docs/cursor_rules.md](docs/cursor_rules.md) | Cursor AI project rules ([中文](docs/cursor_rules_zh.md)) |
| [docs/ui_component_standardization.md](docs/ui_component_standardization.md) | Shared UI component standards ([中文](docs/ui_component_standardization_zh.md)) |
| [docs/card-text-markup.md](docs/card-text-markup.md) | Wiki-style ruby markup on cards |
| [docs/deck-font-ruby-typography.md](docs/deck-font-ruby-typography.md) | Deck font sheet and ruby typography |
| [docs/plan_add_facts.md](docs/plan_add_facts.md) | Add-facts feature plan |
| [docs/api_progress_tracker.md](docs/api_progress_tracker.md) | API integration progress tracker |
| [docs/bug_tracker.md](docs/bug_tracker.md) | Known bugs and fixes |
| [docs/card_tests.md](docs/card_tests.md) | Card integration test notes |
| [docs/typography_global_audit_and_migration.md](docs/typography_global_audit_and_migration.md) | Typography audit and migration |

## Getting started

From the repository root:

```bash
flutter pub get
flutter run
```

See [Catalog](#catalog) for device selection, release builds, and `API_ENV`.

`ios/Flutter/Generated.xcconfig` is **generated** by Flutter and listed in `.gitignore`. If Xcode reports it missing (for example from `Release.xcconfig`), run **`flutter pub get`** again from the repo root before opening or archiving **`ios/Runner.xcworkspace`**.

If plugins fail with **`Flutter/Flutter.h` file not found**, run **`flutter pub get`** then **`cd ios && pod install`** on **this Mac** so CocoaPods picks up your local Flutter engine paths (they are not portable across machines).

## Git hooks

After cloning, run `./utils/setup-hooks.sh` once to install **pre-commit** (format, analyze, tests).

Full guide: [docs/pre_commit_hook_zh.md](docs/pre_commit_hook_zh.md) · [English](docs/pre_commit_hook.md)

## Repository layout

| Path | Purpose |
|------|---------|
| `lib/`, `android/`, `ios/`, … | Flutter app (`pubspec.yaml` at repo root). |
| `docs/` | Project documentation: Markdown files in the `docs/` root (no subfolders). |
| `utils/` | Helper scripts (e.g. pre-commit). |
| `.github/` | GitHub templates and workflows. |
| `lib/core/di/` | Dependency injection setup and composition roots for feature wiring. |
| `lib/features/auth/` | Auth feature module (BLoC/use cases/repositories/data sources). |
| `lib/features/deck_study/` | Deck study feature module under Clean boundaries. |

## `lib/` — application code

### Architecture (BLoC + Clean)

The app is migrating to a **BLoC + Clean Architecture** baseline:

- **Presentation**: screens/widgets + BLoC/Cubit for UI state and events.
- **Domain**: use cases + entities (business rules, framework-agnostic).
- **Data**: repositories + remote/local data sources.

During the transition, **Riverpod remains supported as a compatibility bridge** for existing modules. New features should prefer BLoC-oriented boundaries while integrating with legacy Riverpod flows through adapters/facades.

### Bootstrap and configuration

- **`main.dart`** — `main()`, `WidgetsFlutterBinding`, `PreConfig.init()`, `runApp` with `UncontrolledProviderScope` + `ProviderScope`, `MaterialApp.router`, and `MainTabScreen` (bottom navigation).
- **`pre_config.dart`** — One-time startup: document directory, Hive-backed hydrated storage, `ApiService.init()`, `DioClient` configuration with interceptors.
- **`constants.dart`** — Shared constants used across the app.

### Routing

- **`routers/routers.dart`** — `AppRoutes` enum (path strings for login, main, register, study).
- **`routers/app_pages.dart`** — `GoRouter` definition: routes, auth `redirect`, `refreshListenable` for login-driven refreshes.

### Global providers

- **`providers/`** — App-wide Riverpod state: authentication (`auth_provider.dart`), theme, locale, loading helpers, etc.

### Networking and persistence

- **`services/index.dart`** — Library entry that `part`s the HTTP client, env, and API path constants; import this package path for `DioClient`, `Env`, and `Api`.
- **`services/dio_client/`** — `DioClient` singleton, request helpers, `interceptors.dart` (headers, response handling, logging in non-release builds).
- **`services/apis/`** — Thin API facades: `api_service.dart` (token, generic HTTP), `auth_service.dart`, `deck_service.dart`, `card_service.dart`, etc. These call into `ApiService` / `DioClient` and map responses to models.
- **`services/storage/`** — Hydrated storage integration (`hydrated_storage.dart`, `hydrated_notifier.dart`, storage exceptions).

### Data models

- **`models/`** — Serializable types aligned with the backend: `api_response.dart`, `deck.dart`, `card.dart`, `fact.dart`, `user.dart`, etc.

### Screens (feature UI)

Screens are grouped by area under `screen/`:

| Folder | Role |
|--------|------|
| `screen/login/` | Login UI, controllers, forgot-password widget. |
| `screen/register/` | Registration and controller. |
| `screen/home/` | Home tab (placeholder-style welcome content). |
| `screen/decks/` | Deck list tab: `deck_list_screen.dart`, `providers/` (`deck_list.dart`, `deck_create.dart`), `widgets/` (list body, list row, create form, loading affordances). |
| `screen/deck/` | Deck view / study: `deck_view_screen.dart`, `providers/` (`card_review.dart`, `review_interval_range.dart`, `audio_player.dart`), `formatters/`, `deck_widgets/` (menu, body, interval controls), `card_widgets/` (flip, card face, media), `fact_widgets/` (add / edit / content), `fact_add_composer/` (add-fact row model and UI pieces). |
| `screen/profile/` | Profile tab and profile-related providers. |

Feature providers often sit next to their screen (`screen/<feature>/providers/`). Some screens use a nested **`ProviderScope`** with **overrides** (for example `deck_view_screen.dart` supplies the current `Deck` to `cardProvider` and seeds `createDeckParamsProvider` for the app bar / edit flow).

### Shared UI and utilities

- **`widgets/`** — Reusable components (`buttons_tab_bar`, `common_refresher`, `common_bottom_sheet`, `number_picker`, etc.).
- **`video_player/`** — Custom in-app video UI built on `video_player` (embedded + fullscreen, controls, settings).
- **`utils/`** — Logging, debounce, small helpers.
- **`extensions/`** — `BuildContext`, `Widget`, `Map`, and object extensions.
- **`mixins/`** — Shared notifier or lifecycle behavior (`refresh_controller_mixin`, `delayed_init_mixin`, etc.).

### Localization

- **`l10n/`** — Generated `app_localizations*.dart` and ARB sources (`app_en.arb`, `app_zh.arb`). Flutter `generate: true` is enabled in `pubspec.yaml`.

## How the pieces connect

1. **Startup** — `PreConfig` initializes storage, loads the auth token, configures **Dio** with base URL from **`Env`**.
2. **Navigation** — **go_router** in `app_pages.dart` gates routes using login state; a **`ChangeNotifier`** on the auth notifier refreshes the router when auth changes.
3. **Data flow** — Preferred: UI (Screen/Widget) → BLoC/Cubit → UseCase → Repository → DataSource (`ApiService` / `DioClient`) → Domain/DTO models. Legacy Riverpod Notifier flows may coexist during migration via bridge adapters.
4. **Scoped state** — Some legacy routes wrap **`ProviderScope(overrides: …)`** so feature providers receive the correct `Deck` or parameters without global singletons.
5. **Migration guardrail** — Services/API layers must not directly mutate UI state containers (Riverpod providers, BLoCs, Cubits, controllers). UI state changes go through presentation-layer inputs (events, intents, method calls on state managers).

## Tests

Tests live under `test/` and mirror `lib/` where practical (`test/providers/`, `test/screen/`, `test/services/`, `test/models/`, plus `test/helpers/`). Commands and conventions: [docs/frontend_tests.md](docs/frontend_tests.md) ([中文](docs/frontend_tests_zh.md)).

## Tooling

- **`analysis_options.yaml`** — Dart analyzer and lint rules (extends `flutter_lints`).
- **`devtools_options.yaml`** — DevTools preferences.

Platform-specific build output lives under `android/`, `ios/`, and similar; details are not duplicated here.
