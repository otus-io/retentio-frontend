# Retentio (Flutter)

🌐 English | [中文](docs/readme_zh.md)

Flutter client for Retentio. Entrypoint: `lib/main.dart`. Dependencies and SDK versions: `pubspec.yaml`.

## Getting started

From the repository root:

```bash
flutter pub get
flutter run
```

### Backend environment / host override

API host is compile-time configured via `--dart-define`:

- `API_ENV=debug|dev|release` (default is `dev`)
- `API_HOST=<full-base-url>` (overrides `API_ENV` mapping when provided)

Examples:

```bash
# Use env mapping
flutter run --dart-define=API_ENV=debug
flutter run --dart-define=API_ENV=dev
flutter run --dart-define=API_ENV=release

# Direct host override (takes precedence over API_ENV)
flutter run --dart-define=API_HOST=http://10.0.2.2:8080
flutter run --dart-define=API_HOST=https://api-staging.example.com
```

Current host mapping in `lib/services/env.dart`:

- `debug` -> `http://localhost:8080`
- `dev` -> `https://api.wordupx.com:8443`
- `release` -> `https://api.wordupx.com`

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

## Documentation

- **API:** [docs/api.md](docs/api.md) ([中文](docs/api_zh.md))

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
3. **Data flow** — UI **Consumer** / **ref.watch** → **Notifier** providers → **\*Service** classes → **ApiService** / **DioClient** → **`ApiResponse`** / domain **models**.
4. **Scoped state** — Some routes wrap **`ProviderScope(overrides: …)`** so feature providers receive the correct `Deck` or parameters without global singletons.

## Tests

Tests live under `test/` and mirror `lib/` where practical (`test/providers/`, `test/screen/`, `test/services/`, `test/models/`, plus `test/helpers/`). Commands and conventions: [docs/frontend_tests.md](docs/frontend_tests.md) ([中文](docs/frontend_tests_zh.md)).

## Tooling

- **`analysis_options.yaml`** — Dart analyzer and lint rules (extends `flutter_lints`).
- **`devtools_options.yaml`** — DevTools preferences.

Platform-specific build output lives under `android/`, `ios/`, and similar; details are not duplicated here.
