# Historical prototype investigation

Superseded by validation.md. These are chronological earlier results, not current support claims.

# Prototype validation — 2026-11-02

## Current status (supersedes the earlier investigation notes)

TextEdit developer integration verification passed for one disposable file: live permission, visible proxy panel, minimize, restore, enter full screen, exit full screen and close. The verifier invokes the real panel NSButtons with `performClick` and checks resulting AX window state; it is not a physical mouse/keyboard or visual-compositing test. See `verification-textedit.json`. Eighteen standalone checks pass. Strict installed-app signature verification passes. Permission survived multiple subsequent rebuilds/updates using the same local signing certificate. Global app compatibility and production readiness remain unverified.

Environment: Apple Silicon, Swift 6.1.2, Command Line Tools. No full Xcode installation.

## Passed

- Rightnest SwiftPM app compiles in Swift 6 mode without compiler warnings.
- `./script/build_and_run.sh --verify`: local ad-hoc signed .app starts; process observed.
- `swift run PlacementChecks`: seven checks pass: negative display coordinates, collision and near-collision, unknown layout, content-area rejection, non-finite row, narrow window rejection.
- Computer Use inspected the running native UI. The demo visibly shows all three right-side controls and retains native left controls.
- Clicking right-side Minimize changes the test window to a minimized/dialog state; Raise restores it.
- Clicking right-side Full Screen expands the demo to the display. View → Exit Full Screen returns it to normal.
- Clicking right-side Close closes the demo and returns to the welcome window.
- The welcome window presents TextEdit support off by default and permission guidance. No Accessibility permission was granted by the agent.

## Not validated / limitations

- `swift test` cannot run here: `no such module XCTest`. Test source is retained. Standalone geometry checks passed; they are not a substitute for UI and cross-app testing.
- External TextEdit control requires user-granted Accessibility permission. No external-app control, placement or action is claimed as verified.
- The owned-window accessory proves its own layout/actions; it does not prove the separate external panel's positioning, activation, occlusion or collision detection.
- Custom-drawn/AX-incomplete toolbars cannot be proven safe with Accessibility alone. Only a strict TextEdit experiment is enabled as an option; other apps are rejected.
- Full-screen Spaces, app switching, fast dragging/resizing, multiple displays, sheets, permission revocation and energy impact require additional cross-app testing. Polling is a prototype implementation.
- Only the current Mac and dark system appearance were visually inspected. Light/high-contrast/reduced-transparency and assistive-technology testing remain pending.
- Public Developer ID signing/notarization, Intel/universal builds, clean-machine installation, license and GitHub Release packaging remain pending.

No production compatibility or universal no-overlap promise is made.


## Permission onboarding iteration

- Observed the macOS 27 permission pane directly: Device Control and Data Access, Rightnest switch on. The existing app still reported not trusted after restart. This is consistent with a stale development-signature grant but the cause is not proven from the UI alone.
- `security find-identity -v -p codesigning`: zero valid signing identities. Current app designated requirement is a cdhash. No certificate was provisioned and no system permission toggled by the agent.
- App and core compile in Swift 6 mode. Seven placement checks and eight permission-state combinations pass. Live trust takes precedence over all saved preferences.
- Native UI inspected: required state, primary setup action, waiting state, OS-specific settings label, recheck action, expandable recovery instructions, scrollable long help and permission-free demo entry.
- The permission-setup button successfully opens the correct macOS 27 settings pane. No permission grant was performed by the agent.
- Actual granted/revoked UI transitions and external TextEdit operation remain pending a fresh grant for this exact development binary. Pure state checks do not establish actual permission or app compatibility.


## Permission grant investigation

- User reported re-adding/enabling Rightnest. The live app still returned not trusted, including after an app restart without a rebuild.
- `codesign --verify --strict` found a disallowed `com.apple.FinderInfo` xattr at the Desktop app bundle root. Removing only that generated metadata allowed strict verification to pass without changing its executable signature. The attribute subsequently reappeared. The producer of that metadata was not established; Desktop file-provider synchronization is a hypothesis, not a proven cause.
- TCC logs specifically report `Failed to match existing code requirement` for `dev.bartuercan.starboard`. Recorded old requirements differ from the current ad-hoc cdhash. The private-entitlement recommendation also appears in the logs; no private entitlement was added.
- Copied the same executable/signature (no rebuild or re-sign) into `~/Applications/Rightnest.app` with extended metadata excluded. Strict signature validation passed for the installed copy. It still showed waiting for permission; user action for this installed copy is pending.
- Added `script/install_local.sh` for clean staging, signature verification, replacement/rollback and no-op installation for identical verified artifacts. The development build script now replaces its executable atomically instead of overwriting its inode in place.
- External TextEdit action tests are still pending. No systemwide permission reset or silent permission grant was performed.


