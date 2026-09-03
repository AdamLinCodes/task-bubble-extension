#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/Task Bubble.app"

swift build --package-path "$PROJECT_DIR" -c release --arch arm64 --arch x86_64
BIN_DIR="$(swift build --package-path "$PROJECT_DIR" -c release --arch arm64 --arch x86_64 --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/TaskBubble" "$APP_DIR/Contents/MacOS/TaskBubble"
cp "$PROJECT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
lipo "$APP_DIR/Contents/MacOS/TaskBubble" -verify_arch arm64 x86_64
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
