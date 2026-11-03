# Resume here — Rightnest

Root: ~/Desktop/vibecoding/Rightnest. User chose Rightnest / A Corner logo. Native SwiftUI + AppKit + serial Accessibility actor. Extra right-side controls; originals retained. Order: minimize, fit/restore, close. Apple Silicon, MIT, GitHub Releases, local stable signing, no paid Developer ID/notarization. No accounts/backend/telemetry/automatic updater. Historical bundle ID/signing storage deliberately retained.

## Preview 5 implementation checkpoint (2026-11-03, not released)

Safari/Chrome priority plan is active. Current working source separates ideal/temporary placement, 200 ms clear hysteresis and hover/150 ms release hold; timer-based light probes use cached layouts (maximum 1 second), geometry debounce 80 ms, transient probes 100/250 ms, unknown experimental backoff 1/2/4 seconds. Electron activation is scoped once per enabled incomplete process session, with 100/300 ms retries. Settings groups and last inspection statuses are implemented. All changes remain candidates until real verification.

Debug verifier now supports `--stability-seconds 1800`, content-free progress JSON, geometry latency, 20 synthetic occlusion cycles, cumulative CPU windows and disposable-fixture actions. Synthetic panels do not satisfy real system volume/brightness HUD gates. New five XCTest cases cover return hysteresis, hover safety, flicker, backoff and Electron session activation. Local Swift build passed after a Swift 6 isolation fix. New local checks, CI and interactive verification are pending. Build 6 is a candidate, not a published Preview 5.

User approved a Safari/Chrome test interval in this chat. Use only separately prepared disposable windows; cancel if foreground/fixture identity changes. Real 30 minutes per browser and 20 actual system HUD cycles per browser remain unexecuted. Next: run local checks, build/install signed debug candidate, smoke-test measurements, then start long browser sessions. Do not publish until acceptance gates are evidenced.

## Current delivery (2026-11-03)

Source code: 8682e26. Final CI https://github.com/Bartu-Ercan/Rightnest/actions/runs/41529100917 PASSED: 15 XCTest cases, 64 standalone checks, 24 native hover/layout combinations and arm64 release/bundle validation. Preview 5 candidate changes are described above; the following delivery record describes Preview 4 only. Preview 4 / build 5 PUBLISHED: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4 (release target 8643df3; runtime code identical to CI-tested 8682e26). Public DMG and checksum were re-downloaded to .build/download-preview-4 and SHA-256 matched.

Build-5 DMG was regenerated with updated installation notes. Read-only mount, strict signature, arm64, icon, Applications link, image verification and SHA passed. RELEASE copy installed at ~/Applications/Rightnest.app, strict signature verified, build 5, launched -g without test flags. Existing signing identity is unchanged. This does not prove clean-user browser-download/update permission continuity.

## Actual app evidence

- Chrome 156.0.8078.79: prepared single-tab Guest fixture passed all actions plus 30 visible samples over 3 seconds (verification-chrome.json). A final 30-second rerun stopped before actions when the user’s foreground app became Safari; empty actionTrace in .build/verify-chrome-release-final. Do not count that interruption as a pass or force another foreground test while the user studies.
- Safari 27.0: title-changing fixture passed 300 visible samples over 30 seconds, minimize/restore/fit/restore-frame/close (verification-safari.json). Earlier failed native restore attempts were corrected by bounded missing-focus retries and stale AXObserver callback filtering.
- WhatsApp 26.38.74: native navigation-spacer visibility verified at 1072×600. First startup sample hidden, then 42 consecutive visible samples over 51 seconds (verification-whatsapp.json). No minimize/fit/close was sent to the personal chat window; WhatsApp actions, maximized layout and call/dialog flows remain unverified. No user-input request remains necessary for basic visibility.
- Earlier TextEdit/Finder/Preview action evidence remains in verification-*.json, with source/time limits in validation.md. Blender is not installed/tested. App eligibility/listing is never a compatibility guarantee.
- Normal debug service without audit/verifier: 0.14 CPU seconds over 20.015 wall seconds, ~0.699% of one core, end RSS 32,400 KiB. .build/performance-normal-service.json. Not a one-hour or release benchmark. Separate startup/5Hz title stress ps-%CPU samples were higher (5.895%, 6.845%); different workloads, not a controlled improvement comparison.

