#!/bin/zsh
set -euo pipefail

ROOT=${0:A:h:h}
APP_NAME="PocketPane"
BUILD_DIR="$ROOT/dist"
APP="$BUILD_DIR/$APP_NAME.app"
TOOLS_DIR=$("$ROOT/scripts/fetch-tools.sh")

cd "$ROOT"

# Some Command Line Tools installations retain an older compatible SDK beside
# the newest one while Apple updates compiler components. Prefer it when present.
if [[ -z "${SDKROOT:-}" && -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]]; then
    export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
fi

swift build -c release

rm -rf "$APP"
rm -rf "$BUILD_DIR/DroidMirror.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
mkdir -p "$APP/Contents/Resources/bin" "$APP/Contents/Resources/Licenses"
cp "$TOOLS_DIR/scrcpy" "$APP/Contents/Resources/bin/"
cp "$TOOLS_DIR/adb" "$APP/Contents/Resources/bin/"
cp "$TOOLS_DIR/scrcpy-server" "$APP/Contents/Resources/bin/"
cp "$TOOLS_DIR/scrcpy.png" "$APP/Contents/Resources/bin/"
cp "$TOOLS_DIR/disconnected.png" "$APP/Contents/Resources/bin/"
cp "$ROOT/.tools/scrcpy-LICENSE.txt" "$APP/Contents/Resources/Licenses/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>PocketPane</string>
    <key>CFBundleExecutable</key><string>PocketPane</string>
    <key>CFBundleIdentifier</key><string>app.pocketpane.mac</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>PocketPane</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.2.0</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>PocketPaneWebsite</key><string>https://pocketpane.app</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "$APP"
