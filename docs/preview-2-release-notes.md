# Rightnest 0.1.0 Preview 2

Adds limited **Safari and Finder** support alongside TextEdit on Apple Silicon Macs. The app adds controls; it does not move/remove the originals.

## What works

Disposable-window integration tests passed in all three apps: panel visible, minimize, return from minimized, fit to usable screen, restore previous frame and close. TextEdit was rerun after the shared engine changes. Safari test window: 1469 × 700 pt; Finder: 1760 × 700 pt on a 1920 pt display. These are test geometries, not universal minimum-width requirements.

Controls search from the far right toward the titlebar midpoint. Native groups and true text bounds are inspected. **Narrow/crowded windows intentionally hide controls.** Try widening a window if the menu says there is no clear space. Finder's search field, view controls and long titles can consume the available space. Chrome and Preview remain disabled.

Fit/restore now waits for geometry changes and settles native tiling transitions before saving the restore frame. The original window identity, focus and permissions are revalidated throughout. A small native fit margin is accepted; restoration still uses the recorded frame.

## Install / update

Quit the old copy, download the DMG, drag Rightnest to Applications, eject the image and launch the installed copy. Keep one installed copy. Follow the permission card if needed. Previous local signing identity is retained; no silent permission grant is performed.

**Self-signed; not Apple Developer ID signed or notarized.** Gatekeeper rejects this local certificate in assessment and may block downloaded copies. Review the source and use a per-app Open Anyway choice only if macOS offers it and you accept the limitation. Managed Macs may prohibit installation. Do not disable Gatekeeper or remove quarantine. Full instructions: docs/INSTALL.md and docs/INSTALL.tr.md.

## Verification limits

41 standalone checks pass locally; source CI is linked in Actions. Developer tests invoke real proxy NSButtons with performClick, not physical external-panel pointer input. Own demo pointer tests exist, but external composite visuals, dialogs/menus/tab variations, multiple displays/Spaces, clean-account/browser-download installation, older OS versions and one-hour soak remain incomplete. No broad beta or stable-release claim is made. See docs/plan-audit.md for the full original-plan audit.

Current source CI passed: https://github.com/Bartu-Ercan/Rightnest/actions/runs/41463347790. The downloadable arm64 bundle is build 3; its staged signature, architecture and disk-image checksum were verified locally. The separate-user/downloaded installation and long-duration limitations above still apply.
