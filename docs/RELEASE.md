# Reproducible release process

Current channel: **0.1.0 early access**, published as GitHub Latest at the user’s explicit request. This supersedes the earlier preview-only publication gate; it does not claim all broader beta/stability/install checks passed. Preserve the known limitations in release notes and README.

## Prerequisites

Apple Silicon build host, Swift 6.0+ and macOS SDK; full Xcode for XCTest. Modern OpenSSL is needed only to provision the optional isolated local signing identity. Do not copy private signing material into GitHub or this repository.

## Build and validate

1. Run `swift run PlacementChecks`, `swift test` with Xcode, and the disposable integration test described in README.
2. Use the same local signing identity for successive distributed previews. Record its public certificate fingerprint and bundle ID; never record/export its password or private key in release notes. CI's ad-hoc signing does not preserve identity across changed binaries.
3. Prepare the pinned build tools with `python3 -m venv .build/dmg-tools` and `.build/dmg-tools/bin/pip install -r script/packaging-requirements.txt`, then run `./script/package.sh`. This invokes the release configuration for arm64, verifies the copied bundle and rejects debug audit/test entrypoint strings, then builds the custom DMG, mounts it read-only, verifies the embedded signature/architecture/license and two-item Finder layout, and writes its SHA-256.
4. Mount the DMG read-only, check Rightnest.app and the Applications shortcut, verify the app signature, then eject. Test an actual installed copy on a clean user account and another Mac before uploading.
5. Test a real browser download, Gatekeeper behavior, explicit user-granted window-control permission, login opt-in, normal launch after onboarding, update with preserved settings, permission continuity and removal. Do not simulate this by stripping quarantine.
6. Review source/artifact contents for secrets and personal data. Attach checksums, supported app/macOS list, source commit, toolchain version, known limitations and install instructions.

## Publish gate

For this early-access publication, the user explicitly requested a normal GitHub release marked Latest. Use tagv0.1.0, a clear Early Access title and known limitations; do not use the prerelease flag, which cannot serve the requested Latest channel. A future broad/stable release still needs the open physical-pointer, clean-user/quarantine/update, one-hour and device/display checks. No notarization is performed. Source and downloadable installer are distinct deliverables; verify the public asset checksum after publication.

The app's optional `RightnestReleasesURL` Info.plist value must point to the actual repository's HTTPS releases page. If absent, the UI states no public release is available. There is no updater or silent download.

## Installation identity

Historical bundle ID: `dev.bartuercan.starboard`. The product rename retained it and the existing local certificate. Renaming the visible app does not mean the certificate should be regenerated. The local installer migrates the older named installed copy. Changing bundle ID/certificate is a separate migration and may require a new user grant.

## CI

`.github/workflows/check.yml` runs XCTest, standalone/native regression checks, arm64 release bundling, debug-entrypoint exclusion and custom mounted-DMG checks on a full-Xcode macOS runner. It uploads a short-lived CI artifact; it does not publish releases or receive signing keys. A workflow file being present is not evidence of a successful GitHub run.
