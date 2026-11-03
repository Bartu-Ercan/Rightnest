# Architecture and decisions

## Product boundary

Rightnest adds controls; it does not move/remove foreign application controls or reflow their titlebars. Supported public AX/AppKit APIs only. Unknown/occupied geometry rejects placement. No screenshot analysis, injection, privileged helper, account, backend or telemetry.

One repository root: `~/Desktop/vibecoding/Rightnest`. Shared skills/tooling remain global. Installed app copies belong in Applications. The user chose Rightnest after a macOS app named Starboard was found. Internal bundle ID and local signing identity remain unchanged for permission continuity; public naming is separate from this implementation detail.

## Native architecture

Swift 6 / SwiftPM, macOS 13 API baseline, Apple Silicon initial target, no third-party runtime dependencies.

- SwiftUI renders onboarding/settings/menu. An AppKit-owned settings window is presented on first launch or explicit request, so completing onboarding leaves only the menu item.
- AppModel owns UI state and lifecycle. Generation counters and task cancellation discard stale inspections. Permissions/preferences are independent.
- WindowObserver subscribes to focus/window/geometry notifications on the main run loop. Focus/target changes invalidate immediately; geometry changes hide then settle for 80 ms. Content/title and nonfocused window-created notifications revalidate without hiding. Registration and focused-window subscription have short timeouts.
- WindowEngine serializes AX queries in an actor. AX objects never cross into UI state; snapshots contain IDs, geometry and capabilities. One-shot probes replace polling: normal visible geometry/surface checks every one second reuse at most one-second layout data; transient blockers use 100 ms for five seconds then 250 ms, with an exact clear-area return deadline. Unknown experimental layouts back off 1/2/4 seconds. Unsupported/paused states do not inspect hierarchies.
- AccessibilityClient bounds individual requests and recursive traversal (160 nodes, depth 16, 400 ms total titlebar inspection deadline, plus current in-flight request). Timeouts reject, never mean blank.
- ControlPanel is a nonactivating AppKit panel with actual accessible buttons. Unchanged snapshots do not trigger hide/show. An AX hit on the exact visible overlay is backed by WindowServer ordering below it; other own windows and same-app overlapping windows are not ignored. Pixel-free metadata is heuristic, not a universal no-overlap proof.
- Every action revalidates focus, permission, window identity and geometry. The panel hides before dispatch. Only transient own-panel occlusion is retried, at most six times at 50 ms. An action in progress suppresses ordinary refresh; identity checks continue inside the worker.

## Fit and restore

The middle control fits to the display with largest intersection, using its visible frame. Screen-coordinate conversion uses the primary display's top edge and logical points, including negative coordinates. Restore frames are bounded to 32 in-memory window records. Manual geometry changes invalidate them; removed displays cause restoration to clamp into an available visible frame.

Shrink, position and final size writes are separate asynchronous phases because a target may clamp size using its previous origin. Acknowledgement is not proof: resulting geometry must match. If the target constrains size, report that outcome and preserve a recovery record when possible. Full-screen targets and modal sheets remain unsupported. Close uses AXPress and leaves save prompts to the target app.

## Permission and lifecycle

One explicit request action, no automatic OS permission prompt. Live trust checks happen at activation and at most once per second. Persisted history only chooses explanatory copy. Loss of trust hides controls and cancels further actions. Setup can be skipped to the menu bar; the own demo remains available. Login startup uses SMAppService and is off by default. System registration errors are shown.

## Distribution

MIT. No paid developer membership. Local certificate/ad-hoc builds are not Developer ID signed or notarized; Gatekeeper limitations are documented rather than bypassed. Local key material stays in an isolated keychain outside Git. CI is read-only-permission build/test and produces ad-hoc artifacts. Versioned DMGs are built locally; publication is a separate gate. No automatic updater; Releases opens a configured HTTPS GitHub URL.

Broad beta requires TextEdit plus at least two additional daily-use apps verified in actual interaction flows. Until then, the product remains a developer preview. See compatibility.md and validation.md for evidence and open gates.

## Preview 2 compatibility refinement

Inspect the complete relevant native layout once, then test candidates from the far right toward the window midpoint. Native split/tab groups are traversed rather than treated as controls. Unknown empty groups remain obstacles. Exact text character bounds (at most 4096 characters, without reading text) distinguish title ink from unused native label space; invalid/out-of-label bounds fall back to the full rectangle. Hit testing accepts only the exact already-inspected background node or a native toolbar whose returned WebArea has valid disjoint geometry. No broad role-based exemption is applied.

Fit/restore waits for shrink before movement, permits only 0–8 pt native fit margins (1 pt rounding overflow), confirms stable geometry, and makes at most two bounded fit reconciliation writes. Restoration retains the original geometry tolerance. Revalidation runs before each write. Timeouts may retry while unknown layouts/collisions continue to reject. Safari and Finder basic action fixtures passed; broader validation remains open.

## Preview 3: automatic capability-based discovery

Remove the three-name eligibility gate; retain every geometry, AX action, target identity and occlusion check. Identified regular apps are considered automatically; the app itself, background agents and user exclusions are rejected before AX inspection. This is discovery, not a new universal compatibility guarantee. Settings show running apps plus known names and persisted exclusions. Legacy external-control preference storage remains for migration.

Prefer the existing 102×26 pt strip, then 66×26 pt with 22 pt buttons; never shrink below the chosen pointer-size floor. Reuse the same NSButtons and native resizing. Hidden/unsupported layouts retry on a three-second fallback while focus/window notifications bypass the delay; visible overlays retain one-second rechecks. Hover uses semantic yellow/green/red fills with dark labeled symbols, no scaling/motion, and clears on hide/disable/exit. No runtime dependencies were added.

## Popular apps and outside shelf

User accepted an external shelf on 2026-11-02 when titlebar geometry cannot be verified. Desktop geometry and on-screen surfaces constrain it; no automatic resizing or content overlay. See design-popular-apps.md. Content/title notifications now revalidate without hiding, while geometry/target changes still hide immediately. Native Chromium trailing-tab-strip recognition is structural and narrow; arbitrary empty groups remain rejected.

## Preview 5 candidate: browser priority and reflow

Safari/Chrome are priority; Finder, Preview, System Settings and TextEdit are system apps; other eligible apps are experimental. These labels do not certify compatibility. Settings retain exclusions and show the latest actual inspection outcome.

`PlacementDecision` separates structurally eligible ideal space from currently verified available space and records obstruction, unverified-surface or missing-native-space reasons. Unverified surfaces do not trigger indefinite fast obstruction probes. `ReflowState` owns monotonic-clock hysteresis without AX/UI objects: keep the home anchor when temporarily obstructed, return after 200 ms continuous clearance, defer while hovered/pressed and 150 ms after pointer release, and hide immediately if current space is unsafe. No movement animation or target-window resizing creates room.

Layout/capability caches last at most one second and are discarded on identity, geometry or relevant content changes. Every action still performs fresh target/capability/geometry and surface validation. AX remains actor-owned; UI generations discard cancelled/stale results.

For detected Electron bundles with incomplete trees, enable only documented `AXManualAccessibility` once per process launch session and recheck at 100/300 ms. Disabled apps and explicit read-only audits never trigger this. [Electron documentation](https://raw.githubusercontent.com/electron/electron/main/docs/tutorial/accessibility.md). Native Chromium/WhatsApp geometry rules remain narrowly scoped.
