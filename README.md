# LinkOpener

Makes links you click anywhere on macOS (Slack, Mail, Terminal, etc.) open in
Brave or Chrome with a profile you choose from a small popup, instead of the
browser's own profile-picker dialog.

## Install

```
curl -fsSL https://raw.githubusercontent.com/kuldeepkr16/link-opener/main/bootstrap.sh | bash
```

Then click any link — a dialog will ask which profile to open it in.

The list of profiles is read automatically from whichever of Brave/Chrome you
have installed (their `Local State` files), so it shows your own profiles —
no editing required. If both are installed, each button is labeled with its
browser, e.g. "personal (Chrome)".

## Uninstall

```
curl -fsSL https://raw.githubusercontent.com/kuldeepkr16/link-opener/main/bootstrap-uninstall.sh | bash
```

This resets your default browser (to Brave if installed, otherwise Chrome)
and removes `~/Applications/LinkOpener.app`.

<details>
<summary>Manual install/uninstall (if you'd rather not pipe to bash)</summary>

**Install:** download this repo (**Code > Download ZIP** on GitHub, or `git clone git@github.com:kuldeepkr16/link-opener.git`), unzip it, then run `bash install.sh` from inside the folder.

**Uninstall:** from that same folder, run `bash uninstall.sh`. Or manually: switch your default browser back to Brave in **System Settings > Desktop & Dock > Default web browser**, then delete `~/Applications/LinkOpener.app`.

</details>

## Requirements

- macOS
- Brave Browser and/or Google Chrome installed in `/Applications`
- Optional: [`duti`](https://github.com/moretension/duti) (`brew install duti`) so install/uninstall can set the default browser automatically. Without it, set it manually in **System Settings > Desktop & Dock > Default web browser**.

## Gatekeeper note

LinkOpener isn't notarized or signed with a paid Apple Developer certificate,
so macOS treats it as coming from an unidentified developer. `install.sh`
clears the quarantine flag for you, so you shouldn't see a Gatekeeper warning
when installing this way.

## Building from source

The compiled app is already included, but if you want to rebuild it:

```
bash build.sh
```

This compiles `src/main.swift` into `LinkOpener.app` using `swiftc` (ships
with Xcode Command Line Tools).
