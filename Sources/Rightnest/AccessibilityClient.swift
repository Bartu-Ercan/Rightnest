import AppKit
import ApplicationServices
import RightnestCore

struct WindowTarget {
    let pid: pid_t
    let window: AXUIElement
    let frame: CGRect
    let close: AXUIElement?
    let minimize: AXUIElement?
    let resizable: Bool
}

final class AccessibilityClient {
    private(set) var ownPanelOcclusion = false
    private(set) var placementIssue = "Unverified title bar"
    func value(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }
    func element(_ parent: AXUIElement, _ name: String) -> AXUIElement? {
        guard let raw = value(parent, name), CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        return unsafeDowncast(raw, to: AXUIElement.self)
    }
    func frame(_ element: AXUIElement) -> CGRect? {
        guard let position = value(element, kAXPositionAttribute), let size = value(element, kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero; var dimensions = CGSize.zero
        guard AXValueGetValue(unsafeDowncast(position, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeDowncast(size, to: AXValue.self), .cgSize, &dimensions) else { return nil }
        return CGRect(origin: point, size: dimensions)
    }
    func writable(_ element: AXUIElement, _ name: String) -> Bool {
        var yes = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, name as CFString, &yes) == .success && yes.boolValue
    }
    func pressable(_ button: AXUIElement?) -> AXUIElement? {
        guard let button, (value(button, kAXEnabledAttribute) as? Bool) == true else { return nil }
        var actions: CFArray?
        guard AXUIElementCopyActionNames(button, &actions) == .success,
              (actions as? [String])?.contains(kAXPressAction) == true else { return nil }
        return button
    }
    func focusedWindow(pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.08)
        return element(app, kAXFocusedWindowAttribute)
    }
    func target(pid: pid_t) -> WindowTarget? {
        guard let window = focusedWindow(pid: pid),
              (value(window, kAXSubroleAttribute) as? String) == kAXStandardWindowSubrole,
              (value(window, kAXMinimizedAttribute) as? Bool) == false,
              (value(window, "AXFullScreen") as? Bool) == false,
              let frame = frame(window) else { return nil }
        guard let children = value(window, kAXChildrenAttribute) as? [AXUIElement],
              !children.contains(where: { (value($0, kAXRoleAttribute) as? String) == kAXSheetRole }) else { return nil }
        return WindowTarget(pid: pid, window: window, frame: frame,
            close: pressable(element(window, kAXCloseButtonAttribute)),
            minimize: pressable(element(window, kAXMinimizeButtonAttribute)),
            resizable: writable(window, kAXPositionAttribute) && writable(window, kAXSizeAttribute))
    }

