#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing Flutter SDK..."
FLUTTER_DIR="${FLUTTER_DIR:-${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}/flutter_sdk}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "⚙️ Configuring Flutter..."
flutter --version
flutter config --no-analytics
flutter config --enable-web
flutter pub get

echo "🏗 Building Web App..."
flutter build web --release

echo "✅ Build Complete!"
