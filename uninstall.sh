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

if [ -n "$RESET_BUNDLE_ID" ] && command -v duti >/dev/null 2>&1; then
  duti -s "$RESET_BUNDLE_ID" http || true
  duti -s "$RESET_BUNDLE_ID" https || true
  echo "Default browser reset to $RESET_NAME."
else
  echo "Couldn't reset the default browser automatically (duti missing or no supported browser installed)."
  echo "Set it manually: System Settings > Desktop & Dock > Default web browser"
fi

rm -rf "$APP"
echo "Removed $APP"
