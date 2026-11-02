# Validation — Rightnest developer preview

## Verified

- 34 standalone checks: placement 7, permission combinations 8, obstacle regressions 3, display/restore geometry 9, surface ordering 7.
- Last recorded disposable TextEdit integration passed minimize, restore from minimized, fit, restore original frame and close. See verification-textedit.json. This uses real proxy NSButtons via performClick, not physical pointer input. The earlier acknowledgement discrepancy was fixed by confirming the observed action result. The current saved report ends with Window action sent; this still is not broad release approval.
- Prior intermediate fit runs failed from certain starting origins. The last recorded source separates shrink, move and final size, waiting for observed geometry. No new foreground run was performed while the user was studying.
- Existing local-certificate permission survived product rename in the prior session.

## Historical Preview 1 release gates

- Actual pointer/composite visuals, drag/resize, menus/sheets, focus races and display/Spaces transitions.
- Two additional daily-use apps. Current background/foreground audits reject Finder, Safari, Chrome and Preview; see compatibility.md.
- Clean-user downloaded installation, Gatekeeper experience, update permission continuity for distributed packages, login-item registration.
- One-hour soak, idle CPU target below 1%, stable RSS; older OS/device coverage.
- XCTest requires full Xcode, unavailable on this host. Remote CI passed: https://github.com/Bartu-Ercan/Rightnest/actions/runs/41454033532 (9 XCTest cases, 34 standalone checks, arm64 release and artifact validation).

The app remains a developer preview. Historical full-screen prototype tests are archived in prototype-investigation.md and do not validate the new fit behavior.

## Historical Preview 1 background checks

- Arm64 release compilation passed. Packaging initially failed because of incorrect lipo argument order; fixed in both local and CI scripts.
- Packaging's debug-entrypoint scan caught command-line flag strings retained by an unconditional onboarding guard. Guard now compiles these references only under DEBUG; packaging is rerun after the fix.
- `swift test` still fails with `no such module XCTest` on this Command Line Tools installation. The 34 standalone checks remain the available local automated suite.
- Desktop output can acquire Finder metadata after signing; direct strict verification of that copy detected it again. Packaging copies without extended metadata and verifies the clean staged bundle. Do not equate a mutable Desktop copy with a verified downloaded installation.
- No interactive launch or new permission grant was performed during this background continuation.

## Packaged artifact verified

`dist/Rightnest-0.1.0-preview-arm64.dmg` was produced after the fixes. DMG checksum verification passed. The image was mounted read-only with nobrowse, its app passed strict codesign verification and arm64 architecture verification, AppIcon.icns and Applications symlink were present, and the image was ejected. No app was launched. This validates package structure and local signature, not Gatekeeper acceptance or clean-user installation.

Source repository: https://github.com/Bartu-Ercan/Rightnest. A limited TextEdit preview has been published at https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.1.

## Shareable preview continuation

After action-state confirmation was added, `.build/verification-today/result.json` passed TextEdit minimize/restore/fit/restore-frame/close with lastActionResult = Window action sent. That report is copied to verification-textedit.json. Later verifier runs were interrupted by front-application changes (one caused by our UI inspection, another by normal user activity); they are not counted as passes. The verifier now waits for minimize/close transactions to settle before proceeding.

Computer Use coordinate clicks on the own demo verified fit, return to original size and close. Captures showed the right strip clearly, but this does not prove the external overlay's composite appearance. The menu-bar completion preference persisted; the Computer Use tool reopens the app's settings on subsequent activation, so its snapshot alone cannot prove absence of a welcome window at normal startup.

The limited preview is intended for informed testers; broad beta gates remain open. No clean-account or long-duration claim is made.

Short passive sample on macOS 27.0: 60.01 seconds, 31 samples, mean CPU 0.283% of one core, RSS 20,832 → 19,136 KiB. This is a short background sample, not the planned one-hour soak or an active-overlay benchmark. Packaged Gatekeeper assessment rejects the self-signed app (origin: Starboard Local Development); no bypass was performed. Preview notes explicitly disclose the lack of Developer ID/notarization.

Current release-source CI run 41455384828 passed. Public download was re-downloaded and SHA-256 verification passed. Installed release binary passive sample: 30.02 seconds, mean CPU 0.233%, RSS 23,776 → 23,872 KiB. This is not long-duration or active-overlay validation.

## Preview 2 compatibility

Safari and Finder disposable-window action reports passed: verification-safari.json and verification-finder.json. TextEdit regression also passed with the new shared engine. The standalone suite now has 41 checks (additional right-half candidate search and native fit-margin cases). Narrow Safari and crowded Finder cases hid the panel instead of overlapping controls. These do not replace physical external-panel, richer toolbar/tab/dialog, multi-display, clean-user or soak validation.

Earlier failed attempts revealed: shared active Safari focus, missing window-level AXDocument (resolved using the exact fixture WebArea URL), geometry writes clamped during native tiling, and a broad static-text label rectangle. Fixes use known complete background nodes, actual text character bounds, bounded phased writes and settled final geometry. Unknown empty groups remain rejected. Full original-plan audit: plan-audit.md.

