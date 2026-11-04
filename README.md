# Rightnest

Native macOS menu-bar utility that adds **minimize, fit/restore, and close** controls to the right of supported windows. Original left-side controls remain in place. Occupied or uncertain layouts are rejected.

**Developer preview, not a universal window-control replacement.** Preview 4 evaluates all identified normal applications automatically, without an app-name allowlist. It prefers the rightmost verified anchor, trying a 102 pt strip then 66 pt compact controls before moving left. TextEdit, Safari, Finder, Preview and Chrome have passed disposable-window action tests. WhatsApp’s measured native navigation spacer has passed a read-only foreground visibility check; its three actions are not yet app-verified. Other apps, including Blender, are eligible but not thereby verified. Crowded or incomplete titlebars use a small shelf outside the window only when that desktop space is clear; otherwise controls stay hidden. Screen-filling windows may have no outside space. Safari passed 300 visibility samples over 30 seconds under repeated title changes; broad beta still requires pointer/composite, edge-case and installation validation. See [compatibility](docs/compatibility.md) and [validation](docs/validation.md).

The working branch contains a Preview 5 / build 6 candidate with a fixed corner during temporary occlusion and application status groups. A covering system indicator hides the native strip; it reappears at the same position and size instead of sliding or narrowing. Before the fixed-corner refinement, Chrome completed an 1800-second disposable Guest-window session and all actions; Safari also completed 1800 active seconds and all actions. The new policy has separate regression evidence in STATUS. Actual OS HUD and broader interaction/install gates remain open. It is not a published release; current measured gates are tracked in [STATUS](docs/STATUS.md).

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
./script/build_and_run.sh --profile-build # optimized local DEBUG instrumentation; never distribute
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
open -g -n "$HOME/Applications/Rightnest.app" --args --verify-textedit "$PWD/.build/verification"
```

The JSON report is written under that directory. It exercises real proxy NSButtons through their native accessibility press action (dispatching `performClick`); this does not prove physical mouse hit testing or composite appearance. `--audit-compatibility <directory>` is a separate debug-only, read-only geometry audit of running normal apps. It records no titles, document paths or content. `--verify-app <report-directory> <bundle-id> <fixture-path-or-loopback-URL>` reuses the fixture verifier for an explicitly prepared disposable window in another app. All developer entrypoints are excluded from release binaries.

For a browser stress check, load [Checks/Fixtures/window-stability.html](Checks/Fixtures/window-stability.html) in a new single-tab Safari window or Chrome Guest window, then invoke the matching debug verifier with that fixture path. It observes visibility for 30 seconds before actions; keep that window in front. Add `--stability-seconds 1800` for the candidate long-session verifier: 50 geometry samples, 20 synthetic occlusion cycles, cumulative CPU windows and 30 active minutes before actions (focus pauses excluded). Use a freshly loaded fixture; its title changes at 5 Hz for 180 seconds, then becomes idle. `progress.json` reports the running phase. Synthetic occlusions do not substitute for actual volume/brightness HUD tests. Passive observation pauses when another app/window is focused; it never activates the fixture to resume. Progress records active/paused/wall time. Interrupted continuous CPU workloads are not counted as passes. Preparation, geometry/HUD phases and window actions still cancel on unexpected target changes. A failed acceptance metric remains a failed gate even if the final action sequence succeeds. The verifier waits for 500 ms of stable preparation geometry before observing the window. For normal-service CPU, load the static `Checks/Fixtures/window-idle.html` and use `--measure-idle <report-directory> <bundle-id> <fixture-path>`: 30-second warmup, then five 60-second cumulative CPU windows; no window actions or 10 Hz AX polling. This separate measurement does not erase failed instrumented measurements. Use `--profile-build` for optimized instrumentation when comparing against the normal-service CPU target; record the configuration. This local profiling bundle contains test entrypoints and must not be distributed. Packaging rebuilds the release configuration and rejects those entrypoints. If a local file will not load in the test browser, optionally serve `Checks/Fixtures` with Python 3 (`python3 -m http.server 8765 --bind 127.0.0.1 --directory Checks/Fixtures`), open `http://127.0.0.1:8765/window-stability.html` in the prepared Guest window, and pass that exact URL to `--verify-app`. Only HTTP URLs whose host is exactly `127.0.0.1` are accepted by this debug argument; other inputs remain file paths. Stop the temporary server after testing. Release builds have neither this entrypoint nor a server. Multi-tab browser windows are rejected. Native AXDocument fixture shortcuts are restricted to TextEdit/Preview; other app types can require an explicit safe fixture verifier. A separate macOS Space does not isolate a shared app session; use an actually isolated test account/environment for uninterrupted verification.

For an actual release-service measurement without in-process instrumentation, first install/launch the release and keep the static Chrome Guest fixture in front with its controls visible, then run:

```sh
swiftc -swift-version 6 script/measure_service_cpu.swift -o .build/ServiceCPU
.build/ServiceCPU "$(pgrep -x Rightnest)" com.google.Chrome "$PWD/.build/service-cpu"
```

The finite read-only monitor uses cumulative process CPU after warmup, checks the foreground app and visible panel, and records five 60-second windows. It never activates apps or invokes window actions; foreground/panel changes invalidate the run.

## Contribute

[Architecture and decisions](docs/decisions.md) · [Design](docs/design.md) · [Contributing](CONTRIBUTING.md) · [Release process](docs/RELEASE.md) · [Changelog](CHANGELOG.md)

Licensed under [MIT](LICENSE). No third-party runtime dependencies. System frameworks and SF Symbols are supplied by Apple; they are not redistributed as an independent icon library. Rightnest is a working product name; unrelated uses of the name exist. It is not affiliated with those products.
