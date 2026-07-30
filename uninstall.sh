#!/bin/bash
set -euo pipefail

APP="$HOME/Applications/LinkOpener.app"
BRAVE_BUNDLE_ID="com.brave.Browser"

if command -v duti >/dev/null 2>&1; then
  duti -s "$BRAVE_BUNDLE_ID" http || true
  duti -s "$BRAVE_BUNDLE_ID" https || true
  echo "Default browser reset to Brave."
else
  echo "duti not found — couldn't reset the default browser automatically."
  echo "Set it manually: System Settings > Desktop & Dock > Default web browser > Brave Browser"
fi

rm -rf "$APP"
echo "Removed $APP"
