#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${AEROPOINT_VERSION:-1.0.0}"
APP_NAME="AeroPoint Agent"
BUNDLE_ID="com.aeropoint.agent"
DIST_DIR="$ROOT_DIR/dist/macos"
APP_PATH="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/dist/AeroPointAgent-macos-$VERSION.zip"

rm -rf "$APP_PATH" "$ZIP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources" "$ROOT_DIR/dist"

echo "Building macOS agent..."
swift build --package-path "$ROOT_DIR/macos" -c release
BIN_DIR="$(swift build --package-path "$ROOT_DIR/macos" -c release --show-bin-path)"
cp "$BIN_DIR/AeroPointAgent" "$APP_PATH/Contents/MacOS/AeroPointAgent"
cp "$ROOT_DIR/macos/Sources/AeroPointAgent/Info.plist" "$APP_PATH/Contents/Info.plist"
printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"

chmod +x "$APP_PATH/Contents/MacOS/AeroPointAgent"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo "Signing macOS app with: $DEVELOPER_ID_APPLICATION"
  codesign --force --deep --options runtime --timestamp \
    --identifier "$BUNDLE_ID" \
    --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP_PATH"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
else
  echo "Skipping macOS signing. Set DEVELOPER_ID_APPLICATION to sign for public distribution."
fi

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "Submitting macOS app for notarization..."
  NOTARY_ZIP="$ROOT_DIR/dist/AeroPointAgent-macos-notary-$VERSION.zip"
  rm -f "$NOTARY_ZIP"
  ditto --norsrc -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$APP_PATH"
  rm -f "$NOTARY_ZIP"
else
  echo "Skipping notarization. Set APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD to notarize."
fi

ditto --norsrc -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Created $ZIP_PATH"
