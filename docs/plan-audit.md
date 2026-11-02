# Original plan audit — 2026-11-03

The original plan is **not complete**. Limited developer previews exist; they are not the broad beta described in the plan.

| Original requirement | Status | Evidence / remaining work |
|---|---|---|
| Additional right controls; originals retained; hide on uncertainty | Implemented | Placement and AX/WindowServer checks; universal collision guarantee is not claimed. |
| Minimize / fit-restore / close | Implemented, limited verification | TextEdit, Safari, Finder, Preview and Chrome fixture actions passed; WhatsApp only has read-only visibility proof. Own demo coordinate clicks passed. External composite/pointer and more starting geometries remain. |
| Separate tracking, placement, UI, actions and preferences | Implemented | WindowObserver, WindowEngine, AccessibilityClient, ControlPanel and AppModel. |
| Event-driven updates and bounded serial AX queries | Implemented | Notifications plus one-second fallback, actor isolation, deadlines and stale-result cancellation. Safari passed a 30s title-change visibility fixture; broad flicker/energy validation remains open. |
| Multiple displays, disconnect/restore, Spaces | Partial | Pure coordinate/restore checks; device/display-transition tests pending. |
| Focus/permission/window identity revalidation | Implemented, partial test coverage | Focus changes cancel integration runs. Systematic race/dialog coverage pending. |
| Daily apps: TextEdit, Preview, Finder, Safari, Chrome | Partial | Eligibility is automatic. TextEdit, Safari, Finder, Preview and Chrome basic action fixtures passed; WhatsApp native-header visibility passed but its actions remain unverified. Blender remains untested. |
| TextEdit plus two daily apps before broad beta | Basic-flow threshold met | Safari and Finder action fixtures passed. Other visual/interaction/install/soak gates remain; this alone does not authorize a broad beta label. |
| Permission-first onboarding and menu-bar lifecycle | Implemented, partial validation | Live permission and UI states observed; clean-user journey and regular launch restoration need dedicated validation. |
| Per-app exclusions and optional login startup | Implemented | SMAppService code exists; actual register/unregister needs isolated user test. |
| Turkish/English and native accessibility | Partial | Strings, native controls, labels/tooltips exist. Dynamic diagnostic translations, VoiceOver, keyboard, light/high-contrast/reduced-transparency matrix incomplete. |
| Branded icon | Complete | User selected Corner; SVG/PNG/ICNS included. |
| MIT, public GitHub source, CI, versioned DMG/checksum | Complete | Public source, preview DMGs and checksums exist. Current release/source CI is recorded in STATUS.md. |
| Manual GitHub update link | Implemented | Info.plist points to actual releases page. No automatic updater. |
| Clean-account/browser-download/install/update/removal | Partial | Local install, strict packaged signature, mounted DMG and re-downloaded checksum passed. Clean-user and browser-quarantine journey incomplete. Gatekeeper rejects self-signed app. |
| One-hour soak; CPU below 1%; stable RSS | Not met | Short passive samples and a 20s normal-debug-service cumulative sample (~0.70% of one core) exist; none is a one-hour soak. Title-change stress has separate higher CPU measurements. |
| Older supported OS / Intel | Not verified / deferred | Apple Silicon only. macOS 13 is API baseline, not tested-device support. |
| Complete product / stable release | Not met | Compatibility and user-flow gates above must close first. |

No automatic memory export, cloud sync, telemetry, account/backend or paid signing membership was added. Decisions and actual evidence remain in this repository.

Additional user request: automatic evaluation of new apps, compact verified placement and yellow/green/red hover implemented in Preview 3 source. App-level exclusions remain available. This is not a universal-compatibility claim. Native app/stability/settings refinement is recorded in design-popular-apps.md. See design-automatic-controls.md and current STATUS.md for release/CI evidence.
