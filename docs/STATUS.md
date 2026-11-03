# Resume here — Rightnest

Root: `~/Desktop/vibecoding/Rightnest`. Rightnest / A Corner identity. Native SwiftUI + AppKit + serial AX actor, no runtime dependencies. Extra right controls; originals remain. Minimize → fit/restore → close; yellow/green/red hover. Apple Silicon, MIT, GitHub Releases, stable local signing; no paid Developer ID/notarization, account, backend, telemetry or updater. Historical bundle ID/certificate storage intentionally retained.

## Current state (2026-11-04)

- Branch: `codex/feasibility`. Latest source checkpoint b6771d5. Check `git status` before editing.
- Published version is still **Preview 4 / build 5**: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Preview 5 has NOT been uploaded or approved.
- Installed `~/Applications/Rightnest.app` is now **production release configuration / build 6**, source b6771d5. Developer entrypoint strings were checked absent before installing; strict signature passed. It is an unreleased candidate, not a gate-approved Preview 5.
- `dist/Rightnest-0.1.0-preview-arm64.dmg` is the separately rebuilt production-configuration candidate (b6771d5). Package image/signature/arm64/debug-entrypoint exclusion/checksum passed. Earlier candidate read-only mount/icon/Applications-link/build checks passed; repeat mount check after final changes. No candidate browser-download/clean-user proof or public checksum-download check exists.
- Current accepted scope/gates: [browser-stability-plan.md](browser-stability-plan.md). Original broader plan remains incomplete: [plan-audit.md](plan-audit.md).

## Implemented candidate behavior

Ideal and temporary placement are separate, with obstruction/unverified/missing-native-space reasons. Return after 200 ms continuous clearance; no optional relocation while hovered/pressed or within 150 ms of pointer exit. Unsafe space hides. Exact return deadline avoids extra polling delay. Unknown app surfaces do not cause indefinite fast obstruction polling.

One-shot scheduling replaces repeating polling: focus/target immediate, geometry 80 ms, content/nonfocused-window creation soft revalidation; normal visible light checks every 500 ms with at-most-one-second layout/capability data, transient probes 100 ms for five seconds then 250 ms, unknown experimental layouts 1/2/4 seconds. Actor queries stay bounded; generation/cancellation guards discard stale results. Clicks always use fresh validation.

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

## Active measurement — do not interrupt

Optimized DEBUG comparison completed: five windows mean 1.0463% (FAIL <1); `.build/measure-p5-chrome-idle-optimized/result.json`, configuration.json records -O +DEBUG. This failure remains evidence.

The installed app was then replaced with the separately built production release (no test entrypoints), launched in background and its three accessible controls verified in the static Chrome Guest fixture through CUA. External read-only `script/measure_service_cpu.swift` is now running as `.build/ServiceCPU <pid> com.google.Chrome .build/measure-p5-release-idle`: progress/result JSON. Thirty-second warmup +five 60s cumulative ps CPU windows; monitor runs outside the measured service. It checks foreground app and visible panel through read-only platform metadata, never activates apps or sends AX actions. No final result yet. Do not replace or stop the running service until complete.

## Next actions

1. Collect actual release-service external CPU result. If it still fails, profile/fix the actual service cost and retain failed baselines. Do not call the normal CPU gate passed from unoptimized or incomplete evidence.
2. In a user-authorized uninterrupted interval, retry Chrome and Safari 1800-second fixture sessions using current settled-geometry verifier. The previous 681s Safari and 30s Chrome reports do not satisfy the 30-minute gates. Record actual source/configuration. `--stability-seconds 1800` measures geometry, synthetic occlusion, visibility and actions; its own 10 Hz AX work contributes CPU overhead.
3. Actual 20 OS HUD cycles per browser remain blocked on available input/testing method; no unsupported key workaround or false synthetic substitution. Native Control Center UI may provide additional occlusion evidence but is not automatically equivalent to auto-expiring keyboard HUDs.
4. Separate narrow/wide/tab/toolbar/menu/pointer checks; Finder/Preview/System Settings basics; Discord visibility/placement/actions separately. No actions on personal documents/chats. Browser modal save/open sheets and true full screen stay excluded; verify hiding rather than support.
5. Final CI, production package mount/signature/arm64/debug exclusion, normal install, downloaded checksum and truthful docs. Publish Preview 5 only after accepted gates pass. Original clean-user/older-OS/multi-display/Spaces/one-hour/broad-beta gates remain open.

## Safety and continuity

User approved a Safari/Chrome test interval in this chat. Use only separately prepared local single-tab Safari / Chrome Guest fixtures. A different Space is not process/focus isolation. Stop on unexpected focus/fixture change. Do not close personal browser windows/chats. Avoid new foreground windows while the user studies except authorized tests. Existing local signing identity must be retained; never reset TCC, regenerate keys or print secrets. No new permission is silently granted.

Earlier Preview 4 detailed evidence and limitations remain in validation.md / compatibility.md. Earlier WhatsApp evidence is visibility only (42 consecutive samples /51s at1072×600); no chat-window actions. Blender untested/not installed. App eligibility never means verified compatibility. Keep all project assets, code, scripts and decisions in this root.
