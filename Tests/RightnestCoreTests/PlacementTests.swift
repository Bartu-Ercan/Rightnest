import CoreGraphics
import XCTest
@testable import RightnestCore
final class PlacementTests: XCTestCase {
    let window = CGRect(x: -1200, y: 50, width: 800, height: 500)
    func testContentBoundaryDoesNotCreateFalseCollision() {
        let candidate = CGRect(x: 100, y: 3, width: 102, height: 26)
        let below = CGRect(x: 0, y: 32, width: 800, height: 500)
        XCTAssertFalse(Placement.overlapsTitlebar(below, candidate: candidate, isLayoutContainer: true))
        XCTAssertTrue(Placement.overlapsTitlebar(below, candidate: candidate, isLayoutContainer: false))
    }
    func testClearTitlebarOnLeftDisplay() {
        XCTAssertEqual(Placement.candidate(window: window, rowY: 54, obstacles: [], boundsKnown: true)?.maxX, -408)
    }
    func testCollisionAndNearCollisionAreRejected() {
        for x in [-450.0, -405.0] {
            XCTAssertNil(Placement.candidate(window: window, rowY: 54,
                obstacles: [CGRect(x: x, y: 58, width: 20, height: 20)], boundsKnown: true))
        }
    }
    func testUnknownLayoutAndInvalidGeometryAreRejected() {
        XCTAssertNil(Placement.candidate(window: window, rowY: 54, obstacles: [], boundsKnown: false))
        XCTAssertNil(Placement.candidate(window: window, rowY: 160, obstacles: [], boundsKnown: true))
        XCTAssertNil(Placement.candidate(window: window, rowY: .nan, obstacles: [], boundsKnown: true))
        XCTAssertNil(Placement.candidate(window: CGRect(x: 0, y: 0, width: 200, height: 300), rowY: 4, obstacles: [], boundsKnown: true))
    }
}
