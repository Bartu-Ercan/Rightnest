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
    private var surfaceSnapshot: [Surface]?
    private var surfaceSnapshotLoaded = false
    private var observedOcclusions: [CGRect] = []
    private struct Layout {
        let candidates: [CGRect]
        let obstacles: [CGRect]
        let backgrounds: [AXUIElement]
        let toolbars: [CGRect]
        let spacers: [CGRect]
    }
    private struct LayoutCache {
        let window: AXUIElement
        let frame: CGRect
        let electron: Bool
        let created: TimeInterval
        let layout: Layout?
        let issue: String
    }
    private var cachedLayout: LayoutCache?
    private(set) var incompleteTree = false
    func invalidateLayout() { cachedLayout = nil }
    func activateElectronAccessibility(pid: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.08)
        if value(app, "AXManualAccessibility") as? Bool == true { return true }
        return AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue) == .success
    }
    private(set) var ownPanelOcclusion = false
    private var candidateObstructed = false
    private(set) var placementIssue = "Unverified title bar"
    #if DEBUG
    private var surfaceDiagnostic = ""
    private(set) var focusDiagnostic = ""
    #endif
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
        if let raw = value(element, "AXFrame"), CFGetTypeID(raw) == AXValueGetTypeID() {
            var rect = CGRect.zero
            if AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), .cgRect, &rect), WindowGeometry.valid(rect) { return rect }
        }
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
    func target(pid: pid_t, cached: WindowTarget? = nil) -> WindowTarget? {
        guard let window = focusedWindow(pid: pid),
              (value(window, kAXSubroleAttribute) as? String) == kAXStandardWindowSubrole,
              (value(window, kAXMinimizedAttribute) as? Bool) == false,
              (value(window, "AXFullScreen") as? Bool) == false,
              let frame = frame(window) else { return nil }
        guard let children = value(window, kAXChildrenAttribute) as? [AXUIElement],
              !children.contains(where: { (value($0, kAXRoleAttribute) as? String) == kAXSheetRole }) else { return nil }
        if let cached, cached.pid == pid, cached.frame == frame, CFEqual(cached.window, window) { return cached }
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

    // Chromium exposes the unused end of its native tab strip as a leaf group.
    // Require its native node marker, empty metadata/actions and sibling tabs;
    // never extend this exception to anonymous custom app groups or web content.
    private func chromiumTabBackground(_ node: AXUIElement, window: CGRect) -> Bool {
        guard value(node, "ChromeAXNodeId") != nil, let rect = frame(node),
              rect.height <= 60, rect.minY >= window.minY, rect.maxY <= window.minY + 80,
              let parent = element(node, kAXParentAttribute),
              let peers = value(parent, kAXChildrenAttribute) as? [AXUIElement],
              peers.contains(where: { peer in
                  if value(peer, kAXRoleAttribute) as? String == kAXTabGroupRole { return true }
                  guard value(peer, kAXRoleAttribute) as? String == kAXGroupRole,
                        let children = value(peer, kAXChildrenAttribute) as? [AXUIElement] else { return false }
                  return children.contains { value($0, kAXRoleAttribute) as? String == kAXTabGroupRole }
              }) else { return false }
        var actions: CFArray?
        guard AXUIElementCopyActionNames(node, &actions) == .success,
              (actions as? [String])?.isEmpty == true else { return false }
        return [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXHelpAttribute].allSatisfy {
            let raw = value(node, $0)
            return raw == nil || (raw as? String)?.isEmpty == true
        }
    }

    // WhatsApp's native navigation bar exposes its flexible blank spacer as an
    // anonymous leaf. Recognize the measured spacer between the left header
    // and right action buttons, not an arbitrary empty Catalyst container.
    private func navigationSpacer(_ node: AXUIElement, window: CGRect) -> Bool {
        guard let parent = element(node, kAXParentAttribute),
              value(parent, kAXIdentifierAttribute) as? String == "WDSNavigationBar",
              let rect = frame(node), let parentFrame = frame(parent), parentFrame.contains(rect),
              parentFrame.height <= 60, rect.height <= 40, rect.width >= 100,
              rect.minY >= window.minY, rect.maxY <= window.minY+80,
              let peers = value(parent, kAXChildrenAttribute) as? [AXUIElement] else { return false }
        var actions: CFArray?
        guard AXUIElementCopyActionNames(node, &actions) == .success,
              let names = actions as? [String], Set(names).isSubset(of: ["AXCancel", "AXShowMenu", "AXScrollToVisible"]),
              [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXHelpAttribute, kAXIdentifierAttribute].allSatisfy({
                  let raw = value(node, $0)
                  return raw == nil || (raw as? String)?.isEmpty == true
              }) else { return false }
        let buttons = peers.filter { value($0, kAXRoleAttribute) as? String == kAXButtonRole }.compactMap(frame)
        return buttons.contains { $0.maxX <= rect.minX } && buttons.filter { $0.minX >= rect.maxX }.count >= 2 &&
            buttons.allSatisfy { !$0.intersects(rect) }
    }

    func placement(_ target: WindowTarget, overlayNumber: Int? = nil, screens: [CGRect] = [], preferred: CGRect? = nil) -> CGRect? {
        let decision = placementDecision(target, overlayNumber: overlayNumber, screens: screens,
            current: preferred, forceLayout: true, electron: cachedLayout?.electron ?? false)
        return decision.currentIsClear ? preferred : decision.available
    }

    func placementDecision(_ target: WindowTarget, overlayNumber: Int?, screens: [CGRect], current: CGRect?,
                           forceLayout: Bool, electron: Bool) -> PlacementDecision {
        surfaceSnapshot = nil; surfaceSnapshotLoaded = false; observedOcclusions.removeAll()
        ownPanelOcclusion = false
        #if DEBUG
        surfaceDiagnostic = ""
        #endif
        let now = ProcessInfo.processInfo.systemUptime
        let deadline = now+0.4
        let layout: Layout?
        if !forceLayout, let cached = cachedLayout, cached.frame == target.frame,
           cached.electron == electron, CFEqual(cached.window, target.window), now-cached.created < 1 {
            layout = cached.layout; placementIssue = cached.issue
        } else {
            cachedLayout = nil; incompleteTree = false
            layout = makeLayout(target, electron: electron, deadline: deadline)
            cachedLayout = LayoutCache(window: target.window, frame: target.frame, electron: electron,
                created: now, layout: layout, issue: placementIssue)
        }
        let outside = Placement.detachedCandidates(window: target.frame, visibleFrames: screens)
        let native = layout?.candidates.filter { candidate in
            !(layout?.obstacles.contains { $0.intersects(candidate) } ?? true)
        } ?? []
        var ideal = native.first
        func nativeClear(_ candidate: CGRect) -> Bool {
            guard let layout, !observedOcclusions.contains(where: { $0.intersects(candidate) }) else { return false }
            return verifiedPlacement(target, candidate: candidate, overlayNumber: overlayNumber, deadline: deadline,
                backgrounds: layout.backgrounds, toolbarFrames: layout.toolbars, navigationSpacers: layout.spacers) != nil
        }
        func clear(_ candidate: CGRect) -> Bool {
            if native.contains(candidate) { return nativeClear(candidate) }
            return outside.contains(candidate) && outsideSurfaceClear(candidate, overlayNumber: overlayNumber)
        }
        let homeClear = ideal.map(clear) ?? false
        let homeObstructed = candidateObstructed
        let alternativeReason: PlacementAlternativeReason? = ideal == nil ? .noVerifiedTitlebar : homeClear ? nil : homeObstructed ? .obstruction : .unverifiedSurface
        let currentClear: Bool
        if let current { currentClear = current == ideal ? homeClear : clear(current) }
        else { currentClear = false }
        var available = homeClear ? ideal : nil
        if available == nil, currentClear { available = current }
        if available == nil {
            for candidate in native + outside where candidate != ideal && candidate != current {
                guard ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection timed out"; break }
                if clear(candidate) { available = candidate; break }
            }
        }
        if ideal == nil { ideal = available }
        if let available { placementIssue = target.frame.contains(available) ? "Controls active" : "Controls outside window" }
        else if !screens.isEmpty { placementIssue = "No safe titlebar or outside space" }
        return PlacementDecision(ideal: ideal, available: available, currentIsClear: currentClear, alternativeReason: alternativeReason)
    }

    // Inspect known layout containers; never infer that an unknown subtree is blank.
    private func makeLayout(_ target: WindowTarget, electron: Bool, deadline: TimeInterval) -> Layout? {
        ownPanelOcclusion = false
        placementIssue = "Missing close-button geometry"
        guard let close = target.close, let closeFrame = frame(close) else { return nil }
        let choices = Placement.candidates(window: target.frame, rowY: closeFrame.midY - 13)
        var candidates = choices
        placementIssue = "Not enough room in title bar"
        guard let first = candidates.first, let last = candidates.last else { return nil }
        var searchArea = choices.reduce(first.union(last)) { $0.union($1) }
        var obstacles: [CGRect] = []
        var verifiedBackgrounds: [AXUIElement] = []
        var toolbarFrames: [CGRect] = []
        var navigationSpacers: [CGRect] = []
        var navigationContext: (bar: AXUIElement, spacer: CGRect)?
        var findingNavigationRow = true
        var descriptions: [String] = []
        defer { layoutDiagnostic = "window " + NSStringFromRect(target.frame) + " close " + NSStringFromRect(closeFrame) + " search " + NSStringFromRect(searchArea) + "\n" + descriptions.joined(separator: "\n") }
        var budget = 160
        let containers = [kAXWindowRole, kAXToolbarRole, kAXGroupRole, kAXSplitGroupRole, kAXTabGroupRole] + (electron ? ["AXWebArea", kAXScrollAreaRole] : [])
        func collect(_ node: AXUIElement, depth: Int) -> Bool {
            budget -= 1
            guard budget > 0, ProcessInfo.processInfo.systemUptime < deadline else { placementIssue = "Inspection limit reached"; return false }
            guard let geometry = frame(node) else { placementIssue = "Missing title bar geometry"; return false }
            guard geometry.insetBy(dx: -5, dy: -5).intersects(searchArea) else { return true }
            guard let role = value(node, kAXRoleAttribute) as? String else { placementIssue = "Unknown accessibility role"; return false }
            if (value(node, "AXHidden") as? Bool) == true { return true }
            let rect = geometry
            let layout = containers.contains(role) || role == kAXScrollAreaRole
            let measuredInk = role == kAXStaticTextRole ? textInkFrame(node) : nil
            let ink = measuredInk.flatMap { rect.insetBy(dx: -1, dy: -1).contains($0) ? $0 : nil }
            if ink != nil { verifiedBackgrounds.append(node) }
            let occupied = layout ? rect : (ink ?? rect).insetBy(dx: -5, dy: -5)
            guard occupied.intersects(searchArea) else { return true }
            guard containers.contains(role) else { obstacles.append(occupied); descriptions.append(role + " " + NSStringFromRect(occupied)); return true }
            guard depth < 16 else { placementIssue = "Inspection limit reached"; return false }
            guard let children = value(node, kAXChildrenAttribute) as? [AXUIElement] else { incompleteTree = true; placementIssue = "Incomplete title bar hierarchy"; return false }
            if children.isEmpty {
                if role == kAXGroupRole && rect.width >= target.frame.width*0.8 && rect.height >= target.frame.height*0.8 { incompleteTree = true }
                let navigation = role == kAXGroupRole && navigationSpacer(node, window: target.frame)
                if role == kAXGroupRole && (navigation || chromiumTabBackground(node, window: target.frame)) {
                    verifiedBackgrounds.append(node)
                    if navigation { navigationSpacers.append(rect) }
                    if navigation, let parent = element(node, kAXParentAttribute),
                       Placement.candidates(window: target.frame, rowY: rect.midY-13).contains(where: { rect.contains($0) }) {
                        navigationContext = (parent, rect)
                    }
                    descriptions.append("Verified native toolbar spacer " + NSStringFromRect(rect))
                } else if role != kAXWindowRole && role != kAXToolbarRole {
                    obstacles.append(rect); descriptions.append("empty " + role + " " + NSStringFromRect(rect))
                }
                return true
            }
            var complete = true
            for child in children {
                if !collect(child, depth: depth+1) { complete = false; break }
                // This discovery pass will be discarded and replaced by a full
                // scoped navigation-bar pass. Do not query message content.
                if findingNavigationRow && navigationContext != nil { break }
            }
            if complete { verifiedBackgrounds.append(node); if role == kAXToolbarRole { toolbarFrames.append(rect) } }
            return complete
        }
        guard collect(target.window, depth: 0) else { return nil }
        if let context = navigationContext, let barFrame = frame(context.bar) {
            // Native navigation chrome clips the scroll content beneath it. Use
            // its own row/subtree instead of recycled message-cell bounds which
            // Catalyst may report beyond the actual scrolling viewport.
            let row = Placement.candidates(window: target.frame, rowY: context.spacer.midY-13)
                .filter { context.spacer.contains($0) && barFrame.contains($0) }
            if let first = row.first {
                candidates = row
                searchArea = row.reduce(first) { $0.union($1) }
                findingNavigationRow = false
                obstacles.removeAll(); verifiedBackgrounds.removeAll(); toolbarFrames.removeAll(); navigationSpacers.removeAll()
                descriptions.append("Scoped native navigation row " + NSStringFromRect(searchArea))
                guard collect(context.bar, depth: 0) else { return nil }
            }
        }
        #if DEBUG
        descriptions.append("collection ms " + String(Int((ProcessInfo.processInfo.systemUptime-deadline+0.4)*1000)))
        #endif
        return Layout(candidates: candidates, obstacles: obstacles,
            backgrounds: verifiedBackgrounds, toolbars: toolbarFrames, spacers: navigationSpacers)
    }
    private func verifiedPlacement(_ target: WindowTarget, candidate: CGRect, overlayNumber: Int?, deadline: TimeInterval, backgrounds: [AXUIElement], toolbarFrames: [CGRect], navigationSpacers: [CGRect]) -> CGRect? {
        ownPanelOcclusion = false; candidateObstructed = false
        // Hit-test visible geometry too. A different window, button, or unknown node rejects placement.
        placementIssue = "Another surface covers the title bar"
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.04)
        if overlayNumber != nil && visibleSurface(target, candidate: candidate, overlayNumber: overlayNumber, wholeCoverage: true) {
            placementIssue = "Title bar verified"
            return candidate
        }
        var overlaySurfaceClear: Bool?
        for x in [candidate.minX+1, candidate.midX, candidate.maxX-1] {
            for y in [candidate.minY+1, candidate.maxY-1] {
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
                    #if DEBUG
                    surfaceDiagnostic = "hit pid \(pid), role " + (value(hit, kAXRoleAttribute) as? String ?? "unknown")
                    #endif
                    if pid != ProcessInfo.processInfo.processIdentifier {
                        let covering = (value(hit, kAXRoleAttribute) as? String) == kAXWindowRole ? hit : element(hit, kAXWindowAttribute)
                        if let covering, let rect = frame(covering), WindowGeometry.valid(rect) { observedOcclusions.append(rect) }
                    }
                    ownPanelOcclusion = pid == ProcessInfo.processInfo.processIdentifier
                    if ownPanelOcclusion, let overlayNumber {
                        if overlaySurfaceClear == nil { overlaySurfaceClear = visibleSurface(target, candidate: candidate, overlayNumber: overlayNumber) }
                        if overlaySurfaceClear == true { continue }
                    }
                    candidateObstructed = true
                    placementIssue = "Another surface covers the title bar"; return nil
                }
                let role = value(hit, kAXRoleAttribute) as? String ?? "unknown role"
                let ownerWindow = role == kAXWindowRole ? hit : element(hit, kAXWindowAttribute)
                guard let ownerWindow, CFEqual(ownerWindow, target.window) else {
                    if let ownerWindow, let rect = frame(ownerWindow), WindowGeometry.valid(rect) { observedOcclusions.append(rect) }
                    candidateObstructed = true
                    placementIssue = "Another window covers the title bar"; return nil
                }
                // Safari can return its WebArea for transparent native toolbar
                // background. Correct only a geometrically disjoint content hit
                // inside a completely inspected native toolbar, never real content.
                let disjointContentHit = role == "AXWebArea" && WindowGeometry.disjointHit(frame(hit), from: candidate, inside: toolbarFrames)
                // Catalyst can report a sibling call button for a point in its
                // measured navigation spacer. Correct only an out-of-bounds
                // hit in that exact inspected spacer, never an overlapping button.
                let disjointNavigationHit = role == kAXButtonRole && WindowGeometry.disjointHit(frame(hit), from: candidate, inside: navigationSpacers, clearance: 5)
                guard [kAXWindowRole, kAXToolbarRole].contains(role) || backgrounds.contains(where: { CFEqual($0, hit) }) || disjointContentHit || disjointNavigationHit else {
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
        let status = AXUIElementGetPid(app, &pid)
        #if DEBUG
        focusDiagnostic = "AX focused pid \(pid), status \(status.rawValue)"
        #endif
        return status == .success ? pid : nil
    }

    // WindowServer ordering supplements AX hit tests while our exact overlay is
    // visible. Never ignore other Rightnest windows or a same-app overlapping window.
    private func visibleSurface(_ target: WindowTarget, candidate: CGRect, overlayNumber: Int?, wholeCoverage: Bool = false) -> Bool {
        guard let surfaces = currentSurfaces() else { return false }
        guard let overlayNumber else { return false }
        if wholeCoverage {
            return SurfaceOrder.overlayCoversClearTarget(surfaces, overlayNumber: overlayNumber,
                ownPID: ProcessInfo.processInfo.processIdentifier, targetPID: target.pid,
                targetFrame: target.frame, candidate: candidate)
        }
        return SurfaceOrder.targetIsDirectlyBelow(surfaces, overlayNumber: overlayNumber,
            ownPID: ProcessInfo.processInfo.processIdentifier, targetPID: target.pid,
            targetFrame: target.frame, candidate: candidate)
    }
    // One bounded inspection uses one coherent WindowServer snapshot. Never
    // cache across refreshes/actions, and never query the server per anchor.
    private func currentSurfaces() -> [Surface]? {
        if surfaceSnapshotLoaded { return surfaceSnapshot }
        surfaceSnapshotLoaded = true
        guard let raw = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
        var surfaces: [Surface] = []
        for info in raw {
            guard let number = info[kCGWindowNumber as String] as? Int,
                  let pid = info[kCGWindowOwnerPID as String] as? Int32,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  let alpha = info[kCGWindowAlpha as String] as? Double,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds) else { return nil }
            surfaces.append(Surface(number: number, pid: pid, layer: layer, bounds: rect, alpha: alpha))
        }
        surfaceSnapshot = surfaces
        return surfaces
    }

    private func outsideSurfaceClear(_ candidate: CGRect, overlayNumber: Int?) -> Bool {
        guard let surfaces = currentSurfaces() else { return false }
        if surfaces.contains(where: { $0.pid == ProcessInfo.processInfo.processIdentifier && $0.alpha > 0 && $0.bounds.intersects(candidate) }) {
            ownPanelOcclusion = true
        }
        return SurfaceOrder.outsideIsClear(surfaces, candidate: candidate, overlayNumber: overlayNumber,
            ownPID: ProcessInfo.processInfo.processIdentifier)
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
