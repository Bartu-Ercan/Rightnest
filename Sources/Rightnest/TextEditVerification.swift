#if DEBUG
import AppKit
import ApplicationServices
import RightnestCore
import Darwin

/// Explicit developer-only verification of a disposable file, never a user's document.
@MainActor
enum TextEditVerification {
    struct Failure: Error { let message: String }
    static func wait(_ message: String, seconds: Double = 8, pollMilliseconds: Int = 100, until predicate: () -> Bool) async throws {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(pollMilliseconds))
        }
        throw Failure(message: message)
    }
    static func matchesFixture(_ window: AXUIElement, fixture: URL, client: AccessibilityClient, finderFixture: Bool = false, nativeDocument: Bool = false) -> Bool {
        func matches(_ raw: CFTypeRef?) -> Bool {
            if let url = raw as? URL { return url.isFileURL && fixture.isFileURL ? url.standardizedFileURL.path == fixture.standardizedFileURL.path : url == fixture }
            if let string = raw as? String, let url = URL(string: string) { return url.isFileURL && fixture.isFileURL ? url.standardizedFileURL.path == fixture.standardizedFileURL.path : url == fixture }
            return false
        }
        if finderFixture, fixture.lastPathComponent.hasPrefix("Rightnest-Finder-Verification-"),
           (client.value(window, kAXTitleAttribute) as? String) == fixture.lastPathComponent { return true }
        if nativeDocument && matches(client.value(window, kAXDocumentAttribute)) { return true }
        var budget = 100
        var matching = 0, other = 0
        func visit(_ node: AXUIElement, depth: Int) {
            budget -= 1
            guard budget > 0, depth < 16 else { other += 1; return }
            if (client.value(node, kAXRoleAttribute) as? String) == "AXWebArea" {
                if matches(client.value(node, "AXURL")) { matching += 1 } else { other += 1 }
                return
            }
            if let children = client.value(node, kAXChildrenAttribute) as? [AXUIElement] {
                if client.value(node, kAXRoleAttribute) as? String == kAXTabGroupRole && children.count > 1 { other += 1 }
                for child in children { visit(child, depth: depth + 1) }
            }
        }
        visit(window, depth: 0)
        return matching == 1 && other == 0
    }
    private static func cpuSeconds() -> Double {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return .nan }
        return Double(usage.ru_utime.tv_sec+usage.ru_stime.tv_sec) + Double(usage.ru_utime.tv_usec+usage.ru_stime.tv_usec)/1_000_000
    }
    private static func percentile95(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        return sorted[max(0, Int(ceil(Double(sorted.count)*0.95))-1)]
    }
    private static func saveProgress(_ report: [String: String], directory: URL) {
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: directory.appendingPathComponent("progress.json"), options: .atomic)
        }
    }
    private static func observe(model: AppModel, target: WindowTarget, fixture: URL, applicationID: String,
                                directory: URL, seconds: Int, report: inout [String: String], client: AccessibilityClient) async throws {
        let started = ProcessInfo.processInfo.systemUptime
        var samples = 0
        func verifyOwner() throws {
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == target.pid,
                  let focused = client.focusedWindow(pid: target.pid), CFEqual(focused, target.window) else {
                throw Failure(message: "Focus changed during stability observation")
            }
        }
        func verifyWritableFixture() throws {
            try verifyOwner()
            guard matchesFixture(target.window, fixture: fixture, client: client,
                nativeDocument: ["com.apple.TextEdit", "com.apple.Preview"].contains(applicationID)) else {
                throw Failure(message: "Disposable fixture identity changed")
            }
        }
        if seconds > 30 {
            report["phase"] = "geometry benchmark"; saveProgress(report, directory: directory)
            guard let original = client.frame(target.window), let home = model.verificationPanelFrame else { throw Failure(message: "Fixture geometry missing") }
            var appearance: [Double] = []
            for i in 0..<50 {
                try verifyWritableFixture()
                let x = original.minX + (i.isMultiple(of: 2) ? 20 : 0)
                let begin = ProcessInfo.processInfo.systemUptime
                guard client.setPosition(CGPoint(x: x, y: original.minY), on: target.window) else { throw Failure(message: "Fixture move rejected") }
                try await wait("Panel did not follow settled fixture", pollMilliseconds: 10) {
                    guard let panel = model.verificationPanelFrame, let frame = client.frame(target.window) else { return false }
                    return abs(frame.minX-x) <= 2 && abs(panel.minX-(home.minX+x-original.minX)) <= 2
                }
                appearance.append((ProcessInfo.processInfo.systemUptime-begin)*1000)
            }
            report["appearanceP95Milliseconds"] = String(percentile95(appearance))
            report["appearanceSamples"] = "50"
            if percentile95(appearance) > 300 { report["appearanceGate"] = "failed" }
            else { report["appearanceGate"] = "passed" }
            guard let home = model.verificationPanelFrame, let primary = NSScreen.screens.first else { throw Failure(message: "Home placement missing") }
            let hudAX = home.insetBy(dx: -8, dy: -5)
            let hud = NSPanel(contentRect: WindowGeometry.flip(hudAX, primaryTop: primary.frame.maxY),
                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            hud.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue+1)
            hud.hidesOnDeactivate = false; hud.isReleasedWhenClosed = false; hud.isOpaque = true; hud.backgroundColor = .controlAccentColor
            hud.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
            hud.contentView = NSTextField(labelWithString: "Rightnest collision fixture")
            defer { hud.orderOut(nil); hud.close() }
            var returns: [Double] = []
            report["phase"] = "synthetic HUD benchmark"; saveProgress(report, directory: directory)
            for _ in 0..<20 {
                try verifyOwner()
                hud.orderFrontRegardless()
                try await wait("Controls overlapped synthetic HUD", pollMilliseconds: 10) {
                    model.verificationPanelFrame.map { !$0.intersects(hudAX) } ?? false
                }
                let cleared = ProcessInfo.processInfo.systemUptime
                hud.orderOut(nil)
                try await wait("Controls did not return to original corner", pollMilliseconds: 10) { model.verificationPanelFrame == home }
                returns.append((ProcessInfo.processInfo.systemUptime-cleared)*1000)
            }
            report["syntheticHUDCycles"] = "20"
            report["HUDReturnP95Milliseconds"] = String(percentile95(returns))
            report["HUDReturnMaximumMilliseconds"] = String(returns.max() ?? 0)
            report["HUDReturnGate"] = (returns.max() ?? .infinity) <= 500 ? "passed" : "failed"
            report["systemHUDCycles"] = "not yet verified; synthetic panels are not OS volume indicators"
        }
        var previous = ProcessInfo.processInfo.systemUptime
        var cpuStart = cpuSeconds()
        var stressCPU: Double?
        var idleCPU: [Double] = []
        while ProcessInfo.processInfo.systemUptime-started < Double(seconds) {
            try await Task.sleep(for: .milliseconds(100))
            try verifyOwner()
            guard model.verificationPanelVisible else { throw Failure(message: "Panel disappeared during stable-window observation") }
            samples += 1
            let now = ProcessInfo.processInfo.systemUptime
            let elapsed = now-started
            if seconds > 30 {
                if elapsed < 30 { previous = now; cpuStart = cpuSeconds() }
                else if stressCPU == nil && now-previous >= 60 {
                    stressCPU = 100*(cpuSeconds()-cpuStart)/(now-previous)
                    report["stressCPUPercent"] = String(stressCPU ?? .nan)
                    report["stressCPUGate"] = (stressCPU ?? .infinity) <= 5 ? "passed" : "failed"
                    previous = now; cpuStart = cpuSeconds()
                } else if elapsed < 200 && stressCPU != nil { previous = now; cpuStart = cpuSeconds() }
                else if elapsed >= 200 && idleCPU.count < 5 && now-previous >= 60 {
                    idleCPU.append(100*(cpuSeconds()-cpuStart)/(now-previous))
                    previous = now; cpuStart = cpuSeconds()
                    report["idleCPUWindows"] = String(idleCPU.count)
                    let average = idleCPU.reduce(0,+)/Double(idleCPU.count)
                    report["idleCPUPercent"] = String(average)
                    report["idleCPUGate"] = idleCPU.count == 5 && average < 1 ? "passed" : "pending or failed"
                }
            }
            if samples.isMultiple(of: 50) {
                report["phase"] = elapsed < 100 ? "stress" : elapsed < 500 ? "idle measurement" : "soak"
                report["elapsedSeconds"] = String(Int(elapsed)); report["visibleSamples"] = String(samples)
                saveProgress(report, directory: directory)
            }
        }
        report["stability"] = "passed: \(samples) visible samples; total session \(seconds) seconds including declared geometry/HUD phases"
        report["phase"] = "window actions"; saveProgress(report, directory: directory)
    }

    static func run(model: AppModel, directory: URL, browserFixture: URL? = nil, fixtureApplicationID: String = "com.apple.Safari") async {
        let client = AccessibilityClient()
        var report: [String: String] = [:]
        let previousEnabled = model.enabled, previousExperiment = model.textEditEnabled
        defer { model.enabled = previousEnabled; model.textEditEnabled = previousExperiment }
        do {
            guard AXIsProcessTrusted() else { throw Failure(message: "Accessibility permission missing") }
            report["permission"] = "granted"
            report["os"] = ProcessInfo.processInfo.operatingSystemVersionString
            report["build"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
            report["application"] = fixtureApplicationID
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
                    return matchesFixture($0, fixture: fixture, client: client, finderFixture: applicationID == "com.apple.finder", nativeDocument: ["com.apple.TextEdit", "com.apple.Preview"].contains(applicationID))
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
                      matchesFixture(found.window, fixture: fixture, client: client, finderFixture: applicationID == "com.apple.finder", nativeDocument: ["com.apple.TextEdit", "com.apple.Preview"].contains(applicationID)) else { return false }
                target = found; return true
            }
            guard let target else { throw Failure(message: "No verified target") }
            report["document"] = applicationID == "com.apple.finder" ? "explicitly prepared unique Finder fixture title verified" : "disposable fixture verified by AXDocument or AXWebArea URL"
            try await wait("Control panel did not appear") { model.verificationPanelVisible }
            report["panel"] = "visible"
            if browserFixture != nil {
                let argument = CommandLine.arguments.firstIndex(of: "--stability-seconds")
                var seconds = 30
                if let argument {
                    guard CommandLine.arguments.indices.contains(argument+1),
                          let supplied = Int(CommandLine.arguments[argument+1]), (30...1800).contains(supplied) else {
                        throw Failure(message: "Stability duration must be between 30 and 1800 seconds")
                    }
                    seconds = supplied
                }
                try await observe(model: model, target: target, fixture: fixture, applicationID: applicationID,
                    directory: directory, seconds: seconds, report: &report, client: client)
            }
            guard matchesFixture(target.window, fixture: fixture, client: client, finderFixture: applicationID == "com.apple.finder", nativeDocument: ["com.apple.TextEdit", "com.apple.Preview"].contains(applicationID)) else { throw Failure(message: "Fixture changed before actions") }
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
        report["events"] = model.verificationEvents.joined(separator: "\n")
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
