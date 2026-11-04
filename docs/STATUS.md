# Resume here — Rightnest

Root: `~/Desktop/vibecoding/Rightnest`. Rightnest / A Corner identity. SwiftUI + AppKit + bounded serial AX actor; no runtime dependencies. Extra right controls; originals remain. Minimize → fit/restore → close; yellow/green/red hover. Apple Silicon, MIT, GitHub Releases. Stable local signing; no paid Developer ID/notarization, telemetry, backend or updater. Historical bundle ID/certificate storage retained.

## Current state — 2026-11-04

- Branch `codex/feasibility`; source **b686133**. CI **41770037293 passed**: 22 XCTest, 96 standalone, 24 native hover/layout combinations, 4 native press-routing checks, external CPU monitor compile, arm64 production bundle/signature/developer-entrypoint exclusion. Check git status before editing.
- Published: **Preview 4 / build 5** only: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Preview 5 / build 6 is an unreleased candidate.
- Installed `~/Applications/Rightnest.app`: optimized DEBUG measurement build 6, running `.build/verify-p5-safari-user-resumed1800`. Includes b686133 behavior; its final Finder-fixture argument correction is not in this Safari-only binary. **Do not restart or install until checking progress/result. User foregrounded the owned Safari fixture; replacement long run is active. Do not interact with apps during this run.**
- `dist/Rightnest.app` and DMG were rebuilt as production b686133 without DEBUG. Read-only mount, strict signature, arm64, build6, icon, Applications symlink, test-entrypoint exclusion and local checksum passed. Installed app remains instrumentation. Package is unpublished; clean-user/download proof remains open.
- Accepted current gates: [browser-stability-plan.md](browser-stability-plan.md). Broader original plan remains incomplete: [plan-audit.md](plan-audit.md).

## Implemented behavior

Ideal and temporary placement are separate. Return after 200 ms continuously clear; hover/press defers optional return until 150 ms after exit. Unsafe space hides. Focus/target updates immediately, geometry after 80 ms; content changes revalidate without unconditional hide. Transient probes 100 ms for five seconds, then 250 ms; normal fallback one second; unknown experimental layouts back off 1/2/4 seconds. Query generations, cancellation and fresh action validation prevent stale targeting.

Electron AXManualAccessibility: once per enabled incomplete process session, 100/300 ms retries; disabled/read-only/cancelled work does not request it. Native Chromium/WhatsApp geometry exceptions remain scoped. Safari disjoint AXScrollArea hits are corrected only in measured native toolbar space in the same target window. No blanket content-group or MenuBarAgent exception.

A held physical or accessibility press retains its origin handler. Hide/move cancels it; repeated accessibility press is blocked. Settings groups apps as priority/system/experimental and exposes last-check status and named native switches. A Corner appearance and native accessibility remain.

Do not replace AX hit testing with blanket WindowServer bounding-box rejection: transparent carrier windows may span the screen. Actual foreign hits and other own visible windows still block placement.

## Verification evidence

Persistent metrics: [verification-preview5.json](verification-preview5.json). Raw reports in ignored `.build`; no personal content in notes. Reference: Mac14,2 / Apple M2 / 8 GiB, macOS 27.0 (26A428).

