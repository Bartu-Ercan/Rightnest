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
    private(set) var layoutDiagnostic = ""
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
        guard [point.x, point.y, dimensions.width, dimensions.height].allSatisfy(\.isFinite), dimensions.width >= 0, dimensions.height >= 0 else { return nil }
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

    private func textInkFrame(_ node: AXUIElement) -> CGRect? {
        guard let count = value(node, "AXNumberOfCharacters") as? Int, count > 0, count <= 4096 else { return nil }
        var range = CFRange(location: 0, length: count)
        guard let argument = AXValueCreate(.cfRange, &range) else { return nil }
        var raw: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(node, "AXBoundsForRange" as CFString, argument, &raw) == .success,
              let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), .cgRect, &rect), WindowGeometry.valid(rect) else { return nil }
        return rect
    }

    // Inspect known layout containers; never infer that an unknown subtree is blank.
    func placement(_ target: WindowTarget, overlayNumber: Int? = nil) -> CGRect? {
        ownPanelOcclusion = false
        placementIssue = "Missing close-button geometry"
        guard let close = target.close, let closeFrame = frame(close) else { return nil }
        let candidates = Placement.candidates(window: target.frame, rowY: closeFrame.midY - 13)
        placementIssue = "Not enough room in title bar"
        let deadline = ProcessInfo.processInfo.systemUptime + 0.4
        guard let first = candidates.first, let last = candidates.last else { return nil }
        let searchArea = first.union(last)
        var obstacles: [CGRect] = []
        var verifiedBackgrounds: [AXUIElement] = []
        var toolbarFrames: [CGRect] = []
        var descriptions: [String] = []
        defer { layoutDiagnostic = "window " + NSStringFromRect(target.frame) + " close " + NSStringFromRect(closeFrame) + " search " + NSStringFromRect(searchArea) + "\n" + descriptions.joined(separator: "\n") }
        var budget = 100
        let containers = [kAXWindowRole, kAXToolbarRole, kAXGroupRole, kAXSplitGroupRole, kAXTabGroupRole]
        func collect(_ node: AXUIElement, depth: Int) -> Bool {
            budget -= 1
            guard budget > 0, depth < 7, ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection limit reached"; return false }
            guard let role = value(node, kAXRoleAttribute) as? String else { placementIssue = "Unknown accessibility role"; return false }
            if (value(node, "AXHidden") as? Bool) == true { return true }
            guard let rect = frame(node) else { placementIssue = "Missing geometry for \(role)"; return false }
            let layout = containers.contains(role) || role == kAXScrollAreaRole
            let measuredInk = role == kAXStaticTextRole ? textInkFrame(node) : nil
            let ink = measuredInk.flatMap { rect.insetBy(dx: -1, dy: -1).contains($0) ? $0 : nil }
            if ink != nil { verifiedBackgrounds.append(node) }
            let occupied = layout ? rect : (ink ?? rect).insetBy(dx: -5, dy: -5)
            guard occupied.intersects(searchArea) else { return true }
            guard containers.contains(role) else { obstacles.append(occupied); descriptions.append(role + " " + NSStringFromRect(occupied)); return true }
            guard let children = value(node, kAXChildrenAttribute) as? [AXUIElement] else { placementIssue = "Incomplete title bar hierarchy"; return false }
            if children.isEmpty {
                if role != kAXWindowRole && role != kAXToolbarRole { obstacles.append(rect); descriptions.append("empty " + role + " " + NSStringFromRect(rect)) }
                return true
            }
            let complete = children.allSatisfy { collect($0, depth: depth + 1) }
            if complete { verifiedBackgrounds.append(node); if role == kAXToolbarRole { toolbarFrames.append(rect) } }
            return complete
        }
        guard collect(target.window, depth: 0) else { return nil }
        for candidate in candidates {
            guard ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection timed out"; return nil }
            guard !obstacles.contains(where: { $0.intersects(candidate) }) else { placementIssue = "No clear space in right title bar"; continue }
            if let rect = verifiedPlacement(target, candidate: candidate, overlayNumber: overlayNumber, deadline: deadline, backgrounds: verifiedBackgrounds, toolbarFrames: toolbarFrames) { return rect }
        }
        return nil
    }
    private func verifiedPlacement(_ target: WindowTarget, candidate: CGRect, overlayNumber: Int?, deadline: TimeInterval, backgrounds: [AXUIElement], toolbarFrames: [CGRect]) -> CGRect? {
        ownPanelOcclusion = false
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
                // Safari can return its WebArea for transparent native toolbar
                // background. Correct only a geometrically disjoint content hit
                // inside a completely inspected native toolbar, never real content.
                let disjointContentHit = role == "AXWebArea" && frame(hit).map { WindowGeometry.valid($0) && !$0.intersects(candidate) } == true && toolbarFrames.contains { $0.contains(candidate) }
                guard [kAXWindowRole, kAXToolbarRole].contains(role) || backgrounds.contains(where: { CFEqual($0, hit) }) || disjointContentHit else {
                    placementIssue = "Unverified title bar surface: \(role) " + (frame(hit).map { NSStringFromRect($0) } ?? "missing"); return nil
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
