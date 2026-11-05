#!/bin/zsh
# Builds Flick.app and installs it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=build/Flick.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Flick "$APP/Contents/MacOS/Flick"
cp Icon/Flick.icns "$APP/Contents/Resources/Flick.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Flick</string>
  <key>CFBundleDisplayName</key><string>Flick</string>
  <key>CFBundleIdentifier</key><string>com.thomasflensted.flick</string>
  <key>CFBundleExecutable</key><string>Flick</string>
  <key>CFBundleIconFile</key><string>Flick</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
IDENTITY=$(security find-identity -v -p codesigning | grep -o '"Apple Development[^"]*"' | head -1 | tr -d '"')
codesign --force --sign "${IDENTITY:--}" "$APP"
if [[ "${1:-}" != "--no-install" ]]; then
  pkill -x Flick 2>/dev/null || true
  rm -rf /Applications/Flick.app
  cp -R "$APP" /Applications/Flick.app
  echo "Installed /Applications/Flick.app"
fi
