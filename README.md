# LinkOpener

Makes links you click anywhere on macOS (Slack, Mail, Terminal, etc.) open in
Brave or Chrome with a profile you choose from a small popup, instead of the
browser's own profile-picker dialog.

## Install

```
curl -fsSL https://raw.githubusercontent.com/kuldeepkr16/link-opener/main/bootstrap.sh | bash
```

**macOS will then show a system dialog** asking you to confirm the default
browser change — click **"Use LinkOpener"** to finish setup. This is Apple's
own confirmation prompt for changing your default browser; no install script
(including this one) can skip it, it always requires one click.

Then click any link — a dialog will ask which profile to open it in.

The list of profiles is read automatically from whichever of Brave/Chrome you
have installed (their `Local State` files), so it shows your own profiles —
no editing required. If both are installed, each button is labeled with its
browser, e.g. "personal (Chrome)".

> Don't run the install command more than once in a row without answering
> that dialog first — each run asks again, so unanswered dialogs stack up on
> screen instead of replacing each other.

## Uninstall

```
curl -fsSL https://raw.githubusercontent.com/kuldeepkr16/link-opener/main/bootstrap-uninstall.sh | bash
```

This removes `~/Applications/LinkOpener.app` and requests that your default
browser be reset back to Brave (or Chrome, if Brave isn't installed) — the
same confirmation dialog as above will appear; click **"Use Brave"** (or
Chrome) to finish. If you don't see it, check behind other windows, or set
it manually: **System Settings > Desktop & Dock > Default web browser**.

<details>
<summary>Manual install/uninstall (if you'd rather not pipe to bash)</summary>

**Install:** download this repo (**Code > Download ZIP** on GitHub, or `git clone git@github.com:kuldeepkr16/link-opener.git`), unzip it, then run `bash install.sh` from inside the folder.

**Uninstall:** from that same folder, run `bash uninstall.sh`. Or manually: switch your default browser back to Brave in **System Settings > Desktop & Dock > Default web browser**, then delete `~/Applications/LinkOpener.app`.

</details>

## Requirements

- macOS
- Brave Browser and/or Google Chrome installed in `/Applications`

No other dependencies — install/uninstall use the same LaunchServices API
`duti` wraps, called directly, so there's nothing extra to install.

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
