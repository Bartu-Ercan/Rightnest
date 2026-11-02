# Automatic placement and hover refinement

Native SwiftUI settings, AppKit titlebar panel; one job: make window actions reachable on the right without covering visible native controls. Application names do not grant compatibility. Normal apps are discovered dynamically and the existing geometry/capability/occlusion checks decide each window independently. Per-app exclusions remain authoritative. Unknown layouts stay hidden.

## Design checks used

- apple-design `accessibility.md › Mobility`: macOS minimum control size is 20×20 pt. Ordinary controls remain 34×26; compact controls are 22×26. No variant grows beyond its verified titlebar rectangle.
- `color.md › Best practices`: “When possible, use system colors.” Hover uses systemYellow, systemGreen and systemRed as opaque fills with black symbols. Offscreen checks require symbol contrast >=3:1 for aqua/dark/high-contrast appearances. This checks the resolved fill/symbol colors; it is not a completed VoiceOver or end-to-end visual audit.
- `buttons.md › Best practices`: native tooltips explain each icon; symbols and accessibility labels remain distinct, so color is supplementary.
- `settings.md › Desktop (macOS)`: settings minimize/maximize are unavailable; the single-pane window is named Rightnest Settings and keeps Command-Comma access.

No scaling, decorative motion, theme switch or new runtime dependency was added. Rightmost position wins; at each anchor, ordinary width is preferred when both fit. The compact fallback reuses the same native buttons and only changes layout. Hover clears on exit, disable and external-panel hide. A settings disclosure lists known/running apps and retained exclusions; opening a new app needs no manual registration.

## Validation and limits

49 standalone checks include unknown-app eligibility, exclusions, self/background rejection, candidate boundaries and compact width. `script/check_hover.sh` checks 24 button/appearance/width combinations including contrast, labels, minimum hit size, containment, disabled and exit states. Preview's ordinary crowded strip hid; its compact disposable-PDF action test passed. Blender is not installed and is not verified. An app that omits usable AX window/titlebar metadata may still show no controls. Automatic eligibility is not a universal compatibility claim.
