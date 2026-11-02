import AppKit
import ApplicationServices

// Read-only diagnostic. Never presses controls or changes another application's UI.
struct AttributeCheck: Encodable {
    let attribute: String
    let queryStatus: Int32
    let settable: Bool?
}

struct ButtonCheck: Encodable {
    let kind: String
    let lookupStatus: Int32
    let attributes: [AttributeCheck]
    let actions: [String]
    let actionQueryStatus: Int32?
}

struct ProbeReport: Encodable {
    let trusted: Bool
    let applicationID: String?
    let windowQueryStatus: Int32?
    let buttons: [ButtonCheck]
    let note: String
}

func copyAttribute(_ element: AXUIElement, _ name: String) -> (AXError, CFTypeRef?) {
    var value: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(element, name as CFString, &value)
    return (status, value)
}

func checkAttribute(_ element: AXUIElement, _ name: String) -> AttributeCheck {
    var settable = DarwinBoolean(false)
    let status = AXUIElementIsAttributeSettable(element, name as CFString, &settable)
    return AttributeCheck(attribute: name, queryStatus: status.rawValue,
                          settable: status == .success ? settable.boolValue : nil)
}

@MainActor
func inspect() -> ProbeReport {
    guard AXIsProcessTrusted() else {
        return ProbeReport(trusted: false, applicationID: nil, windowQueryStatus: nil, buttons: [],
            note: "Accessibility access is not granted. No cross-application conclusions were measured. No permission prompt was requested.")
    }
    guard let frontmost = NSWorkspace.shared.frontmostApplication else {
        return ProbeReport(trusted: true, applicationID: nil, windowQueryStatus: nil, buttons: [],
                           note: "No frontmost application available.")
    }
    let application = AXUIElementCreateApplication(frontmost.processIdentifier)
    AXUIElementSetMessagingTimeout(application, 1.0)
    let (status, rawWindow) = copyAttribute(application, kAXFocusedWindowAttribute)
    guard status == .success, let rawWindow, CFGetTypeID(rawWindow) == AXUIElementGetTypeID() else {
        return ProbeReport(trusted: true, applicationID: frontmost.bundleIdentifier,
                           windowQueryStatus: status.rawValue, buttons: [], note: "Focused window unavailable.")
    }
    // The CF type ID check above establishes that this is an AXUIElement.
    let window = unsafeDowncast(rawWindow, to: AXUIElement.self)
    let checks = [kAXCloseButtonAttribute, kAXMinimizeButtonAttribute, kAXZoomButtonAttribute, "AXFullScreenButton"].map { name in
        let (lookup, rawButton) = copyAttribute(window, name)
        guard lookup == .success, let rawButton, CFGetTypeID(rawButton) == AXUIElementGetTypeID() else {
            return ButtonCheck(kind: name, lookupStatus: lookup.rawValue, attributes: [], actions: [], actionQueryStatus: nil)
        }
        let button = unsafeDowncast(rawButton, to: AXUIElement.self)
        var actions: CFArray?
        let actionStatus = AXUIElementCopyActionNames(button, &actions)
        return ButtonCheck(kind: name, lookupStatus: lookup.rawValue,
            attributes: [checkAttribute(button, kAXPositionAttribute), checkAttribute(button, kAXSizeAttribute)],
            actions: actions as? [String] ?? [], actionQueryStatus: actionStatus.rawValue)
    }
    return ProbeReport(trusted: true, applicationID: frontmost.bundleIdentifier,
        windowQueryStatus: status.rawValue, buttons: checks,
        note: "Read-only snapshot of one focused window. No attributes changed, no actions invoked. A supported action does not prove its execution succeeds. This does not prove compatibility across apps.")
}

let arguments = CommandLine.arguments.dropFirst()
if arguments.contains("--help") {
    print("RightSideProbe: read-only Accessibility capability report for the focused app. No permissions requested, no UI changes. Run with no arguments for JSON.")
} else if !arguments.isEmpty {
    fputs("Unknown argument. Use --help.\n", stderr)
    exit(64)
} else {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
        let data = try encoder.encode(inspect())
        print(String(decoding: data, as: UTF8.self))
    } catch {
        fputs("Unable to encode report: \(error)\n", stderr)
        exit(1)
    }
}
