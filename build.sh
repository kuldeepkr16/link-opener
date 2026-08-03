#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LinkOpener"
BUILD_DIR="$APP_NAME.app"
CONTENTS="$BUILD_DIR/Contents"

rm -rf "$BUILD_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

# Build both architectures and combine into one universal binary, so the app
# runs on Intel and Apple Silicon Macs alike regardless of which Mac built it.
swiftc -O -target arm64-apple-macosx11.0 src/main.swift -o "$CONTENTS/MacOS/${APP_NAME}-arm64"
swiftc -O -target x86_64-apple-macosx11.0 src/main.swift -o "$CONTENTS/MacOS/${APP_NAME}-x86_64"
lipo -create -output "$CONTENTS/MacOS/$APP_NAME" "$CONTENTS/MacOS/${APP_NAME}-arm64" "$CONTENTS/MacOS/${APP_NAME}-x86_64"
rm "$CONTENTS/MacOS/${APP_NAME}-arm64" "$CONTENTS/MacOS/${APP_NAME}-x86_64"

cp Info.plist "$CONTENTS/Info.plist"
cp icon/AppIcon.icns "$CONTENTS/Resources/AppIcon.icns"

codesign --force --deep -s - "$BUILD_DIR"

echo "Built $BUILD_DIR"