## Installed-app permission verified; TextEdit validation in progress

- After the user added `~/Applications/Rightnest.app`, the live app transitioned automatically to **Window control is allowed / READY**. This verifies real permission detection, not only the pure presentation-state tests.
- **Try in TextEdit** enabled the experiment and launched TextEdit. Created one blank, unsaved test document. The initial build reported **Hidden: occupied or unverified title bar**. No external close/minimize/full-screen action was dispatched or claimed successful.
- Code review identified that the five-point control safety gap was incorrectly also applied to the large document scroll-area container. Added a regression check: content below the titlebar does not collide, interactive controls still receive the gap, and genuinely intersecting content is still rejected. The exact blocker in the live TextEdit window was not independently isolated in the old build.
- Added explicit placement rejection reasons for missing geometry, unknown roles, incomplete hierarchy, inspection limits, actual content overlap and occlusion. Unsupported window state is distinguished from placement failure.
- Updated build installed to `~/Applications/Rightnest.app` and compiled without warnings. Eighteen standalone checks pass (7 placement + 8 permission-state + 3 obstacle regressions). XCTest still requires full Xcode.
- After this ad-hoc update, the live app correctly displayed **Window control needs permission again**, confirming the prior-grant/missing-current-trust presentation path. A fresh user grant for the updated binary is pending before external-action testing. No permission was granted by the agent.


## Stale permission record repair

- On the next user-confirmed re-add, live trust was still false even after restarting the installed app without rebuilding. System Settings showed Rightnest enabled.
- Targeted TCC logs establish the mismatch: stored code requirement `6219c658…` versus current installed `ecaa63e4…`, with `SecStaticCodeCheckValidity` status -67050. The current installed bundle passes strict signature verification.
- Reset only this app's Accessibility approval using `tccutil reset Accessibility dev.bartuercan.starboard`; the command succeeded. Other app permissions were not reset. No system service was restarted and no private entitlement added.
- Prepared the native Add-file dialog with the exact installed `~/Applications/Rightnest.app` selected. The user must perform final Open and enable its switch. No new build or re-sign occurred during this repair/test.


## Stable local signing and successful integration verification

- Generated a code-signing identity in a separate keychain under `~/.local/share/starboard-signing`. Only codesign receives private-key access. The normal user keychain search list remains unchanged. No system trust root was installed. Private identity material is outside the source checkout.
- Two different copied executables signed with this identity produced the same designated requirement (identifier + pinned certificate), rather than a per-binary cdhash. After the user granted the new identity access, actual subsequent app updates preserved the granted state without another permission toggle.
- Build assembly/signing now happens in an automatically cleaned local temporary directory. Signed output is copied to project dist and installed through a clean staging directory; strict verification is performed before installation. This avoids metadata being added to the package during signing on Desktop.
- The titlebar occlusion test initially observed Rightnest's own just-hidden panel during action validation. The fix hides the panel, suppresses refresh while dispatch is pending, and retries at 50 ms intervals up to six times only when the occluder is Rightnest itself. Actual target identity, permission, app focus and geometry are revalidated before dispatch. Other/unknown occlusion still cancels the action.
- Explicit developer-only `--verify-textedit <directory>` creates an empty disposable .txt, matches its AXDocument URL before control, invokes the actual panel NSButtons, and checks each resulting window state. It handles leftovers from interrupted fixture runs. It does not control an arbitrary pre-existing document. Test-only animation waits avoid sending restore commands during macOS Space/minimize animation transitions.
- Latest result: permission granted, panel visible, minimize passed, restore passed, full screen passed, full-screen exit passed, close passed, result passed. Last action sent, titlebar verified. No permission reset was needed between these local-certificate app updates.
- Native Computer Use snapshots exclude the separate overlay window when capturing TextEdit; a coordinate-click attempt returned a tool error. Physical pointer hit testing, composite visual placement and energy/flicker behavior therefore remain manual verification items. The integration result must not be presented as universal visual verification.
- `swift run PlacementChecks`: 7 geometry + 8 permission state + 3 titlebar regression checks passed. Shell syntax and local-signing Python syntax checked. Installer's identical-artifact/no-op path verified. Installed signature strict verification passed.
