//
//  ThreadSearchField.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import AppKit
import CoreUIComponents
import SwiftUI
import UMCFoundation

struct ThreadSearchField: View {
    @Binding var query: String
    var focusRequest = 0
    var placeholder = "스레드 검색"
    let selectResult: () -> Void

    @State private var focused = false
    @State private var clearRequest = 0

    var body: some View {
        UMCSearchField(text: $query, isFocused: focused, onClear: {
            query = ""
            clearRequest += 1
        }) {
            ThreadSearchEditor(query: $query, focused: $focused, focusRequest: focusRequest,
                               clearRequest: clearRequest, placeholder: placeholder,
                               selectResult: selectResult)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ThreadSearchEditor: NSViewRepresentable {
    @Binding var query: String
    @Binding var focused: Bool
    let focusRequest: Int
    let clearRequest: Int
    let placeholder: String
    let selectResult: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSearchField {
        let field = ConversationSearchControl()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        if let cell = field.cell as? NSSearchFieldCell {
            cell.searchButtonCell = nil
            cell.cancelButtonCell = nil
        }
        field.placeholderString = AppLocalization.string(.init(placeholder))
        field.setAccessibilityLabel(field.placeholderString)
        field.didFocus = { [weak coordinator = context.coordinator] in
            coordinator?.parent.focused = true
        }
        field.delegate = context.coordinator
        field.stringValue = query
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        if let font = context.environment.font?.resolve(in: context.environment.fontResolutionContext) {
            let nativeFont = font.ctFont as NSFont
            if field.font != nativeFont { field.font = nativeFont }
        }
        if field.isEnabled != context.environment.isEnabled {
            field.isEnabled = context.environment.isEnabled
        }
        context.coordinator.parent = self
        let shouldClear = context.coordinator.clearRequest != clearRequest
        if shouldClear || context.coordinator.focusRequest != focusRequest {
            context.coordinator.clearRequest = clearRequest
            context.coordinator.focusRequest = focusRequest
            // The panel relinquishes its first responder after SwiftUI removes the overlay.
            Task { @MainActor [weak field] in
                await Task.yield()
                guard let field, field.isEnabled, let window = field.window,
                      window.makeFirstResponder(field) else { return }
                if shouldClear, let editor = field.currentEditor() as? NSTextView {
                    editor.unmarkText()
                    editor.string = ""
                    field.stringValue = ""
                } else {
                    field.selectText(nil)
                }
            }
        }
        if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() { return }
        if field.stringValue != query { field.stringValue = query }
    }

    @MainActor final class Coordinator: NSObject, NSSearchFieldDelegate {
        var focusRequest = 0
        var clearRequest = 0
        var parent: ThreadSearchEditor
        init(_ parent: ThreadSearchEditor) { self.parent = parent }

        func controlTextDidEndEditing(_ notification: Notification) { parent.focused = false }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() { return }
            parent.query = field.stringValue
        }

        func control(
            _ control: NSControl, textView: NSTextView, doCommandBy selector: Selector
        ) -> Bool {
            guard !textView.hasMarkedText(),
                  selector == #selector(NSResponder.insertNewline(_:))
                    || selector == #selector(NSResponder.moveDown(_:)) else { return false }
            parent.query = textView.string
            parent.selectResult()
            return true
        }
    }
}

private final class ConversationSearchControl: NSSearchField {
    var didFocus: (() -> Void)?

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { didFocus?() }
        return accepted
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isEnabled, event.modifierFlags.intersection([.command, .shift, .option, .control]) == .command,
           event.charactersIgnoringModifiers?.lowercased() == "f", let window,
           window.makeFirstResponder(self) {
            selectText(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
