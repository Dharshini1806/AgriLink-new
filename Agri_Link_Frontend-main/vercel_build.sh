#!/bin/bash
set -e

echo "🚀 AgriLink Flutter Web Build Script"
echo "======================================"

# Vercel sets CWD to the project root (agrilink-flutter/)
# Flutter SDK is cloned into a local 'flutter' dir inside the project
FLUTTER_DIR="$(pwd)/flutter_sdk"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "📥 Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

echo "🔍 Flutter version:"
flutter --version

echo "📦 Running flutter pub get..."
flutter pub get

echo "🔨 Building Flutter web (optimized)..."
flutter build web -O2 --no-tree-shake-icons

echo "✅ Build complete! Output: build/web"
