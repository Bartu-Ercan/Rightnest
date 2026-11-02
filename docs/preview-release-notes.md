# Rightnest 0.1.0 Preview 1

Limited **TextEdit-only** developer preview for Apple Silicon Macs. Adds right-side minimize, fit/restore and close controls; original left-side controls remain. Unknown/occupied titlebars hide the controls. Finder, Safari, Chrome and Preview are not enabled.

## Install

Download the arm64 DMG and drag Rightnest to Applications. Eject the image, open the installed copy, try the demo and follow permission setup. Installation details: docs/INSTALL.md (English) and docs/INSTALL.tr.md (Turkish) in the repository.

**Not Apple Developer ID signed or notarized.** macOS may block the download. A local certificate is not verification by Apple. Only consider the system's per-app Open Anyway option after reviewing the source. Managed Macs may not permit it. Do not disable Gatekeeper or remove quarantine as an installation method.

## Validation and limits

- Standalone geometry, permission and surface-order checks: 34 passed.
- Prior remote CI: 9 XCTest cases plus release validation passed; see linked Actions runs for current source.
- Disposable TextEdit tests exercise minimize, fit, restore and close through the proxy button path.
- Own demo fit/restore and close tested with coordinate pointer clicks.
- Physical pointer/composite validation of the external overlay, clean-account Internet-download installation, older macOS versions, multi-display/Spaces edge cases and long-duration use remain incomplete.

The API baseline is macOS 13, but device testing is on the developer's macOS 27 host. Intel is not provided. This is a test build for reviewers, not a general-purpose stable release. No account, analytics or automatic updater.

Current source CI passed: https://github.com/Bartu-Ercan/Rightnest/actions/runs/41455384828. Local release build, 34 regression checks and staged package signature/architecture checks passed. A clean separate-user download/install has not been verified. Local Gatekeeper assessment rejects this self-signed build; the installation caveat above is a real limitation, not hypothetical.