Preview 2 source CI 41463347790 passed (11 XCTest cases, 41 standalone checks and arm64 release verification). Final Finder regression after numeric/text-bounds validation passed and replaced verification-finder.json. Build-3 DMG was mounted read-only; strict signature and arm64 checks passed. Published Preview 2 download was re-downloaded and its SHA-256 matched.

## Automatic placement / hover development

49 standalone checks and 24 offscreen AppKit button/appearance/width combinations passed. Native checks cover resolved fill/symbol contrast >=3:1, labels, minimum hit size, containment, disabled and exit states across light/dark/high-contrast themes. These are component checks, not real pointer/composite verification.

Preview, previously outside the runtime allowlist, was automatically evaluated. Its crowded ordinary strip was rejected; the shared compact strip passed the complete disposable-PDF action sequence (verification-preview.json). TextEdit regression passed after hidden-window backoff. Command-Comma settings opening, dynamic application listing and Preview exclusion toggle/restore were observed through Computer Use. Blender is not installed and was not tested. Other unverified app names must not be promoted to verified merely because automatic eligibility is enabled.

## Preview 3 publication

Source 278fd56 passed CI https://github.com/Bartu-Ercan/Rightnest/actions/runs/41472088196: 12 XCTest cases, 49 standalone checks, 24 native hover/layout combinations and arm64 release validation. Build 4 DMG passed checksum, read-only mount, strict signature, arm64 architecture and Applications symlink checks. Preview 3 is published at https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.3. The published DMG and checksum were re-downloaded using gh into .build/download-preview-3; shasum -a 256 -c passed. This is not a browser-quarantine test. Installed release updated at ~/Applications/Rightnest.app and launched in the background. Self-signing is unchanged; no new permission was silently granted. Clean-account browser download, Gatekeeper acceptance and distributed-update permission continuity remain unverified.

## Preview 4 refinement (2026-11-03)

Native Chromium tab-strip and WhatsApp navigation-spacer geometry are recognized by strict structural checks. Empty generic groups remain rejected. Safari/WhatsApp disjoint hit-test corrections require same-window ownership and fully measured background scope; actual overlapping native buttons remain blockers. 64 standalone checks and 24 native hover/layout combinations passed locally. CI for final source is recorded in STATUS.md after completion; earlier 4b94e07/a74ad9d CI results do not stand in for that final source.

Safari: verification-safari.json passed 300 visible samples over 30 seconds while a local fixture changed titles at 5Hz, followed by minimize/restore/fit/restore-frame/close. Chrome passed a 3s version of the same action flow. The attempted final 30s rerun stopped before actions when the foreground application changed to Safari; it is not a pass. No further interactive rerun was forced while the user studied. A prior Chrome 30s attempt stopped when focus changed for the user-assisted WhatsApp interval and is not a pass. Earlier failed Safari restore attempts were fixed by bounded missing-focus retries and stale-observer filtering; failed artifacts remain ignored under .build.

WhatsApp 26.38.74: verification-whatsapp.json records 42 consecutive visible samples over 51 seconds after the first startup sample (hidden). Window 1072×600. No window action was sent to the personal chat, so this verifies visibility/capability discovery only. Full-screening/maximizing, call dialogs, alternate layouts and all three WhatsApp action results remain pending.

Performance: one normal-debug-service sample with developer audit/verifier disabled used 0.14 CPU seconds over 20.015 wall seconds (0.699% of one core), RSS at end 32,400 KiB. This is a short, environment-specific sample; it is not a one-hour soak or a release benchmark. Separate 5Hz title stress samples using ps %CPU averaged 5.895% (blocked layout before pruning) and 6.845% (active layout before unchanged-control redraw suppression). These are different workloads and include startup; they are not a controlled performance comparison or idle-target passes. Whole-candidate WindowServer topmost bounding-box rejection was removed after a full-screen system carrier caused a false positive; native hit ownership checks remain.

Settings: dark appearance rendered inspection passed; Overview/Applications navigation, search, Chrome exclusion off/on and Command-Comma were checked. Semantic light/high-contrast control combinations have component checks, not a complete rendered settings/VoiceOver audit. New users are still guided by the existing explicit permission flow; no new silent permission or service was added.

After the control-update suppression, the final Chrome 30s rerun (.build/verify-chrome-release-final) ended with “Disposable document did not become focused”; foreground was Safari and actionTrace was empty. This is an interrupted verification attempt, not a positive Chrome stability result. Existing Chrome basic action evidence remains qualified to its recorded source/fixture.

Final runtime source 8682e26 passed CI https://github.com/Bartu-Ercan/Rightnest/actions/runs/41529100917: 15 XCTest cases, 64 standalone checks, 24 native combinations, arm64 release and strict bundle validation. The final build-5 DMG with updated installation notes passed read-only mount, strict signature, arm64, icon, Applications-link and SHA checks. Installed release copy passed strict signature verification and was launched in the background.

Preview 4 published: https://github.com/Bartu-Ercan/Rightnest/releases/tag/v0.1.0-preview.4. Release target 8643df3 has runtime sources identical to CI-tested 8682e26; later differences are documentation only. Public DMG and checksum re-downloaded under .build/download-preview-4; SHA-256 verification passed. This gh download does not test browser quarantine or a clean-user installation.
