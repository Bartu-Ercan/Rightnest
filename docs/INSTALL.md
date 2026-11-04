# Install, update and remove Rightnest

## Before installing

Current status: **0.1.0 early access**, Apple Silicon only. [Open the latest release](https://github.com/Bartu-Ercan/Rightnest/releases/latest) and download `Rightnest-0.1.0-arm64.dmg` under Assets. Safari and Chrome are the primary targets; other applications are evaluated automatically but are not universally supported. Safe space is required. Disable an app in Settings → Applications if its layout does not suit you.

API minimum: macOS13. Tested host: Apple Silicon/macOS27.0(26A428). Older macOS versions, clean-user installation/update and managed-device behavior have not been fully validated. See the [compatibility table](compatibility.md).

The app is **not Developer ID signed or notarized**. A local signature verifies package integrity but is not Apple's verification of the publisher. macOS can display an unidentified-developer warning or block a downloaded copy. Managed Macs may disallow it altogether. Do not disable Gatekeeper or remove quarantine through Terminal. If macOS offers an explicit per-app **Open Anyway** choice under Privacy & Security, use it only after checking the source and accepting that limitation. If it is unavailable, stop; source builds are intended for developers, not a mandatory end-user workaround.

## Install

1. Open the DMG. Its custom installation window shows Rightnest and the Applications shortcut. Drag Rightnest onto Applications, then eject the disk image.
2. Launch the installed copy, not the one inside the DMG. Keep only one active copy.
3. Try the built-in test window before granting access.
4. Choose **Set Up Window Control…**. In System Settings → Privacy & Security, find the window-control permission pane: **Accessibility** on earlier systems; **Device Control and Data Access** on the tested macOS 27 host.
5. Enable Rightnest and return. Only a live system check shows Ready.
6. Turn on **Automatically place controls in other apps**, try a normal Safari/Chrome window (or choose **Try in TextEdit**), then choose **Continue in menu bar**.

No screen-recording, microphone, camera, full-disk or administrator access is requested. Login startup is optional and off initially.

## If controls are hidden

Check menu-bar status and **Automatically place controls in other apps** in Settings. The app hides controls for unsupported states, dialogs, full-screen windows and permission loss. An uncertain/occupied titlebar can use an outside shelf only if that desktop space is clear; screen-filling windows may leave no outside space. Making a supported window wider can help only if its right titlebar actually has clear space. Do not change system protections to make unsupported layouts work.

If permission is on but the app reports it missing, quit and reopen the installed copy. Check that there is no old duplicate. The app's Finder button reveals its exact location. Replacing an old permission entry may be necessary after a signing-identity change. Routine updates signed by the same local identity preserved permission in development; downloaded-distribution update continuity still needs independent testing.

## Update

Quit Rightnest, replace the installed app with the new version from the same publisher, then reopen. Settings remain in the app's preferences. The menu's Releases item opens the configured GitHub releases page; there is no automatic download or installation. Do not install a second copy beside the first.

## Remove

Turn off Launch at login, quit from the menu bar, and move the installed app to Trash. Remove its entry from the macOS window-control permission pane if desired. A separate privileged service is not installed. Optional preference cleanup uses the historical domain `dev.bartuercan.starboard`; deleting preferences resets onboarding and app choices. Developers' isolated signing keychain is a separate tool asset, not installed by the DMG.

## Verification status

Local install and signatures are tested. Internet quarantine, a clean separate user account, managed-device behavior, older macOS releases and Intel are not yet verified. See validation.md before describing this as a general release.
