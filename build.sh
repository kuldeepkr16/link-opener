#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LinkOpener"
BUILD_DIR="$APP_NAME.app"
CONTENTS="$BUILD_DIR/Contents"

rm -rf "$BUILD_DIR"
mkdir -p "$CONTENTS/MacOS"

swiftc -O src/main.swift -o "$CONTENTS/MacOS/$APP_NAME"
cp Info.plist "$CONTENTS/Info.plist"

codesign --force --deep -s - "$BUILD_DIR"

echo "Built $BUILD_DIR"
