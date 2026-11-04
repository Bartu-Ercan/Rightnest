# Safari / Chrome stability acceptance

Accepted user plan, 2026-11-03. Candidate target: Preview 5 / build 6. This is a gate list, not a list of passed tests.

## Scope

1. Safari and Chrome normal windows: placement, minimize, fit, restore and close.
2. Finder, Preview and System Settings normal windows.
3. Other regular apps, including Discord, attempted automatically; exclusions always win. Listing is not verification.
4. Verified native space, then clear outside shelf, else hide. Never resize a target to create space. True full screen, modal windows and open/save sheets are excluded.

## Engine requirements

- Distinguish ideal/temporary placement and alternative reason. Return after 200 ms continuous clearance; hold while hovered/pressed and 150 ms after pointer exit. Unsafe placement hides immediately. No movement animation.
- Focus/window changes inspect immediately; geometry hides and settles for 80 ms. Transient probes: 100 ms for five seconds, then 250 ms. Clear-area return uses its exact remaining deadline.
- Normal layout/capability caches last at most one second. Light checks validate identity, geometry and surfaces. Unknown experimental layouts back off 1/2/4 seconds; new focus/window/content events interrupt the wait.
- Queries remain serial and bounded; discard cancelled/stale work. Revalidate every action independently.
- Incomplete Electron trees: documented AXManualAccessibility once per enabled process session, then 100/300 ms retries. Never grant system permission or accept unknown empty groups. Keep native Chromium/WhatsApp exceptions scoped.
- Settings: priority/system/experimental groups, latest inspection result and opt-outs. Preserve A Corner, native styling and yellow/green/red hover.

## Automated gates

- Obstacle/clearance/return, flicker, hover/exit hold, unsafe placement, reset and unknown backoff.
- Normal/compact/outside ordering and real control collisions.
- Late/missing Electron tree and disabled/cancelled preparation.
- Permission/focus/window/geometry changes and stale results; manual fit restoration.
- Full-Xcode CI tests, native hover checks, arm64 release/signature and absence of developer entrypoints.

## Interactive and performance gates

- At least 30 minutes each Safari/Chrome, with separate narrow/wide/tab/toolbar/menu checks and all four window operations.
- 20 actual volume/brightness indicator cycles per browser; synthetic panels are additional evidence only.
- Appearance after settled geometry: p95 <=300 ms with healthy AX responses.
- Return after obstacle removal: <=500 ms when not hovered.
- No wrong-window action or spontaneous movement with no obstacle.
- Normal warmed service CPU: mean <1% of one core, measured with cumulative CPU time and stated configuration.
- 60-second 5 Hz title-change CPU: mean <=5%. Preserve failed measurements.
- Finder/Preview/System Settings basic actions; Discord visibility, placement and actions recorded separately. Do not act on personal documents/chats.
- Different Space alone is not isolation. Preparation and action phases cancel on unexpected focus/fixture changes. Passive observation may pause without refocusing, excluding paused and transition time; exact fixture verification is required to resume. Interrupted continuous CPU workloads are invalidated. Use an uninterrupted interval or separate test account/device for those measurements.

## Publication

Publish Preview 5 only after gates pass. Update README, compatibility, validation and STATUS with tested versions, source/configuration and limitations. Validate package signature/architecture and downloaded checksum. Current results and open gates: STATUS.md and verification-preview5.json. Original broad-beta obligations remain in plan-audit.md.
