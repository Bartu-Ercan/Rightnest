# Privacy

Rightnest has no backend, account, analytics, advertising SDK, updater or network client. The Releases button opens a GitHub page in the default browser only when chosen.

Accessibility permission is broad. After external controls are enabled, Rightnest automatically evaluates identified normal apps except those excluded by the user. It uses window identity, geometry, roles, enabled states and advertised actions to decide whether it can display controls and dispatch a requested window action. WindowServer metadata supplements occlusion checks. Character-count and character-bounds metadata may be used to avoid covering native title text; the text itself is not read for that measurement. The app does not capture screen images or read document text for its runtime control logic. It does not upload window information.

Preferences store enabled/paused state, disabled app IDs, onboarding completion and permission presentation history. Permission itself always comes from the live OS trust check. Restore frames are bounded, in-memory records, cleared when the app exits. No document title or content is stored with them.

Debug-only tests create a disposable document and verify its URL before controlling it. Explicit compatibility audits save bundle IDs, versions, geometry, action capability and rejection reasons under a developer-chosen directory. They do not save window titles, document paths, URLs, text or screenshots. These tools are excluded from release builds.

Bug reports are voluntary. Review any attachments and remove private filenames, content or screenshots before posting. Future changes to data handling require updating this document.

Native toolbar spacers: Rightnest checks whether candidate spacer title/description/value/help metadata is empty, and inspects native roles, actions, identifiers and geometry to distinguish known non-pressable filler from actual controls. Those label values are not retained or logged. Outside-window placement uses WindowServer bounds/ordering, not screen pixels. Developer-only compatibility observations record app identifiers, geometry, reasons and panel visibility locally; they do not upload data.
