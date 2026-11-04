# Resume here — Rightnest

Root: `~/Desktop/vibecoding/Rightnest`. Rightnest / A Corner. SwiftUI + AppKit + bounded serial AX actor; no runtime dependencies. Extra right controls, originals remain. Minimize → fit/restore → close; yellow/green/red hover. Apple Silicon, MIT. Stable local certificate/internal bundle ID retained. No paid Developer ID/notarization, telemetry, backend or updater.

## Current state — 2026-11-04

- Branch `codex/feasibility`; code **dfdaa4e**. User revised HUD behavior: hide the native strip at its existing anchor and width while covered; never slide left or shrink for a temporary foreign surface. Initial toolbar layout/collision rules remain.
- **CI41884081792 passed**:23XCTest,100standalone,24native hover/layout,4native press, monitor compile,arm64release/signature/developer-entrypoint checks. Hostmacos-15-intel; release cross-builtarm64. Previous41860586078/41861124832/41862549450 jobs never acquired anarm64runner and were cancelled with capacity annotations; no source-test failures were reported there.
- Published **Preview4/build5** only; Preview5/build6 remains unpublished. Current package rebuilt fromdfdaa4e. Normal release installed/launched at `~/Applications/Rightnest.app`; strict signature and developer-entrypoint exclusion passed. DMG read-only mount,arm64,build6,icon,Applications link and checksum passed.
- Temporary loopback fixture serverPID79522 was stopped after the failed Safari preparation. No successful new browser synthetic cycle run is claimed.
- Previous normal build user feedback: physical HUDs moved panel left and returned quickly in both browsers. Safari compacting looked poor; Chrome lateral movement also disliked. Counts and milliseconds were not explicitly reported. This drove the fixed-corner policy; do not count that report as verification of the new behavior.

## Implemented behavior

Keep the structural home position and width. Temporary foreign coverage hides instead of selecting an alternate/compact rectangle;200ms continuously clear before reappearance. Hover/press postpones optional return until150ms after exit; unsafe position hides. Focus/target immediate, geometry80ms debounce, content revalidation without unconditional hide. Transient probes100ms for5s then250ms; steady fallback1s; uncertain experimental layouts1/2/4s. Bounded actor queries, cancellation/generation checks and fresh click validation prevent stale actions.

Electron AXManualAccessibility once per enabled incomplete process session,100/300ms retries; no system grant. Disabled/read-only/cancelled work does not activate it. Chromium/WhatsApp geometry exceptions and Safari same-window disjoint-scroll-hit correction remain scoped. Held physical/AX presses retain their origin handler; hide/move cancels, nestedAX press rejected. Native A Corner appearance, app groups/status and opt-outs remain.

Do not add blanket foreign-surface exceptions, accept unknown content groups as empty, or restore blanket WindowServer bounding-box rejection. Carrier windows can have huge transparent bounds; actual hits still matter.

## Exact evidence

Persistent record: [verification-preview5.json](verification-preview5.json); raw reports under ignored `.build`. Reference host Mac14,2 /AppleM2 /8GiB, macOS27.0(26A428). No older OS/Intel/device-support claim.

