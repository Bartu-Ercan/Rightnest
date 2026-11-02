# Compatibility — automatic placement preview

API baseline: macOS 13. Actual host observations below: Apple Silicon, macOS 27.0 (26A428), 2026-11-02. No older macOS or Intel device claim is made.

| Application | Version observed | Current state | Evidence / limitation |
|---|---|---|---|
| TextEdit | 1.21 | Limited; enabled | Disposable document action integration; physical pointer/composite and edge cases still pending. |
| Finder | 27.0 | Limited; enabled in Preview 2 | Unique disposable folder window at 1760 pt passed all actions. 1469 pt crowded long-title layout hid controls. Native character bounds separate title ink from blank label space. |
| Safari | 27.0 | Limited; enabled in Preview 2 | Disposable local HTML window passed minimize, restore, fit, restore-frame and close. Narrow 880 pt window correctly hid controls. |
| Chrome | 156.0.8078.79 (earlier audit) | Automatic eligibility; not action-verified | Earlier audit exposed an unknown empty titlebar group. Such unknown geometry still rejects placement; no recent positive action result is claimed. |
| Preview | 11.0 | Automatic; basic actions verified | Disposable PDF passed minimize, return, fit, restore-frame and close with a 66 pt compact strip in a 1760 pt window. 102 pt strip correctly did not fit. |

Raw, content-free observations: compatibility-observations.json (foreground sampling) and compatibility-background-observations.json (explicit background probes marked with foreground=false). Background results are never treated as visible placement or action proof.

Earlier layout rejections were conservative implementation results, not proof that support was impossible. A future app-specific adapter must understand the relevant container and still prove no collision with interactive toolbar items. Do not simply classify all groups as empty or enable bundle IDs.

## Automatic eligibility is not universal compatibility

There is no app-name allowlist in Preview 3. Identified regular apps are checked as they become active; user exclusions win. The table records test evidence, not permission to inspect an app. Blender is not installed on the test Mac and remains unverified. A custom-drawn or AX-incomplete titlebar can still be rejected. No image recognition, injection or blind forced positioning is used. Running apps appear in Settings; excluded apps remain listed even after closing.

## Release gate

The normal-action threshold (TextEdit plus two daily apps) is now met by the recorded Safari and Finder fixtures. This is still a limited preview: physical external-pointer/composite checks, richer app/window scenarios and installation/soak gates remain open. Before enabling another app, test standard/compact/tabbed windows, open menus, dialogs/save sheets, move/resize, occlusion, full-screen/Spaces transitions, all three actions, and manual fit restoration. Record app and OS versions. Unknown layouts remain hidden even for an enabled app.
