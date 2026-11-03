import AppKit
import ApplicationServices
import RightnestCore

struct WindowSnapshot: Sendable {
    let token: UInt64
    let pid: pid_t
    let frame: CGRect
    let placement: CGRect
    let actions: Set<WindowAction>
    let restoring: Bool
}
struct Inspection: Sendable {
    let snapshot: WindowSnapshot?
    let reason: String
    var retryAfter: TimeInterval = 1
}
struct ApplicationInspectionContext: Sendable {
    let session: String
    let electron: Bool
    let experimental: Bool
    var allowActivation = true
}

/// AX objects never leave this actor. UI work remains on MainActor; queries are
/// serial, bounded and returned as value snapshots, never as live AX references.
actor WindowEngine {
    private let client = AccessibilityClient()
    private var target: WindowTarget?
    private var token: UInt64 = 0
    private var capabilityCheckedAt = -Double.infinity
    private var reflow = ReflowState()
    private var electronPreparation = ElectronPreparation()
    #if DEBUG
    private var trace: [String] = []
    func verificationTrace() -> [String] { trace }
    func auditLayout() -> String { client.layoutDiagnostic + "\n" + client.focusDiagnostic }
    #endif
    private struct Saved {
        let pid: pid_t
        let window: AXUIElement
        let record: RestoreRecord
    }
    private var saved: [Saved] = []

    func inspect(pid: pid_t, overlayNumber: Int?, requireFocus: Bool = true, screens: [CGRect] = [], forceLayout: Bool = false,
                 resetPlacement: Bool = false, context: ApplicationInspectionContext? = nil,
                 pointerQuery: (@MainActor @Sendable () -> Bool)? = nil) async -> Inspection {
        guard !Task.isCancelled, AXIsProcessTrusted() else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
        if requireFocus {
            var confirmed = false
            for attempt in 0..<4 {
                guard !Task.isCancelled else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
                if let focused = client.focusedPID() {
                    guard focused == pid else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
                    confirmed = true; break
                }
                if attempt < 3 { try? await Task.sleep(for: .milliseconds(50)) }
            }
            guard confirmed, !Task.isCancelled else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
        }
        let reuseCapabilities = !forceLayout && !resetPlacement && ProcessInfo.processInfo.systemUptime-capabilityCheckedAt < 1
        guard let next = client.target(pid: pid, cached: reuseCapabilities ? target : nil) else {
            _ = reflow.update(PlacementDecision(ideal: nil, available: nil, currentIsClear: false),
                now: ProcessInfo.processInfo.systemUptime, pointerInside: false)
            return Inspection(snapshot: nil, reason: "Unsupported window state",
                retryAfter: reflow.retryDelay(now: ProcessInfo.processInfo.systemUptime, experimental: context?.experimental ?? true))
        }
        guard !Task.isCancelled else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
        let geometryChanged = target?.frame != next.frame
        if !reuseCapabilities || geometryChanged { capabilityCheckedAt = ProcessInfo.processInfo.systemUptime }
        if resetPlacement { reflow.reset(); client.invalidateLayout() }
        if let old = target {
            if old.pid != pid || !CFEqual(old.window, next.window) || old.frame != next.frame {
                token &+= 1; reflow.reset(); client.invalidateLayout()
            }
        } else { token &+= 1 }
        target = next
        saved.removeAll { $0.pid == pid && CFEqual($0.window, next.window) && !WindowGeometry.close($0.record.fitted, next.frame) }
        let revision = token
        var decision = client.placementDecision(next, overlayNumber: overlayNumber, screens: screens,
            current: reflow.current, forceLayout: forceLayout, electron: context?.electron ?? false)
        if let context, context.electron, !Task.isCancelled,
           electronPreparation.shouldActivate(session: context.session, enabled: context.allowActivation, incomplete: client.incompleteTree),
           client.activateElectronAccessibility(pid: pid) {
            for delay in [100, 200] {
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled, token == revision, AXIsProcessTrusted(),
                      let fresh = client.target(pid: pid), CFEqual(fresh.window, next.window), fresh.frame == next.frame,
                      !requireFocus || client.focusedPID() == pid else {
                    return Inspection(snapshot: nil, reason: "Window control permission or focus changed")
                }
                decision = client.placementDecision(fresh, overlayNumber: overlayNumber, screens: screens,
                    current: reflow.current, forceLayout: true, electron: true)
                if !client.incompleteTree { break }
            }
        }
        let pointerInside = await pointerQuery?() ?? false
        guard !Task.isCancelled, token == revision else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
        let now = ProcessInfo.processInfo.systemUptime
        let rect = reflow.update(decision, now: now, pointerInside: pointerInside)
        let retry = reflow.retryDelay(now: now, experimental: context?.experimental ?? true)
        guard let rect else { return Inspection(snapshot: nil, reason: client.placementIssue, retryAfter: retry) }
        var actions: Set<WindowAction> = []
        if next.close != nil { actions.insert(.close) }
        if next.minimize != nil { actions.insert(.minimize) }
        if next.resizable { actions.insert(.fit) }
        guard !actions.isEmpty else { return Inspection(snapshot: nil, reason: "No supported window actions") }
        let snapshot = WindowSnapshot(token: token, pid: pid, frame: next.frame, placement: rect, actions: actions,
            restoring: saved.contains { $0.pid == pid && CFEqual($0.window, next.window) })
        return Inspection(snapshot: snapshot, reason: "Controls active", retryAfter: retry)
    }

    func perform(_ action: WindowAction, snapshot: WindowSnapshot, screens: [CGRect]) async -> String {
        #if DEBUG
        trace = ["action \(action.rawValue)", "snapshot \(NSStringFromRect(snapshot.frame))"]
        #endif
        guard !Task.isCancelled, snapshot.actions.contains(action), token == snapshot.token,
              let old = target, AXIsProcessTrusted(), client.focusedPID() == snapshot.pid,
              let current = client.target(pid: snapshot.pid), CFEqual(old.window, current.window),
              WindowGeometry.close(current.frame, snapshot.frame) else { return "Window action cancelled: target changed" }
        // A hidden panel can remain in WindowServer hit testing for a short time.
        var clear = false
        for _ in 0..<6 {
            guard !Task.isCancelled, token == snapshot.token, AXIsProcessTrusted(), client.focusedPID() == snapshot.pid,
                  let focused = client.focusedWindow(pid: snapshot.pid), CFEqual(focused, current.window),
                  let frame = client.frame(current.window), WindowGeometry.close(frame, snapshot.frame) else { return "Window action cancelled: target changed" }
            if client.placement(current, screens: screens, preferred: snapshot.placement) == snapshot.placement { clear = true; break }
            guard client.ownPanelOcclusion || client.placementIssue == "Inspection timed out" || client.placementIssue == "Inspection limit reached" else { return client.placementIssue }
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
        }
        guard clear, !Task.isCancelled else { return "Window action cancelled: surface did not clear" }
        if action != .fit {
            let acknowledged = client.act(action, on: current)
            // Closing can destroy the AX element before AXPress replies. Confirm
            // the requested state instead of reporting failure from the ACK alone.
            for _ in 0..<10 {
                guard !Task.isCancelled, AXIsProcessTrusted() else { return "Window action cancelled" }
                if action == .close {
                    let app = AXUIElementCreateApplication(current.pid)
                    AXUIElementSetMessagingTimeout(app, 0.08)
                    if let windows = client.value(app, kAXWindowsAttribute) as? [AXUIElement],
                       !windows.contains(where: { CFEqual($0, current.window) }) { return "Window action sent" }
                } else if (client.value(current.window, kAXMinimizedAttribute) as? Bool) == true {
                    return "Window action sent"
                }
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
            }
            return acknowledged ? "Window action awaiting application" : "Window action unavailable"
        }
        guard current.resizable, let screen = WindowGeometry.screen(for: current.frame, visibleFrames: screens) else { return "Window cannot be resized" }
        let index = saved.firstIndex { $0.pid == current.pid && CFEqual($0.window, current.window) }
        let destination: CGRect
        if let index { destination = saved[index].record.destination(current: current.frame, screens: screens) ?? screen }
        else { destination = screen }
        // Separate shrink, move and grow. Some applications clamp a size request
        // to the old origin until they have processed the position change.
        let smaller = CGSize(width: min(current.frame.width, destination.width), height: min(current.frame.height, destination.height))
        if smaller != current.frame.size {
            guard client.setSize(smaller, on: current.window) else { return "Window resize was not accepted" }
            var shrunk = false
            for _ in 0..<20 {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
                guard let focused = await verifiedWindow(window: current.window, pid: current.pid, revision: snapshot.token) else { return "Window action cancelled: target changed" }
                if let rect = client.frame(focused), rect.width <= smaller.width+2, rect.height <= smaller.height+2 { shrunk = true; break }
            }
            guard shrunk else { return "Application limited the window size" }
        }
        guard client.setPosition(destination.origin, on: current.window) else { return "Window resize was not accepted" }
        for _ in 0..<20 {
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
            guard let focused = await verifiedWindow(window: current.window, pid: current.pid, revision: snapshot.token) else { return "Window action cancelled: target changed" }
            #if DEBUG
            trace.append("move: " + (client.frame(focused).map { NSStringFromRect($0) } ?? "missing"))
            #endif
            if let actual = client.frame(focused), abs(actual.minX-destination.minX) <= 2, abs(actual.minY-destination.minY) <= 2 { break }
        }
        guard let focused = await verifiedWindow(window: current.window, pid: current.pid, revision: snapshot.token),
              client.setSize(destination.size, on: focused) else { return "Window resize was not accepted" }
        for attempt in 0..<20 {
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
            guard let focused = await verifiedWindow(window: current.window, pid: current.pid, revision: snapshot.token) else { return "Window action cancelled: target changed" }
            #if DEBUG
            trace.append("size: " + (client.frame(focused).map { NSStringFromRect($0) } ?? "missing"))
            #endif
            if index == nil && (attempt == 3 || attempt == 8), let actual = client.frame(focused),
               !WindowGeometry.isFitted(actual, inside: destination) {
                _ = client.setPosition(destination.origin, on: focused)
                do { try await Task.sleep(for: .milliseconds(80)) } catch { return "Window action cancelled" }
                guard let fresh = await verifiedWindow(window: current.window, pid: current.pid, revision: snapshot.token) else { return "Window action cancelled: target changed" }
                _ = client.setSize(destination.size, on: fresh)
            }
            if attempt == 3, let actual = client.frame(focused),
               abs(actual.width-destination.width) <= 2, abs(actual.height-destination.height) <= 2,
               !WindowGeometry.close(actual, destination) {
                // A native tiling transition can re-clamp origin while applying
                // final size. Correct origin once, only after size is confirmed.
                _ = client.setPosition(destination.origin, on: focused)
            }
            if let actual = client.frame(focused), (index == nil ? WindowGeometry.isFitted(actual, inside: destination) : WindowGeometry.close(actual, destination)) {
                guard let settled = await settledFrame(window: current.window, pid: current.pid, revision: snapshot.token) else { return "Window action cancelled: target changed" }
                guard index == nil ? WindowGeometry.isFitted(settled, inside: destination) : WindowGeometry.close(settled, destination) else { return "Application limited the window size" }
                if let index { saved.remove(at: index) }
                if index == nil {
                    if saved.count >= 32 { saved.removeFirst() }
                    saved.append(Saved(pid: current.pid, window: current.window, record: RestoreRecord(original: current.frame, fitted: settled)))
                }
                return "Window action sent"
            }
        }
        if index == nil, let actual = client.frame(current.window), WindowGeometry.valid(actual) {
            if saved.count >= 32 { saved.removeFirst() }
            saved.append(Saved(pid: current.pid, window: current.window, record: RestoreRecord(original: current.frame, fitted: actual)))
        }
        return "Application limited the window size"
    }
    private func verifiedWindow(window: AXUIElement, pid: pid_t, revision: UInt64) async -> AXUIElement? {
        // A missing reply is not a different target. Retry missing AX data briefly;
        // a real focus/identity change still cancels before the next write.
        for attempt in 0..<10 {
            guard !Task.isCancelled, token == revision, AXIsProcessTrusted() else {
                #if DEBUG
                trace.append("target invalidated: cancelled=\(Task.isCancelled) revision=\(token == revision)")
                #endif
                return nil
            }
            if let focusedPID = client.focusedPID() {
                guard focusedPID == pid else {
                    #if DEBUG
                    trace.append("focus changed to pid \(focusedPID)")
                    #endif
                    return nil
                }
                if let focused = client.focusedWindow(pid: pid) {
                    guard CFEqual(focused, window) else {
                        #if DEBUG
                        trace.append("focused window identity changed")
                        #endif
                        return nil
                    }
                    return focused
                }
            }
            if attempt < 9 { do { try await Task.sleep(for: .milliseconds(50)) } catch { return nil } }
        }
        #if DEBUG
        trace.append("target AX data unavailable after bounded retries")
        #endif
        return nil
    }

    private func settledFrame(window: AXUIElement, pid: pid_t, revision: UInt64) async -> CGRect? {
        var previous: CGRect?
        var stableSamples = 0
        for _ in 0..<12 {
            do { try await Task.sleep(for: .milliseconds(80)) } catch { return nil }
            guard let focused = await verifiedWindow(window: window, pid: pid, revision: revision), let rect = client.frame(focused) else { return nil }
            if let previous, WindowGeometry.close(rect, previous, tolerance: 0.5) { stableSamples += 1 } else { stableSamples = 0 }
            previous = rect
            if stableSamples >= 3 { return rect }
        }
        return nil
    }
    func invalidate() { token &+= 1; target = nil; reflow.reset(); client.invalidateLayout() }
}