## Current behavior and rationale

Generic native inspection remains strict. Chromium native tab-strip filler is structurally recognized. WhatsApp WDSNavigationBar uses the measured spacer row and complete native-bar subtree, avoiding recycled scroll-cell bounds. Out-of-bounds hit corrections require the same target window, fully measured native scope and valid disjoint bounds; overlapping buttons remain blockers. A fresh per-inspection WindowServer snapshot supports exact-own-overlay/outside-space checks. Foreign AX hits can prune measured covering regions only for that inspection.

Preview 4 used a 300ms visible / 1s hidden throttle. Preview 5 replaces it with the one-shot schedule described above. Content/title notifications revalidate without hiding; geometry/focus changes hide immediately. Stale observer sources/results are discarded. Missing native focus is retried briefly; real PID/window changes cancel. Preview 4 pinned valid prior anchors; Preview 5 separates ideal and temporary anchors for recovery. Panel joins Spaces and ignores cycling; actual Space-transition matrix remains untested. Native controls are not redrawn/recreated for unchanged state.

User accepted an outside-window shelf when titlebar safety cannot be verified. It must fit the usable display and avoid other windows; never silently resize the target or cover its content to create room. Screen-filling/crowded desktops may have no outside space.

Settings: Overview/Applications sidebar, A Corner window illustration, semantic surfaces, searchable app icons/exclusions, native focus/controls and visible build number. Existing yellow/green/red hover retained. Dark rendered UI, search and exclusion off/on were inspected. Nashi source/design/window-management/packaging/test review: design-popular-apps.md; no code/artwork copied or new runtime dependency.

## Next work / limits

1. Preview 4 distribution is complete. Next work is actual isolated app/edge-case verification, not a claim of broad-beta completion.
2. Actually isolated account/device: physical external-panel pointer/composite checks, fuller Chrome/Safari/WhatsApp toolbar/tab/dialog cases and WhatsApp actions. A different macOS Space is not process/focus isolation. Do not control personal documents/chats. User studies in the other desktop; avoid foreground windows/new permission prompts.
3. Multi-display/Spaces/Mission Control/Stage Manager, sleep/wake, one-hour CPU/RSS soak, clean-user browser-download/install/update/remove and older macOS coverage. Broad beta/stable gates remain open; see plan-audit.md.

All project code/assets/docs stay in this root. Shared skill sources remain global under ~/.codex/skill-sources. Use relevant installed skills selectively; reference material is not a configured service. Keep evidence and failures explicit when resuming; never turn planned verification into a pass.

### Preview 5 verification in progress

- Local 87 standalone + 24 native hover checks passed before the latest timing refinement; next count is 88 standalone. Debug build 6 installed with the existing stable local identity; AX grant remains valid in the verifier.
- `.build/verify-p5-safari-smoke` failed to show a panel during an activating launch. Repeated with background launch (`open -g -n`), the panel appeared. Do not count the first failure as an app compatibility pass.
- `.build/verify-p5-safari-smoke2`: 50 geometry samples p95 314.7 ms (FAIL <=300), 20 synthetic occlusion cycles maximum return 632.6 ms (FAIL <=500). Stable observation subsequently detected a disappearing panel, no actions dispatched. Investigating incidental window-created invalidations. These are synthetic panels, not actual OS HUD cycles.
- Refinement: a clear transient area schedules the remaining clear/pointer deadline directly, instead of adding repeated probe intervals; nonfocused window-created events trigger reinspection without immediately hiding. Measurement polling reduced from 100 ms to 10 ms for latency phases only. Real 30-minute sessions have not begun.

