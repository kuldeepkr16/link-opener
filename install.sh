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

# Clear quarantine so Gatekeeper doesn't block a downloaded/unsigned app, but
# keep the signature build.sh already made. Re-signing here would give the
# binary a new cdhash, and macOS keys the Full Disk Access grant (see below) to
# that hash for an ad-hoc signed app — so re-signing on every install would
# silently revoke the permission each time, sending the profile list back to a
# lone "Default" entry with no visible error.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

if ! codesign --verify --strict "$DEST" >/dev/null 2>&1; then
  echo "Bundled signature is invalid — re-signing." >&2
  echo "If you had granted Full Disk Access before, you will need to grant it again." >&2
  codesign --force --deep -s - "$DEST"
fi

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$DEST"

if [ ! -d "/Applications/Brave Browser.app" ] && [ ! -d "/Applications/Google Chrome.app" ]; then
  echo "Warning: neither Brave Browser.app nor Google Chrome.app found in /Applications — install one first." >&2
fi

"$DEST/Contents/MacOS/LinkOpener" --set-default-handler "$BUNDLE_ID"

# Launch the app itself so its menu bar icon appears right away — the
# --set-default-handler call above exits before ever starting the app.
open -a "$DEST"

# Since macOS 26 the browsers' `Local State` files — where the profile list
# lives — are behind Full Disk Access. A denied read is silent, so without the
# grant the picker shows one "Default" per browser rather than your profiles.
# Check now so this surfaces here instead of on the next link click.
if ! "$DEST/Contents/MacOS/LinkOpener" --check-profile-access; then
  cat <<'EOF'

----------------------------------------------------------------------
LinkOpener cannot read your browser profiles yet.

macOS keeps the browser profile list behind Full Disk Access. Until you
grant it, the picker will only offer a single "Default" entry per browser
instead of your real profiles.

Opening System Settings > Privacy & Security > Full Disk Access, and a
Finder window showing the app. To finish:

  1. Drag LinkOpener.app from the Finder window into the list
     (or click "+" and pick it).
  2. Make sure its switch is turned ON.
  3. Quit LinkOpener from its menu bar icon, then launch it again from
     ~/Applications — the permission is only read at launch.

You do not need to re-run this installer.
----------------------------------------------------------------------
EOF
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" || true
  open -R "$DEST" || true
fi

echo "LinkOpener installed to $DEST."
echo "macOS should now show a dialog asking to confirm the default browser change —"
echo "click \"Use LinkOpener\" to finish setup. If you don't see it, check behind other windows."
echo "You should also see a small arrow icon appear in your menu bar."
