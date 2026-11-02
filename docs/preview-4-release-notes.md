# Rightnest Preview 4 — native app compatibility and stability

Chrome's unused native tab-strip background is recognized structurally, so the right-side controls can appear without covering tabs or toolbar buttons. WhatsApp's native navigation bar uses its measured spacer row; an accessibility bug that returned a neighboring call button for blank points is corrected only inside that exact verified spacer. Other unknown layouts remain conservative.

Content focus/title changes revalidate without unconditional hiding. Geometry/target changes still hide; stale observation callbacks are discarded. Missing native focus data is retried briefly and real target changes cancel. Previous safe anchors are reused only after fresh validation. Query throttling, per-inspection occlusion caching and unchanged-control update suppression reduce redundant work. A clear outside-window shelf is available when no titlebar space can be proved; it never resizes the app or covers content to create room. Screen-filling/crowded desktops may have no outside space.

Settings now has Overview/Applications navigation, a corner illustration, application icons, searchable exclusions and visible build number (build 5). Native controls, system appearances, keyboard access and yellow/green/red hover remain.

## Actual evidence and limits

Safari's local title-changing fixture passed 300 visibility samples over 30 seconds and all window actions. Chrome's completed fixture results are in docs/verification-chrome.json. WhatsApp 26.38.74 had 42 consecutive visible samples over 51 seconds in a 1072×600 normal window, after startup. **WhatsApp actions were not sent to the personal chat and remain unverified. Listed/enabled apps do not imply universal compatibility.** Blender is still untested.

64 standalone checks and 24 native hover/layout combinations passed locally; final-source CI runs 15 XCTest cases as well. Final runtime source passed CI 41529100917: 15 XCTest cases, 64 standalone checks, 24 native combinations and arm64 release validation. A short normal-debug-service sample used approximately 0.70% of one CPU core over 20 seconds; this is not a one-hour performance claim. Physical external-panel pointer/composite tests, broader dialogs/tabs/Spaces/displays, clean-user downloaded install/update/removal and older OS coverage remain incomplete. This is a developer preview.

Nashi's SwiftUI/AppKit design, window management, packaging and UI-test source were reviewed as a reference. No Nashi code or artwork was copied and no runtime dependency was added.

## Install/update

Apple Silicon. Quit the older copy, drag Rightnest from the DMG to Applications, eject and open the installed copy. Keep one copy. The existing local signing identity is retained; macOS permission is never granted silently.

Not Developer ID signed or notarized. macOS may block the download and managed devices may prohibit it. Use only an offered per-app Open Anyway choice if you accept this limitation. Do not disable Gatekeeper or remove quarantine. Installation and removal guidance: docs/INSTALL.md and docs/INSTALL.tr.md. Manual updates only.
