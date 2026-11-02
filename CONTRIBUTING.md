# Contributing

Use Swift 6, SwiftUI for settings and AppKit only for the native panel/window boundary. No runtime dependencies are required. Keep all project code, assets, tests and documentation in this repository.

Before a change: read docs/decisions.md and docs/compatibility.md. Run `swift run PlacementChecks`; with full Xcode run `swift test`. Build both debug and release. Any change to window placement/actions needs a disposable-document integration test and real pointer/visual checks. Do not test close actions against personal unsaved documents.

Never add an app to the enabled support list just because its bundle ID is known or one empty window works. Record app/macOS version, window type, collision cases, dialogs, focus changes, drag/resize and all actions. Unknown Accessibility data must reject placement. Never waive checks to make a demo pass.

Do not commit signing keys, keychain passwords, tokens, personal paths, user document contents or generated .build/dist artifacts. Use `RIGHTNEST_SIGNING_IDENTITY` for an existing identity, or the documented isolated local signing helper. CI artifacts are ad-hoc builds, not public signed updates.

Keep Turkish and English UI entries paired. Update the architecture, compatibility matrix, installation instructions and changelog with user-visible changes. Submit focused pull requests with behavior and verification evidence.
