//
//  ThreadSearchField.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import AppKit
import SwiftUI

struct ThreadSearchField: NSViewRepresentable {
    @Binding var query: String
    let selectResult: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "스레드 검색"
        field.setAccessibilityLabel("스레드 검색")
        field.delegate = context.coordinator
        field.stringValue = query
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.parent = self
        if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() { return }
        if field.stringValue != query { field.stringValue = query }
    }

    @MainActor final class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: ThreadSearchField
        init(_ parent: ThreadSearchField) { self.parent = parent }

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
