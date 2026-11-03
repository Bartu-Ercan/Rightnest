# Changelog

## Unreleased — Preview 5 candidate / build 6

- Separate primary and temporary placement; restore the primary corner after verified clearance, with pointer/press protection.
- Replace repeated polling with notification-driven one-shot scheduling, bounded layout reuse and experimental backoff.
- Prepare incomplete Electron accessibility trees once per process session; preserve application opt-outs.
- Group applications as priority, system and experimental, with the last measured inspection result.
- Add deterministic reflow tests and debug-only latency, occlusion, CPU and long-session verification. Release gates remain pending; see docs/STATUS.md.

## 0.1.0 Preview 4 — native toolbar compatibility

- Recognize native Chromium tab-strip filler and scoped WhatsApp navigation spacers; correct disjoint native hit-test reports without accepting real button overlap.
- Keep safe anchors, coalesce content queries, filter stale AX observers, retry temporarily missing focus data, and avoid unchanged native-control redraws.
- Add measured outside-window shelf fallback; no automatic window resizing or content overlap.
- Refine settings with Overview/Applications navigation, app icons/search, explicit compatibility wording and build number.
- Safari passed a 30s visibility/action fixture; WhatsApp passed read-only foreground visibility, with actions still unverified. Chrome fixture evidence and remaining release gates are in docs/validation.md.
- Add scoped hit geometry, detached placement and native-hover checks. No new runtime dependency.

## 0.1.0 Preview 3 — automatic discovery

- Evaluate all identified regular apps without a name allowlist; retain strict window capability/geometry checks and opt-outs.
- Add compact 66 pt placement with 22×26 pt buttons; Preview's disposable PDF action test now passes.
- Add semantic yellow/green/red hover fills, contrasting symbols and reset on hide/disable/exit.
- Add dynamic application choices to Settings and menu; bound retry frequency on hidden layouts.
- Add native offscreen hover/layout checks and eligibility regressions. Blender remains unverified.

## 0.1.0 Preview 2 — 2026-11-02

- Add limited Safari and Finder support after disposable-window action verification.
- Search verified titlebar gaps in the right half; traverse native split/tab groups and measure native text ink without reading text.
- Stabilize fit/restore around native tiling and delayed geometry application.
- Add 7 regression checks (41 total) and an explicit original-plan audit.
- Chrome/Preview and broader release gates remain incomplete.

## 0.1.0 Preview 1 — 2026-11-02

- Renamed the product from Starboard to Rightnest; retained internal bundle/signing identity for continuity.
- Changed middle control from full screen to fit/restore, including display selection and restore clamping.
- Added serial actor-owned AX inspection, notification-driven invalidation and a one-second fallback.
- Added exact-overlay occlusion validation, window identity checks and stale-result cancellation.
- Added menu-bar onboarding completion, app exclusions, optional login startup, Turkish/English UI and close hover feedback.
- Added core geometry/occlusion checks, updated disposable TextEdit integration test, local DMG packaging and macOS CI configuration.
- Confirm close/minimize outcomes from window state rather than AX acknowledgement alone.
- Kept external support restricted to TextEdit. General beta, clean-user installation and long-duration validation remain gated.
