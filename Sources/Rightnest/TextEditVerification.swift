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
    static func matchesFixture(_ window: AXUIElement, fixture: URL, client: AccessibilityClient, finderFixture: Bool = false) -> Bool {
        func matches(_ raw: CFTypeRef?) -> Bool {
            if let url = raw as? URL { return url.isFileURL && fixture.isFileURL ? url.standardizedFileURL.path == fixture.standardizedFileURL.path : url == fixture }
            if let string = raw as? String, let url = URL(string: string) { return url.isFileURL && fixture.isFileURL ? url.standardizedFileURL.path == fixture.standardizedFileURL.path : url == fixture }
            return false
        }
        if finderFixture, fixture.lastPathComponent.hasPrefix("Rightnest-Finder-Verification-"),
           (client.value(window, kAXTitleAttribute) as? String) == fixture.lastPathComponent { return true }
        if matches(client.value(window, kAXDocumentAttribute)) || matches(client.value(window, "AXURL")) { return true }
        var budget = 100
        var matching = 0, other = 0
        func visit(_ node: AXUIElement, depth: Int) {
            budget -= 1
            guard budget > 0, depth < 7 else { other += 1; return }
            if (client.value(node, kAXRoleAttribute) as? String) == "AXWebArea" {
                if matches(client.value(node, "AXURL")) { matching += 1 } else { other += 1 }
                return
            }
            if let children = client.value(node, kAXChildrenAttribute) as? [AXUIElement] {
                for child in children { visit(child, depth: depth + 1) }
            }
        }
        visit(window, depth: 0)
        return matching == 1 && other == 0
    }
    static func run(model: AppModel, directory: URL, browserFixture: URL? = nil, fixtureApplicationID: String = "com.apple.Safari") async {
        let client = AccessibilityClient()
        var report: [String: String] = [:]
        let previousEnabled = model.enabled, previousExperiment = model.textEditEnabled
        defer { model.enabled = previousEnabled; model.textEditEnabled = previousExperiment }
        do {
            guard AXIsProcessTrusted() else { throw Failure(message: "Accessibility permission missing") }
            report["permission"] = "granted"
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: directory.appendingPathComponent("result.json"))
            let fixture = browserFixture ?? directory.appendingPathComponent("Rightnest Window Verification.txt")
            let applicationID = browserFixture == nil ? "com.apple.TextEdit" : fixtureApplicationID
            if browserFixture == nil { try Data().write(to: fixture, options: .atomic) }
            guard let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: applicationID) else {
                throw Failure(message: "TextEdit unavailable")
            }
            model.enabled = true; model.textEditEnabled = true
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.addsToRecentItems = false
            let running: NSRunningApplication
            if browserFixture != nil {
                guard let browser = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == applicationID }) else { throw Failure(message: "Safari is not running") }
                running = browser
            } else {
                running = try await NSWorkspace.shared.open([fixture], withApplicationAt: application, configuration: configuration)
            }
            // Recover only this fixture if an interrupted earlier run left it full-screen.
            var fixtureWindow: AXUIElement?
            try await wait("Disposable document did not open") {
                guard let windows = client.value(AXUIElementCreateApplication(running.processIdentifier), kAXWindowsAttribute) as? [AXUIElement] else { return false }
                fixtureWindow = windows.first {
                    return matchesFixture($0, fixture: fixture, client: client, finderFixture: applicationID == "com.apple.finder")
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
                if browserFixture != nil {
                    try await Task.sleep(for: .milliseconds(500))
                    _ = client.setPosition(CGPoint(x: 80, y: 90), on: window)
                    try await Task.sleep(for: .milliseconds(200))
                    let fixtureWidth: CGFloat = min(1760, (NSScreen.main?.visibleFrame.width ?? 1920) - 160)
                    _ = client.setSize(CGSize(width: fixtureWidth, height: 700), on: window)
                    try await wait("Safari fixture did not accept normal starting size") {
                        guard let rect = client.frame(window) else { return false }
                        return abs(rect.width-fixtureWidth) <= 2 && abs(rect.height-700) <= 2
                    }
                }
            }
            var target: WindowTarget?
            try await wait("Disposable document did not become focused") {
                guard let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier == applicationID,
                      let found = client.target(pid: front.processIdentifier),
                      matchesFixture(found.window, fixture: fixture, client: client, finderFixture: applicationID == "com.apple.finder") else { return false }
                target = found; return true
            }
            guard let target else { throw Failure(message: "No verified target") }
            report["document"] = applicationID == "com.apple.finder" ? "explicitly prepared unique Finder fixture title verified" : "disposable fixture verified by AXDocument or AXWebArea URL"
            try await wait("Control panel did not appear") { model.verificationPanelVisible }
            report["panel"] = "visible"
            guard model.invokeVerificationAction(.minimize) else { throw Failure(message: "Minimize button unavailable") }
            report["minimizeDispatchStatus"] = model.status
            report["minimizePlacementIssue"] = client.placementIssue
            try await wait("Minimize action did not change the window") {
                (client.value(target.window, kAXMinimizedAttribute) as? Bool) == true
            }
            try await wait("Minimize transaction did not settle") { model.verificationActionIdle }
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
                client.frame(target.window).map { WindowGeometry.isFitted($0, inside: fitted) } ?? false
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
            try await wait("Close transaction did not settle") { model.verificationActionIdle }
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
        report["layout"] = await model.verificationLayout()
        report["lastPlacementIssue"] = client.placementIssue
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appendingPathComponent("result.json"), options: .atomic)
        } catch { NSLog("Rightnest verification report could not be written: %@", String(describing: error)) }
    }
}
#endif
