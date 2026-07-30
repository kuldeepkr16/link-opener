#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LinkOpener.app"
DEST="$HOME/Applications/$APP_NAME"
BUNDLE_ID="com.kuldeep.linkopener"

if [ ! -d "$APP_NAME" ]; then
  echo "Error: $APP_NAME not found next to this script." >&2
  exit 1
fi

mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP_NAME" "$DEST"

# Clear quarantine so Gatekeeper doesn't block a downloaded/unsigned app.
xattr -cr "$DEST"
codesign --force --deep -s - "$DEST"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$DEST"

if [ ! -d "/Applications/Brave Browser.app" ]; then
  echo "Warning: Brave Browser.app not found in /Applications — install Brave first." >&2
fi

if command -v duti >/dev/null 2>&1; then
  duti -s "$BUNDLE_ID" http || true
  duti -s "$BUNDLE_ID" https || true
  echo "LinkOpener installed and set as default browser."
else
  echo "LinkOpener installed to $DEST."
  echo "duti not found, so the default browser wasn't set automatically."
  echo "Install it with 'brew install duti' and re-run this script, or set it manually:"
  echo "  System Settings > Desktop & Dock > Default web browser > LinkOpener"
fi
