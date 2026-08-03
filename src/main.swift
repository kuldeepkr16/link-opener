import Cocoa
import SwiftUI
import CoreServices
import UniformTypeIdentifiers

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

struct Profile: Identifiable, Hashable {
    let browserLabel: String
    let bundleID: String
    let directory: String
    let profileName: String

    var id: String { "\(bundleID)|\(directory)" }
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

// MARK: - Auto-open rules (per-profile regex patterns, saved locally)

enum RuleStore {
    static let configURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LinkOpener", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("rules.json")
    }()

    static func load() -> [String: [String]] {
        guard
            let data = try? Data(contentsOf: configURL),
            let dict = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            return [:]
        }
        return dict
    }

    static func save(_ rules: [String: [String]]) {
        guard let data = try? prettyData(for: rules) else { return }
        try? data.write(to: configURL)
    }

    static func prettyData(for rules: [String: [String]]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(rules)
    }
}

/// Returns the single profile whose saved patterns match `urlString`, or nil
/// if zero or more than one profile matches (ambiguous matches fall back to
/// showing the picker rather than guessing).
func matchingProfile(for urlString: String, among profiles: [Profile], rules: [String: [String]]) -> Profile? {
    let nsURL = urlString as NSString
    let fullRange = NSRange(location: 0, length: nsURL.length)

    let matches = profiles.filter { profile in
        guard let patterns = rules[profile.id], !patterns.isEmpty else { return false }
        return patterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return false
            }
            return regex.firstMatch(in: urlString, options: [], range: fullRange) != nil
        }
    }

    return matches.count == 1 ? matches.first : nil
}

// MARK: - Settings window (SwiftUI)

private struct RuleRow: Identifiable {
    let id = UUID()
    var text: String
}

struct SettingsView: View {
    let profiles: [Profile]
    @State private var rows: [String: [RuleRow]]
    let onSave: ([String: [String]]) -> Void

    init(profiles: [Profile], savedRules: [String: [String]], onSave: @escaping ([String: [String]]) -> Void) {
        self.profiles = profiles
        self.onSave = onSave
        var initial: [String: [RuleRow]] = [:]
        for profile in profiles {
            initial[profile.id] = (savedRules[profile.id] ?? []).map { RuleRow(text: $0) }
        }
        _rows = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto-open rules").font(.title2).bold()
            Text("Add patterns (plain text or regex) per profile. A link matching a profile's patterns opens straight into that profile — no picker. Hold ⌥ Option while clicking a link to always show the picker.")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(profiles) { profile in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(profile.profileName) (\(profile.browserLabel))").font(.headline)

                            ForEach(Array((rows[profile.id] ?? []).enumerated()), id: \.element.id) { index, row in
                                HStack {
                                    TextField("e.g. quicksight", text: binding(profileID: profile.id, index: index))
                                        .textFieldStyle(.roundedBorder)
                                    Button {
                                        removeRow(at: index, from: profile.id)
                                    } label: {
                                        Image(systemName: "minus.circle")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Button {
                                addRow(to: profile.id)
                            } label: {
                                Label("Add pattern", systemImage: "plus.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Save") {
                    var toSave: [String: [String]] = [:]
                    for profile in profiles {
                        let patterns = (rows[profile.id] ?? [])
                            .map { $0.text.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        toSave[profile.id] = patterns
                    }
                    onSave(toSave)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 500, height: 480)
    }

    private func binding(profileID: String, index: Int) -> Binding<String> {
        Binding(
            get: { rows[profileID]?[index].text ?? "" },
            set: { newValue in rows[profileID]?[index].text = newValue }
        )
    }

    private func addRow(to profileID: String) {
        rows[profileID, default: []].append(RuleRow(text: ""))
    }

    private func removeRow(at index: Int, from profileID: String) {
        rows[profileID]?.remove(at: index)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "arrow.up.forward.square", accessibilityDescription: "LinkOpener")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        let exportItem = NSMenuItem(title: "Export Config…", action: #selector(exportConfig), keyEquivalent: "")
        exportItem.target = self
        menu.addItem(exportItem)
        let importItem = NSMenuItem(title: "Import Config…", action: #selector(importConfig), keyEquivalent: "")
        importItem.target = self
        menu.addItem(importItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit LinkOpener", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        item.menu = menu

        statusItem = item
    }

    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        let profiles = loadProfiles()
        let rules = RuleStore.load()
        let view = SettingsView(profiles: profiles, savedRules: rules) { [weak self] newRules in
            RuleStore.save(newRules)
            self?.settingsWindow?.close()
        }

        if let window = settingsWindow {
            window.contentViewController = NSHostingController(rootView: view)
            window.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "LinkOpener Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            window.makeKeyAndOrderFront(nil)
            settingsWindow = window
        }
    }

    @objc func exportConfig() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "linkopener-rules.json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try RuleStore.prettyData(for: RuleStore.load())
            try data.write(to: url)
        } catch {
            showAlert(title: "Export failed", message: error.localizedDescription)
        }
    }

    @objc func importConfig() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let rules = try JSONDecoder().decode([String: [String]].self, from: data)
            RuleStore.save(rules)
            showAlert(title: "Import complete", message: "Replaced saved rules with \(rules.count) profile(s) from \(url.lastPathComponent).")
        } catch {
            showAlert(title: "Import failed", message: error.localizedDescription)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
            return
        }
        // The event arrives during the launch sequence, before the run loop
        // is free to run a modal session — defer to the next tick.
        DispatchQueue.main.async {
            self.route(urlString)
        }
    }

    func route(_ urlString: String) {
        let optionHeld = NSEvent.modifierFlags.contains(.option)
        if !optionHeld {
            let profiles = loadProfiles()
            let rules = RuleStore.load()
            if let match = matchingProfile(for: urlString, among: profiles, rules: rules) {
                open(urlString, in: match)
                return
            }
        }
        showPicker(for: urlString)
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

        open(urlString, in: profiles[index])
    }

    func open(_ urlString: String, in profile: Profile) {
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
