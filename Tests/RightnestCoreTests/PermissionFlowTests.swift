import XCTest
@testable import RightnestCore
final class PermissionFlowTests: XCTestCase {
    func testPreferencesCannotGrantPermission() {
        XCTAssertEqual(PermissionFlow(trusted: false, requested: true, previouslyGranted: false), .waiting)
        XCTAssertEqual(PermissionFlow(trusted: false, requested: false, previouslyGranted: false), .required)
    }
    func testRevocationAndRegrant() {
        XCTAssertEqual(PermissionFlow(trusted: false, requested: true, previouslyGranted: true), .revoked)
        XCTAssertEqual(PermissionFlow(trusted: true, requested: true, previouslyGranted: true), .granted)
    }
}
