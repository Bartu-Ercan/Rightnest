import AppKit
MainActor.assumeIsolated {
    NSApplication.shared.setActivationPolicy(.prohibited)
    print("PressRouting: \(ControlPanel.verifyHeldPressRouting()) native checks passed")
    print("HoverChecks: \(ControlStrip.verifyHoverFeedback()) button/appearance combinations passed (contrast, labels, disabled and exit states)")
}
