import CoreGraphics
import RightnestCore

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}
let host = CGRect(x: -1200, y: 50, width: 800, height: 500)
require(Placement.candidate(window: host, rowY: 54, obstacles: [], boundsKnown: true)?.maxX == -408,
        "Negative display coordinates must be supported")
for x in [-450.0, -405.0] {
    require(Placement.candidate(window: host, rowY: 54,
        obstacles: [CGRect(x: x, y: 58, width: 20, height: 20)], boundsKnown: true) == nil,
        "Overlapping and near-overlapping controls must hide the panel")
}
require(Placement.candidate(window: host, rowY: 54, obstacles: [], boundsKnown: false) == nil, "Unknown layout must be rejected")
require(Placement.candidate(window: host, rowY: 160, obstacles: [], boundsKnown: true) == nil, "Content area is not titlebar")
require(Placement.candidate(window: host, rowY: .nan, obstacles: [], boundsKnown: true) == nil, "Non-finite geometry is invalid")
require(Placement.candidate(window: CGRect(x: 0, y: 0, width: 200, height: 300), rowY: 4, obstacles: [], boundsKnown: true) == nil, "Narrow windows must be rejected")
print("PlacementChecks: 7 checks passed")
for trusted in [false, true] {
    for requested in [false, true] {
        for previouslyGranted in [false, true] {
            let expected: PermissionFlow = trusted ? .granted : previouslyGranted ? .revoked : requested ? .waiting : .required
            require(PermissionFlow(trusted: trusted, requested: requested, previouslyGranted: previouslyGranted) == expected,
                    "Permission presentation must follow live trust, not saved preferences")
        }
    }
}
print("PermissionFlow: 8 state combinations passed")

let titlebar = CGRect(x: 100, y: 3, width: 102, height: 26)
let contentBelow = CGRect(x: 0, y: 32, width: 800, height: 500)
require(!Placement.overlapsTitlebar(contentBelow, candidate: titlebar, isLayoutContainer: true),
        "Document content below the titlebar must not create a false collision")
require(Placement.overlapsTitlebar(contentBelow, candidate: titlebar, isLayoutContainer: false),
        "Actual controls still need the safety gap")
require(Placement.overlapsTitlebar(CGRect(x: 0, y: 28, width: 800, height: 500), candidate: titlebar, isLayoutContainer: true),
        "A content container truly intersecting the titlebar must still be rejected")
print("Titlebar obstacle regression: 3 checks passed")

let leftScreen = CGRect(x: -1440, y: 25, width: 1440, height: 875)
let rightScreen = CGRect(x: 0, y: 25, width: 1920, height: 1015)
let original = CGRect(x: -1300, y: 100, width: 800, height: 600)
require(WindowGeometry.screen(for: original, visibleFrames: [rightScreen, leftScreen]) == leftScreen, "Fit must choose the window's display")
let record = RestoreRecord(original: original, fitted: leftScreen)
require(record.destination(current: leftScreen, screens: [leftScreen, rightScreen]) == original, "Restore preserves original frame")
require(record.destination(current: leftScreen.insetBy(dx: 20, dy: 0), screens: [leftScreen]) == nil, "Manual resizing invalidates restore")
let relocated = record.destination(current: leftScreen, screens: [rightScreen])!
require(rightScreen.contains(relocated), "Disconnected display restore stays visible")
let spanning = CGRect(x: -100, y: 100, width: 900, height: 600)
require(WindowGeometry.screen(for: spanning, visibleFrames: [leftScreen, rightScreen]) == rightScreen, "Largest intersection chooses display")
let flipped = WindowGeometry.flip(leftScreen, primaryTop: 1080)
require(WindowGeometry.flip(flipped, primaryTop: 1080) == leftScreen, "Coordinate conversion round trips negative displays")
require(WindowGeometry.screen(for: original, visibleFrames: []) == nil, "No screen means no resize")
require(!WindowGeometry.valid(CGRect(x: 0, y: 0, width: CGFloat.nan, height: 100)), "Invalid geometry rejected")
require(WindowGeometry.clamped(CGRect(x: -200, y: -200, width: 3000, height: 3000), to: rightScreen) == rightScreen, "Oversize restore is clamped")
print("WindowGeometry: 9 checks passed")
let targetFrame = CGRect(x: 0, y: 40, width: 800, height: 600)
let candidate = CGRect(x: 690, y: 44, width: 102, height: 26)
let overlay = Surface(number: 10, pid: 1, layer: 3, bounds: candidate, alpha: 1)
let targetSurface = Surface(number: 20, pid: 2, layer: 0, bounds: targetFrame, alpha: 1)
let blocker = Surface(number: 30, pid: 3, layer: 0, bounds: candidate, alpha: 1)
func surfaceClear(_ rows: [Surface]) -> Bool {
    SurfaceOrder.targetIsDirectlyBelow(rows, overlayNumber: 10, ownPID: 1, targetPID: 2, targetFrame: targetFrame, candidate: candidate)
}
require(surfaceClear([overlay, targetSurface]), "Exact overlay with target below is clear")
require(!surfaceClear([overlay, blocker, targetSurface]), "Foreign window under panel blocks")
require(!surfaceClear([targetSurface]), "Missing overlay cannot be ignored")
require(surfaceClear([blocker, overlay, targetSurface]), "AX-confirmed overlay is not masking surfaces above itself")
require(!surfaceClear([overlay, Surface(number: 31, pid: 1, layer: 0, bounds: candidate, alpha: 1), targetSurface]), "Other own windows are not ignored")
require(!surfaceClear([overlay, Surface(number: 32, pid: 2, layer: 0, bounds: candidate, alpha: 1), targetSurface]), "Other target-app windows block")
require(surfaceClear([overlay, Surface(number: 33, pid: 3, layer: 0, bounds: candidate, alpha: 0), targetSurface]), "Fully transparent surfaces do not block")
print("SurfaceOrder: 7 checks passed")

