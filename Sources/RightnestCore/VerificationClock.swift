#if DEBUG
import Foundation

/// Developer observation time only. Pauses and focus-transition intervals never
/// count toward the requested active-browser duration. Not in release builds.
public struct VerificationClock {
    public private(set) var activeSeconds: TimeInterval
    public private(set) var pausedSeconds: TimeInterval = 0
    private var previous: TimeInterval
    private var previouslyActive = true
    public init(now: TimeInterval, initialActiveSeconds: TimeInterval) {
        previous = now; activeSeconds = initialActiveSeconds
    }
    public mutating func advance(now: TimeInterval, active: Bool) {
        let interval = max(0, now-previous)
        if active && previouslyActive { activeSeconds += interval }
        else { pausedSeconds += interval }
        previous = max(previous, now); previouslyActive = active
    }
}
#endif
