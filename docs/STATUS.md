# Resume here — Rightnest

Root: `~/Desktop/vibecoding/Rightnest`. Rightnest / A Corner. SwiftUI + AppKit + bounded serial AX actor; no runtime dependencies. Extra right controls, originals remain. Minimize → fit/restore → close; yellow/green/red hover. Apple Silicon, MIT. Stable local certificate/internal bundle ID retained. No paid Developer ID/notarization, telemetry, backend or updater.

## Current state — 2026-11-04

- Branch `codex/feasibility`; latest source **3a2c05a**. Production behavior is b686133; the later source change accepts explicit loopback fixture URLs only inside DEBUG verification. Check git status and CI before editing.
- CI **41770037293 passed** for b686133:22 XCTest,96 standalone,24 native hover/layout combinations,4 native press-routing checks, external CPU monitor compile, arm64 release/signature/developer-entrypoint exclusion. New source CI pending; do not imply it passed until checked.
- Published **Preview4/build5** only: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Preview5/build6 remains an unpublished candidate; accepted publication gates remain open.
- Installed `~/Applications/Rightnest.app` is optimized DEBUG measurement build6 from current source. Latest short Chrome loopback attempt has finished with a foreign-surface rejection; **no long verifier is running**. User asked to foreground the existing owned Chrome Guest fixture for a60s retry. Do not change installed code/permissions while waiting.
- Local fixture server: Python PID73762, exec session62914, HTTP bound only127.0.0.1:8765, serving `Checks/Fixtures`. Stop this temporary server after browser tests. It is not part of the app or release.
- Production package from3a2c05a completed via package.sh. Read-only mount,strict signature,arm64,build6,icon,Applications link,test-entrypoint exclusion and local SHA256 all passed. No production installation/launch yet. Logs `.build/package-p5-loopback-source.log` and `.build/package-p5-mount.log`. Never distribute a DEBUG/profile bundle.

## Implemented behavior

Separate ideal/temporary positions;200ms continuously clear before return. Hover/press postpones optional return until150ms after exit; unsafe position hides. Focus/target immediate, geometry80ms debounce, content revalidation without unconditional hide. Transient probes100ms for5s then250ms; steady fallback1s; uncertain experimental layouts1/2/4s. Bounded actor queries, cancellation/generation checks and fresh click validation prevent stale actions.

Electron AXManualAccessibility once per enabled incomplete process session,100/300ms retries; no system grant. Disabled/read-only/cancelled work does not activate it. Chromium/WhatsApp geometry exceptions and Safari same-window disjoint-scroll-hit correction remain scoped. Held physical/AX presses retain their origin handler; hide/move cancels, nestedAX press rejected. Native A Corner appearance, app groups/status and opt-outs remain.

Do not add blanket foreign-surface exceptions, accept unknown content groups as empty, or restore blanket WindowServer bounding-box rejection. Carrier windows can have huge transparent bounds; actual hits still matter.

## Exact evidence

Persistent record: [verification-preview5.json](verification-preview5.json); raw reports under ignored `.build`. Reference host Mac14,2 /AppleM2 /8GiB, macOS27.0(26A428). No older OS/Intel/device-support claim.

- **Safari1800 active seconds PASSED**: `.build/verify-p5-safari-user-resumed1800/result.json`, optimized DEBUG b686133 behavior (final Finder-only argument patch absent in that Safari binary).16,850 visible samples,0pauses. Minimize/return/fit/restore-frame/close all passed through native AX proxy buttons. Appearance50samples p95209.185ms;20synthetic obstruction cycles max382.413ms. Continuous60s5Hz stress4.285% passed. Baseline and final observed panel both `{{1154,103},{102,26}}`. Next normal Safari window status Controls active after close.
- Safari instrumented idle5windows mean1.4699% **FAILED<1**. Do not erase it or relabel as normal release-service CPU. Earlier Safari531active/2154paused attempt ended fixture-unverifiable throughAX; same window later existed, so closure was not proved. Earlier681s/244s attempts also are not long-session passes.
- **Chrome1800s PASSED**, a73e16f optimized DEBUG(enginec259556):16,712 visible samples, all actions passed; appearance p95201.6ms,20synthetic returns max355.9ms,60s5Hz CPU1.737%. Instrumented idle1.226% failed separately. Held-press guard follow-up174d4d0 passed30s/284samples and all actions.
- Chrome latest native-AX-press follow-up remains **unpassed**. File fixture navigation stalled before matching. Loopback fixture loaded/matched, but no panel: first candidate rejected by AX hit from `com.apple.finder/AXGroup` while foreground metadata said Chrome. Report `.build/verify-p5-chrome-loopback-final/result.json`; no actions. Do not infer the exact Space/order cause or bypass safety. User foreground request pending.
- **Normal production idle CPU PASSED** on Chrome static Guest fixture: c259556, external cumulativeCPU monitor,30s warmup+five60s windows, mean0.5978%,RSS55904→24464KiB. Earlier production500ms baseline1.0273% failed; all instrumented failures retained. Not a one-hour/multi-device or Safari-specific normal-CPU proof.
- **Finder current attempt FAILED**: `.build/verify-p5-finder-final/result.json`,1310×700. Own toolbar filled searched right half; no verified outside desktop space; controls hid, no actions. Historical1760pt Finder action pass remains historical, not a current1310pt pass.
- Preview new attempt did not complete disposable-document preparation while Open panel remained. Stopped without action pass. Temporary native-opening-path change was reverted. Historical Preview11.0 PDF/66pt-strip action proof remains historical.
- Actual20 volume/brightness HUD cycles per browser **NOT VERIFIED**; unsupported CUA media key. Synthetic panels do not substitute. Physical pointer/composite remains unpassed. Discord/SystemSettings current candidate checks, narrow/tab/toolbar/menu cases, clean-user/download/update/removal, multiple displays/Spaces/one-hour soak/olderOS remain open.

## Next action

1. Wait for user to foreground **Chrome Guest /Rightnest Stability Fixture** at `http://127.0.0.1:8765/window-stability.html`. Retry installed measurement binary with `--verify-app <new-report-dir> com.google.Chrome <exact-loopback-URL>`. Its verifier activates/raises only the matched owned fixture; do not navigate or close personal profile windows. Record actual result, including failures.
2. Check current sourceCI and production-package completion; mount read-only, verify strict signature,arm64,build6,icon,Applications link,test-entrypoint exclusion and checksum. Stop fixture server after tests. Restore normal installed release when instrumentation is no longer needed.
3. Close accepted remaining gates before Preview5 publication, or get an explicit scope change. Original broader product plan remains incomplete: [plan-audit.md](plan-audit.md). Current acceptance plan: [browser-stability-plan.md](browser-stability-plan.md).

## Computer-use constraints

User authorized owned browser tests. Different Spaces do not isolate app/focus state. Never touch personal tabs/chats/docs. Stop preparation/actions on unexpected target change; passive observation may pause without refocusing, excludes paused/transition time, verifies exact fixture on resume. No silent system permission grants; retain certificate/TCC identity.

CUA rejected controlling Codex; do not bypass. Dock timed out twice. AX Raise/click/Tab previously did not restore verified Safari system foreground; user foregrounding plus a fresh verifier run did. App snapshots can show a window that does not own global hit-testing points; do not infer visibility from an app-only screenshot. Rightnest getApp/reopen can show Settings; Preview getApp/reopen can show Open. After restart/reinstall reclaim bindings. Use fullAX snapshots/exposedCancel for open menus when needed. Avoid repeated coordinate guesses and further foreground disruption.
