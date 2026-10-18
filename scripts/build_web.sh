#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${HOME}/flutter-sdk"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define=NEST_API_BASE_URL=https://nest-kohl-nine.vercel.app \
  --dart-define=NEST_API_KEY="${NEST_API_KEY:?NEST_API_KEY is required}"
