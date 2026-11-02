# Validation — Rightnest developer preview

## Verified

- 34 standalone checks: placement 7, permission combinations 8, obstacle regressions 3, display/restore geometry 9, surface ordering 7.
- Last recorded disposable TextEdit integration passed minimize, restore from minimized, fit, restore original frame and close. See verification-textedit.json. This uses real proxy NSButtons via performClick, not physical pointer input. The action trace ends with “Window action unavailable” despite observing the fixture close; that diagnostic discrepancy remains unresolved and the run is not a broad release approval.
- Prior intermediate fit runs failed from certain starting origins. The last recorded source separates shrink, move and final size, waiting for observed geometry. No new foreground run was performed while the user was studying.
- Existing local-certificate permission survived product rename in the prior session.

## Pending release gates

- Actual pointer/composite visuals, drag/resize, menus/sheets, focus races and display/Spaces transitions.
- Two additional daily-use apps. Current background/foreground audits reject Finder, Safari, Chrome and Preview; see compatibility.md.
- Clean-user downloaded installation, Gatekeeper experience, update permission continuity for distributed packages, login-item registration.
- One-hour soak, idle CPU target below 1%, stable RSS; older OS/device coverage.
- XCTest requires full Xcode, unavailable on this host. CI workflow is configured but not yet run remotely.

The app remains a developer preview. Historical full-screen prototype tests are archived in prototype-investigation.md and do not validate the new fit behavior.

## Current background checks

- Arm64 release compilation passed. Packaging initially failed because of incorrect lipo argument order; fixed in both local and CI scripts.
- Packaging's debug-entrypoint scan caught command-line flag strings retained by an unconditional onboarding guard. Guard now compiles these references only under DEBUG; packaging is rerun after the fix.
- `swift test` still fails with `no such module XCTest` on this Command Line Tools installation. The 34 standalone checks remain the available local automated suite.
- Desktop output can acquire Finder metadata after signing; direct strict verification of that copy detected it again. Packaging copies without extended metadata and verifies the clean staged bundle. Do not equate a mutable Desktop copy with a verified downloaded installation.
- No interactive launch or new permission grant was performed during this background continuation.

## Packaged artifact verified

`dist/Rightnest-0.1.0-preview-arm64.dmg` was produced after the fixes. DMG checksum verification passed. The image was mounted read-only with nobrowse, its app passed strict codesign verification and arm64 architecture verification, AppIcon.icns and Applications symlink were present, and the image was ejected. No app was launched. This validates package structure and local signature, not Gatekeeper acceptance or clean-user installation.
