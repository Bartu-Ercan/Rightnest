import CoreGraphics
import Foundation

public enum Placement {
    public static let width: CGFloat = 102
    public static let height: CGFloat = 26

    public static func overlapsTitlebar(_ rect: CGRect, candidate: CGRect, isLayoutContainer: Bool) -> Bool {
        (isLayoutContainer ? rect : rect.insetBy(dx: -5, dy: -5)).intersects(candidate)
    }

    /// Prefer the far right, then search left within the right half only.
    public static func candidates(window: CGRect, rowY: CGFloat) -> [CGRect] {
        guard let first = candidate(window: window, rowY: rowY, obstacles: [], boundsKnown: true) else { return [] }
        let lower = window.midX
        return stride(from: first.minX, through: lower, by: -18).map {
            CGRect(x: $0, y: first.minY, width: width, height: height)
        }
    }

    // All rectangles use AX screen coordinates (origin at the main screen's top left).
    // Caller must supply complete, trustworthy obstacle data; empty AX data is not proof of safety.
    public static func candidate(window: CGRect, rowY: CGFloat, obstacles: [CGRect],
                                 boundsKnown: Bool) -> CGRect? {
        guard boundsKnown, window.width >= 340, window.height >= 100,
              window.minX.isFinite, window.minY.isFinite, window.width.isFinite,
              window.height.isFinite, rowY.isFinite else { return nil }
        let rect = CGRect(x: window.maxX - width - 8, y: rowY, width: width, height: height)
        guard window.contains(rect), rect.maxY <= window.minY + 80 else { return nil }
        guard obstacles.allSatisfy({ !$0.insetBy(dx: -5, dy: -5).intersects(rect) }) else { return nil }
        return rect
    }
}