let searchWindow = CGRect(x: -1000, y: 40, width: 900, height: 600)
let searchCandidates = Placement.candidates(window: searchWindow, rowY: 44)
require(!searchCandidates.isEmpty, "A valid window supplies placement alternatives")
require(searchCandidates.first == Placement.candidate(window: searchWindow, rowY: 44, obstacles: [], boundsKnown: true), "Prefer original far-right position")
require(searchCandidates.allSatisfy { $0.minX >= searchWindow.midX && searchWindow.contains($0) }, "Alternatives stay in the right half and inside window")
require(Placement.candidates(window: CGRect(x: 0, y: 0, width: 200, height: 200), rowY: 4).isEmpty, "Narrow windows must not gain alternatives")
print("Titlebar search: 4 checks passed")
let available = CGRect(x: 0, y: 30, width: 1920, height: 992)
require(WindowGeometry.isFitted(CGRect(x: 3, y: 34, width: 1917, height: 987), inside: available), "Native 3-5pt tiling margins are a successful fit")
require(!WindowGeometry.isFitted(available.insetBy(dx: 20, dy: 20), inside: available), "An undersized window must not count as fitted")
require(!WindowGeometry.isFitted(available.offsetBy(dx: -10, dy: 0), inside: available), "Overflow must not count as fitted")
print("Native fit margin: 3 checks passed")
require(ApplicationEligibility.allows(bundleID: "org.blenderfoundation.blender", isRegular: true, ownBundleID: "self", disabled: []), "New app names must be evaluated without an allowlist")
require(!ApplicationEligibility.allows(bundleID: "org.blenderfoundation.blender", isRegular: true, ownBundleID: "self", disabled: ["org.blenderfoundation.blender"]), "App exclusion must win over automatic discovery")
require(!ApplicationEligibility.allows(bundleID: nil, isRegular: true, ownBundleID: "self", disabled: []), "Unidentified apps must not bypass exclusions")
require(!ApplicationEligibility.allows(bundleID: "agent", isRegular: false, ownBundleID: "self", disabled: []), "Background agents are not window targets")
require(!ApplicationEligibility.allows(bundleID: "self", isRegular: true, ownBundleID: "self", disabled: []), "Own app is not an external target")
print("Application eligibility: 5 checks passed")
let adaptive = Placement.candidates(window: CGRect(x: 80, y: 90, width: 1760, height: 700), rowY: 103)
require(adaptive.contains { $0.width == 66 && $0.maxX < 1049 }, "Compact controls can use a verified gap too small for the ordinary strip")
require(adaptive.allSatisfy { $0.width/3 >= 20 }, "Adaptive controls must not shrink below minimum pointer size")
print("Adaptive width: 2 checks passed")
require(adaptive[0].width == 102 && adaptive[1].width == 66 && adaptive[0].maxX == adaptive[1].maxX, "Try both sizes at the rightmost anchor before moving left")
print("Rightmost-anchor preference: 1 check passed")
