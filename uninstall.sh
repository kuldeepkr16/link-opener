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
  if "$APP/Contents/MacOS/LinkOpener" --set-default-handler "$RESET_BUNDLE_ID"; then
    echo "Default browser reset to $RESET_NAME."
  else
    echo "Couldn't confirm the default browser was reset to $RESET_NAME."
    echo "Set it manually: System Settings > Desktop & Dock > Default web browser"
  fi
else
  echo "Couldn't reset the default browser automatically (no supported browser installed, or LinkOpener already removed)."
  echo "Set it manually: System Settings > Desktop & Dock > Default web browser"
fi

rm -rf "$APP"
echo "Removed $APP"