- **Chrome 1800s passed**, runtime a73e16f optimized DEBUG (engine c259556): 16,712 visible samples; minimize/restore/fit/restore-frame/close passed; 50 geometry samples p95 201.6 ms; 20 synthetic obstruction cycles max return 355.9 ms; continuous 60s 5 Hz stress CPU 1.737%. Instrumented idle mean 1.226% failed and remains recorded separately.
- **Chrome held-press regression passed**, source174d4d0: 30s /284 visible samples and all actions. Latest accessibility-press override has Safari regression plus four native routing checks, not another Chrome long run.
- **Safari current long run pending**: `.build/verify-p5-safari-user-resumed1800/{progress,result}.json`. Latest early metrics: geometry p95 214.4 ms, 20 synthetic cycles max return 423.5 ms, 60s stress CPU 4.248%. Read live files for duration/result; do not count planned 1800s as completed.
- Safari native accessibility-press regression passed: 30 active seconds /285 visible samples, all actions, endpoint at observed baseline. A separate owned Start Page 1310×700 showed controls repeatedly for over two minutes after the scoped scroll-hit correction; no actions in that blank-page audit.
- Earlier Safari long attempts stopped at681s and244s when focus became Codex. No final actions were sent; neither satisfies30min. The current DEBUG-only observation clock pauses on another app/window, never refocuses it, excludes pause/transition time, and resumes only after exact fixture verification. Permission/fixture loss fails; interrupted continuous stress is invalidated. Four clock checks plus XCTest passed; controlled live pause held active531s /4805 samples while paused time advanced; resume is pending. Finder owns the separate empty test folder window. CUA Raise/click/Tab did not return system foreground ownership; Dock timed out twice. User asked to foreground Safari; do not bypass through shell/other UI automation.
- **Normal production idle CPU passed**: runtime c259556, external cumulative CPU monitor,30s warmup +five60s windows, mean0.5978%, RSS55904→24464 KiB. Earlier production500ms baseline1.0273% failed; unoptimized/optimized instrumentation and10Hz verifier failures remain recorded. This is one host/workload, not a one-hour/multi-device claim.
- Actual OS volume/brightness cycles: **not verified**. CUA media key returned keyNotFound. Synthetic panels do not satisfy this gate. Direct physical pointer/composite verification remains unpassed; the earlier coordinate attempt opened Settings. Native AX proxy actions are distinct evidence.
- Historical Finder/Preview/TextEdit fixture actions and WhatsApp visibility are in compatibility/validation documents. They are not fresh Preview5 passes. Earlier intermittent Chrome initial NoSafe rejection remains unexplained; successful diagnostic retry changed logging only. Three later rejected probes belonged to MenuBarAgent, which does not prove the earlier cause.

## Next actions

1. Read current Safari progress/result; preserve the running installed binary. Finish 1800 active seconds and final fixture actions. Record exact metrics/failure without changing its source mid-run.
2. Afterward, test permitted focus pause/resume using a separate owned Finder window; never target Codex through computer use (tool rejected it). Verify narrow/wide, tabs/toolbar/menus and pointer cases; preserve personal windows.
3. Finder/Preview/System Settings normal-window basics; Discord visibility/placement/actions separately. No personal chat/document actions. Dialogs and true full screen stay excluded.
4. Actual20 OS HUD cycles per browser require supported physical/UI testing. Do not substitute synthetic cycles or unsupported event injection. Keep Preview5 unpublished until gates pass or the user explicitly changes scope.
5. Rebuild production package; mount read-only and verify signature/arm64/build/icon/Applications link/debug exclusion/checksum. Normal install, downloaded checksum and clean-user path remain to prove. Update compatibility/README/validation from results.
6. Original broader gates remain: older macOS, multiple displays, Spaces/Mission Control/Stage Manager, one-hour memory/focus soak and clean-user installation/update. No broad compatibility or beta-ready claim until evidence exists.

## Safety and continuity

User authorized browser testing in this chat. Use owned local Safari fixtures and Chrome Guest windows only. Different Spaces are not process/focus isolation. Do not close/navigate personal windows. During passive observation focus loss pauses without activation; preparation and action phases require exact foreground fixture ownership. No silent system permission grant. Retain signing identity; never reset TCC/regenerate keys/print secrets.

After reinstall/restart reclaim Rightnest through cua.getApp. For open menus use a fresh full AX snapshot and exposed Cancel action; Escape/diff snapshots previously missed menu state. Keep all project files here; shared skills remain global. Preserve failed results and distinguish native AX actions, physical clicks, synthetic obstruction and real OS HUD tests.

Computer-use limitation in this resume: Safari Raise/AX click/Tab and a screenshot-based content click did not restore verifier foreground ownership. Dock timed out twice. Rightnest Settings appeared during these attempts and an AX close attempt returned another Settings window; stop further UI attempts rather than claim focus/click success. User focus request is pending. Passive verifier remains safe/paused; check progress/result before next action.

User returned Safari fixture to foreground. Prior active1800 attempt ended with AX fixture-unverifiable while paused (531 active /2154 paused seconds); same owned UUID was subsequently present, so do not claim it was actually closed. Reloaded only that local fixture and restarted installed measurement binary as `.build/verify-p5-safari-user-resumed1800`, without reinstall/permission changes. First metrics: geometry p95209.2ms,20 synthetic cycles max382.4ms,60s5Hz CPU4.285% passed. No completed Safari long-session result yet. Avoid further CUA during the run.
