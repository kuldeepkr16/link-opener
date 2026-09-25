#!/bin/bash
set -euo pipefail

# `--keep-config` leaves your auto-open rules and the Full Disk Access grant
# alone. repair.sh passes it, because a repair is meant to reinstall the app,
# not to wipe the settings you configured or make you grant permission again.
KEEP_CONFIG=0
if [ "${1:-}" = "--keep-config" ]; then
  KEEP_CONFIG=1
fi

# Older versions installed into ~/Applications; current ones use
# /Applications. Clean up whichever is present.
if [ -d "/Applications/LinkOpener.app" ]; then
  APP="/Applications/LinkOpener.app"
else
  APP="$HOME/Applications/LinkOpener.app"
fi

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

# A running app keeps going after its bundle is deleted, carrying on as the
# link handler from a copy that no longer exists. Stop it before removing
# anything, or the uninstall leaves a process behind that nothing can update.
pkill -f "LinkOpener.app/Contents/MacOS/LinkOpener" 2>/dev/null || true

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[ -d "$APP" ] && "$LSREGISTER" -u "$APP" 2>/dev/null || true

if [ -w "$(dirname "$APP")" ]; then
  rm -rf "$APP"
else
  sudo rm -rf "$APP"
fi
rm -rf "$HOME/Applications/LinkOpener.app"
echo "Removed $APP"

if [ "$KEEP_CONFIG" -eq 1 ]; then
  echo "Kept your auto-open rules and permissions."
else
  defaults delete com.kuldeep.linkopener >/dev/null 2>&1 || true
  rm -rf "$HOME/Library/Application Support/LinkOpener"
  rm -f "$HOME/Library/Preferences/com.kuldeep.linkopener.plist"
  # TCC keeps the Full Disk Access grant after the app is gone. Left behind, it
  # shows up as an enabled LinkOpener row that silently denies a reinstall,
  # because the grant no longer matches the new binary.
  tccutil reset All com.kuldeep.linkopener >/dev/null 2>&1 || true
  echo "Removed saved rules and reset the Full Disk Access grant."
fi
