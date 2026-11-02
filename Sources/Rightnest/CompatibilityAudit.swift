#if DEBUG
import AppKit

/// Explicit opt-in developer audit. Records geometry/capabilities only, never
/// titles, document paths, text, URLs or screenshots. It never dispatches actions.
@MainActor
enum CompatibilityAudit {
    static func run(directory: URL, model: AppModel) async {
        let engine = WindowEngine()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var rows: [[String: String]] = []
        var previous: [String: String] = [:]
        var observations: [[String: String]] = []
        while !Task.isCancelled {
            for app in NSWorkspace.shared.runningApplications {
                guard let id = app.bundleIdentifier, app.activationPolicy == .regular, id != Bundle.main.bundleIdentifier else { continue }
                let screens = NSScreen.screens.map { screen in
                    CGRect(x: screen.visibleFrame.minX, y: (NSScreen.screens.first?.frame.maxY ?? 0)-screen.visibleFrame.maxY,
                           width: screen.visibleFrame.width, height: screen.visibleFrame.height)
                }
                let result = await engine.inspect(pid: app.processIdentifier, overlayNumber: nil, requireFocus: false, screens: screens)
                let frame = result.snapshot.map { NSStringFromRect($0.frame) } ?? "unavailable"
                let key = id + result.reason + frame
                if previous[id] != key {
                    previous[id] = key
                    rows.append(["application": id, "foreground": String(NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier), "version": app.bundleURL.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String } ?? "unknown",
                        "os": ProcessInfo.processInfo.operatingSystemVersionString,
                        "time": ISO8601DateFormatter().string(from: Date()), "placement": result.reason,
                        "layout": await engine.auditLayout(), "frame": frame, "actions": result.snapshot?.actions.map(\.rawValue).sorted().joined(separator: ",") ?? "none"])
                    if let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]) {
                        try? data.write(to: directory.appendingPathComponent("compatibility.json"), options: .atomic)
                    }
                }
            }
            observations.append(["time": ISO8601DateFormatter().string(from: Date()),
                "application": NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "none",
                "panelVisible": String(model.verificationPanelVisible)])
            if observations.count > 300 { observations.removeFirst() }
            if let data = try? JSONSerialization.data(withJSONObject: observations, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: directory.appendingPathComponent("observations.json"), options: .atomic)
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
#endif
