#!/bin/zsh
set -euo pipefail

ROOT=${0:A:h:h}
SDK=${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}
ARCH=$(uname -m)
BUILD_ROOT="$ROOT/.build/$ARCH-apple-macosx/release"
OUTPUT="$ROOT/assets/screenshots"
BINARY="/tmp/PocketPaneReadmeScreenshots"

cd "$ROOT"
SDKROOT="$SDK" swift build -c release

swiftc \
    -sdk "$SDK" \
    -target "$ARCH-apple-macosx14.0" \
    -I "$BUILD_ROOT/Modules" \
    "$ROOT/Sources/PocketPane/ContentView.swift" \
    "$ROOT/Sources/PocketPane/MirrorModel.swift" \
    "$ROOT/Sources/PocketPane/AppLauncherView.swift" \
    "$ROOT/scripts/render-readme-screenshots.swift" \
    "$BUILD_ROOT"/PocketPaneCore.build/*.o \
    -o "$BINARY"

"$BINARY" "$OUTPUT"
echo "$OUTPUT"
