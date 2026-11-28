//  SupportInputField.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import AppKit
import CoreDesignSystem
import SwiftUI

/// The active field editor consumes composition commands before inquiry navigation or submission.
struct SupportInputField: NSViewRepresentable {
    let label: String
    let identifier: String
    @Binding var text: String
    var focusRequest = 0
    var onFocus: () -> Void = {}
    let submit: () -> Void
    var moveDown: (() -> Void)?
    var escape: (() -> Void)?
    @Environment(\.umcBodyTextScale) private var scale
    @Environment(\.umcFontFamily) private var family

    init(
        _ label: String, identifier: String, text: Binding<String>, focusRequest: Int = 0,
        onFocus: @escaping () -> Void = {}, submit: @escaping () -> Void,
        moveDown: (() -> Void)? = nil, escape: (() -> Void)? = nil
    ) {
        self.label = label
        self.identifier = identifier
        _text = text
        self.focusRequest = focusRequest
        self.onFocus = onFocus
        self.submit = submit
        self.moveDown = moveDown
        self.escape = escape
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSTextField {
        let field = SupportTextControl()
        field.didFocus = { [weak coordinator = context.coordinator] in
            Task { @MainActor in coordinator?.parent.onFocus() }
        }
        context.coordinator.observeComposition(in: field)
        field.isBordered = false
        field.drawsBackground = false
        field.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        return field
    }
    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        field.placeholderString = label
        field.setAccessibilityIdentifier(identifier)
        field.setAccessibilityLabel(label)
        field.isEnabled = context.environment.isEnabled
        field.font =
            NSFont(name: family ?? "Pretendard-Regular", size: 14 * scale)
            ?? .systemFont(ofSize: 14 * scale)
        if context.coordinator.focusRequest != focusRequest {
            context.coordinator.focusRequest = focusRequest
            Task { @MainActor [weak field] in
                await Task.yield()
                if let field, field.isEnabled { field.window?.makeFirstResponder(field) }
            }
        }
        guard (field.currentEditor() as? NSTextView)?.hasMarkedText() != true else { return }
        if field.stringValue != text { field.stringValue = text }
    }

    static func dismantleNSView(_ view: NSTextField, coordinator: Coordinator) {
        if let monitor = coordinator.monitor { NSEvent.removeMonitor(monitor) }
    }

    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SupportInputField
        var focusRequest = 0
        var monitor: Any?
        private var markedEvent: TimeInterval?
        func observeComposition(in field: NSTextField) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
                [weak self, weak field] event in
                guard let field, field.window == event.window,
                    let editor = field.currentEditor() as? NSTextView,
                    field.window?.firstResponder === editor
                else { return event }
                self?.markedEvent = editor.hasMarkedText() ? event.timestamp : nil
                return event
            }
        }
        init(_ parent: SupportInputField) { self.parent = parent }
        func controlTextDidBeginEditing(_ notification: Notification) { parent.onFocus() }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField,
                (field.currentEditor() as? NSTextView)?.hasMarkedText() != true
            else { return }
            parent.text = field.stringValue
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector)
            -> Bool
        {
            guard !textView.hasMarkedText(),
                markedEvent == nil || markedEvent != NSApp.currentEvent?.timestamp
            else { return false }
            let action: (() -> Void)?
            switch selector {
            case #selector(NSResponder.insertNewline(_:)): action = parent.submit
            case #selector(NSResponder.moveDown(_:)): action = parent.moveDown
            case #selector(NSResponder.cancelOperation(_:)): action = parent.escape
            default: return false
            }
            guard let action else { return false }
            parent.text = textView.string
            action()
            return true
        }
    }
}

private final class SupportTextControl: NSTextField {
    var didFocus: (() -> Void)?
    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { didFocus?() }
        return accepted
    }
}
