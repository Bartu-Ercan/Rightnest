# Resume here

Product: Rightnest, formerly Starboard. Root: ~/Desktop/vibecoding/Rightnest.
User choices: extra right-side controls, originals retained, hide on uncertainty; minimize / fit-restore / close; Apple Silicon; MIT; no paid Developer ID membership; logo A Corner selected. User is studying: do not open or focus test windows on their desktop.

## Current evidence
- `swift run PlacementChecks`: 34 checks pass.
- Last interactive record: `.build/verification-trace/result.json`, copied to docs/verification-textedit.json. Fit/restore/minimize/close state checks passed. Final action acknowledgement says unavailable despite observed closure; investigate on a disposable fixture when isolated interaction is possible.
- Arm64 release, debug-entrypoint exclusion, DMG checksum, read-only mount, packaged signature/icon/Applications link all passed. Release build/DMG details are recorded in validation.md. Never infer clean-machine install or remote CI success from local build.
- Candidate app audit rejects Finder/Safari/Preview at layout containers and Chrome at unknown empty group. Only TextEdit enabled. Broad beta gate unmet.

## Implementation
Actor-owned serial AX client, MainActor notification subscriptions and nonactivating panel, 1-second fallback, stale-result cancellation, split geometry transaction, bounded in-memory restore history. Onboarding, optional SMAppService startup and en/tr strings exist. Historical bundle ID/signing storage intentionally retained.

## Next actions
1. Close acknowledgement discrepancy fixed by observing window removal; latest successful verification-textedit.json reports Window action sent. Remaining work: preserve useful action feedback while periodic status updates resume.
2. On an actually isolated GUI environment: physical pointer/composite verification, origin-varied fit/restore regression, focus/occlusion/sheets/drag/Spaces tests. Another Space alone is not isolation.
3. Improve app-specific titlebar traversal without assuming containers are blank; verify two additional daily apps before broad beta.
4. One-hour soak, CPU/RSS, clean-account downloaded installation/update/removal, older macOS and accessibility visual validation.
5. Source published at https://github.com/Bartu-Ercan/Rightnest. CI run 41454033532 passed (9 XCTest cases and 34 standalone checks plus release validation). Limited TextEdit preview published at https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.1. Broad beta remains gated. Current code CI run 41455384828 was queued at publication; check its final result.

Shared reference repositories live under ~/.codex/skill-sources. Eleven avenox skills installed globally; next-turn discovery required. sifirdan is learning material, not an installable SKILL package. Its evidence/provenance and continuity ideas are reflected here and in global guidance. No chat export, nightly job or cloud sync was installed.
