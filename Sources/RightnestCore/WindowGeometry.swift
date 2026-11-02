import Foundation
import CoreGraphics

public enum WindowGeometry {
    /// AX and AppKit share points, but use opposite vertical origins. The desktop
    /// reference is the primary display, not whichever display currently has focus.
    public static func flip(_ rect: CGRect, primaryTop: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryTop - rect.maxY, width: rect.width, height: rect.height)
    }
    public static func screen(for rect: CGRect, visibleFrames: [CGRect]) -> CGRect? {
        visibleFrames.filter { valid($0) }.max {
            area($0.intersection(rect)) < area($1.intersection(rect))
        }
    }
    private static func area(_ rect: CGRect) -> CGFloat { rect.isNull ? 0 : rect.width * rect.height }
    public static func valid(_ rect: CGRect) -> Bool {
        [rect.minX, rect.minY, rect.width, rect.height].allSatisfy(\.isFinite) && rect.width > 0 && rect.height > 0
    }
    public static func close(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(a.minX-b.minX) <= tolerance && abs(a.minY-b.minY) <= tolerance &&
        abs(a.width-b.width) <= tolerance && abs(a.height-b.height) <= tolerance
    }
    public static func clamped(_ rect: CGRect, to screen: CGRect) -> CGRect {
        let width = min(rect.width, screen.width), height = min(rect.height, screen.height)
        return CGRect(x: min(max(rect.minX, screen.minX), screen.maxX-width),
                      y: min(max(rect.minY, screen.minY), screen.maxY-height), width: width, height: height)
    }
}

public struct RestoreRecord: Sendable {
    public let original: CGRect
    public let fitted: CGRect
    public init(original: CGRect, fitted: CGRect) { self.original = original; self.fitted = fitted }
    public func destination(current: CGRect, screens: [CGRect]) -> CGRect? {
        guard WindowGeometry.close(current, fitted), let screen = WindowGeometry.screen(for: original, visibleFrames: screens) else { return nil }
        return WindowGeometry.clamped(original, to: screen)
    }
}
