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
}

/// AX objects never leave this actor. UI work remains on MainActor; queries are
/// serial, bounded and returned as value snapshots, never as live AX references.
actor WindowEngine {
    private let client = AccessibilityClient()
    private var target: WindowTarget?
    private var token: UInt64 = 0
    #if DEBUG
    private var trace: [String] = []
    func verificationTrace() -> [String] { trace }
    #endif
    private struct Saved {
        let pid: pid_t
        let window: AXUIElement
        let record: RestoreRecord
    }
    private var saved: [Saved] = []

    func inspect(pid: pid_t, overlayNumber: Int?, requireFocus: Bool = true) -> Inspection {
        guard AXIsProcessTrusted(), (!requireFocus || client.focusedPID() == pid) else { return Inspection(snapshot: nil, reason: "Window control permission or focus changed") }
        guard let next = client.target(pid: pid) else { return Inspection(snapshot: nil, reason: "Unsupported window state") }
        if let old = target {
            if old.pid != pid || !CFEqual(old.window, next.window) { token &+= 1 }
        } else { token &+= 1 }
        target = next
        saved.removeAll { $0.pid == pid && CFEqual($0.window, next.window) && !WindowGeometry.close($0.record.fitted, next.frame) }
        guard let rect = client.placement(next, overlayNumber: overlayNumber) else { return Inspection(snapshot: nil, reason: client.placementIssue) }
        var actions: Set<WindowAction> = []
        if next.close != nil { actions.insert(.close) }
        if next.minimize != nil { actions.insert(.minimize) }
        if next.resizable { actions.insert(.fit) }
        guard !actions.isEmpty else { return Inspection(snapshot: nil, reason: "No supported window actions") }
        return Inspection(snapshot: WindowSnapshot(token: token, pid: pid, frame: next.frame, placement: rect, actions: actions,
            restoring: saved.contains { $0.pid == pid && CFEqual($0.window, next.window) }), reason: "Controls active")
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
            if client.placement(current) == snapshot.placement { clear = true; break }
            guard client.ownPanelOcclusion else { return client.placementIssue }
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
        }
        guard clear, !Task.isCancelled else { return "Window action cancelled: surface did not clear" }
        guard action == .fit else { return client.act(action, on: current) ? "Window action sent" : "Window action unavailable" }
        guard current.resizable, let screen = WindowGeometry.screen(for: current.frame, visibleFrames: screens) else { return "Window cannot be resized" }
        let index = saved.firstIndex { $0.pid == current.pid && CFEqual($0.window, current.window) }
        let destination: CGRect
        if let index { destination = saved[index].record.destination(current: current.frame, screens: screens) ?? screen }
        else { destination = screen }
        if let index { saved.remove(at: index) }
        // Separate shrink, move and grow. Some applications clamp a size request
        // to the old origin until they have processed the position change.
        let smaller = CGSize(width: min(current.frame.width, destination.width), height: min(current.frame.height, destination.height))
        if smaller != current.frame.size { _ = client.setSize(smaller, on: current.window) }
        guard client.setPosition(destination.origin, on: current.window) else { return "Window resize was not accepted" }
        for _ in 0..<20 {
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
            guard !Task.isCancelled, token == snapshot.token, AXIsProcessTrusted(), client.focusedPID() == current.pid,
                  let focused = client.focusedWindow(pid: current.pid), CFEqual(focused, current.window) else { return "Window action cancelled: target changed" }
            #if DEBUG
            trace.append("move: " + (client.frame(focused).map { NSStringFromRect($0) } ?? "missing"))
            #endif
            if let actual = client.frame(focused), abs(actual.minX-destination.minX) <= 2, abs(actual.minY-destination.minY) <= 2 { break }
        }
        guard !Task.isCancelled, token == snapshot.token, AXIsProcessTrusted(), client.focusedPID() == current.pid,
              let focused = client.focusedWindow(pid: current.pid), CFEqual(focused, current.window),
              client.setSize(destination.size, on: focused) else { return "Window resize was not accepted" }
        for _ in 0..<20 {
            do { try await Task.sleep(for: .milliseconds(50)) } catch { return "Window action cancelled" }
            guard !Task.isCancelled, token == snapshot.token, AXIsProcessTrusted(), client.focusedPID() == current.pid,
                  let focused = client.focusedWindow(pid: current.pid), CFEqual(focused, current.window) else { return "Window action cancelled: target changed" }
            #if DEBUG
            trace.append("size: " + (client.frame(focused).map { NSStringFromRect($0) } ?? "missing"))
            #endif
            if let actual = client.frame(focused), WindowGeometry.close(actual, destination) {
                if index == nil {
                    if saved.count >= 32 { saved.removeFirst() }
                    saved.append(Saved(pid: current.pid, window: current.window, record: RestoreRecord(original: current.frame, fitted: actual)))
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
    func invalidate() { token &+= 1; target = nil }
}
