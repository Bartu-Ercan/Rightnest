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
    public static func outsideIsClear(_ surfaces: [Surface], candidate: CGRect,
                                      overlayNumber: Int?, ownPID: Int32) -> Bool {
        guard WindowGeometry.valid(candidate) else { return false }
        return surfaces.allSatisfy { item in
            guard WindowGeometry.valid(item.bounds) else { return false }
            if item.number == overlayNumber && item.pid == ownPID && WindowGeometry.close(item.bounds, candidate) { return true }
            return item.alpha <= 0 || !item.bounds.intersects(candidate)
        }
    }

    public static func overlayCoversClearTarget(_ surfaces: [Surface], overlayNumber: Int, ownPID: Int32,
                                               targetPID: Int32, targetFrame: CGRect, candidate: CGRect) -> Bool {
        guard let index = surfaces.firstIndex(where: { $0.number == overlayNumber && $0.pid == ownPID }),
              surfaces[index].bounds.contains(candidate),
              surfaces.prefix(index).allSatisfy({ WindowGeometry.valid($0.bounds) && ($0.alpha <= 0 || !$0.bounds.intersects(candidate)) }) else { return false }
        return targetIsDirectlyBelow(surfaces, overlayNumber: overlayNumber, ownPID: ownPID,
            targetPID: targetPID, targetFrame: targetFrame, candidate: candidate)
    }

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
