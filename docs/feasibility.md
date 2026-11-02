# Feasibility — 2026-11-02

## Requirements

- Background/menu-bar utility, downloadable from an open-source GitHub repository.
- Move native close, minimize and full-screen controls from left to right.
- Preserve working behavior and the host application's visual design.
- Do not overlap existing right-hand toolbar controls.

## Supported API boundaries

AppKit's `NSWindow.standardWindowButton(_:)` returns controls belonging to an NSWindow in the app's own view hierarchy. In an app we control, we can customize that hierarchy and reserve toolbar space. This is not an API for obtaining and re-layouting another process's NSViews.

Accessibility exposes a semantic tree, attributes and actions implemented by each target app. It is not access to that application's layout system. Apple's SDK `AXAttributeConstants.h` states that AXPosition is generally not writable; moveable elements such as windows may expose a writable position. AXCloseButton, AXMinimizeButton and AXZoomButton are read-only references. Read-only reference attributes alone do not prove that every referenced button's position is read-only: check its AXPosition with AXUIElementIsAttributeSettable. The probe does that without mutation.

A press action can allow a replacement control to request the target app's behavior. Action availability, permission, errors and target-window identity must be validated per app. Zoom, maximize and full screen are distinct behaviors. A proxy does not automatically preserve green-button hover menus, modifier-click semantics, tiling or other native behavior.

## Collision limits

No universal public API reserves blank titlebar space inside a third-party application. Accessibility geometry can detect reported obstacles, but it does not expose every custom-drawn control or every changing toolbar state. A missing AX node is not proof that a region is blank. Screenshots or visual models can provide heuristics, not a guarantee, and add screen-recording/privacy/performance costs.

Any experimental proxy implementation must skip uncertain regions, permission failures, unsupported apps, full-screen/Space transitions and modal states until tested. Window movement, resize, multi-display scale/coordinate changes and occlusion require explicit handling. A global always-on-top panel must never appear over unrelated windows. Start with a small app allowlist and fail closed rather than claim universal compatibility.

Painting over the left controls cannot reliably reproduce transparent/material backgrounds, steals interaction space and does not remove the original controls. It does not meet the requested quality requirement.

## Options

1. True relocation within apps that explicitly integrate an SDK/plugin: possible to investigate with host cooperation; does not work globally for arbitrary apps.
2. Optional additional right-side controls for supported windows: investigate via Accessibility and a separate panel. Originals remain. Prefer outside-window or explicitly verified placement rather than covering toolbar content. This changes the product promise and needs user agreement.
3. Unsupported process injection/system patching: not selected for a broadly installable, maintainable first release. No such modification has been made.

## Evidence

- Apple NSWindow: https://developer.apple.com/documentation/appkit/nswindow
- Apple standardWindowButton: https://developer.apple.com/documentation/appkit/nswindow/standardwindowbutton(_:)
- Apple Accessibility model: https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXmodel.html
- Apple AXPosition: https://developer.apple.com/documentation/applicationservices/kaxpositionattribute
- Local macOS SDK: ApplicationServices.framework/Frameworks/HIServices.framework/Headers/AXAttributeConstants.h (AXPosition and AX window-button attributes).

## Product gate resolved for prototype

User accepted investigating additional controls with originals retained. This does not establish universal placement safety. The current prototype has a controlled demo and an explicitly experimental, opt-in TextEdit path. True relocation remains outside this implementation.
