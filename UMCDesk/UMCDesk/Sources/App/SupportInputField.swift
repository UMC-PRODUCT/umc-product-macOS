//  SupportInputField.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import AppKit
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

/// The active field editor consumes composition commands before inquiry navigation or submission.
struct SupportInputField: View {
    let label: String
    let identifier: String
    @Binding var text: String
    let isSearch: Bool
    var focusRequest = 0
    var onFocus: () -> Void = {}
    let submit: () -> Void
    var moveDown: (() -> Void)?
    var escape: (() -> Void)?

    init(
        _ label: String, identifier: String, text: Binding<String>, isSearch: Bool = false,
        focusRequest: Int = 0,
        onFocus: @escaping () -> Void = {}, submit: @escaping () -> Void,
        moveDown: (() -> Void)? = nil, escape: (() -> Void)? = nil
    ) {
        self.isSearch = isSearch
        self.label = label
        self.identifier = identifier
        _text = text
        self.focusRequest = focusRequest
        self.onFocus = onFocus
        self.submit = submit
        self.moveDown = moveDown
        self.escape = escape
    }

    @State private var composing = false
    @State private var isFocused = false
    @State private var clearRequest = 0

    var body: some View {
        if isSearch {
            UMCSearchField(text: $text, isFocused: isFocused, onClear: {
                composing = false
                text = ""
                clearRequest += 1
            }) { editor }
        } else {
            editor.umcInputField(isFocused: isFocused)
        }
    }

    private var editor: some View {
        SupportNativeInputField(
            input: self, composing: $composing, isFocused: $isFocused, clearRequest: clearRequest
        )
        .overlay(alignment: .leading) {
            if text.isEmpty && !composing {
                Text(label)
                    .inquiryFont(14)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct SupportNativeInputField: NSViewRepresentable {
    let input: SupportInputField
    @Binding var composing: Bool
    @Binding var isFocused: Bool
    let clearRequest: Int
    @Environment(\.umcBodyTextScale) private var scale
    @Environment(\.umcFontFamily) private var family

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSTextField {
        let field = SupportTextControl()
        field.didFocus = { [weak coordinator = context.coordinator, weak field] in
            Task { @MainActor in
                guard let field, let editor = field.currentEditor(),
                      field.window?.firstResponder === editor else { return }
                coordinator?.parent.isFocused = true
                coordinator?.parent.input.onFocus()
            }
        }
        context.coordinator.observeComposition(in: field)
        field.focusRingType = .none
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
        field.setAccessibilityIdentifier(input.identifier)
        field.setAccessibilityLabel(input.label)
        field.isEnabled = context.environment.isEnabled
        field.font =
            NSFont(name: family ?? "Pretendard-Regular", size: 14 * scale)
            ?? .systemFont(ofSize: 14 * scale)
        let clearing = context.coordinator.clearRequest != clearRequest
        if clearing {
            context.coordinator.clearRequest = clearRequest
            if let editor = field.currentEditor() as? NSTextView {
                editor.inputContext?.discardMarkedText()
                editor.string = ""
            }
            field.stringValue = ""
        }
        if clearing || context.coordinator.focusRequest != input.focusRequest {
            context.coordinator.focusRequest = input.focusRequest
            Task { @MainActor [weak field] in
                await Task.yield()
                if let field, field.isEnabled { field.window?.makeFirstResponder(field) }
            }
        }
        guard (field.currentEditor() as? NSTextView)?.hasMarkedText() != true else { return }
        if field.stringValue != input.text { field.stringValue = input.text }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView field: NSTextField, context: Context)
        -> CGSize?
    {
        let font = field.font ?? .systemFont(ofSize: 14 * scale)
        let line = ceil(font.ascender - font.descender + font.leading)
        return .init(
            width: proposal.width ?? 180, height: max(line + 6, field.cell?.cellSize.height ?? 0))
    }

    static func dismantleNSView(_ view: NSTextField, coordinator: Coordinator) {
        if let monitor = coordinator.monitor { NSEvent.removeMonitor(monitor) }
    }

    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SupportNativeInputField
        var focusRequest = 0
        var clearRequest = 0
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
        init(_ parent: SupportNativeInputField) { self.parent = parent }
        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.isFocused = true
            parent.input.onFocus()
        }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            let marked = (field.currentEditor() as? NSTextView)?.hasMarkedText() == true
            parent.composing = marked
            guard !marked else { return }
            parent.input.text = field.stringValue
        }
        func controlTextDidEndEditing(_ notification: Notification) {
            parent.isFocused = false
            parent.composing = false
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector)
            -> Bool
        {
            guard !textView.hasMarkedText(),
                markedEvent == nil || markedEvent != NSApp.currentEvent?.timestamp
            else { return false }
            let action: (() -> Void)?
            switch selector {
            case #selector(NSResponder.insertNewline(_:)): action = parent.input.submit
            case #selector(NSResponder.moveDown(_:)): action = parent.input.moveDown
            case #selector(NSResponder.cancelOperation(_:)): action = parent.input.escape
            default: return false
            }
            guard let action else { return false }
            parent.input.text = textView.string
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
