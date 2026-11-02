# Privacy

Rightnest has no backend, account, analytics, advertising SDK, updater or network client. The Releases button opens a GitHub page in the default browser only when chosen.

Accessibility permission is broad. Rightnest uses window identity, geometry, roles, enabled states and advertised actions to decide whether it can display controls and dispatch a requested window action. WindowServer metadata supplements occlusion checks. Character-count and character-bounds metadata may be used to avoid covering native title text; the text itself is not read for that measurement. The app does not capture screen images or read document text for its runtime control logic. It does not upload window information.

Preferences store enabled/paused state, disabled app IDs, onboarding completion and permission presentation history. Permission itself always comes from the live OS trust check. Restore frames are bounded, in-memory records, cleared when the app exits. No document title or content is stored with them.

Debug-only tests create a disposable document and verify its URL before controlling it. Explicit compatibility audits save bundle IDs, versions, geometry, action capability and rejection reasons under a developer-chosen directory. They do not save window titles, document paths, URLs, text or screenshots. These tools are excluded from release builds.

Bug reports are voluntary. Review any attachments and remove private filenames, content or screenshots before posting. Future changes to data handling require updating this document.
