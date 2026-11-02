import AppKit

// No activation: clicking these controls must not focus Rightnest instead of the target app.
@MainActor
final class ControlPanel: NSPanel {
    private var action: ((WindowAction) -> Void)?
    private var buttons: [WindowAction: NSButton] = [:]
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 102, height: 26),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false; backgroundColor = .clear; hasShadow = false
        hidesOnDeactivate = false; level = .floating
        isMovable = false; isReleasedWhenClosed = false
        animationBehavior = .none
        let material = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 102, height: 26))
        material.material = .titlebar; material.blendingMode = .withinWindow; material.state = .active
        material.wantsLayer = true; material.layer?.cornerRadius = 7
        contentView = material
        let strip = ControlStrip { [weak self] kind in self?.action?(kind) }
        strip.frame = material.bounds
        material.addSubview(strip)
        for subview in strip.subviews {
            if let button = subview as? NSButton { buttons[WindowAction.allCases[button.tag]] = button }
        }
    }
    #if DEBUG
    func invokeForVerification(_ action: WindowAction) -> Bool {
        guard isVisible, let button = buttons[action], button.isEnabled else { return false }
        button.performClick(nil)
        return true
    }
    #endif
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    func show(at frame: CGRect, enabled: Set<WindowAction>, restoring: Bool = false, action: @escaping (WindowAction) -> Void) {
        self.action = action
        for (kind, button) in buttons { button.isEnabled = enabled.contains(kind) }
        if let button = buttons[.fit] {
            let label = L(restoring ? "Restore window" : "Fit window to screen")
            button.toolTip = label; button.setAccessibilityLabel(label)
            button.image = NSImage(systemSymbolName: restoring ? "square.on.square" : "square", accessibilityDescription: label)
        }
        if self.frame != frame { setFrame(frame, display: true) }
        if !isVisible { orderFrontRegardless() }
    }
}

enum WindowAction: String, CaseIterable, Hashable, Sendable {
    case minimize, fit, close
    var label: String {
        switch self { case .minimize: "Minimize window"; case .fit: "Fit or restore window"; case .close: "Close window" }
    }
    var symbol: String {
        switch self { case .minimize: "minus"; case .fit: "square"; case .close: "xmark" }
    }
}


@MainActor
final class ControlStrip: NSView {
    private let perform: (WindowAction) -> Void
    init(action: @escaping (WindowAction) -> Void) {
        perform = action
        super.init(frame: NSRect(x: 0, y: 0, width: 102, height: 26))
        for (index, kind) in WindowAction.allCases.enumerated() {
            let button = ControlButton(frame: NSRect(x: index * 34, y: 0, width: 34, height: 26))
            button.isClose = kind == .close
            button.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: L(kind.label))
            button.imagePosition = .imageOnly; button.isBordered = false; button.bezelStyle = .inline
            button.toolTip = L(kind.label); button.setAccessibilityLabel(L(kind.label))
            button.target = self; button.action = #selector(pressed(_:)); button.tag = index
            addSubview(button)
        }
    }
    required init?(coder: NSCoder) { fatalError("Programmatic view") }
    @objc private func pressed(_ sender: NSButton) { perform(WindowAction.allCases[sender.tag]) }
}

@MainActor
private final class ControlButton: NSButton {
    var isClose = false
    private var hover: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hover { removeTrackingArea(hover) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area); hover = area
    }
    override func mouseEntered(with event: NSEvent) { if isClose && isEnabled { contentTintColor = .systemRed } }
    override func mouseExited(with event: NSEvent) { contentTintColor = .labelColor }
}
