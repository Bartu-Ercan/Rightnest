# Compatibility — automatic placement preview

API baseline: macOS 13. Actual host observations below: Apple Silicon, macOS 27.0 (26A428), 2026-11-02–04. No older macOS or Intel device claim is made.

| Application | Version observed | Current state | Evidence / limitation |
|---|---|---|---|
| TextEdit | 1.21 | Limited; enabled | Disposable document action integration; physical pointer/composite and edge cases still pending. |
| Finder | 27.0 | Limited; enabled in Preview 2 | Unique disposable folder window at 1760 pt passed all actions. 1469 pt crowded long-title layout hid controls. Native character bounds separate title ink from blank label space. |
| Safari | 27.0 | Limited; enabled in Preview 2 | Preview 5 candidate: 30 active-second native-press regression passed all actions; owned Start Page 1310×700 showed controls for over two minutes after a scoped Safari hit-test correction. Current 1800 active-second run passed /16,850 visible samples and all actions, no pauses, endpoint at original observed placement; geometry p95209.2ms, synthetic return max382.4ms. Previous interrupted runs remain recorded. Narrow 880 pt historical layout hid controls. |
| Chrome | 156.0.8078.79 | Limited; guest fixture verified | Native trailing tab-strip filler is structurally recognized. Preview 5 candidate: single-tab Guest fixture passed an 1800-second session /16,712 visible samples and all actions; geometry p95 201.6 ms, synthetic obstacle return max 355.9 ms. Held-press guard follow-up passed 30s /284 samples and all actions. Latest native AX press override still needs Chrome follow-up; actual OS HUD, crowded tabs/profile toolbars and physical pointer cases remain open. |
| WhatsApp | 26.38.74 | Limited; foreground visibility verified, actions unverified | Measured native navigation spacer, aligned to its own row; disjoint sibling-button hit-test bug corrected within that exact scope. A 1072×600 window had 42 consecutive visible samples over 51s after startup. No action was dispatched to the personal chat window. See verification-whatsapp.json. |
| System Settings | Not freshly recorded | Automatic; current candidate unverified | Normal-window placement/actions need dedicated validation; privacy/modal panes are not generic test fixtures. |
| Discord | Not freshly recorded | Experimental; unverified | Automatic AX inspection and scoped Electron accessibility activation exist. Visibility, placement and actions have no current candidate pass. App opt-out disables attempts. |
| Preview | 11.0 | Automatic; basic actions verified | Disposable PDF passed minimize, return, fit, restore-frame and close with a 66 pt compact strip in a 1760 pt window. 102 pt strip correctly did not fit. |

Raw, content-free observations: compatibility-observations.json (foreground sampling) and compatibility-background-observations.json (explicit background probes marked with foreground=false). Background results are never treated as visible placement or action proof.

Earlier layout rejections were conservative implementation results, not proof that support was impossible. A future app-specific adapter must understand the relevant container and still prove no collision with interactive toolbar items. Do not simply classify all groups as empty or enable bundle IDs.

## Automatic eligibility is not universal compatibility

There is no app-name eligibility allowlist. Preview 4 adds narrow native toolbar geometry adapters. Identified regular apps are checked as they become active; user exclusions win. The table records test evidence, not permission to inspect an app. Blender is not installed on the test Mac and remains unverified. A custom-drawn or AX-incomplete titlebar can still be rejected. No image recognition, injection or blind forced positioning is used. Running apps appear in Settings; excluded apps remain listed even after closing.

## Preview 5 candidate metrics

Source b686133 CI 41770037293 passed 22 XCTest, 96 standalone, 24 hover/layout and 4 native press-routing checks plus production bundle validation. Normal release-service CPU was measured externally on this host at mean 0.5978% after warmup; the separate 10 Hz instrumented browser verifier exceeded the idle target. Twenty synthetic obstruction cycles per browser are additional evidence, not actual volume/brightness HUD cycles. These results do not satisfy all publication gates. See [STATUS](STATUS.md) and [metrics](verification-preview5.json).

## Release gate

The normal-action threshold (TextEdit plus two daily apps) is now met by the recorded Safari and Finder fixtures. This is still a limited preview: physical external-pointer/composite checks, richer app/window scenarios and installation/soak gates remain open. Before enabling another app, test standard/compact/tabbed windows, open menus, dialogs/save sheets, move/resize, occlusion, full-screen/Spaces transitions, all three actions, and manual fit restoration. Record app and OS versions. Unknown layouts remain hidden even for an enabled app.
