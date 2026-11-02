import AppKit
MainActor.assumeIsolated {
    NSApplication.shared.setActivationPolicy(.prohibited)
    print("HoverChecks: \(ControlStrip.verifyHoverFeedback()) button/appearance combinations passed (contrast, labels, disabled and exit states)")
}
