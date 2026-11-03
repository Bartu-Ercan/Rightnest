# Resume here — Rightnest

Root: `~/Desktop/vibecoding/Rightnest`. Rightnest / A Corner identity. Native SwiftUI + AppKit + serial AX actor, no runtime dependencies. Extra right controls; originals remain. Minimize → fit/restore → close; yellow/green/red hover. Apple Silicon, MIT, GitHub Releases, stable local signing; no paid Developer ID/notarization, account, backend, telemetry or updater. Historical bundle ID/certificate storage intentionally retained.

## Current state (2026-11-04)

- Branch: `codex/feasibility`. Latest source a73e16f (CI 41727040231 passed: 21 XCTest, 92 standalone, 24 native, external monitor compile and release validation). Engine is c259556; SettingsView rendered/AX-verified. Check `git status` before editing.
- Published version is still **Preview 4 / build 5**: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Preview 5 has NOT been uploaded or approved.
- Installed `~/Applications/Rightnest.app` is **optimized DEBUG instrumentation / build 6**, source a73e16f, running the Chrome browser verifier. Never distribute this measurement copy. Rebuild --release for delivery; public Preview 5 remains gated.
- `dist/Rightnest-0.1.0-preview-arm64.dmg` is the separately rebuilt production-configuration candidate (c259556). Package image/signature/arm64/debug-entrypoint exclusion/checksum passed. Earlier candidate read-only mount/icon/Applications-link/build checks passed; repeat mount check after final changes. No candidate browser-download/clean-user proof or public checksum-download check exists.
- Current accepted scope/gates: [browser-stability-plan.md](browser-stability-plan.md). Original broader plan remains incomplete: [plan-audit.md](plan-audit.md).

## Implemented candidate behavior

Ideal and temporary placement are separate, with obstruction/unverified/missing-native-space reasons. Return after 200 ms continuous clearance; no optional relocation while hovered/pressed or within 150 ms of pointer exit. Unsafe space hides. Exact return deadline avoids extra polling delay. Unknown app surfaces do not cause indefinite fast obstruction polling.

One-shot scheduling replaces repeating polling: focus/target immediate, geometry 80 ms, content/nonfocused-window creation soft revalidation; normal visible light checks every one second with at-most-one-second layout/capability data, transient probes 100 ms for five seconds then 250 ms, unknown experimental layouts 1/2/4 seconds. Actor queries stay bounded; generation/cancellation guards discard stale results. Clicks always use fresh validation.

Electron AXManualAccessibility is attempted once per enabled incomplete process session; retry at 100/300 ms. Disabled/read-only-audit/cancelled work does not trigger it. Top-strip traversal remains strict; native Chromium and WhatsApp exceptions are scoped. Settings group priority/system/experimental and show the latest inspection result. No new theme/motion/runtime dependency.

Do not restore blanket WindowServer bounding-box rejection: transparent Dock carrier windows can report huge bounds. Exact visible own-overlay checks still require AX/WindowServer ordering; other own windows and actual foreign hits are not ignored.

## Evidence: current candidate

Compact persistent record: [verification-preview5.json](verification-preview5.json). Raw reports/logs under ignored `.build`; no personal content in notes.

