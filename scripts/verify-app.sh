#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-$PROJECT_DIR/dist/Task Bubble.app}"
MODE="${2:-local}"
EXECUTABLE="$APP_PATH/Contents/MacOS/TaskBubble"

if [[ ! -d "$APP_PATH" || ! -x "$EXECUTABLE" ]]; then
  echo "Task Bubble app bundle is missing or incomplete: $APP_PATH" >&2
  exit 1
fi

if [[ "$MODE" != "local" && "$MODE" != "release" ]]; then
  echo "Usage: $0 [app-path] [local|release]" >&2
  exit 1
fi

lipo "$EXECUTABLE" -verify_arch arm64 x86_64
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

MINIMUM_SYSTEM_VERSION="$(plutil -extract LSMinimumSystemVersion raw "$APP_PATH/Contents/Info.plist")"
if [[ "$MINIMUM_SYSTEM_VERSION" != "14.0" ]]; then
  echo "Expected macOS 14.0 deployment target, found $MINIMUM_SYSTEM_VERSION" >&2
  exit 1
fi

if otool -L "$EXECUTABLE" | tail -n +2 | grep -Eq '/Users/|/private/(tmp|var/folders)/'; then
  echo "The app contains a dependency on a build-machine path." >&2
  exit 1
fi

SIGNATURE_DETAILS="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
if [[ "$MODE" == "release" ]]; then
  if grep -q '^Signature=adhoc$' <<<"$SIGNATURE_DETAILS"; then
    echo "Release verification failed: the app is ad-hoc signed and Gatekeeper will reject it on other Macs." >&2
    exit 1
  fi

  if ! grep -q '^Authority=Developer ID Application:' <<<"$SIGNATURE_DETAILS"; then
    echo "Release verification failed: a Developer ID Application signature is required." >&2
    exit 1
  fi

  xcrun stapler validate "$APP_PATH"
  spctl --assess --type execute --verbose=4 "$APP_PATH"
fi

echo "Verified Task Bubble for $MODE use: arm64 + x86_64, macOS $MINIMUM_SYSTEM_VERSION+"
