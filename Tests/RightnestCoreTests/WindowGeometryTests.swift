import XCTest
import RightnestCore

final class WindowGeometryTests: XCTestCase {
    func testRestoreAfterDisplayRemoval() {
        let old = CGRect(x: -1200, y: 20, width: 1200, height: 780)
        let screen = CGRect(x: 0, y: 25, width: 1440, height: 850)
        let record = RestoreRecord(original: CGRect(x: -1100, y: 100, width: 700, height: 500), fitted: old)
        XCTAssertTrue(screen.contains(record.destination(current: old, screens: [screen])!))
    }
    func testManualResizeInvalidatesRestore() {
        let fit = CGRect(x: 0, y: 25, width: 1440, height: 850)
        let record = RestoreRecord(original: fit.insetBy(dx: 100, dy: 100), fitted: fit)
        XCTAssertNil(record.destination(current: fit.insetBy(dx: 20, dy: 0), screens: [fit]))
    }
    func testCoordinatesRoundTripOnUpperDisplay() {
        let rect = CGRect(x: -100, y: -900, width: 900, height: 600)
        XCTAssertEqual(WindowGeometry.flip(WindowGeometry.flip(rect, primaryTop: 1080), primaryTop: 1080), rect)
    }
    func testFitAllowsOnlySmallNativeMargins() {
        let available = CGRect(x: 0, y: 30, width: 1920, height: 992)
        XCTAssertTrue(WindowGeometry.isFitted(CGRect(x: 3, y: 34, width: 1917, height: 987), inside: available))
        XCTAssertFalse(WindowGeometry.isFitted(available.insetBy(dx: 20, dy: 20), inside: available))
        XCTAssertFalse(WindowGeometry.isFitted(available.offsetBy(dx: -10, dy: 0), inside: available))
    }
    func testPlacementSearchRetainsRightHalfBoundary() {
        let window = CGRect(x: -1000, y: 40, width: 900, height: 600)
        let candidates = Placement.candidates(window: window, rowY: 44)
        XCTAssertEqual(candidates.first, Placement.candidate(window: window, rowY: 44, obstacles: [], boundsKnown: true))
        XCTAssertTrue(candidates.allSatisfy { $0.minX >= window.midX && window.contains($0) })
        XCTAssertTrue(candidates.contains { $0.width == 66 })
    }
    func testAutomaticApplicationEligibilityAndExclusions() {
        XCTAssertTrue(ApplicationEligibility.allows(bundleID: "org.blenderfoundation.blender", isRegular: true, ownBundleID: "self", disabled: []))
        XCTAssertFalse(ApplicationEligibility.allows(bundleID: "org.blenderfoundation.blender", isRegular: true, ownBundleID: "self", disabled: ["org.blenderfoundation.blender"]))
        XCTAssertFalse(ApplicationEligibility.allows(bundleID: "self", isRegular: true, ownBundleID: "self", disabled: []))
        XCTAssertFalse(ApplicationEligibility.allows(bundleID: "agent", isRegular: false, ownBundleID: "self", disabled: []))
        XCTAssertFalse(ApplicationEligibility.allows(bundleID: nil, isRegular: true, ownBundleID: "self", disabled: []))
    }
}
