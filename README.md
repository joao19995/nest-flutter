# Nest

Nest is the Flutter client for the Nest household finance app. It is a
read-mostly companion to the Nest web app: year/month dashboards, shared to-do
lists, the calendar, and a small number of create/update forms.

## Requirements

- Flutter (stable, with the Web and Windows/iOS/Android toolchains you need)
- A running Nest web API

## Setup

```powershell
flutter pub get
Copy-Item config/dev.example.json config/dev.json
```

Paste the API key from the web app's `.env.local` into `config/dev.json`.
`config/dev.json`, `config/android.json` and `config/pwa.json` are git-ignored.

## Run

```powershell
# Desktop
flutter run -d windows --dart-define-from-file=config/dev.json

# Android emulator (uses config/android.json with 10.0.2.2)
flutter run -d emulator-5554 --dart-define-from-file=config/android.json
```

## Quality checks

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Web / PWA

```powershell
.\scripts\deploy_web.ps1
```

The script builds the PWA from `config/pwa.json` and deploys `build/web` to
Vercel. The deployment proxies `/api` to the Nest API so the browser does not
need CORS.

## Structure

```
lib/
├── config/     # environment, constants and the dependency graph
├── data/       # API client, models and repositories
├── domain/     # immutable entities and typed failures
└── ui/         # theme tokens, shared widgets and feature screens
```

The UI talks to repositories through `ChangeNotifier` view models; the
dependency graph is built explicitly in `lib/config/dependencies.dart`.
