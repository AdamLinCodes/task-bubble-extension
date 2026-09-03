#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/Task Bubble.app"
BUILD_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/task-bubble-build.XXXXXX")"
ICONSET_DIR="$BUILD_TEMP_DIR/AppIcon.iconset"
trap 'rm -rf "$BUILD_TEMP_DIR"' EXIT

# A single SwiftPM invocation with multiple --arch values switches to XCBuild.
# Standalone Command Line Tools installations do not always include XCBuild, so
# build each architecture with SwiftPM's native build system and combine them.
swift build --package-path "$PROJECT_DIR" -c release --arch arm64
ARM64_BIN_DIR="$(swift build --package-path "$PROJECT_DIR" -c release --arch arm64 --show-bin-path)"
swift build --package-path "$PROJECT_DIR" -c release --arch x86_64
X86_64_BIN_DIR="$(swift build --package-path "$PROJECT_DIR" -c release --arch x86_64 --show-bin-path)"
swift "$PROJECT_DIR/scripts/generate-app-icon.swift" "$ICONSET_DIR"
iconutil --convert icns --output "$BUILD_TEMP_DIR/AppIcon.icns" "$ICONSET_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
lipo -create \
  "$ARM64_BIN_DIR/TaskBubble" \
  "$X86_64_BIN_DIR/TaskBubble" \
  -output "$APP_DIR/Contents/MacOS/TaskBubble"
cp "$PROJECT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BUILD_TEMP_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
lipo "$APP_DIR/Contents/MacOS/TaskBubble" -verify_arch arm64 x86_64
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
