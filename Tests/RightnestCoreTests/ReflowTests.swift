import CoreGraphics
import XCTest
@testable import RightnestCore

final class ReflowTests: XCTestCase {
    let home = CGRect(x: 700, y: 40, width: 102, height: 26)
    let alternate = CGRect(x: 550, y: 40, width: 102, height: 26)
    func testTransientObstacleDoesNotReplaceHome() {
        var state = ReflowState()
        XCTAssertEqual(state.update(.init(ideal: home, available: home, currentIsClear: false), now: 0, pointerInside: false), home)
        XCTAssertEqual(state.update(.init(ideal: home, available: alternate, currentIsClear: false), now: 1, pointerInside: false), alternate)
        let clear = PlacementDecision(ideal: home, available: home, currentIsClear: true)
        XCTAssertEqual(state.update(clear, now: 2, pointerInside: false), alternate)
        XCTAssertEqual(state.update(clear, now: 2.19, pointerInside: false), alternate)
        XCTAssertEqual(state.update(clear, now: 2.21, pointerInside: false), home)
    }
    func testHoverDefersOptionalReturnButDoesNotPermitCollision() {
        var state = ReflowState()
        _ = state.update(.init(ideal: home, available: alternate, currentIsClear: false), now: 0, pointerInside: false)
        let clear = PlacementDecision(ideal: home, available: home, currentIsClear: true)
        _ = state.update(clear, now: 1, pointerInside: true)
        XCTAssertEqual(state.update(clear, now: 2, pointerInside: true), alternate)
        XCTAssertEqual(state.update(clear, now: 3, pointerInside: false), alternate)
        XCTAssertEqual(state.update(clear, now: 3.14, pointerInside: false), alternate)
        XCTAssertEqual(state.update(clear, now: 3.16, pointerInside: false), home)
        XCTAssertNil(state.update(.init(ideal: home, available: nil, currentIsClear: false), now: 4, pointerInside: true))
    }
    func testFlickeringObstacleRestartsClearInterval() {
        var state = ReflowState()
        let blocked = PlacementDecision(ideal: home, available: alternate, currentIsClear: false)
        let clear = PlacementDecision(ideal: home, available: home, currentIsClear: true)
        _ = state.update(blocked, now: 0, pointerInside: false)
        _ = state.update(clear, now: 1, pointerInside: false)
        _ = state.update(blocked, now: 1.1, pointerInside: false)
        XCTAssertEqual(state.update(clear, now: 1.3, pointerInside: false), alternate)
        XCTAssertEqual(state.update(clear, now: 1.51, pointerInside: false), home)
    }
    func testUnknownExperimentalBackoffAndReset() {
        var state = ReflowState()
        for delay in [1.0, 2.0, 4.0, 4.0] {
            XCTAssertNil(state.update(.init(ideal: nil, available: nil, currentIsClear: false), now: 0, pointerInside: false))
            XCTAssertEqual(state.retryDelay(now: 0, experimental: true), delay)
        }
        state.reset()
        XCTAssertEqual(state.update(.init(ideal: home, available: home, currentIsClear: false), now: 1, pointerInside: false), home)
    }
    func testUnverifiedNativeCandidateUsesUnknownBackoff() {
        var state = ReflowState()
        for delay in [1.0, 2.0, 4.0] {
            XCTAssertNil(state.update(.init(ideal: home, available: nil, currentIsClear: false, alternativeReason: .unverifiedSurface), now: 0, pointerInside: false))
            XCTAssertEqual(state.retryDelay(now: 0, experimental: true), delay)
        }
    }
    #if DEBUG
    func testObservationDurationExcludesFocusPauses() {
        var clock = VerificationClock(now: 0, initialActiveSeconds: 0)
        clock.advance(now: 1, active: true)
        clock.advance(now: 10, active: false)
        clock.advance(now: 20, active: false)
        clock.advance(now: 21, active: true)
        XCTAssertEqual(clock.activeSeconds, 1)
        clock.advance(now: 22, active: true)
        XCTAssertEqual(clock.activeSeconds, 2)
        XCTAssertEqual(clock.pausedSeconds, 20)
    }
    #endif
    func testElectronActivationIsScopedToEnabledIncompleteProcessSession() {
        var preparation = ElectronPreparation()
        XCTAssertFalse(preparation.shouldActivate(session: "pid:launch", enabled: false, incomplete: true))
        XCTAssertFalse(preparation.shouldActivate(session: "pid:launch", enabled: true, incomplete: false))
        XCTAssertTrue(preparation.shouldActivate(session: "pid:launch", enabled: true, incomplete: true))
        XCTAssertFalse(preparation.shouldActivate(session: "pid:launch", enabled: true, incomplete: true))
        XCTAssertTrue(preparation.shouldActivate(session: "pid:next-launch", enabled: true, incomplete: true))
    }
}
