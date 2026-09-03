#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/Task Bubble.app"
BUILD_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/task-bubble-build.XXXXXX")"
ICONSET_DIR="$BUILD_TEMP_DIR/AppIcon.iconset"
trap 'rm -rf "$BUILD_TEMP_DIR"' EXIT

swift build --package-path "$PROJECT_DIR" -c release --arch arm64 --arch x86_64
BIN_DIR="$(swift build --package-path "$PROJECT_DIR" -c release --arch arm64 --arch x86_64 --show-bin-path)"
swift "$PROJECT_DIR/scripts/generate-app-icon.swift" "$ICONSET_DIR"
iconutil --convert icns --output "$BUILD_TEMP_DIR/AppIcon.icns" "$ICONSET_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/TaskBubble" "$APP_DIR/Contents/MacOS/TaskBubble"
cp "$PROJECT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BUILD_TEMP_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
lipo "$APP_DIR/Contents/MacOS/TaskBubble" -verify_arch arm64 x86_64
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
