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
}