    // Strict initial support: TextEdit standard windows only. Never treat a missing subtree as blank.
    func placement(_ target: WindowTarget, overlayNumber: Int? = nil) -> CGRect? {
        ownPanelOcclusion = false
        placementIssue = "Missing close-button geometry"
        guard let close = target.close, let closeFrame = frame(close) else { return nil }
        placementIssue = "Not enough room in title bar"
        guard let candidate = Placement.candidate(window: target.frame, rowY: closeFrame.midY - 13,
                                                   obstacles: [], boundsKnown: true) else { return nil }
        let deadline = ProcessInfo.processInfo.systemUptime + 0.12
        var budget = 100
        func clear(_ node: AXUIElement, depth: Int) -> Bool {
            budget -= 1
            guard budget > 0, depth < 7, ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection limit reached"; return false }
            guard let role = value(node, kAXRoleAttribute) as? String else {
                placementIssue = "Unknown accessibility role"; return false
            }
            // Hidden elements do not occupy visible titlebar space. Disabled elements still can.
            if (value(node, "AXHidden") as? Bool) == true { return true }
            guard let rect = frame(node) else { placementIssue = "Missing geometry for \(role)"; return false }
            // Content below the titlebar is not a toolbar obstacle. Apply the safety gap to
            // controls only; expanding a document's large scroll area creates false collisions.
            let containers = [kAXWindowRole, kAXToolbarRole, kAXGroupRole, kAXScrollAreaRole]
            guard Placement.overlapsTitlebar(rect, candidate: candidate, isLayoutContainer: containers.contains(role)) else { return true }
            guard [kAXWindowRole, kAXToolbarRole, kAXGroupRole].contains(role) else {
                placementIssue = "Title bar intersects \(role)"; return false
            }
            guard let children = value(node, kAXChildrenAttribute) as? [AXUIElement] else {
                placementIssue = "Incomplete title bar hierarchy"; return false
            }
            if children.isEmpty {
                let knownBackground = role == kAXWindowRole || role == kAXToolbarRole
                if !knownBackground { placementIssue = "Unknown empty title bar group" }
                return knownBackground
            }
            return children.allSatisfy { clear($0, depth: depth + 1) }
        }
        guard clear(target.window, depth: 0) else { return nil }
        // Hit-test visible geometry too. A different window, button, or unknown node rejects placement.
        placementIssue = "Another surface covers the title bar"
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.04)
        var overlaySurfaceClear: Bool?
        for x in stride(from: candidate.minX, through: candidate.maxX, by: 8) {
            for y in [candidate.minY, candidate.midY, candidate.maxY] {
                guard ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection timed out"; return nil }
                var hit: AXUIElement?
                let hitStatus = AXUIElementCopyElementAtPosition(system, Float(x), Float(y), &hit)
                guard hitStatus == .success, let hit else {
                    placementIssue = "Title bar hit test failed (\(hitStatus.rawValue))"; return nil
                }
                var pid: pid_t = 0
                guard AXUIElementGetPid(hit, &pid) == .success else {
                    placementIssue = "Unknown owner over title bar"; return nil
                }
                guard pid == target.pid else {
                    ownPanelOcclusion = pid == ProcessInfo.processInfo.processIdentifier
                    if ownPanelOcclusion, let overlayNumber {
                        if overlaySurfaceClear == nil { overlaySurfaceClear = visibleSurface(target, candidate: candidate, overlayNumber: overlayNumber) }
                        if overlaySurfaceClear == true { continue }
                    }
                    placementIssue = "Another surface covers the title bar"; return nil
                }
                let role = value(hit, kAXRoleAttribute) as? String ?? "unknown role"
                let ownerWindow = role == kAXWindowRole ? hit : element(hit, kAXWindowAttribute)
                guard let ownerWindow, CFEqual(ownerWindow, target.window) else {
                    placementIssue = "Another window covers the title bar"; return nil
                }
                guard [kAXWindowRole, kAXToolbarRole].contains(role) else {
                    placementIssue = "Unverified title bar surface: \(role)"; return nil
                }
            }
        }
        placementIssue = "Title bar verified"
        return candidate
    }

    func focusedPID() -> pid_t? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.04)
        guard let app = element(system, kAXFocusedApplicationAttribute) else { return nil }
        var pid: pid_t = 0
        return AXUIElementGetPid(app, &pid) == .success ? pid : nil
    }

    // WindowServer ordering supplements AX hit tests while our exact overlay is
    // visible. Never ignore other Rightnest windows or a same-app overlapping window.
    private func visibleSurface(_ target: WindowTarget, candidate: CGRect, overlayNumber: Int?) -> Bool {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return false }
        guard let overlayNumber else { return false }
        var surfaces: [Surface] = []
        for info in windows {
            guard let number = info[kCGWindowNumber as String] as? Int,
                  let pid = info[kCGWindowOwnerPID as String] as? Int32,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  let alpha = info[kCGWindowAlpha as String] as? Double,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds) else { return false }
            surfaces.append(Surface(number: number, pid: pid, layer: layer, bounds: rect, alpha: alpha))
        }
        return SurfaceOrder.targetIsDirectlyBelow(surfaces, overlayNumber: overlayNumber,
            ownPID: ProcessInfo.processInfo.processIdentifier, targetPID: target.pid,
            targetFrame: target.frame, candidate: candidate)
    }
    func setPosition(_ point: CGPoint, on window: AXUIElement) -> Bool {
        guard point.x.isFinite, point.y.isFinite, writable(window, kAXPositionAttribute) else { return false }
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return false }
        return AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value) == .success
    }
    func setSize(_ size: CGSize, on window: AXUIElement) -> Bool {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              writable(window, kAXSizeAttribute) else { return false }
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return false }
        return AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value) == .success
    }

    func act(_ action: WindowAction, on target: WindowTarget) -> Bool {
        guard AXIsProcessTrusted(), focusedPID() == target.pid,
              let current = focusedWindow(pid: target.pid), CFEqual(current, target.window) else { return false }
        switch action {
        case .close:
            guard let button = pressable(target.close) else { return false }
            return AXUIElementPerformAction(button, kAXPressAction as CFString) == .success
        case .minimize:
            guard let button = pressable(target.minimize) else { return false }
            return AXUIElementPerformAction(button, kAXPressAction as CFString) == .success
        case .fit: return false // Geometry transactions are owned by WindowEngine.
        }
    }
}
