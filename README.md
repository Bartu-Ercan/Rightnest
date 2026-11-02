# Rightnest

Native macOS menu-bar utility that adds **minimize, fit/restore, and close** controls to the right of supported windows. Original left-side controls remain in place. Occupied or uncertain layouts are rejected.

**Developer preview, not a universal window-control replacement.** Preview 4 evaluates all identified normal applications automatically, without an app-name allowlist. It prefers the rightmost verified anchor, trying a 102 pt strip then 66 pt compact controls before moving left. TextEdit, Safari, Finder, Preview and Chrome have passed disposable-window action tests. WhatsApp’s measured native navigation spacer has passed a read-only foreground visibility check; its three actions are not yet app-verified. Other apps, including Blender, are eligible but not thereby verified. Crowded or incomplete titlebars use a small shelf outside the window only when that desktop space is clear; otherwise controls stay hidden. Screen-filling windows may have no outside space. Safari passed 300 visibility samples over 30 seconds under repeated title changes; broad beta still requires pointer/composite, edge-case and installation validation. See [compatibility](docs/compatibility.md) and [validation](docs/validation.md).

## Use

1. Install the app into Applications; launch that installed copy.
2. Try the permission-free test window.
3. Choose **Set Up Window Control…**, enable the app in macOS privacy settings, and return. The app checks the actual permission; opening Settings alone does not grant it.
4. Enable external controls and try a standard TextEdit window. When there is no verified free space, nothing is shown.
5. Choose **Continue in menu bar**. Subsequent launches stay in the menu bar. Settings, pause and quit remain available there.

The middle button fits the window into its display's usable area, leaving the Dock/menu bar visible. Press again to restore its previous frame. Manual resizing invalidates that restore record; records are kept only during the current session. Close means close the window, not quit the application. Save prompts belong to the target application.

Minimize/fit/close hover fills are system yellow/green/red, with contrasting dark symbols. App exclusions are available in the menu and Settings, including newly running apps. English and Turkish follow the system language. Launch at login is off by default. No account, network service, telemetry, screenshots, screen-recording permission or process injection.

## Download and installation

Download the limited developer preview from [GitHub Releases](https://github.com/Bartu-Ercan/Rightnest/releases). Locally generated DMGs are **developer previews**, not production releases. Builds use a local certificate or ad-hoc signature, **not Apple Developer ID or notarization**. macOS may block downloaded copies, and managed devices may prohibit them. Open source does not remove Gatekeeper checks. No protection-disabling commands are part of our installation instructions.

[Installation, update and removal](docs/INSTALL.md) · [Türkçe kurulum](docs/INSTALL.tr.md) · [Privacy](docs/PRIVACY.md)

## Build

Apple Silicon Mac, Swift 6.0+ and a macOS SDK are required. The API deployment target is macOS 13; that is not a claim of device-tested compatibility. The current test host runs macOS 27.0 (26A428). Full Xcode is needed for XCTest; standalone regression checks also work with Command Line Tools.

```sh
swift run PlacementChecks
./script/check_hover.sh          # offscreen AppKit hover/layout checks
swift test                       # full Xcode environment
./script/build_and_run.sh         # debug build, install in ~/Applications, launch
./script/build_and_run.sh --build # build only, does not stop the running app
./script/build_and_run.sh --release
./script/package.sh              # release DMG and SHA-256, no upload
```

`--verify` checks process launch only. `--debug` uses LLDB; `--logs` streams process logs. All source, documentation, scripts and assets belong in this repository. Installed app copies live in Applications.

### Stable local signing

```sh
python3 script/setup_local_signing.py
./script/build_and_run.sh
```

This requires modern OpenSSL and creates an isolated local signing keychain. It does not install a system trust root or grant Accessibility access. Key material stays outside the repository. `RIGHTNEST_SIGNING_IDENTITY` can select an existing certificate. CI uses ad-hoc signing; its artifact is not a continuity-preserving public update.

The prototype was named Starboard. Its internal bundle ID (`dev.bartuercan.starboard`), local certificate name and signing storage location are deliberately retained to avoid needless identity churn. The local installer migrates the earlier app name. Do not run both copies. Public-facing app and project names are Rightnest.

### Developer verification

The following is debug-only and controls **only a disposable fixture matched by AXDocument URL**. Quit a running copy first and let TextEdit stay in front during the test. User focus changes intentionally cancel actions.

```sh
./script/build_and_run.sh --build
./script/install_local.sh
open -n "$HOME/Applications/Rightnest.app" --args --verify-textedit "$PWD/.build/verification"
```

The JSON report is written under that directory. It exercises real proxy NSButtons with `performClick`; this does not prove physical mouse hit testing or composite appearance. `--audit-compatibility <directory>` is a separate debug-only, read-only geometry audit of running normal apps. It records no titles, document paths or content. `--verify-app <report-directory> <bundle-id> <fixture-path>` reuses the fixture verifier for an explicitly prepared disposable window in another app. All developer entrypoints are excluded from release binaries.

For a browser stress check, load [Checks/Fixtures/window-stability.html](Checks/Fixtures/window-stability.html) in a new single-tab Safari window or Chrome Guest window, then invoke the matching debug verifier with that fixture path. It observes visibility for 30 seconds before actions; keep that window in front. Multi-tab browser windows are rejected. A separate macOS Space does not isolate a shared app session; use an actually isolated test account/environment for uninterrupted verification.

## Contribute

[Architecture and decisions](docs/decisions.md) · [Design](docs/design.md) · [Contributing](CONTRIBUTING.md) · [Release process](docs/RELEASE.md) · [Changelog](CHANGELOG.md)

Licensed under [MIT](LICENSE). No third-party runtime dependencies. System frameworks and SF Symbols are supplied by Apple; they are not redistributed as an independent icon library. Rightnest is a working product name; unrelated uses of the name exist. It is not affiliated with those products.
