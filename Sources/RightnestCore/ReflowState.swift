import Foundation
import CoreGraphics

public struct PlacementDecision: Sendable {
    public let ideal: CGRect?
    public let available: CGRect?
    public let currentIsClear: Bool
    public init(ideal: CGRect?, available: CGRect?, currentIsClear: Bool) {
        self.ideal = ideal; self.available = available; self.currentIsClear = currentIsClear
    }
}

/// Monotonic time is supplied by the caller; no timers or AX objects live here.
public struct ReflowState: Sendable {
    public private(set) var current: CGRect?
    public private(set) var transientSince: TimeInterval?
    private var ideal: CGRect?
    private var clearSince: TimeInterval?
    private var wasHovered = false
    private var pointerReleasedAt: TimeInterval?
    private var unknownFailures = 0
    public init() {}
    public mutating func reset() { self = ReflowState() }

    public mutating func update(_ decision: PlacementDecision, now: TimeInterval, pointerInside: Bool) -> CGRect? {
        if pointerInside { wasHovered = true; pointerReleasedAt = nil }
        else if wasHovered { wasHovered = false; pointerReleasedAt = now }
        if ideal != decision.ideal { ideal = decision.ideal; clearSince = nil }
        if decision.ideal == nil && decision.available == nil { unknownFailures = min(3, unknownFailures+1) }
        else { unknownFailures = 0 }
        if let home = decision.ideal, decision.available == home {
            if current == home || transientSince == nil {
                current = home; transientSince = nil; clearSince = nil; return current
            }
            if clearSince == nil { clearSince = now }
            let pointerReady = !pointerInside && pointerReleasedAt.map { now-$0 >= 0.15 } != false
            if now-(clearSince ?? now) >= 0.2 && pointerReady {
                current = home; transientSince = nil; clearSince = nil
            } else if !decision.currentIsClear { current = nil }
            return current
        }
        clearSince = nil
        if decision.ideal != nil && transientSince == nil { transientSince = now }
        if !decision.currentIsClear || current == nil { current = decision.available }
        return current
    }
    public func retryDelay(now: TimeInterval, experimental: Bool) -> TimeInterval {
        if let clearSince, !wasHovered {
            let clearWait = max(0, 0.2-(now-clearSince))
            let pointerWait = pointerReleasedAt.map { max(0, 0.15-(now-$0)) } ?? 0
            return max(0.01, max(clearWait, pointerWait))
        }
        if let start = transientSince { return now-start < 5 ? 0.1 : 0.25 }
        if current == nil && experimental { return [1.0, 1.0, 2.0, 4.0][unknownFailures] }
        return current == nil ? 1 : 0.5
    }
}

public enum ApplicationSupport: String, Sendable, CaseIterable {
    case primary, system, experimental
    public static func group(for id: String) -> Self {
        switch id {
        case "com.apple.Safari", "com.google.Chrome": .primary
        case "com.apple.finder", "com.apple.Preview", "com.apple.systempreferences", "com.apple.TextEdit": .system
        default: .experimental
        }
    }
}

public struct ElectronPreparation: Sendable {
    private var attempted: Set<String> = []
    public init() {}
    public mutating func shouldActivate(session: String, enabled: Bool, incomplete: Bool) -> Bool {
        guard enabled, incomplete, !attempted.contains(session) else { return false }
        attempted.insert(session); return true
    }
}
