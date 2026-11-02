# Rightnest Preview 3 — automatic app discovery

Identified normal applications are now evaluated automatically; there is no application-name allowlist. Running apps and retained exclusions appear in Settings and the menu. Your app-level disable choices still win. Enable external controls in setup to use discovery.

At each rightmost titlebar anchor the engine tries the ordinary 102 pt strip, then 66 pt compact controls (22×26 pt buttons), before moving left within the right half. Missing/ambiguous geometry, custom inaccessible titlebars and occupied areas still hide the controls. No blind forced placement, injection or screenshot analysis is used. **Automatic eligibility does not mean every application is compatible. Blender is not installed on the test Mac and is unverified.**

Hover fills: yellow minimize, green fit/restore, red close, with dark symbols and accessible labels. No scaling or animation. Native checks cover normal/compact layouts, light/dark/high-contrast appearances, contrast >=3:1 and disabled/exit behavior.

TextEdit regression and the previously unlisted Preview disposable-PDF action flow passed. The latter required compact placement; its crowded ordinary strip was correctly rejected. Prior Safari/Finder fixture results remain documented. The menu/settings application list and opt-out/restore were inspected in the native UI. 49 standalone regressions and 24 native hover/layout combinations passed locally; see Actions for source CI.

## Install/update

Apple Silicon developer preview. Quit the earlier copy, drag Rightnest from the DMG to Applications, eject and launch the installed copy. Keep one copy. The existing local signing identity is retained; no permission is granted silently. Setup explains macOS window-control access.

**Not Developer ID signed or notarized.** macOS may block the download; managed devices may prohibit it. Review the source and use only an explicitly offered per-app Open Anyway choice if you accept this limitation. Do not disable Gatekeeper or remove quarantine. Read docs/INSTALL.md or docs/INSTALL.tr.md.

Remaining limits: arbitrary custom-app compatibility, physical external-panel pointer/composite checks, fuller toolbar/tab/dialog cases, multi-display/Spaces, clean-user browser-download/update/removal, older macOS and one-hour soak are incomplete. This is not a stable/general beta. The full original-plan audit and quota-resume checkpoint are in docs/plan-audit.md and docs/STATUS.md.
