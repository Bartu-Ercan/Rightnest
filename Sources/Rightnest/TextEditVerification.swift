#if DEBUG
import AppKit
import ApplicationServices
import RightnestCore

/// Explicit developer-only verification of a disposable file, never a user's document.
@MainActor
enum TextEditVerification {
    struct Failure: Error { let message: String }
    static func wait(_ message: String, seconds: Double = 8, until predicate: () -> Bool) async throws {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw Failure(message: message)
    }
    static func run(model: AppModel, directory: URL) async {
        let client = AccessibilityClient()
        var report: [String: String] = [:]
        let previousEnabled = model.enabled, previousExperiment = model.textEditEnabled
        defer { model.enabled = previousEnabled; model.textEditEnabled = previousExperiment }
        do {
            guard AXIsProcessTrusted() else { throw Failure(message: "Accessibility permission missing") }
            report["permission"] = "granted"
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: directory.appendingPathComponent("result.json"))
            let fixture = directory.appendingPathComponent("Rightnest Window Verification.txt")
            try Data().write(to: fixture, options: .atomic)
            guard let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") else {
                throw Failure(message: "TextEdit unavailable")
            }
            model.enabled = true; model.textEditEnabled = true
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.addsToRecentItems = false
            let running = try await NSWorkspace.shared.open([fixture], withApplicationAt: application, configuration: configuration)
            // Recover only this fixture if an interrupted earlier run left it full-screen.
            var fixtureWindow: AXUIElement?
            try await wait("Disposable document did not open") {
                guard let windows = client.value(AXUIElementCreateApplication(running.processIdentifier), kAXWindowsAttribute) as? [AXUIElement] else { return false }
                fixtureWindow = windows.first {
                    guard let raw = client.value($0, kAXDocumentAttribute) as? String else { return false }
                    return URL(string: raw)?.standardizedFileURL == fixture.standardizedFileURL
                }
                return fixtureWindow != nil
            }
            if let window = fixtureWindow {
                if (client.value(window, "AXFullScreen") as? Bool) == true {
                    try await Task.sleep(for: .milliseconds(1200))
                    _ = AXUIElementSetAttributeValue(window, "AXFullScreen" as CFString, kCFBooleanFalse)
                    try await wait("Previous fixture full-screen state did not clear") {
                        (client.value(window, "AXFullScreen") as? Bool) == false
                    }
                    try await Task.sleep(for: .milliseconds(800))
                }
                if (client.value(window, kAXMinimizedAttribute) as? Bool) == true {
                    _ = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                }
                _ = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                running.activate(options: [])
            }
            var target: WindowTarget?
            try await wait("Disposable document did not become focused") {
                guard let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier == "com.apple.TextEdit",
                      let found = client.target(pid: front.processIdentifier),
                      let raw = client.value(found.window, kAXDocumentAttribute) as? String,
                      URL(string: raw)?.standardizedFileURL == fixture.standardizedFileURL else { return false }
                target = found; return true
            }
            guard let target else { throw Failure(message: "No verified target") }
            report["document"] = "disposable fixture verified by AXDocument URL"
            try await wait("Control panel did not appear") { model.verificationPanelVisible }
            report["panel"] = "visible"
            guard model.invokeVerificationAction(.minimize) else { throw Failure(message: "Minimize button unavailable") }
            report["minimizeDispatchStatus"] = model.status
            report["minimizePlacementIssue"] = client.placementIssue
            try await wait("Minimize action did not change the window") {
                (client.value(target.window, kAXMinimizedAttribute) as? Bool) == true
            }
            report["minimize"] = "passed"
            guard AXUIElementSetAttributeValue(target.window, kAXMinimizedAttribute as CFString, kCFBooleanFalse) == .success else {
                throw Failure(message: "Could not restore disposable window")
            }
            try await wait("Restored window did not become focused") {
                guard let front = NSWorkspace.shared.frontmostApplication, front.processIdentifier == target.pid,
                      let current = client.focusedWindow(pid: target.pid) else { return false }
                return CFEqual(current, target.window)
            }
            report["restore"] = "passed"
            try await Task.sleep(for: .milliseconds(1200))
            try await wait("Control panel did not return after restore") { model.verificationPanelVisible }
            guard let original = client.frame(target.window), let primary = NSScreen.screens.first,
                  let fitted = WindowGeometry.screen(for: original, visibleFrames: NSScreen.screens.map({ WindowGeometry.flip($0.visibleFrame, primaryTop: primary.frame.maxY) })) else { throw Failure(message: "Screen geometry unavailable") }
            report["expectedFit"] = NSStringFromRect(fitted)
            report["originalFrame"] = NSStringFromRect(original)
            guard model.invokeVerificationAction(.fit) else { throw Failure(message: "Fit button unavailable") }
            try await wait("Fit did not reach visible screen bounds") {
                client.frame(target.window).map { WindowGeometry.close($0, fitted) } ?? false
            }
            report["fit"] = "passed"
            try await wait("Panel did not return after fit") { model.verificationPanelVisible }
            guard model.invokeVerificationAction(.fit) else { throw Failure(message: "Restore button unavailable") }
            try await wait("Restore did not reach original frame") {
                client.frame(target.window).map { WindowGeometry.close($0, original) } ?? false
            }
            report["restoreFrame"] = "passed"
            try await wait("Panel did not return after restore") { model.verificationPanelVisible }
            guard model.invokeVerificationAction(.close) else { throw Failure(message: "Close button unavailable") }
            try await wait("Close action did not remove the disposable window") {
                guard let windows = client.value(AXUIElementCreateApplication(target.pid), kAXWindowsAttribute) as? [AXUIElement] else { return false }
                return !windows.contains { CFEqual($0, target.window) }
            }
            report["close"] = "passed"
            report["result"] = "passed"
        } catch {
            report["result"] = "failed"
            report["error"] = (error as? Failure)?.message ?? String(describing: error)
        }
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier, let t = client.target(pid: pid) { report["finalFrame"] = NSStringFromRect(t.frame) }
        report["frontApplication"] = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "none"
        report["actionTrace"] = await model.verificationTrace().joined(separator: "\n")
        report["lastActionResult"] = model.lastActionResult
        report["lastAppStatus"] = model.status
        report["lastPlacementIssue"] = client.placementIssue
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appendingPathComponent("result.json"), options: .atomic)
        } catch { NSLog("Rightnest verification report could not be written: %@", String(describing: error)) }
    }
}
#endif