- CI 41720443181 / source 8848014 PASSED: 21 XCTest, 92 standalone, 24 native hover/layout combinations, arm64 release/signature/debug-entrypoint exclusion. b6771d5 CI 41721442223 PASSED the same 21+92+24/release checks. The new external monitor needs the next CI compile check. Local latest 92 standalone +24 native checks passed.
- Safari smoke3 / runtime 2b81726: 60-second total fixture session, 355 visible stable samples; minimize/restore/fit/restore-frame/close PASSED. 50 geometry samples p95 207.9 ms; 20 synthetic occlusions max return 437.7 ms. Earlier smoke failures retained, not counted as passes.
- Safari final1800 / runtime 2b81726: recorded 681s /6250 visible samples, then STOPPED because foreground became Codex. Empty action trace, no actions sent. Not a 30-minute pass. Geometry p95 213.5 ms; 20 synthetic occlusions max return 372.3 ms; 60s 5 Hz stress CPU 3.90% (passes <=5). Five instrumented idle windows mean 1.7426% (FAIL <1).
- Chrome first1800 failed during initial geometry benchmark; next short attempt stopped during initial resize settling, no actions sent. The verifier's fixed-origin expectation was corrected to track actual settled right-edge geometry.
- Chrome geometry diagnostic / runtime core f2dbe31: 30s /287 visible samples and all window actions PASSED. Held/fresh AX references agreed during stable preparation; no stale-reference cause is claimed. Verifier now waits for 500 ms continuous stable preparation geometry.
- Normal unoptimized debug service, static Chrome Guest fixture: 30s warmup +five 60s windows, mean 1.2119% (FAIL <1). `.build/measure-p5-chrome-idle/result.json`. This is separate from the 10 Hz AX verifier result; neither failure is hidden.
- Actual OS volume/brightness cycles: NOT VERIFIED. CUA `XF86AudioLowerVolume` returned keyNotFound. Synthetic panels do not satisfy that gate. No system volume setting was changed by the failed key attempt.

## Current verification / next immediate step

Actual release CPU after one-second fallback PASSED: `.build/measure-p5-release-idle-1s/result.json`, 30s warmup +five 60s windows, mean 0.5978%, RSS 55904→24464 KiB. Runtime c259556. This closes this host/workload's normal idle CPU gate, not a one-hour or multi-device gate. Failed baseline mean 1.0273% and all instrumented failures remain in verification-preview5.json.

Production DMG c259556 was mounted read-only: strict signature, arm64, build 6, icon, Applications link, image checksum all passed. Current dist/Rightnest.app is being replaced by optimized DEBUG instrumentation for browser verification; the DMG stays production. Installed app is being replaced with that local profiling binary; do not distribute it.

CUA direct own-panel coordinate click opened Rightnest Settings, so physical pointer/composite verification is NOT counted as passed. Settings rendered review revealed uneven application row widths and missing app-name labels on switch AX elements. Working-tree SettingsView fix fills row width and explicitly labels switches with app names / last-check hints. No engine change. Initial rendered/AX verification confirmed app-name descriptions and full-width rows; toggle controls also needed trailing alignment, now adjusted with a separate expanding text column. Final rendered settings inspection PASSED: full-width rows, trailing-aligned native toggles, app-name AX descriptions and last-check hints. Close Settings, prepare Chrome Guest fixture, then run the 1800s verifier. CUA can leave menus open: use a fresh full AX snapshot and the exposed Cancel action rather than assuming Escape dismissed it.

## Next actions

1. Normal release idle CPU gate is passed for this host/workload. Preserve failed baselines; continue browser/interaction gates.
2. In a user-authorized uninterrupted interval, retry Chrome and Safari 1800-second fixture sessions using current settled-geometry verifier. The previous 681s Safari and 30s Chrome reports do not satisfy the 30-minute gates. Record actual source/configuration. `--stability-seconds 1800` measures geometry, synthetic occlusion, visibility and actions; its own 10 Hz AX work contributes CPU overhead.
3. Actual 20 OS HUD cycles per browser remain blocked on available input/testing method; no unsupported key workaround or false synthetic substitution. Native Control Center UI may provide additional occlusion evidence but is not automatically equivalent to auto-expiring keyboard HUDs.
4. Separate narrow/wide/tab/toolbar/menu/pointer checks; Finder/Preview/System Settings basics; Discord visibility/placement/actions separately. No actions on personal documents/chats. Browser modal save/open sheets and true full screen stay excluded; verify hiding rather than support.
5. Final CI, production package mount/signature/arm64/debug exclusion, normal install, downloaded checksum and truthful docs. Publish Preview 5 only after accepted gates pass. Original clean-user/older-OS/multi-display/Spaces/one-hour/broad-beta gates remain open.

