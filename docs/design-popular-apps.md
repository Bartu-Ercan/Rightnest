# Popular-app refinement

## Reference and design decision

Reviewed Nashi source at 676752f763ec1099fd0e85e4b7411708b779a82a: Package.swift, WelcomeView.swift, HomeView.swift and DesignSystem.swift (https://github.com/orkunisitmak/nashi-app). It uses SwiftUI with narrow AppKit integration, a shared palette and reusable surface/button styles, native keyboard/accessibility hooks, and separate first-run setup. These are patterns to evaluate, not proof that a window-overlay engine works. No source or artwork was copied; the reference clone is ignored under .build/references.

Rightnest retains A Corner identity. The settings window has a quiet native sidebar, overview and applications sections; a small window illustration explains the right corner; app icons and search make exclusions practical. Native buttons, switches, text fields and focus rings remain. Color uses semantic macOS surfaces/content, system accent for navigation, system yellow/green/red only for window-action meaning. No animated layout, large translucent backdrop or new dependency. Typography: 28 pt semibold heading, 13 pt body, system caption for supplementary text. Standard macOS settings titlebar and Command-Comma remain.

Apple-design references read: accessibility.md (Vision, Mobility, Speech), layout.md (Visual hierarchy, Adaptability), typography.md, color.md, designing-for-macos.md, settings.md, buttons.md and feedback.md. Native semantic text/surfaces preserve system appearance and contrast preferences. Header symbols are decorative; real action buttons retain accessible labels. Component hover checks do not constitute a complete VoiceOver audit.

## Behavior decision

On 2026-11-02 the user accepted a small shelf immediately outside the target window when safe titlebar placement cannot be established. It uses the current display's usable frame and rejects any intersecting on-screen surface except its own exact overlay. It never silently resizes a target, overlaps the menu bar/Dock, or covers app content. A screen-filling window may have no outside space: this remains a limitation, stated by the menu status.

Chrome has a native trailing tab-strip group with no children. General custom groups stay blocked. A Chromium marker, no actions/text metadata, top-strip geometry and adjacent native tab hierarchy are all required before treating this specific structural filler as background. Other tab controls are still obstacles; crowded tab strips can fail safely. WhatsApp’s WDSNavigationBar spacer is recognized only as an empty, non-pressable measured leaf between a left header button and at least two right-side action buttons, with no intersecting peer buttons. General Catalyst groups remain blocked.

Focus within content and title updates revalidate without unconditional panel removal. Focused window changes, move/resize, destruction, minimize and Space changes still hide immediately. AX inspection remains bounded (160 nodes, depth 16, 400 ms); exact overlay coverage and WindowServer ordering permit one occlusion check instead of repeated covered-point queries. Hidden windows retry at the existing 1-second fallback tick.

## Evidence

59 standalone checks and 24 offscreen native hover combinations passed during development. Settings overview was visually inspected in dark appearance through Computer Use; applications search and Chrome exclusion off/on were observed. Full original-plan release gates remain in plan-audit.md. Integration results and publication state are recorded separately in STATUS.md/validation.md; do not infer them from this design note.
