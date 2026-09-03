#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$DIST_DIR/Task Bubble.app"
INFO_PLIST="$PROJECT_DIR/Packaging/Info.plist"
SIGNING_IDENTITY="${TASK_BUBBLE_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${TASK_BUBBLE_NOTARY_PROFILE:-}"
NOTARY_KEY_PATH="${TASK_BUBBLE_NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${TASK_BUBBLE_NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${TASK_BUBBLE_NOTARY_ISSUER_ID:-}"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST")"
ZIP_PATH="$DIST_DIR/Task-Bubble-$VERSION-macOS-universal.zip"
DMG_PATH="$DIST_DIR/Task-Bubble-$VERSION-macOS-universal.dmg"
CHECKSUM_PATH="$DIST_DIR/Task-Bubble-$VERSION-SHA256SUMS.txt"
PACKAGE_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/task-bubble-package.XXXXXX")"
DMG_SOURCE_DIR="$PACKAGE_TEMP_DIR/dmg"
trap 'rm -rf "$PACKAGE_TEMP_DIR"' EXIT

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "TASK_BUBBLE_SIGNING_IDENTITY must name an installed Developer ID Application certificate." >&2
  exit 1
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  NOTARY_ARGUMENTS=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "$NOTARY_KEY_PATH" && -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER_ID" ]]; then
  NOTARY_ARGUMENTS=(
    --key "$NOTARY_KEY_PATH"
    --key-id "$NOTARY_KEY_ID"
    --issuer "$NOTARY_ISSUER_ID"
  )
else
  echo "Configure TASK_BUBBLE_NOTARY_PROFILE or all three App Store Connect API key variables." >&2
  exit 1
fi

TASK_BUBBLE_SIGNING_IDENTITY="$SIGNING_IDENTITY" "$PROJECT_DIR/scripts/build-app.sh"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUM_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" "${NOTARY_ARGUMENTS[@]}" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

# Recreate the ZIP so it contains the stapled application ticket.
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

mkdir -p "$DMG_SOURCE_DIR"
ditto "$APP_PATH" "$DMG_SOURCE_DIR/Task Bubble.app"
ln -s /Applications "$DMG_SOURCE_DIR/Applications"
hdiutil create \
  -volname "Task Bubble" \
  -srcfolder "$DMG_SOURCE_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" "${NOTARY_ARGUMENTS[@]}" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

"$PROJECT_DIR/scripts/verify-app.sh" "$APP_PATH" release
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" "$(basename "$DMG_PATH")" \
    >"$(basename "$CHECKSUM_PATH")"
)

echo "$DMG_PATH"
echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
