import Foundation
import CoreGraphics

public struct Surface: Sendable {
    public let number: Int
    public let pid: Int32
    public let layer: Int
    public let bounds: CGRect
    public let alpha: Double
    public init(number: Int, pid: Int32, layer: Int, bounds: CGRect, alpha: Double) {
        self.number = number; self.pid = pid; self.layer = layer; self.bounds = bounds; self.alpha = alpha
    }
}
public enum SurfaceOrder {
    /// Call only after AX hit testing identifies our visible overlay. Windows
    /// above it cannot be masked by it; every intersecting surface below matters.
    public static func targetIsDirectlyBelow(_ surfaces: [Surface], overlayNumber: Int, ownPID: Int32,
                                            targetPID: Int32, targetFrame: CGRect, candidate: CGRect) -> Bool {
        guard let overlay = surfaces.firstIndex(where: { $0.number == overlayNumber && $0.pid == ownPID }) else { return false }
        for item in surfaces.dropFirst(overlay + 1) {
            guard WindowGeometry.valid(item.bounds) else { return false }
            guard item.alpha > 0, item.bounds.intersects(candidate) else { continue }
            return item.pid == targetPID && item.layer == 0 && WindowGeometry.close(item.bounds, targetFrame)
        }
        return false
    }
}
