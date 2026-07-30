#!/bin/bash
set -euo pipefail

APP="$HOME/Applications/LinkOpener.app"

if [ -d "/Applications/Brave Browser.app" ]; then
  RESET_BUNDLE_ID="com.brave.Browser"
  RESET_NAME="Brave Browser"
elif [ -d "/Applications/Google Chrome.app" ]; then
  RESET_BUNDLE_ID="com.google.Chrome"
  RESET_NAME="Google Chrome"
else
  RESET_BUNDLE_ID=""
fi

if [ -n "$RESET_BUNDLE_ID" ] && [ -x "$APP/Contents/MacOS/LinkOpener" ]; then
  "$APP/Contents/MacOS/LinkOpener" --set-default-handler "$RESET_BUNDLE_ID"
  echo "Requested default browser reset to $RESET_NAME."
  echo "macOS should now show a dialog asking to confirm the change —"
  echo "click \"Use $RESET_NAME\" to finish. If you don't see it, check behind other windows,"
  echo "or set it manually: System Settings > Desktop & Dock > Default web browser"
else
  echo "Couldn't reset the default browser automatically (no supported browser installed, or LinkOpener already removed)."
  echo "Set it manually: System Settings > Desktop & Dock > Default web browser"
fi

rm -rf "$APP"
echo "Removed $APP"
