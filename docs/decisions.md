# Architecture and decisions

## Product boundary

Rightnest adds controls; it does not move/remove foreign application controls or reflow their titlebars. Supported public AX/AppKit APIs only. Unknown/occupied geometry rejects placement. No screenshot analysis, injection, privileged helper, account, backend or telemetry.

One repository root: `~/Desktop/vibecoding/Rightnest`. Shared skills/tooling remain global. Installed app copies belong in Applications. The user chose Rightnest after a macOS app named Starboard was found. Internal bundle ID and local signing identity remain unchanged for permission continuity; public naming is separate from this implementation detail.

## Native architecture

Swift 6 / SwiftPM, macOS 13 API baseline, Apple Silicon initial target, no third-party runtime dependencies.

- SwiftUI renders onboarding/settings/menu. An AppKit-owned settings window is presented on first launch or explicit request, so completing onboarding leaves only the menu item.
- AppModel owns UI state and lifecycle. Generation counters and task cancellation discard stale inspections. Permissions/preferences are independent.
- WindowObserver subscribes to focus/window/geometry notifications on the main run loop. Callbacks invalidate/hide, then debounce inspection by 140 ms. Registration and focused-window subscription have short timeouts.
- WindowEngine serializes AX queries in an actor. AX objects never cross into UI state; snapshots contain IDs, geometry and capabilities. A one-second fallback handles missed notifications. Unsupported/paused states do not inspect hierarchies.
- AccessibilityClient bounds individual requests and recursive traversal (100 nodes, depth 7, 120 ms inspection deadline, plus current in-flight request). Timeouts reject, never mean blank.
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
