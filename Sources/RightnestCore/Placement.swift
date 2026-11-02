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
        // Prefer the rightmost available anchor, then comfortable controls.
        // Compact buttons remain above macOS's 20 pt minimum.
        [width, 66].flatMap { controlWidth -> [CGRect] in
            guard let first = candidate(window: window, rowY: rowY, obstacles: [], boundsKnown: true, controlWidth: controlWidth) else { return [] }
            return stride(from: first.minX, through: window.midX, by: -18).map {
                CGRect(x: $0, y: first.minY, width: controlWidth, height: height)
            }
        }.sorted { $0.maxX == $1.maxX ? $0.width > $1.width : $0.maxX > $1.maxX }
    }

    /// Prefer above the upper-right corner, then beside or below. Never enter
    /// the menu bar, Dock, another display, or the target window itself.
    public static func detachedCandidates(window: CGRect, visibleFrames: [CGRect]) -> [CGRect] {
        guard WindowGeometry.valid(window), let screen = WindowGeometry.screen(for: window, visibleFrames: visibleFrames) else { return [] }
        return [width, 66].flatMap { w in
            [CGRect(x: window.maxX-w, y: window.minY-height-6, width: w, height: height),
             CGRect(x: window.maxX+6, y: window.minY+6, width: w, height: height),
             CGRect(x: window.maxX-w, y: window.maxY+6, width: w, height: height),
             CGRect(x: window.minX-w-6, y: window.minY+6, width: w, height: height)]
                .filter { screen.contains($0) && !$0.intersects(window) }
        }
    }

    // All rectangles use AX screen coordinates (origin at the main screen's top left).
    // Caller must supply complete, trustworthy obstacle data; empty AX data is not proof of safety.
    public static func candidate(window: CGRect, rowY: CGFloat, obstacles: [CGRect],
                                 boundsKnown: Bool, controlWidth: CGFloat = width) -> CGRect? {
        guard boundsKnown, controlWidth.isFinite, controlWidth >= 66, controlWidth <= width, window.width >= 340, window.height >= 100,
              window.minX.isFinite, window.minY.isFinite, window.width.isFinite,
              window.height.isFinite, rowY.isFinite else { return nil }
        let rect = CGRect(x: window.maxX - controlWidth - 8, y: rowY, width: controlWidth, height: height)
        guard window.contains(rect), rect.maxY <= window.minY + 80 else { return nil }
        guard obstacles.allSatisfy({ !$0.insetBy(dx: -5, dy: -5).intersects(rect) }) else { return nil }
        return rect
    }
}
