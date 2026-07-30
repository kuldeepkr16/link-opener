import Cocoa

struct Profile {
    let name: String
    let directory: String
}

func loadBraveProfiles() -> [Profile] {
    let path = NSString(string: "~/Library/Application Support/BraveSoftware/Brave-Browser/Local State")
        .expandingTildeInPath

    guard
        let data = FileManager.default.contents(atPath: path),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let profileSection = json["profile"] as? [String: Any],
        let infoCache = profileSection["info_cache"] as? [String: Any]
    else {
        return [Profile(name: "Default", directory: "Default")]
    }

    let profiles = infoCache.compactMap { directory, value -> Profile? in
        guard let info = value as? [String: Any] else { return nil }
        let name = (info["name"] as? String) ?? directory
        return Profile(name: name, directory: directory)
    }

    return profiles.sorted { $0.directory < $1.directory }
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

        let profiles = loadBraveProfiles()

        let alert = NSAlert()
        alert.messageText = "Open link with which Brave profile?"
        alert.informativeText = urlString
        for profile in profiles {
            alert.addButton(withTitle: profile.name)
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
            "-na", "Brave Browser",
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
