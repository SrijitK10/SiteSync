#!/bin/bash

echo "🚀 Installing Flutter SDK..."
if [ ! -d "flutter_sdk" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
fi

export PATH="$PATH:`pwd`/flutter_sdk/bin"

echo "⚙️ Configuring Flutter..."
flutter config --enable-web
flutter pub get

echo "🏗 Building Web App..."
flutter build web

echo "✅ Build Complete!"
