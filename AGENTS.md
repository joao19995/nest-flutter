# AGENTS.md

## 1. Project Overview

Nest (Flutter) is the mobile client for the Nest household finance app. It is a
**simple, read-mostly companion** to the existing Next.js web app: dashboards
overview screens plus a small number of create/update forms ("inserts"). It
talks to the same API.

- API contract: the web repo `docs/api-contract.md`.
- Machine-readable spec: `GET /api/openapi` (OpenAPI v3.1).
- Auth: `Authorization: Bearer <NEST_API_KEY>` on every `/api/*` route except
  `/api/health`.

Build only what provides clear, practical value. This is not an enterprise
platform: every abstraction, dependency and extra layer must justify itself.

## 2. Architecture

Feature-first, layered. Group UI by feature; group data/domain by type.

```
lib/
├── main.dart                 # bootstrap only
├── app.dart                  # MaterialApp + DependenciesScope
├── config/                   # env, constants, composition root
├── data/
│   ├── models/               # API models with fromJson/toDomain
│   ├── repositories/         # concrete repositories (consume the API client)
│   └── services/             # NestApiClient (HTTP + auth + error mapping)
├── domain/
│   ├── failures/             # typed failures (ApiFailure)
│   └── models/               # clean, immutable entities
└── ui/
    ├── core/
    │   ├── theme/            # App* token classes + barrel
    │   ├── widgets/          # shared component library + barrel
    │   └── dependencies_scope.dart
    └── features/<feature>/
        ├── view_models/      # ChangeNotifier presentation state
        └── views/            # widgets, screens, forms
```

Rules:

- The UI layer never imports `data/` directly; it goes through a ViewModel that
  was constructed with repositories.
- ViewModels extend `ChangeNotifier`, expose immutable getters, and are created
  by their View from `DependenciesScope.of(context)`.
- Views use `ListenableBuilder`; they contain no business logic.
- Repositories return domain models, never raw JSON.
- No DI package: the graph is small and built in `config/dependencies.dart`.

## 3. Design Tokens

The web palette (`app/globals.css` `@theme`) is mirrored into `App*` classes in
`lib/ui/core/theme/`. **No raw value may appear in widget code.**

- Colours: `AppColors.*` — never `Color(0x...)` or `Colors.*`.
- Text: `AppTextStyles.*` — no inline `TextStyle` with raw sizes.
- Spacing: `AppSpacing.*` / `AppSizes.*` — no raw layout doubles.
- Radius: `AppRadius.*All` — no `BorderRadius.circular(x)` with a literal.
- Shadows: `AppShadows.*` — no inline `BoxShadow`.
- Motion: `AppMotion.*` — no raw `Duration`.
- Breakpoints: `AppBreakpoints.*` — never compare `MediaQuery` width to a raw
  number.
- Badge colours: `AppBadgeStyles.*` only.
- Money: `AppFormatters.currency(value)` (EUR, pt-PT) — never string
  interpolation.

## 4. Widget Authoring

- Default to `StatelessWidget`; use `StatefulWidget` only for widget-local,
  non-business state (controllers, focus, local animation).
- Decompose when a `build` exceeds ~60 lines or nested layout gets deep.
  Extracted pieces must be widget classes, not `Widget`-returning methods.
- Every widget that can be `const` must be `const`.
- A component never accepts a `BuildContext`/ref as a parameter; it reads only
  what is passed in. Visual variants are enums, not booleans.
- Every screen that loads async data handles loading, error and empty states
  via `AsyncView`. No blank screen, no silent failure.
- Responsive branching uses `LayoutBuilder` + `AppBreakpoints`; below
  `breakpoint.md` multi-column layouts collapse to one column.

## 5. Dart Conventions

- `dart format` is the authority. No unformatted commits.
- Zero `flutter analyze` warnings on `main`.
- Imports: `dart:` → `package:flutter/` → third-party → `package:nest/`, all
  alphabetised, separated by blank lines. **No relative imports** (enforced by
  `always_use_package_imports`).
- Files `snake_case`; classes `UpperCamelCase`; members `lowerCamelCase`;
  constants `lowerCamelCase`; predicates named `isX`/`hasX`.
- Prefer `const`; forbid `!` outside tests; avoid `late` except `late final`
  initialised before first use.
- Domain/data models are immutable. Recoverable errors are `ApiFailure`; never
  pass raw `Exception`/`String` between layers.

## 6. Testing

- Model mapping has unit tests (`test/data/models/...`).
- Shared widgets have widget tests for their states
  (`test/ui/core/widgets/...`). See `AsyncView` tests.
- Test files mirror the source structure.
- No `sleep`/`Future.delayed`; use `pump`/`pumpAndSettle`/`await`.
- Run before finishing: `flutter analyze` and `flutter test`.

## 7. Commands

```
flutter pub get
flutter analyze
flutter test
```

### Running against the local web API

The web app must be running first (its `NEST_API_KEY` is in the web repo
`.env.local`). `--dart-define` values are compile-time, so the built binary
bakes them in — always pass them on the command line you actually run.

| Target         | `NEST_API_BASE_URL`         |
| -------------- | --------------------------- |
| Windows/Linux  | `http://localhost:3000`     |
| Android emu.   | `http://10.0.2.2:3000`      |
| iOS simulator  | `http://localhost:3000`     |
| Physical phone | `http://<LAN IP>:3000`      |

`10.0.2.2` is the Android emulator's alias for the host machine; `localhost`
inside the emulator means the emulator itself. For a physical device the web
server must listen on `0.0.0.0` and the firewall must allow port 3000.

```powershell
# Desktop (hot reload: r = reload, R = restart, q = quit)
flutter run -d windows --dart-define=NEST_API_BASE_URL=http://localhost:3000 --dart-define=NEST_API_KEY=<key>

# Android emulator
flutter emulators --launch Medium_Phone_API_36.0
flutter run -d emulator-5554 --dart-define=NEST_API_BASE_URL=http://10.0.2.2:3000 --dart-define=NEST_API_KEY=<key>
```

Flutter web (`-d chrome`) is **not** usable against the local API: the browser
enforces CORS and the web app does not send CORS headers.

Android debug builds permit plain HTTP through a debug-only
`network_security_config.xml`; release builds keep Android's HTTPS-only
default. Run `flutter doctor --android-licenses` once before release builds.

### Release

```
flutter build <apk|appbundle|windows|web> --dart-define=NEST_API_BASE_URL=https://<host> --dart-define=NEST_API_KEY=<key>
```

## 8. Definition of Done

- Solves the requested problem; follows the conventions above.
- Loading/error/empty/data states implemented.
- `flutter analyze` clean and `flutter test` green.
- No raw values in widget code.
