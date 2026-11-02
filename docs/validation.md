# Validation — Rightnest developer preview

## Verified

- 34 standalone checks: placement 7, permission combinations 8, obstacle regressions 3, display/restore geometry 9, surface ordering 7.
- Last recorded disposable TextEdit integration passed minimize, restore from minimized, fit, restore original frame and close. See verification-textedit.json. This uses real proxy NSButtons via performClick, not physical pointer input. The earlier acknowledgement discrepancy was fixed by confirming the observed action result. The current saved report ends with Window action sent; this still is not broad release approval.
- Prior intermediate fit runs failed from certain starting origins. The last recorded source separates shrink, move and final size, waiting for observed geometry. No new foreground run was performed while the user was studying.
- Existing local-certificate permission survived product rename in the prior session.

## Pending release gates

- Actual pointer/composite visuals, drag/resize, menus/sheets, focus races and display/Spaces transitions.
- Two additional daily-use apps. Current background/foreground audits reject Finder, Safari, Chrome and Preview; see compatibility.md.
- Clean-user downloaded installation, Gatekeeper experience, update permission continuity for distributed packages, login-item registration.
- One-hour soak, idle CPU target below 1%, stable RSS; older OS/device coverage.
- XCTest requires full Xcode, unavailable on this host. Remote CI passed: https://github.com/Bartu-Ercan/Rightnest/actions/runs/41454033532 (9 XCTest cases, 34 standalone checks, arm64 release and artifact validation).

The app remains a developer preview. Historical full-screen prototype tests are archived in prototype-investigation.md and do not validate the new fit behavior.

## Current background checks

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
