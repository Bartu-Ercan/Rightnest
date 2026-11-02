import AppKit
import ApplicationServices

/// Subscriptions live on the main run loop. Callback only invalidates UI state;
/// all window inspection is performed by WindowEngine.
@MainActor
final class WindowObserver {
    private var observer: AXObserver?
    private var pid: pid_t?
    private var window: AXUIElement?
    var changed: ((Bool) -> Void)?
    private(set) var lastNotification = ""
    private let appNotifications = [kAXFocusedWindowChangedNotification, kAXWindowCreatedNotification,
                                    kAXFocusedUIElementChangedNotification]
    private let windowNotifications = [kAXMovedNotification, kAXResizedNotification,
        kAXUIElementDestroyedNotification, kAXWindowMiniaturizedNotification, kAXWindowDeminiaturizedNotification,
        kAXTitleChangedNotification]

    func watch(pid: pid_t?) {
        guard self.pid != pid else { updateWindow(); return }
        stop()
        guard let pid else { return }
        self.pid = pid
        var result: AXObserver?
        let callback: AXObserverCallback = { source, _, notification, context in
            guard let context else { return }
            // Source is installed exclusively on the main run loop.
            MainActor.assumeIsolated {
                let owner = Unmanaged<WindowObserver>.fromOpaque(context).takeUnretainedValue()
                guard let current = owner.observer, CFEqual(current, source) else { return }
                owner.lastNotification = notification as String
                let contentOnly = notification as String == kAXFocusedUIElementChangedNotification || notification as String == kAXTitleChangedNotification
                owner.changed?(!contentOnly)
            }
        }
        guard AXObserverCreate(pid, callback, &result) == .success, let result else { return }
        observer = result
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.02)
        let context = Unmanaged.passUnretained(self).toOpaque()
        for name in appNotifications { AXObserverAddNotification(result, app, name as CFString, context) }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(result), .commonModes)
        updateWindow()
    }
    private func updateWindow() {
        guard let pid, let observer else { return }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.02)
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &raw) == .success,
              let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() else { return }
        let next = unsafeDowncast(raw, to: AXUIElement.self)
        if let window, CFEqual(window, next) { return }
        if let window { for name in windowNotifications { AXObserverRemoveNotification(observer, window, name as CFString) } }
        window = next
        let context = Unmanaged.passUnretained(self).toOpaque()
        for name in windowNotifications { AXObserverAddNotification(observer, next, name as CFString, context) }
    }
    func stop() {
        if let observer { CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes) }
        observer = nil; window = nil; pid = nil
    }
}
