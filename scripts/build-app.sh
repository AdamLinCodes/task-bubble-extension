#!/usr/bin/env bash
set -euo pipefail

REQUIRED_TOOLS=(swift iconutil lipo codesign)
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    MISSING_TOOLS+=("$tool")
  fi
done

if (( ${#MISSING_TOOLS[@]} > 0 )); then
  echo "Missing required Apple build tools: ${MISSING_TOOLS[*]}" >&2
  echo "Install them with: xcode-select --install" >&2
  exit 1
fi

MACOS_VERSION="$(sw_vers -productVersion)"
MACOS_MAJOR_VERSION="${MACOS_VERSION%%.*}"
if [[ ! "$MACOS_MAJOR_VERSION" =~ ^[0-9]+$ ]] || (( MACOS_MAJOR_VERSION < 14 )); then
  echo "Task Bubble requires macOS 14 or newer; this Mac is running $MACOS_VERSION." >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/Task Bubble.app"
BUILD_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/task-bubble-build.XXXXXX")"
ICONSET_DIR="$BUILD_TEMP_DIR/AppIcon.iconset"
SIGNING_IDENTITY="${TASK_BUBBLE_SIGNING_IDENTITY:--}"
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

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR"
else
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$APP_DIR"
fi

echo "$APP_DIR"
