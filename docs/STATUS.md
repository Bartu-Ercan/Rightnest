# Resume here

Product: Rightnest, formerly Starboard. Root: ~/Desktop/vibecoding/Rightnest.
User choices: extra right-side controls, originals retained, hide on uncertainty; minimize / fit-restore / close; Apple Silicon; MIT; no paid Developer ID membership; logo A Corner selected. User is studying: do not open or focus test windows on their desktop.

## Active work — popular-app stability and refined settings (2026-11-03)

User request: real Chrome/WhatsApp support, stable Safari, better native design after reviewing Nashi. User accepted an external shelf if the titlebar cannot be verified; do not resize windows or cover app content to create room. Original A Corner logo retained.

Source work: narrow Chromium tab-strip background and WDSNavigationBar spacer adapters; WDS uses its actual navigation row and complete bar subtree, excluding recycled scroll-cell bounds. Generic layouts remain strict. Per-inspection WindowServer snapshot; six native ownership probes; exact-own-overlay checks; observed foreign occlusion bounds prune repeated candidate queries. Stable previous anchors are revalidated before reuse. Content/title events no longer hide; they honor a 300ms visible/1s hidden throttle. Hard geometry/focus events still hide, stale observer callbacks are discarded. Missing focus data has bounded retries; actual different PID/window cancels. Panel joins Spaces and ignores cycling (transition tests still pending). Identical status strings do not republish UI state.

Design: Overview/Applications sidebar, native groups, A Corner illustration, searchable app icons/exclusions, semantic system colors, existing yellow/green/red hover, build number shown. Nashi source/packaging/test review recorded in design-popular-apps.md; no code/artwork copied or new runtime dependency.

Verification: 59 standalone and 24 offscreen native checks passed before latest throttle. CI a74ad9d / 41525363806 passed 14 XCTest + 59 standalone + 24 native and arm64 release. Chrome title-changing guest fixture passed all actions + 30 samples over 3s (verification-chrome.json). Safari after bounded retry fix passed all actions + 300 visible samples over 30s (.build/verify-safari-owner-diagnostic/result.json). Later source adds occlusion pruning/throttle/status dedup; current installed debug run is .build/verify-safari-throttled with 30s observation; inspect its result before claiming final-source success. Earlier failed runs remain ignored .build evidence, not passes. One short 20s debug sample during repeated blocked 5Hz title probes averaged 5.895% CPU, so that is not idle performance or a success target. New sample .build/performance-safari-throttled.json must be read with its test context.

WhatsApp: fixed the concrete disjoint hit-test bug. Its empty native navigation spacer was returning a sibling call button whose reported frame is entirely outside the candidate. Correction is restricted to the exact inspected WDS spacer, same target window and valid non-overlapping button bounds with 5pt clearance; real overlapping controls remain blockers. Read-only foreground observation now passed: 42 consecutive visible samples over 51 seconds after the initial startup sample (which was hidden). Test window 1072×600, app 26.38.74, macOS 27.0. Evidence docs/verification-whatsapp.json. No minimize/fit/close was sent to the personal WhatsApp window; those actions are still unverified for that app. No user-input request remains needed for visibility. Chrome 30s test was interrupted for the user's WhatsApp interval, so rerun it; do not count that attempt as a pass.

Next: read Safari final throttle result and metrics; run final Chrome 30s fixture (Checks/Fixtures/window-stability.html in the prepared guest window); sample normal-service CPU using cumulative process CPU time after stopping developer audits; run final CI/package and verify DMG build 5. Latest local checks: 64 standalone and 24 native passed. Final CI must include 15 XCTest cases. New public release is NOT yet published; Preview 3 remains latest. Earlier build-5 DMG predates the throttle and must be regenerated. Record precise results/limitations in compatibility/validation/release notes. Keep all files here. Broad beta/one-hour/clean-user/physical pointer/Spaces gates remain incomplete.

## Active work — automatic app discovery and hover colors

User requested: remove app-name restrictions; automatically find verified right-titlebar gaps in new apps (Blender was an example); preserve per-app opt-out; yellow minimize, green fit and red close hover; use apple-design and ponytail; leave reliable resume notes if quota interrupts work.

Current implementation: AppModel eligibility now uses regular-app capability discovery rather than the three-app allowlist. The existing strict AX geometry, text bounds, occlusion and action revalidation remain. Running apps and persisted exclusions are available in menu/settings. Shared buttons use semantic filled hover colors and dark symbols, with labels/shapes retained. No new runtime dependency.

Evidence: 49 standalone checks and 24 offscreen native hover/layout combinations passed. Previously unlisted Preview passed its full disposable-PDF action test using compact controls (docs/verification-preview.json). TextEdit regression also passed after backoff was added. Command-Comma, dynamic settings list and exclusion toggle/restore were checked through Computer Use. Rightmost anchor is preferred before moving left; each anchor tries normal then compact width. Source 278fd56 passed CI 41472088196: 12 XCTest cases, 49 standalone checks, 24 native hover combinations and arm64 release validation. Preview 3 is published: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.3. Build 4 DMG passed read-only mount, strict signature, arm64 and Applications-link checks. The release copy was installed at ~/Applications/Rightnest.app and launched in the background. Blender is not installed; do not claim Blender verified.

## Current evidence
- Current source CI: https://github.com/Bartu-Ercan/Rightnest/actions/runs/41472088196 (12 XCTest, 49 standalone checks, 24 native hover combinations, arm64 release).
- TextEdit and Preview disposable action tests passed in this source; Safari/Finder reports were recorded on the preceding shared engine. See docs/verification-*.json. These invoke real proxy NSButtons, not physical pointer clicks.
- Automatic eligibility covers identified regular apps, excluding Rightnest and user-disabled apps. Geometry and native capabilities decide each window; Chrome/Blender are not verified. Unknown/occupied layouts hide controls.
- Build 4 release/DMG debug-entrypoint exclusion, strict signature, arm64 and mounted package checks passed. Published Preview 3 assets were re-downloaded into .build/download-preview-3 and their SHA-256 matched. This does not prove Gatekeeper acceptance or clean-user installation.
- Full plan audit: docs/plan-audit.md. Broad-beta gates remain open.

## Implementation
Actor-owned serial AX client, MainActor notification subscriptions and nonactivating panel, 1-second fallback, stale-result cancellation, split geometry transaction, bounded in-memory restore history. Onboarding, optional SMAppService startup and en/tr strings exist. Historical bundle ID/signing storage intentionally retained.

## Next actions
1. Close acknowledgement discrepancy fixed by observing window removal; latest successful verification-textedit.json reports Window action sent. Remaining work: preserve useful action feedback while periodic status updates resume.
2. On an actually isolated GUI environment: physical pointer/composite verification, origin-varied fit/restore regression, focus/occlusion/sheets/drag/Spaces tests. Another Space alone is not isolation.
3. Extend Safari/Finder/Preview window/toolbar/tab coverage; investigate Chrome and Blender without weakening unknown-layout rejection. Blender must first be installed in an approved test environment.
4. One-hour soak, CPU/RSS, clean-account downloaded installation/update/removal, older macOS and accessibility visual validation.
5. Preview 3 is shareable with the documented self-signing/compatibility limits. Do not claim stable or universal support. Next work is compatibility evidence and pending release gates, not another architecture rewrite.

Shared reference repositories live under ~/.codex/skill-sources. Eleven avenox skills installed globally; next-turn discovery required. sifirdan is learning material, not an installable SKILL package. Its evidence/provenance and continuity ideas are reflected here and in global guidance. No chat export, nightly job or cloud sync was installed.
