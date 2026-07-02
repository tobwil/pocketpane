#!/bin/zsh
set -euo pipefail

ROOT=${0:A:h:h}
VERSION="4.0"
ARCH=$(uname -m)
CACHE_ROOT="$ROOT/.tools"

case "$ARCH" in
    arm64)
        RELEASE_ARCH="aarch64"
        SHA256="f5167fe047fe4a2ae2c2ea8634c7145a4d64d0b6005f24bb45639a965b8c60d4"
        ;;
    x86_64)
        RELEASE_ARCH="x86_64"
        SHA256="b83169f856d7022ed0e4428d98acea18dde2d63f49611b52ea137577ce4efe6b"
        ;;
    *)
        echo "Unsupported Mac architecture: $ARCH" >&2
        exit 1
        ;;
esac

TOOLS_DIR="$CACHE_ROOT/scrcpy-macos-$RELEASE_ARCH-v$VERSION"
ARCHIVE="$CACHE_ROOT/scrcpy-macos-$RELEASE_ARCH-v$VERSION.tar.gz"
URL="https://github.com/Genymobile/scrcpy/releases/download/v$VERSION/scrcpy-macos-$RELEASE_ARCH-v$VERSION.tar.gz"

if [[ ! -x "$TOOLS_DIR/scrcpy" || ! -x "$TOOLS_DIR/adb" ]]; then
    mkdir -p "$CACHE_ROOT"
    echo "Downloading official scrcpy $VERSION tools for $ARCH…" >&2
    curl --fail --location --progress-bar "$URL" --output "$ARCHIVE"

    ACTUAL_SHA=$(shasum -a 256 "$ARCHIVE" | cut -d ' ' -f 1)
    if [[ "$ACTUAL_SHA" != "$SHA256" ]]; then
        echo "Checksum mismatch for scrcpy archive." >&2
        exit 1
    fi

    tar -xzf "$ARCHIVE" -C "$CACHE_ROOT"
fi

if [[ ! -f "$CACHE_ROOT/scrcpy-LICENSE.txt" ]]; then
    curl --fail --silent --show-error --location \
        "https://raw.githubusercontent.com/Genymobile/scrcpy/v$VERSION/LICENSE" \
        --output "$CACHE_ROOT/scrcpy-LICENSE.txt"
fi

echo "$TOOLS_DIR"
