#!/bin/bash
# Builds Habla.app from the Swift package.
# Signing: set HABLA_SIGN_ID to the name of a self-signed certificate in Keychain so macOS
# keeps the Accessibility permission between builds. Without it, an ad-hoc signature is used.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Habla

# The project folder is synced by iCloud, which stamps files and breaks signing.
# So the app is assembled and signed in ~/Applications, outside any synced folder.
APP="${HABLA_OUT:-$HOME/Applications}/Habla.app"
mkdir -p "$(dirname "$APP")"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/Habla" "$APP/Contents/MacOS/Habla"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.habla.app</string>
  <key>CFBundleName</key><string>Habla</string>
  <key>CFBundleExecutable</key><string>Habla</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>Habla listens while you hold Right Option, to turn your voice into text.</string>
</dict></plist>
PLIST

xattr -cr "$APP"
# A local, gitignored .sign-id file can hold the certificate name or hash.
[ -z "${HABLA_SIGN_ID:-}" ] && [ -f .sign-id ] && HABLA_SIGN_ID="$(cat .sign-id)"
codesign --force --sign "${HABLA_SIGN_ID:--}" "$APP"
echo "Built $APP"
