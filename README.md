# LinkOpener

Makes links you click anywhere on macOS (Slack, Mail, Terminal, etc.) open in
Brave with a profile you choose from a small popup, instead of Brave's own
profile-picker dialog.

## Install

Open Terminal and run:

```
curl -fsSL https://raw.githubusercontent.com/kuldeepkr16/link-opener/main/bootstrap.sh | bash
```

Then click any link — a dialog will ask which Brave profile to open it in.

<details>
<summary>Manual install (if you'd rather not pipe to bash)</summary>

1. Download this repo: click **Code > Download ZIP** on GitHub (or `git clone git@github.com:kuldeepkr16/link-opener.git`), then unzip it.
2. Open Terminal, `cd` into the unzipped folder, and run:
   ```
   bash install.sh
   ```

</details>

The list of profiles is read automatically from your own Brave installation
(`~/Library/Application Support/BraveSoftware/Brave-Browser/Local State`), so
it shows your profiles, not anyone else's — no editing required.

## Requirements

- macOS
- Brave Browser installed in `/Applications`
- Optional: [`duti`](https://github.com/moretension/duti) (`brew install duti`) so the installer can set LinkOpener as your default browser automatically. Without it, set it manually in **System Settings > Desktop & Dock > Default web browser**.

## Gatekeeper note

LinkOpener isn't notarized or signed with a paid Apple Developer certificate,
so macOS treats it as coming from an unidentified developer. `install.sh`
clears the quarantine flag for you, so you shouldn't see a Gatekeeper warning
when installing this way.

## Uninstall

1. In **System Settings > Desktop & Dock > Default web browser**, switch back to Brave (or another browser).
2. Delete `~/Applications/LinkOpener.app`.

## Building from source

The compiled app is already included, but if you want to rebuild it:

```
bash build.sh
```

This compiles `src/main.swift` into `LinkOpener.app` using `swiftc` (ships
with Xcode Command Line Tools).
