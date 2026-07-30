import Cocoa
import CoreServices

// CLI mode: `LinkOpener --set-default-handler <bundleID>` requests that
// bundle ID as the default http/https handler, using the same LaunchServices
// API the `duti` tool wraps. macOS shows its own system dialog asking the
// user to confirm a default-browser change ("Use X" / "Keep Y") — that
// confirmation can't be scripted or read back synchronously, so this just
// fires the request and exits. install.sh/uninstall.sh call this instead of
// depending on `duti`, and tell the user to expect and answer that dialog.
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--set-default-handler" {
    let bundleID = CommandLine.arguments[2] as CFString
    _ = LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID)
    _ = LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID)
    print("Requested default handler: \(bundleID as String)")
    exit(0)
}

struct Profile {
    let browserLabel: String
    let bundleID: String
    let directory: String
    let profileName: String
}

struct BrowserConfig {
    let label: String
    let bundleID: String
    let localStatePath: String
}

let browserConfigs: [BrowserConfig] = [
    BrowserConfig(
        label: "Brave",
        bundleID: "com.brave.Browser",
        localStatePath: "~/Library/Application Support/BraveSoftware/Brave-Browser/Local State"
    ),
    BrowserConfig(
        label: "Chrome",
        bundleID: "com.google.Chrome",
        localStatePath: "~/Library/Application Support/Google/Chrome/Local State"
    ),
]

func isInstalled(bundleID: String) -> Bool {
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
}

func loadProfiles() -> [Profile] {
    var profiles: [Profile] = []

    for config in browserConfigs {
        guard isInstalled(bundleID: config.bundleID) else { continue }

        let path = NSString(string: config.localStatePath).expandingTildeInPath
        guard
            let data = FileManager.default.contents(atPath: path),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profileSection = json["profile"] as? [String: Any],
            let infoCache = profileSection["info_cache"] as? [String: Any],
            !infoCache.isEmpty
        else {
            profiles.append(Profile(browserLabel: config.label, bundleID: config.bundleID, directory: "Default", profileName: "Default"))
            continue
        }

        for (directory, value) in infoCache {
            guard let info = value as? [String: Any] else { continue }
            let name = (info["name"] as? String) ?? directory
            profiles.append(Profile(browserLabel: config.label, bundleID: config.bundleID, directory: directory, profileName: name))
        }
    }

    return profiles.sorted { ($0.browserLabel, $0.directory) < ($1.browserLabel, $1.directory) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
            return
        }
        // The event arrives during the launch sequence, before the run loop
        // is free to run a modal session — defer to the next tick.
        DispatchQueue.main.async {
            self.showPicker(for: urlString)
        }
    }

    func showPicker(for urlString: String) {
        NSApp.activate(ignoringOtherApps: true)

        let profiles = loadProfiles()

        guard !profiles.isEmpty else {
            // Neither Brave nor Chrome is installed — nothing to route to.
            NSSound.beep()
            return
        }

        let showBrowserLabel = Set(profiles.map { $0.browserLabel }).count > 1

        let alert = NSAlert()
        alert.messageText = "Open link with which profile?"
        alert.informativeText = urlString
        for profile in profiles {
            let title = showBrowserLabel ? "\(profile.profileName) (\(profile.browserLabel))" : profile.profileName
            alert.addButton(withTitle: title)
        }
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        guard index >= 0, index < profiles.count else {
            return
        }

        let profile = profiles[index]
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [
            "-b", profile.bundleID,
            "-n",
            "--args",
            "--profile-directory=\(profile.directory)",
            urlString,
        ]
        try? task.run()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