## Safety and continuity

User approved a Safari/Chrome test interval in this chat. Use only separately prepared local single-tab Safari / Chrome Guest fixtures. A different Space is not process/focus isolation. Stop on unexpected focus/fixture change. Do not close personal browser windows/chats. Avoid new foreground windows while the user studies except authorized tests. Existing local signing identity must be retained; never reset TCC, regenerate keys or print secrets. No new permission is silently granted.

Earlier Preview 4 detailed evidence and limitations remain in validation.md / compatibility.md. Earlier WhatsApp evidence is visibility only (42 consecutive samples /51s at1072×600); no chat-window actions. Blender untested/not installed. App eligibility never means verified compatibility. Keep all project assets, code, scripts and decisions in this root.

After reinstalling/restarting Rightnest, reclaim it through `cua.getApp` before interacting; old bindings can become inactive. Use fresh full AX snapshots when an open menu is missed by diff output; use exposed Cancel actions.

FAILED before observation: `.build/verify-p5-chrome-final1800` / --stability-seconds 1800, source 11d03e0 optimized DEBUG, engine c259556. Started after final settings review; prepared single-tab Chrome Guest local stability fixture. Do not use CUA/app activation during this session. Read progress/result files only. No completed 30-minute pass yet. Next Safari needs its own uninterrupted 1800s session.

Chrome final1800 failed before observation/actions: "Control panel did not appear", foreground Chrome, granted permission, repeatedly measured native tab spacer but No safe titlebar or outside space. No 1800s session is currently running. Working DEBUG diagnostic now records the first rejected native candidate and AX owner/role. Next: compile/install optimized diagnostic and run a short owned Chrome fixture; inspect precise rejection before changing safety logic.

Diagnostic retry `.build/verify-p5-chrome-rejection` unexpectedly PASSED 30s /287 visible samples and all actions with no behavior change (only DEBUG rejection logging added). Therefore the preceding NoSafe rejection is intermittent and not yet explained. Do not add a guessed Chrome exception. DEBUG now retains up to 20 changed rejection records and records same-bundle process IDs at test startup. Next clean Guest 1800s attempt must capture any failure owner/role.

ACTIVE NOW (replacement for failed final1800): `.build/verify-p5-chrome-traced1800`, optimized DEBUG, engine c259556 / SettingsView 11d03e0 plus DEBUG-only rejection history. Single same-bundle process 44758 confirmed at startup. Geometry benchmark PASSED: 50 samples p95 201.6ms. Twenty synthetic cycles/1800s observation still running. Do not use CUA/app activation or reinstall. Earlier final1800 remains a failure; no safety exception was added. Latest DEBUG source retains 20 changed rejection records with native candidate/AX owner bundle/role, to diagnose any intermittent failure.

Reference host: Mac14,2 /Apple M2 /8 GiB RAM, macOS 27.0 (26A428). Current traced Chrome metrics: geometry p95 201.6ms; 20 synthetic occlusions max return 355.9ms; 60s 5 Hz stress CPU 1.737%. Five instrumented idle windows average 1.226% (not normal-service CPU; keep separately). Normal production release external mean remains 0.5978% PASS. Long session is still in progress, not complete.

WORKING SOURCE (not installed during Chrome soak): ControlPanel now retains the press-origin callback while a mouse button is held and clears callbacks on hide. A late callback cannot inherit a newly shown window's handler; moving during the held gesture hides/cancels it. Three offscreen native NSButton routing checks PASSED, 24 hover/layout checks still PASSED, SwiftPM debug build PASSED. No new UI/permission/dependency. After current Chrome session finishes, install updated optimized instrumentation, run a short Chrome action regression, then Safari 1800s. Do not restart the active a73e16f session to install this isolated pointer-routing guard.
