import AppKit
import SwiftUI
import ApplicationServices
import RightnestCore
import ServiceManagement

@MainActor
final class AppModel: NSObject, ObservableObject, NSWindowDelegate {
    @Published var enabled = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(enabled, forKey: "enabled"); invalidate() }
    }
    @Published var textEditEnabled = UserDefaults.standard.bool(forKey: "textEditEnabled") {
        didSet { UserDefaults.standard.set(textEditEnabled, forKey: "textEditEnabled"); invalidate() }
    }
    @Published private(set) var trusted = AXIsProcessTrusted()
    @Published private(set) var status = "Test window ready"
    @Published private(set) var permissionRequested = UserDefaults.standard.bool(forKey: "permissionRequested")
    @Published private(set) var previouslyGranted = UserDefaults.standard.bool(forKey: "previouslyGranted")
    @Published var settingsOpenFailed = false
    var permissionFlow: PermissionFlow {
        PermissionFlow(trusted: trusted, requested: permissionRequested, previouslyGranted: previouslyGranted)
    }
    var permissionPaneName: String {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 ? "Device Control and Data Access" : "Accessibility"
    }
    private var activationObserver: NSObjectProtocol?
    private var lastPermissionCheck = Date.distantPast
    private let panel = ControlPanel()
    private let engine = WindowEngine()
    private let observer = WindowObserver()
    private var inspectionTask: Task<Void, Never>?
    private var generation: UInt64 = 0
    private var lastInspection = Date.distantPast
    private var extraObservers: [NSObjectProtocol] = []
    private var welcome: NSWindow?
    private var demoOriginal: CGRect?
    private var demoFitted: CGRect?
    @Published var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var loginMessage = ""
    @Published var disabledApplications = Set(UserDefaults.standard.stringArray(forKey: "disabledApplications") ?? []) {
        didSet { UserDefaults.standard.set(Array(disabledApplications), forKey: "disabledApplications"); invalidate() }
    }
    static let candidates = [("com.apple.TextEdit", "TextEdit"), ("com.apple.Preview", "Preview"),
        ("com.apple.finder", "Finder"), ("com.apple.Safari", "Safari"), ("com.google.Chrome", "Chrome")]
    // Recorded test coverage, not an eligibility allowlist.
    var availableApplications: [(String, String)] {
        var names = Dictionary(uniqueKeysWithValues: Self.candidates)
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            if let id = app.bundleIdentifier, id != Bundle.main.bundleIdentifier {
                names[id] = app.localizedName ?? id
            }
        }
        for id in disabledApplications where names[id] == nil { names[id] = id }
        return names.map { ($0.key, $0.value) }.sorted { $0.1.localizedStandardCompare($1.1) == .orderedAscending }
    }
    func setApplication(_ id: String, enabled: Bool) {
        if enabled { disabledApplications.remove(id) } else { disabledApplications.insert(id) }
    }
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginMessage = SMAppService.mainApp.status == .requiresApproval ? L("Allow Rightnest in Login Items in System Settings.") : ""
        } catch { loginMessage = L("Could not change Login Items. Check System Settings.") }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    func finishSetup() {
        onboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        welcome?.close()
    }
    func showSettings() {
        if let welcome { welcome.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 660),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = L("Rightnest Settings"); window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: WelcomeView(model: self))
        window.center(); welcome = window
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func openReleases() {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "RightnestReleasesURL") as? String,
              let url = URL(string: raw), url.scheme == "https", url.host == "github.com" else {
            status = L("No public release is available yet"); return
        }
        NSWorkspace.shared.open(url)
    }
    private var timer: Timer?
    private(set) var lastActionResult = "none"
    private var actionTask: Task<Void, Never>?
    private var demo: NSWindow?
    private var demoAccessory: NSTitlebarAccessoryViewController?
    private var workspaceObserver: NSObjectProtocol?

    private var isVerificationRun: Bool {
        #if DEBUG
        CommandLine.arguments.contains("--verify-app") || CommandLine.arguments.contains("--audit-compatibility") || CommandLine.arguments.contains("--verify-textedit") || (CommandLine.arguments.contains("--verify-safari") || CommandLine.arguments.contains("--verify-finder"))
        #else
        false
        #endif
    }
    func start() {
        guard timer == nil else { return }
        observer.changed = { [weak self] requiresHide in
            if requiresHide { self?.invalidate() } else { self?.refresh(settling: true) }
        }
        let workspace = NSWorkspace.shared.notificationCenter
        workspaceObserver = workspace.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.invalidate() }
        }
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didWakeNotification, NSWorkspace.willSleepNotification] {
            extraObservers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.invalidate() }
            })
        }
        extraObservers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.invalidate() }
        })
        activationObserver = NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.checkPermission(); self?.launchAtLogin = SMAppService.mainApp.status == .enabled; self?.invalidate() }
        }
        checkPermission()
        if !onboardingComplete && !isVerificationRun { showSettings() }
        #if DEBUG
        if let index = CommandLine.arguments.firstIndex(of: "--audit-compatibility"), CommandLine.arguments.indices.contains(index + 1) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            Task { await CompatibilityAudit.run(directory: directory, model: self) }
        }
        if let index = CommandLine.arguments.firstIndex(of: "--verify-app"), CommandLine.arguments.indices.contains(index + 3) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            let appID = CommandLine.arguments[index + 2]
            let fixture = URL(fileURLWithPath: CommandLine.arguments[index + 3])
            Task { await TextEditVerification.run(model: self, directory: directory, browserFixture: fixture, fixtureApplicationID: appID) }
        }
        if let index = CommandLine.arguments.firstIndex(of: "--verify-finder"), CommandLine.arguments.indices.contains(index + 2) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            let fixture = URL(fileURLWithPath: CommandLine.arguments[index + 2], isDirectory: true)
            Task { await TextEditVerification.run(model: self, directory: directory, browserFixture: fixture, fixtureApplicationID: "com.apple.finder") }
        }
        if let index = CommandLine.arguments.firstIndex(of: "--verify-safari"), CommandLine.arguments.indices.contains(index + 2) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            let fixture = URL(fileURLWithPath: CommandLine.arguments[index + 2])
            Task { await TextEditVerification.run(model: self, directory: directory, browserFixture: fixture) }
        }
        if let index = CommandLine.arguments.firstIndex(of: "--verify-textedit"), CommandLine.arguments.indices.contains(index + 1) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            Task { await TextEditVerification.run(model: self, directory: directory) }
        }
        #endif
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
    private func invalidate() {
        generation &+= 1
        panel.orderOut(nil)
        inspectionTask?.cancel(); inspectionTask = nil
        actionTask?.cancel(); actionTask = nil
        refresh(settling: true)
    }
    func checkPermission() {
        lastPermissionCheck = Date()
        let result = AXIsProcessTrusted()
        if trusted != result { trusted = result }
        if result && !previouslyGranted {
            previouslyGranted = true
            UserDefaults.standard.set(true, forKey: "previouslyGranted")
        }
        if !result { panel.orderOut(nil) }
    }
    #if DEBUG
    func verificationLayout() async -> String { await engine.auditLayout() }
    func verificationTrace() async -> [String] { await engine.verificationTrace() }
    var verificationActionIdle: Bool { actionTask == nil }
    var verificationPanelVisible: Bool { panel.isVisible }
    func invokeVerificationAction(_ action: WindowAction) -> Bool { panel.invokeForVerification(action) }
    #endif
    func requestPermission() {
        checkPermission()
        guard !trusted else { return }
        permissionRequested = true
        UserDefaults.standard.set(true, forKey: "permissionRequested")
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openPrivacySettings()
        refresh()
    }
    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        settingsOpenFailed = !NSWorkspace.shared.open(url)
    }
    func revealApplication() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
    func openTextEdit() {
        guard trusted else { return }
        textEditEnabled = true
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") else { return }
        NSWorkspace.shared.open(url)
    }
    func openDemo() {
        if let demo, demo.isMiniaturized { demo.deminiaturize(nil) }
        if let demo, demo.isVisible { demo.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 660, height: 420),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Rightnest Test Window"; window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false; window.delegate = self
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentView = NSHostingView(rootView: DemoView())
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .right
        accessory.view = ControlStrip { [weak self, weak window] action in
            guard let self, self.enabled, let window else { return }
            switch action {
            case .close: window.performClose(nil)
            case .minimize: window.miniaturize(nil)
            case .fit:
                guard let screen = window.screen else { return }
                if let fitted = self.demoFitted, let original = self.demoOriginal, WindowGeometry.close(window.frame, fitted) {
                    window.setFrame(WindowGeometry.clamped(original, to: screen.visibleFrame), display: true)
                    self.demoOriginal = nil; self.demoFitted = nil
                } else {
                    self.demoOriginal = window.frame; self.demoFitted = screen.visibleFrame
                    window.setFrame(screen.visibleFrame, display: true)
                }
            }
        }
        window.addTitlebarAccessoryViewController(accessory)
        demoAccessory = accessory
        window.center(); demo = window
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        refresh()
    }
    func windowWillClose(_ notification: Notification) { panel.orderOut(nil) }
    func windowWillMiniaturize(_ notification: Notification) { panel.orderOut(nil) }
    func windowWillEnterFullScreen(_ notification: Notification) { panel.orderOut(nil) }

    func refresh(settling: Bool = false) {
        demoAccessory?.isHidden = !enabled
        if Date().timeIntervalSince(lastPermissionCheck) >= 1 { checkPermission() }
        guard enabled, trusted, textEditEnabled,
              let front = NSWorkspace.shared.frontmostApplication,
              let bundle = front.bundleIdentifier,
              ApplicationEligibility.allows(bundleID: bundle, isRegular: front.activationPolicy == .regular,
                  ownBundleID: Bundle.main.bundleIdentifier ?? "dev.bartuercan.starboard", disabled: disabledApplications) else {
            panel.orderOut(nil); observer.watch(pid: nil)
            inspectionTask?.cancel(); inspectionTask = nil
            actionTask?.cancel(); actionTask = nil
            generation &+= 1
            status = L(!enabled ? "Paused" : !trusted ? "Window control permission needed" :
                !textEditEnabled ? "External controls are off" : "Controls hidden for this application")
            return
        }
        guard actionTask == nil, inspectionTask == nil else { return }
        // ponytail: one bounded fallback interval; AX notifications bypass it.
        if !settling && !panel.isVisible && Date().timeIntervalSince(lastInspection) < 1 { return }
        lastInspection = Date()
        observer.watch(pid: front.processIdentifier)
        let revision = generation, pid = front.processIdentifier
        let overlayNumber = panel.isVisible ? panel.windowNumber : nil
        guard let primary = NSScreen.screens.first else { return }
        let screens = NSScreen.screens.map { WindowGeometry.flip($0.visibleFrame, primaryTop: primary.frame.maxY) }
        inspectionTask = Task { [weak self] in
            guard let self else { return }
            if settling { try? await Task.sleep(for: .milliseconds(140)) }
            guard !Task.isCancelled else { return }
            let result = await self.engine.inspect(pid: pid, overlayNumber: overlayNumber, screens: screens)
            guard !Task.isCancelled, self.generation == revision else { return }
            self.inspectionTask = nil
            guard self.enabled, self.trusted, NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
                self.panel.orderOut(nil); return
            }
            guard let snapshot = result.snapshot, let primary = NSScreen.screens.first else {
                self.panel.orderOut(nil); self.status = L("Hidden") + ": " + L(result.reason); return
            }
            self.panel.show(at: WindowGeometry.flip(snapshot.placement, primaryTop: primary.frame.maxY),
                enabled: snapshot.actions, restoring: snapshot.restoring) { [weak self] action in self?.queue(action, snapshot: snapshot) }
            self.status = L(snapshot.frame.contains(snapshot.placement) ? "Controls active" : "Controls outside window") + " · " + (front.localizedName ?? bundle)
        }
    }
    private func queue(_ action: WindowAction, snapshot: WindowSnapshot) {
        guard actionTask == nil, enabled, trusted else { return }
        inspectionTask?.cancel(); inspectionTask = nil
        generation &+= 1
        let revision = generation
        panel.orderOut(nil)
        status = L("Checking target window…"); lastActionResult = "pending"
        guard let primary = NSScreen.screens.first else { return }
        let screens = NSScreen.screens.map { WindowGeometry.flip($0.visibleFrame, primaryTop: primary.frame.maxY) }
        // Ignore geometry callbacks generated by our own transaction; the worker
        // validates focus and window identity independently at dispatch time.
        observer.stop()
        actionTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            let result = await self.engine.perform(action, snapshot: snapshot, screens: screens)
            guard !Task.isCancelled, self.generation == revision else { return }
            self.lastActionResult = result
            self.status = L(result)
            self.actionTask = nil
            self.refresh(settling: true)
        }
    }
}
