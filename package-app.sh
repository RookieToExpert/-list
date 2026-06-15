#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TudouList"
BUNDLE_ID="com.rui.tudoulist"
VERSION="1.0.1"
BUILD_DIR="dist"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
DMG_ROOT="${BUILD_DIR}/dmg-root"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

swift build -c release

rm -rf "$APP_DIR" "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$DMG_ROOT"

cp ".build/release/${APP_NAME}" "$APP_DIR/Contents/MacOS/${APP_NAME}"
chmod +x "$APP_DIR/Contents/MacOS/${APP_NAME}"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"

cp -R "$APP_DIR" "$DMG_ROOT/${APP_NAME}.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create   -volname "$APP_NAME"   -srcfolder "$DMG_ROOT"   -ov   -format UDZO   "$DMG_PATH"

rm -rf "$DMG_ROOT"

echo "App bundle: $APP_DIR"
echo "Installer DMG: $DMG_PATH"
