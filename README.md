# Retentio (Flutter)

🌐 English | [中文](README_zh.md)

Flutter client for Retentio. Entrypoint: `lib/main.dart`. Dependencies and SDK versions: `pubspec.yaml`.

## Getting started

From the repository root:

```bash
flutter pub get
flutter run
```

## Git hooks

After cloning, run `./utils/setup-hooks.sh` once to install **pre-commit** (format, analyze, tests).

Full guide: [docs/PRE_COMMIT_HOOK_zh.md](docs/PRE_COMMIT_HOOK_zh.md) · [English](docs/PRE_COMMIT_HOOK.md)

## Repository layout

| Path | Purpose |
|------|---------|
| `lib/`, `android/`, `ios/`, … | Flutter app (`pubspec.yaml` at repo root). |
| `docs/` | Project documentation: Markdown files in the `docs/` root (no subfolders). |
| `utils/` | Helper scripts (e.g. pre-commit). |
| `.github/` | GitHub templates and workflows. |

## Documentation

- **API:** [docs/API.md](docs/API.md) ([中文](docs/API_zh.md))

## `lib/` — application code

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
| `screen/decks/` | Deck list tab: `decks_screen.dart`, `providers/` (deck list, create-deck), `widgets/`. |
| `screen/deck/` | Studying and deck editing: `deck_learn_screen.dart`, `deck_detail_screen.dart`, `providers/` (card state, review intervals, audio), `widgets/` (cards, flash card, media, facts). |
| `screen/profile/` | Profile tab and profile-related providers. |

Feature providers often sit next to their screen (`screen/<feature>/providers/`). Some screens use a nested **`ProviderScope`** with **overrides** (for example `deck_learn_screen.dart` supplies the current `Deck` to `cardProvider`).

### Shared UI and utilities

- **`widgets/`** — Reusable components (`common_refresher`, `common_bottom_sheet`, `video_player/` subtree, etc.).
- **`utils/`** — Logging, debounce, small helpers.
- **`extensions/`** — `BuildContext`, `Widget`, `Map`, and object extensions.
- **`mixins/`** — Shared notifier or lifecycle behavior (`refresh_controller_mixin`, `delayed_init_mixin`, etc.).

### Localization

- **`l10n/`** — Generated `app_localizations*.dart` and ARB sources (`app_en.arb`, `app_zh.arb`). Flutter `generate: true` is enabled in `pubspec.yaml`.

## How the pieces connect

1. **Startup** — `PreConfig` initializes storage, loads the auth token, configures **Dio** with base URL from **`Env`**.
2. **Navigation** — **go_router** in `app_pages.dart` gates routes using login state; a **`ChangeNotifier`** on the auth notifier refreshes the router when auth changes.
3. **Data flow** — UI **Consumer** / **ref.watch** → **Notifier** providers → **\*Service** classes → **ApiService** / **DioClient** → **`ApiResponse`** / domain **models**.
4. **Scoped state** — Some routes wrap **`ProviderScope(overrides: …)`** so feature providers receive the correct `Deck` or parameters without global singletons.

## Tests

Tests live under `test/` and mirror `lib/` where practical (`test/providers/`, `test/screen/`, `test/services/`, `test/models/`, plus `test/helpers/`). Commands and conventions: [docs/FRONTEND_TESTS.md](docs/FRONTEND_TESTS.md) ([中文](docs/FRONTEND_TESTS_zh.md)).

## Tooling

- **`analysis_options.yaml`** — Dart analyzer and lint rules (extends `flutter_lints`).
- **`devtools_options.yaml`** — DevTools preferences.

Platform-specific build output lives under `android/`, `ios/`, and similar; details are not duplicated here.
