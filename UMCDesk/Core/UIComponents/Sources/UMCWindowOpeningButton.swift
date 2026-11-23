//
//  UMCWindowOpeningButton.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/23/26.
//

import SwiftUI

/// Opens a window and returns keyboard focus to its caller when the original window is reactivated.
public struct UMCWindowOpeningButton<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    private let title: String
    private let identifier: String?
    private let cornerRadius: CGFloat
    private let action: () -> Void
    private let label: (Bool) -> Label

    public init(
        _ title: String, identifier: String? = nil, cornerRadius: CGFloat = 4,
        action: @escaping () -> Void, @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.title = title
        self.identifier = identifier
        self.cornerRadius = cornerRadius
        self.action = action
        self.label = label
    }

    public var body: some View {
        label(isEnabled && isHovered)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .overlay {
                WindowButton(title: title, identifier: identifier, cornerRadius: cornerRadius,
                             isEnabled: isEnabled, action: action)
            }
            .onHover { isHovered = $0 }
    }
}

private struct WindowButton: NSViewRepresentable {
    let title: String
    let identifier: String?
    let cornerRadius: CGFloat
    let isEnabled: Bool
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
            restoresFocusOnReturn = true
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
