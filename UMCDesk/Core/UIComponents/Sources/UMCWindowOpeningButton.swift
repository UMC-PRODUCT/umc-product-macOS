//
//  UMCWindowOpeningButton.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/23/26.
//

import SwiftUI

/// Programmatic keyboard focus for the native control that opens a window.
@MainActor
public final class UMCWindowButtonFocus {
    fileprivate weak var control: NSButton?

    public init() {}

    public var hasFollowingKeyView: Bool {
        guard let control, let next = control.nextValidKeyView else { return false }
        return next !== control
    }

    @discardableResult
    public func focus() -> Bool {
        guard let control, control.canBecomeKeyView, let window = control.window
        else { return false }
        return window.makeFirstResponder(control)
    }
}

/// Opens a window and returns keyboard focus to its caller when the original window is reactivated.
public struct UMCWindowOpeningButton<Label: View>: View {
    private let button: UMCFocusableButton<Label>

    public init(
        _ title: String, identifier: String? = nil, cornerRadius: CGFloat = 4,
        focusTarget: UMCWindowButtonFocus? = nil, action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        button = UMCFocusableButton(
            title, identifier: identifier, cornerRadius: cornerRadius, focusTarget: focusTarget,
            restoresFocusOnReturn: true, action: action, label: label)
    }

    public var body: some View { button }
}

/// A native button that participates in the key-view loop with any keyboard navigation setting.
public struct UMCFocusableButton<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    private let title: String
    private let identifier: String?
    private let cornerRadius: CGFloat
    private let focusTarget: UMCWindowButtonFocus?
    private let restoresFocusOnReturn: Bool
    private let action: () -> Void
    private let label: (Bool) -> Label

    public init(
        _ title: String, identifier: String? = nil, cornerRadius: CGFloat = 4,
        focusTarget: UMCWindowButtonFocus? = nil, restoresFocusOnReturn: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.title = title
        self.identifier = identifier
        self.cornerRadius = cornerRadius
        self.focusTarget = focusTarget
        self.restoresFocusOnReturn = restoresFocusOnReturn
        self.action = action
        self.label = label
    }

    public var body: some View {
        label(isEnabled && isHovered)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .overlay {
                WindowButton(title: title, identifier: identifier, cornerRadius: cornerRadius,
                             isEnabled: isEnabled, focusTarget: focusTarget,
                             restoresFocusOnReturn: restoresFocusOnReturn, action: action)
            }
            .onHover { isHovered = $0 }
    }
}

private struct WindowButton: NSViewRepresentable {
    let title: String
    let identifier: String?
    let cornerRadius: CGFloat
    let isEnabled: Bool
    let focusTarget: UMCWindowButtonFocus?
    let restoresFocusOnReturn: Bool
    let action: () -> Void

    func makeNSView(context: Context) -> Control {
        let button = Control()
        button.title = ""
        button.isBordered = false
        button.focusRingType = .exterior
        button.target = button
        button.action = #selector(Control.activate)
        return button
    }

    func updateNSView(_ button: Control, context: Context) {
        focusTarget?.control = button
        button.restoresAfterActivation = restoresFocusOnReturn
        button.open = action
        button.cornerRadius = cornerRadius
        button.isEnabled = isEnabled
        button.setAccessibilityLabel(title)
        if let identifier { button.setAccessibilityIdentifier(identifier) }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: Control, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    final class Control: NSButton {
        var restoresAfterActivation = false
        var open: (() -> Void)?
        var cornerRadius: CGFloat = 4
        private var restoresFocusOnReturn = false

        override var acceptsFirstResponder: Bool { isEnabled }
        override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            restoresFocusOnReturn = false
            NotificationCenter.default.removeObserver(
                self, name: NSWindow.didBecomeKeyNotification, object: nil)
            if let window {
                NotificationCenter.default.addObserver(self, selector: #selector(restoreFocus),
                    name: NSWindow.didBecomeKeyNotification, object: window)
            }
        }

        @objc func activate() {
            guard isEnabled, let window else { return }
            window.makeFirstResponder(self)
            restoresFocusOnReturn = restoresAfterActivation
            open?()
        }

        @objc private func restoreFocus() {
            guard restoresFocusOnReturn else { return }
            restoresFocusOnReturn = false
            if canBecomeKeyView { window?.makeFirstResponder(self) }
        }

        override func keyDown(with event: NSEvent) {
            if event.charactersIgnoringModifiers == "\r",
               event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                performClick(nil)
            } else {
                super.keyDown(with: event)
            }
        }

        override var focusRingMaskBounds: NSRect { bounds.insetBy(dx: 2, dy: 2) }

        override func drawFocusRingMask() {
            NSBezierPath(roundedRect: focusRingMaskBounds, xRadius: cornerRadius,
                         yRadius: cornerRadius).fill()
        }
    }
}
