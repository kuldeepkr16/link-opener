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

if [ ! -d "/Applications/Brave Browser.app" ] && [ ! -d "/Applications/Google Chrome.app" ]; then
  echo "Warning: neither Brave Browser.app nor Google Chrome.app found in /Applications — install one first." >&2
fi

if "$DEST/Contents/MacOS/LinkOpener" --set-default-handler "$BUNDLE_ID"; then
  echo "LinkOpener installed and set as default browser."
else
  echo "LinkOpener installed to $DEST, but couldn't confirm it was set as the default browser."
  echo "Click a link to test it — if it doesn't open through LinkOpener, just re-run this script."
fi
