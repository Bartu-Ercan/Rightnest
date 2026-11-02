# Resume here — Rightnest

Root: ~/Desktop/vibecoding/Rightnest. User chose Rightnest / A Corner logo. Native SwiftUI + AppKit + serial Accessibility actor. Extra right-side controls; originals retained. Order: minimize, fit/restore, close. Apple Silicon, MIT, GitHub Releases, local stable signing, no paid Developer ID/notarization. No accounts/backend/telemetry/automatic updater. Historical bundle ID/signing storage deliberately retained.

## Current delivery (2026-11-03)

Source code: 8682e26. Final CI https://github.com/Bartu-Ercan/Rightnest/actions/runs/41529100917 PASSED: 15 XCTest cases, 64 standalone checks, 24 native hover/layout combinations and arm64 release/bundle validation. Later pending changes are documentation only. Preview 4 / build 5 release candidate is ready; publish next at https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Do not call publication complete until gh confirms it.

Build-5 DMG was regenerated with updated installation notes. Read-only mount, strict signature, arm64, icon, Applications link, image verification and SHA passed. RELEASE copy installed at ~/Applications/Rightnest.app, strict signature verified, build 5, launched -g without test flags. Existing signing identity is unchanged. This does not prove clean-user browser-download/update permission continuity.

## Actual app evidence

- Chrome 156.0.8078.79: prepared single-tab Guest fixture passed all actions plus 30 visible samples over 3 seconds (verification-chrome.json). A final 30-second rerun stopped before actions when the user’s foreground app became Safari; empty actionTrace in .build/verify-chrome-release-final. Do not count that interruption as a pass or force another foreground test while the user studies.
- Safari 27.0: title-changing fixture passed 300 visible samples over 30 seconds, minimize/restore/fit/restore-frame/close (verification-safari.json). Earlier failed native restore attempts were corrected by bounded missing-focus retries and stale AXObserver callback filtering.
- WhatsApp 26.38.74: native navigation-spacer visibility verified at 1072×600. First startup sample hidden, then 42 consecutive visible samples over 51 seconds (verification-whatsapp.json). No minimize/fit/close was sent to the personal chat window; WhatsApp actions, maximized layout and call/dialog flows remain unverified. No user-input request remains necessary for basic visibility.
- Earlier TextEdit/Finder/Preview action evidence remains in verification-*.json, with source/time limits in validation.md. Blender is not installed/tested. App eligibility/listing is never a compatibility guarantee.
- Normal debug service without audit/verifier: 0.14 CPU seconds over 20.015 wall seconds, ~0.699% of one core, end RSS 32,400 KiB. .build/performance-normal-service.json. Not a one-hour or release benchmark. Separate startup/5Hz title stress ps-%CPU samples were higher (5.895%, 6.845%); different workloads, not a controlled improvement comparison.

## Current behavior and rationale

Generic native inspection remains strict. Chromium native tab-strip filler is structurally recognized. WhatsApp WDSNavigationBar uses the measured spacer row and complete native-bar subtree, avoiding recycled scroll-cell bounds. Out-of-bounds hit corrections require the same target window, fully measured native scope and valid disjoint bounds; overlapping buttons remain blockers. A fresh per-inspection WindowServer snapshot supports exact-own-overlay/outside-space checks. Foreign AX hits can prune measured covering regions only for that inspection.

Content/title notifications revalidate without hiding and honor a 300ms visible / 1s hidden query throttle. Geometry/focus changes hide immediately. Stale observer sources/results are discarded. Missing native focus is retried briefly; real PID/window changes cancel. Valid prior anchors are preferred to prevent drifting. Panel joins Spaces and ignores cycling; actual Space-transition matrix remains untested. Native controls are not redrawn/recreated for unchanged state.

User accepted an outside-window shelf when titlebar safety cannot be verified. It must fit the usable display and avoid other windows; never silently resize the target or cover its content to create room. Screen-filling/crowded desktops may have no outside space.

Settings: Overview/Applications sidebar, A Corner window illustration, semantic surfaces, searchable app icons/exclusions, native focus/controls and visible build number. Existing yellow/green/red hover retained. Dark rendered UI, search and exclusion off/on were inspected. Nashi source/design/window-management/packaging/test review: design-popular-apps.md; no code/artwork copied or new runtime dependency.

## Next work / limits

1. Publish Preview 4 only after the passed CI above, re-download assets and verify checksum, then record the actual release URL/result here.
2. Actually isolated account/device: physical external-panel pointer/composite checks, fuller Chrome/Safari/WhatsApp toolbar/tab/dialog cases and WhatsApp actions. A different macOS Space is not process/focus isolation. Do not control personal documents/chats. User studies in the other desktop; avoid foreground windows/new permission prompts.
3. Multi-display/Spaces/Mission Control/Stage Manager, sleep/wake, one-hour CPU/RSS soak, clean-user browser-download/install/update/remove and older macOS coverage. Broad beta/stable gates remain open; see plan-audit.md.

All project code/assets/docs stay in this root. Shared skill sources remain global under ~/.codex/skill-sources. Use relevant installed skills selectively; reference material is not a configured service. Keep evidence and failures explicit when resuming; never turn planned verification into a pass.