- Source checkpoint e5dcdba CI 41716615456 PASSED: 20 XCTest, 88 standalone, 24 native hover/layout combinations and arm64 release validation. Later alternative-reason source changes require another CI run.
- Safari smoke3 (`.build/verify-p5-safari-smoke3/result.json`) PASSED disposable actions and 60-second total session: geometry p95 207.9 ms, 20 synthetic occlusion cycles, maximum return 437.7 ms, 355 visible stable-window samples. Actual system HUD gate remains pending.
- First 1800-second attempt intentionally stopped after 217 seconds for the alternative-reason refinement; `.build/verify-p5-safari-1800/interrupted.json` records partial evidence, not a 30-minute pass. Its 60-second 5 Hz CPU mean was 4.04%.
- Final-source session `.build/verify-p5-safari-final1800` now running; progress every five seconds and finite external RSS/process-time sampling every 30 seconds. Do not replace or stop the installed running debug app during this session; separate release packaging is allowed. Latest standalone total is 89.

- Final engine/source 2b81726 CI 41717532496 PASSED (20 XCTest, 89 standalone, 24 native checks, release validation). Candidate DMG built locally, mounted read-only, strict signature/arm64/build 6/icon/Applications-link/image verification/checksum all passed. No public upload or browser-download check has been performed for this candidate.
- Final-session initial metrics: Safari geometry p95 213.5 ms, 20 synthetic occlusions maximum return 372.3 ms, 60-second title stress CPU 3.90%. Still running; no completed long-session pass yet.
- Instrumented idle CPU failed the <1% target: first four 60s windows averaged 1.75%. This process includes the 10 Hz verifier's AX/fixture checks; do not relabel it a normal-service pass. After browser sessions, measure the normal release service separately after warmup; retain both results.
- Working-tree-only refinement: unknown experimental layouts with a structural ideal but no verified placement now also back off 1/2/4 seconds. Three standalone assertions and one XCTest added. This branch is not traversed by the passing visible Safari path. Installed browser test binary remains source 2b81726; do not imply it includes this pending refinement.

### 2026-11-04: test interval interruption and Chrome

Safari final1800 stopped at recorded elapsed 681 seconds / 6250 visible stable-window samples when foreground became com.openai.codex. Empty action trace; no window actions sent. This is an interrupted test, not a 30-minute pass. Five instrumented idle windows averaged 1.7426% (FAIL <1). Normal release-service idle measurement remains required. Compact evidence: verification-preview5.json.

Chrome launched through the native UI into a separate Guest window, exact local fixture verified. Installed debug runtime still 2b81726; `.build/verify-p5-chrome-1800` is now running. Do not interrupt or reinstall the active test process. New source f2dbe31 only changes unknown experimental backoff; CI queued/running, check before delivery.

### Chrome geometry diagnostic and normal CPU measurement

Chrome's initial long attempt `.build/verify-p5-chrome-1800` failed before observation/actions: the native frame settled from the requested dimensions to a different actual frame, invalidating the verifier's fixed-origin expectation. `.build/verify-p5-chrome-actions` stopped during initial resize settling. No actions sent in either failure. After recording fresh/held AX references, `.build/verify-p5-chrome-geometry` PASSED 30s / 287 visible samples and all actions; both AX frame references were identical during settled preparation. This supports a startup-settling cause, not a stale AX-reference claim.

Debug verifier now requires 500 ms continuously stable geometry/panel before observation and computes movement expectations from actual right/bottom geometry rather than assuming size never changes. Added debug-only `--measure-idle` for 30s warmup + five 60s cumulative CPU windows with 1 Hz cached status checks and fixture identity at boundaries; no fixture moves/HUD panels/window actions. Dedicated static window-idle.html avoids timer workload. All new flags remain excluded from release. These latest debug-only changes are not yet committed/CI-tested.
