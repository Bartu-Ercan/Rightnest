# Resume here

Product: Rightnest, formerly Starboard. Root: ~/Desktop/vibecoding/Rightnest.
User choices: extra right-side controls, originals retained, hide on uncertainty; minimize / fit-restore / close; Apple Silicon; MIT; no paid Developer ID membership; logo A Corner selected. User is studying: do not open or focus test windows on their desktop.

## Active work — automatic app discovery and hover colors

User requested: remove app-name restrictions; automatically find verified right-titlebar gaps in new apps (Blender was an example); preserve per-app opt-out; yellow minimize, green fit and red close hover; use apple-design and ponytail; leave reliable resume notes if quota interrupts work.

Current implementation: AppModel eligibility now uses regular-app capability discovery rather than the three-app allowlist. The existing strict AX geometry, text bounds, occlusion and action revalidation remain. Running apps and persisted exclusions are available in menu/settings. Shared buttons use semantic filled hover colors and dark symbols, with labels/shapes retained. No new runtime dependency.

Evidence: 49 standalone checks and 24 offscreen native hover/layout combinations passed. Previously unlisted Preview passed its full disposable-PDF action test using compact controls (docs/verification-preview.json). TextEdit regression also passed after backoff was added. Command-Comma, dynamic settings list and exclusion toggle/restore were checked through Computer Use. Rightmost anchor is preferred before moving left; each anchor tries normal then compact width. Next: release packaging and CI; then update this checkpoint with the new release URL and final run ID. Blender is not installed; do not claim Blender verified. Preview 2 remains the published release until this change is verified/published.

## Current evidence
- Preview 2 published: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.2. TextEdit/Safari/Finder enabled when space is verified. Source CI 41463347790 passed: 11 XCTest cases and 41 standalone checks. Full plan audit: docs/plan-audit.md.
- `swift run PlacementChecks`: 41 checks pass.
- Current recorded successful integration: docs/verification-textedit.json. Fit/restore/minimize/close passed, with Window action sent. Later runs interrupted by focus changes are not passes. Own demo fit/restore/close passed coordinate-pointer tests; external composite pointer tests remain pending.
- Arm64 release, debug-entrypoint exclusion, DMG checksum, read-only mount, packaged signature/icon/Applications link all passed. Release build/DMG details are recorded in validation.md. Never infer clean-machine install or remote CI success from local build.
- Preview 2 source enables TextEdit, Safari and Finder. Their disposable action tests passed (docs/verification-*.json). Narrow/crowded titlebars still hide controls. Chrome/Preview remain disabled. Full broad-beta validation remains incomplete.

## Implementation
Actor-owned serial AX client, MainActor notification subscriptions and nonactivating panel, 1-second fallback, stale-result cancellation, split geometry transaction, bounded in-memory restore history. Onboarding, optional SMAppService startup and en/tr strings exist. Historical bundle ID/signing storage intentionally retained.

## Next actions
1. Close acknowledgement discrepancy fixed by observing window removal; latest successful verification-textedit.json reports Window action sent. Remaining work: preserve useful action feedback while periodic status updates resume.
2. On an actually isolated GUI environment: physical pointer/composite verification, origin-varied fit/restore regression, focus/occlusion/sheets/drag/Spaces tests. Another Space alone is not isolation.
3. Safari and Finder basic action threshold met; extend actual window/toolbar/tab coverage and investigate Chrome/Preview without weakening unknown-layout rejection.
4. One-hour soak, CPU/RSS, clean-account downloaded installation/update/removal, older macOS and accessibility visual validation.
5. Source published at https://github.com/Bartu-Ercan/Rightnest. CI run 41454033532 passed (9 XCTest cases and 34 standalone checks plus release validation). Limited TextEdit preview published at https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.1. Broad beta remains gated. Current code CI run 41455384828 passed. Published download was re-downloaded and its SHA-256 matched.

Shared reference repositories live under ~/.codex/skill-sources. Eleven avenox skills installed globally; next-turn discovery required. sifirdan is learning material, not an installable SKILL package. Its evidence/provenance and continuity ideas are reflected here and in global guidance. No chat export, nightly job or cloud sync was installed.
