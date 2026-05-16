#!/usr/bin/env bash
# VocaNova DMG 빌드 스크립트.
#
# 전제: build/export/VocaNova.app이 이미 서명·notarize·staple된 상태.
# 산출물: build/VocaNova-<version>.dmg (notarize는 별도 단계).
#
# 사용법: ./scripts/make-dmg.sh

set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="build/export/VocaNova.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
DMG_PATH="build/VocaNova-$VERSION.dmg"
STAGING_DIR="build/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: $APP_PATH not found. Run archive+export first." >&2
  exit 1
fi

# create-dmg는 staging 디렉터리 전체를 DMG에 담는다. .app만 들어가도록 격리.
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

create-dmg \
  --volname "VocaNova" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "VocaNova.app" 175 190 \
  --hide-extension "VocaNova.app" \
  --app-drop-link 425 190 \
  --no-internet-enable \
  "$DMG_PATH" \
  "$STAGING_DIR/"

rm -rf "$STAGING_DIR"

echo ""
echo "✓ DMG created: $DMG_PATH"
echo "  $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "Next:"
echo "  xcrun notarytool submit \"$DMG_PATH\" --keychain-profile vocanova-notarize --wait"
echo "  xcrun stapler staple \"$DMG_PATH\""