- **Safari1800 active seconds PASSED before fixed-corner refinement**: `.build/verify-p5-safari-user-resumed1800/result.json`, optimized DEBUG b686133 behavior (final Finder-only argument patch absent in that Safari binary).16,850 visible samples,0pauses. Minimize/return/fit/restore-frame/close all passed through native AX proxy buttons. Appearance50samples p95209.185ms;20synthetic obstruction cycles max382.413ms. Continuous60s5Hz stress4.285% passed. Baseline and final observed panel both `{{1154,103},{102,26}}`. Next normal Safari window status Controls active after close.
- Safari instrumented idle5windows mean1.4699% **FAILED<1**. Do not erase it or relabel as normal release-service CPU. Earlier Safari531active/2154paused attempt ended fixture-unverifiable throughAX; same window later existed, so closure was not proved. Earlier681s/244s attempts also are not long-session passes.
- **Chrome1800s PASSED before fixed-corner refinement**, a73e16f optimized DEBUG(enginec259556):16,712 visible samples, all actions passed; appearance p95201.6ms,20synthetic returns max355.9ms,60s5Hz CPU1.737%. Instrumented idle1.226% failed separately. Held-press guard follow-up174d4d0 passed30s/284samples and all actions.
- Chrome latest native-AX-press follow-up **PASSED after user foregrounding**: `.build/verify-p5-chrome-user-foreground/result.json`,30active seconds,250visible samples,0pauses; minimize/return/fit/restore-frame/close all passed. The following earlier failures remain preserved: File fixture navigation stalled before matching. Loopback fixture loaded/matched, but no panel: first candidate rejected by AX hit from `com.apple.finder/AXGroup` while foreground metadata said Chrome. Report `.build/verify-p5-chrome-loopback-final/result.json`; no actions. Do not infer the exact Space/order cause or bypass safety. User foregrounding and a fresh retry subsequently passed; exact underlying cause of the earlier mismatch remains unproved.
- **Normal production idle CPU PASSED** on Chrome static Guest fixture: c259556, external cumulativeCPU monitor,30s warmup+five60s windows, mean0.5978%,RSS55904→24464KiB. Earlier production500ms baseline1.0273% failed; all instrumented failures retained. Not a one-hour/multi-device or Safari-specific normal-CPU proof.
- **Finder current attempt FAILED**: `.build/verify-p5-finder-final/result.json`,1310×700. Own toolbar filled searched right half; no verified outside desktop space; controls hid, no actions. Historical1760pt Finder action pass remains historical, not a current1310pt pass.
- Preview new attempt did not complete disposable-document preparation while Open panel remained. Stopped without action pass. Temporary native-opening-path change was reverted. Historical Preview11.0 PDF/66pt-strip action proof remains historical.
- New fixed-corner physical HUD behavior and exact cycle counts **NOT VERIFIED**; prior behavior has user-reported qualitative proof. unsupported CUA media key. Synthetic panels do not substitute. Physical pointer/composite remains unpassed. Discord/SystemSettings current candidate checks, narrow/tab/toolbar/menu cases, clean-user/download/update/removal, multiple displays/Spaces/one-hour soak/olderOS remain open.

## Next action

1. Normal release is installed/running; package checks passed and fixture server stopped. No new system grant/TCC reset occurred.
2. New fixed-corner standalone/native/CI checks passed. Safari attempt `.build/verify-p5-safari-pinned` stopped before actions becauseAX hit Codex over the target. Do not claim a new browser integration pass; do not bypass the Codex tool restriction or ignore foreign surfaces. Use an actually foregrounded owned fixture for later integration.
3. Update/manual-test new physicalHUD behavior when user next uses Safari/Chrome; previous user feedback applies to the old moving policy. Older long runs remain baseline evidence, not current-policy30min proof.
4. Browser narrow/tab/toolbar/menu/pointer, system/experimental app coverage, clean-user/quarantine/update/removal and broader display/one-hour/platform gates remain open. Preview5 stays unpublished. [Acceptance plan](browser-stability-plan.md), [broader audit](plan-audit.md).

## Computer-use constraints

User authorized owned browser tests. Different Spaces do not isolate app/focus state. Never touch personal tabs/chats/docs. Stop preparation/actions on unexpected target change; passive observation may pause without refocusing, excludes paused/transition time, verifies exact fixture on resume. No silent system permission grants; retain certificate/TCC identity.

CUA rejected controlling Codex; do not bypass. Dock timed out twice. AX Raise/click/Tab previously did not restore verified Safari system foreground; user foregrounding plus a fresh verifier run did. App snapshots can show a window that does not own global hit-testing points; do not infer visibility from an app-only screenshot. Rightnest getApp/reopen can show Settings; Preview getApp/reopen can show Open. After restart/reinstall reclaim bindings. Use fullAX snapshots/exposedCancel for open menus when needed. Avoid repeated coordinate guesses and further foreground disruption.
