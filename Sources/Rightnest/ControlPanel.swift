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
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        isMovable = false; isReleasedWhenClosed = false
        animationBehavior = .none
        let material = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 102, height: 26))
        material.material = .titlebar; material.blendingMode = .withinWindow; material.state = .active
        material.wantsLayer = true; material.layer?.cornerRadius = 7
        contentView = material
        let strip = ControlStrip { [weak self] kind in self?.action?(kind) }
        strip.frame = material.bounds
        strip.autoresizingMask = [.width, .height]
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
    override func orderOut(_ sender: Any?) {
        for button in buttons.values { (button as? ControlButton)?.clearHover() }
        super.orderOut(sender)
    }
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
            switch kind {
            case .minimize: button.hoverColor = .systemYellow
            case .fit: button.hoverColor = .systemGreen
            case .close: button.hoverColor = .systemRed
            }
            button.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: L(kind.label))
            button.imagePosition = .imageOnly; button.isBordered = false; button.bezelStyle = .inline
            button.toolTip = L(kind.label); button.setAccessibilityLabel(L(kind.label))
            button.target = self; button.action = #selector(pressed(_:)); button.tag = index
            addSubview(button)
        }
    }
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        let unit = bounds.width / CGFloat(WindowAction.allCases.count)
        for button in subviews.compactMap({ $0 as? NSButton }) {
            button.frame = NSRect(x: CGFloat(button.tag)*unit, y: 0, width: unit, height: bounds.height)
        }
    }
    #if DEBUG
    static func verifyHoverFeedback() -> Int {
        var checked = 0
        for width in [102.0, 66.0] {
            for name in [NSAppearance.Name.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua] {
                let strip = ControlStrip { _ in }
                strip.appearance = NSAppearance(named: name)
                strip.setFrameSize(NSSize(width: width, height: 26))
                for button in strip.subviews.compactMap({ $0 as? ControlButton }) {
                    precondition(button.frame.width >= 20 && button.frame.height >= 20 && strip.bounds.contains(button.frame), "Compact buttons must remain usable and contained")
                    button.verifyHoverFeedback()
                    checked += 1
                }
            }
        }
        return checked
    }
    #endif
    required init?(coder: NSCoder) { fatalError("Programmatic view") }
    @objc private func pressed(_ sender: NSButton) { perform(WindowAction.allCases[sender.tag]) }
}

@MainActor
private final class ControlButton: NSButton {
    var hoverColor: NSColor = .controlAccentColor
    private var hovered = false
    override var isEnabled: Bool { didSet { updateHoverAppearance() } }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); updateHoverAppearance() }
    func clearHover() { hovered = false; updateHoverAppearance() }
    private func updateHoverAppearance() {
        wantsLayer = true
        layer?.cornerRadius = 5
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = hovered && isEnabled ? hoverColor.cgColor : NSColor.clear.cgColor
            contentTintColor = hovered && isEnabled ? .black : .labelColor
        }
    }
    private var hover: NSTrackingArea?
    #if DEBUG
    func verifyHoverFeedback() {
        hovered = true; isEnabled = true; updateHoverAppearance()
        guard let background = layer?.backgroundColor,
              let rgb = NSColor(cgColor: background)?.usingColorSpace(.deviceRGB) else { preconditionFailure("Missing hover background") }
        func linear(_ x: CGFloat) -> CGFloat { x <= 0.04045 ? x/12.92 : pow((x+0.055)/1.055, 2.4) }
        let luminance = 0.2126*linear(rgb.redComponent) + 0.7152*linear(rgb.greenComponent) + 0.0722*linear(rgb.blueComponent)
        precondition((luminance+0.05)/0.05 >= 3, "Hover symbol must contrast with its fill")
        precondition(contentTintColor == .black, "Hovered symbols remain dark")
        precondition(image != nil && accessibilityLabel()?.isEmpty == false, "Icon buttons require symbols and labels")
        isEnabled = false
        precondition(layer?.backgroundColor?.alpha == 0, "Disabled buttons must not retain hover fill")
        isEnabled = true; hovered = false; updateHoverAppearance()
        precondition(layer?.backgroundColor?.alpha == 0, "Leaving the button clears its fill")
    }
    #endif
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hover { removeTrackingArea(hover) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area); hover = area
    }
    override func mouseEntered(with event: NSEvent) { hovered = true; updateHoverAppearance() }
    override func mouseExited(with event: NSEvent) { hovered = false; updateHoverAppearance() }
}
