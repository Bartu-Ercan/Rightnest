import Foundation
import CoreGraphics

public enum WindowGeometry {
    /// Correct an out-of-bounds AX hit only inside a fully measured background.
    public static func disjointHit(_ reported: CGRect?, from candidate: CGRect,
                                   inside backgrounds: [CGRect], clearance: CGFloat = 0) -> Bool {
        guard let reported, valid(reported), valid(candidate), clearance.isFinite, clearance >= 0,
              backgrounds.contains(where: { valid($0) && $0.contains(candidate) }) else { return false }
        return !reported.insetBy(dx: -clearance, dy: -clearance).intersects(candidate)
    }

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
    /// macOS may retain a small native tiling margin after a successful resize.
    /// This applies to fit confirmation only, never target identity or restoration.
    public static func isFitted(_ actual: CGRect, inside available: CGRect) -> Bool {
        guard valid(actual), valid(available) else { return false }
        let insets = [actual.minX-available.minX, actual.minY-available.minY,
                      available.maxX-actual.maxX, available.maxY-actual.maxY]
        return insets.allSatisfy { $0 >= -1 && $0 <= 8 }
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
