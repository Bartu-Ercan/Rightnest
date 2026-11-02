# Compatibility — developer preview

API baseline: macOS 13. Actual host observations below: Apple Silicon, macOS 27.0 (26A428), 2026-11-02. No older macOS or Intel device claim is made.

| Application | Version observed | Current state | Evidence / limitation |
|---|---|---|---|
| TextEdit | 1.21 | Limited; enabled | Disposable document action integration; physical pointer/composite and edge cases still pending. |
| Finder | 27.0 | Limited; enabled in Preview 2 | Unique disposable folder window at 1760 pt passed all actions. 1469 pt crowded long-title layout hid controls. Native character bounds separate title ink from blank label space. |
| Safari | 27.0 | Limited; enabled in Preview 2 | Disposable local HTML window passed minimize, restore, fit, restore-frame and close. Narrow 880 pt window correctly hid controls. |
| Chrome | 156.0.8078.79 | Unsupported; disabled | Unknown empty titlebar group; cannot prove free space. |
| Preview | 11.0 | Unsupported; disabled | Blank PDF window hierarchy rejected at AXSplitGroup; background read-only observation, not a foreground action test. |

Raw, content-free observations: compatibility-observations.json (foreground sampling) and compatibility-background-observations.json (explicit background probes marked with foreground=false). Background results are never treated as visible placement or action proof.

Earlier layout rejections were conservative implementation results, not proof that support was impossible. A future app-specific adapter must understand the relevant container and still prove no collision with interactive toolbar items. Do not simply classify all groups as empty or enable bundle IDs.

## Release gate

The normal-action threshold (TextEdit plus two daily apps) is now met by the recorded Safari and Finder fixtures. This is still a limited preview: physical external-pointer/composite checks, richer app/window scenarios and installation/soak gates remain open. Before enabling another app, test standard/compact/tabbed windows, open menus, dialogs/save sheets, move/resize, occlusion, full-screen/Spaces transitions, all three actions, and manual fit restoration. Record app and OS versions. Unknown layouts remain hidden even for an enabled app.
