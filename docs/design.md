# Design language

Rightnest is a quiet native macOS utility. System typography, semantic colors, native controls and material; no dashboard, decorative animation, account flow or theme editor.

Controls are ordered minimize, fit/restore, close. Fit uses a square and restore overlapping squares. The strip is 102 × 26 points, with 34-point buttons, labels and tooltips. Close uses red only on hover. Unknown/unsupported actions are unavailable. Original application chrome is never repainted.

Settings are one scrollable window: product explanation, permission card, safe demo, external controls, optional startup, completion and status. Onboarding completion closes the window; the app stays in the menu bar. English and Turkish follow preferred language. Diagnostics shown to users should use plain-language reasons; raw AX detail belongs in explicit developer reports.

Accessibility: native button semantics, keyboard focus, visible system focus indicators, VoiceOver labels, semantic colors/materials. Dark/light, high contrast, reduced transparency and VoiceOver still require device validation; using native controls alone is not verification.

Icon direction selected by user: A / Corner. A detached upper-right rounded square sits in an open frame. Master geometry is in Assets; 16/32/64 px concepts were rendered and reviewed. No third-party reference artwork is included. Variants and macOS icon are generated from the same geometry.
