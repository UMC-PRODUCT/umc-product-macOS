//
//  UMCTabTools.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/25/26.
//

import CoreDesignSystem
import SwiftUI

public extension EnvironmentValues {
    /// Changed by the enclosing window when an action outside the feature takes focus.
    @Entry var tabToolsDismissalRequest = 0
}

public extension View {
    /// Hosts the active feature's commands beneath its trailing window toolbar button.
    func umcTabTools<Actions: View>(
        _ title: String, description: String, findShortcut: Bool = false,
        @ViewBuilder actions: @escaping (@escaping () -> Void) -> Actions
    ) -> some View {
        modifier(TabTools(title: title, description: description, findShortcut: findShortcut,
                          actions: actions))
    }
}

private struct TabTools<Actions: View>: ViewModifier {
    let title: String
    let description: String
    let findShortcut: Bool
    let actions: (@escaping () -> Void) -> Actions
    @Environment(\.tabToolsDismissalRequest) private var dismissalRequest
    @Environment(\.isEnabled) private var isEnabled
    @State private var presented = false
    @State private var triggerFocus = UMCWindowButtonFocus()
    @FocusState private var closeFocused: Bool
    @AccessibilityFocusState private var accessibleFocus: Target?

    private enum Target { case trigger, close }

    func body(content: Content) -> some View {
        content
            .disabled(presented)
            .accessibilityHidden(presented)
            .overlay(alignment: .topTrailing) {
                if presented {
                    ZStack(alignment: .topTrailing) {
                        Color.clear.contentShape(.rect)
                            .onTapGesture(perform: dismiss)
                            .accessibilityHidden(true)
                        panel.padding([.top, .trailing], UMCSpacing.value4)
                    }
                }
            }
            .toolbar {
                ToolbarSpacer(.flexible, placement: .primaryAction)
                ToolbarItem(placement: .primaryAction) {
                    ToolsTrigger(title: title, presented: presented, findShortcut: findShortcut,
                                 focus: triggerFocus) {
                        if presented { dismiss() } else { presented = true }
                    }
                    .frame(width: 32, height: 28)
                    .accessibilityFocused($accessibleFocus, equals: .trigger)
                }
            }
            .onDisappear { presented = false }
            .onChange(of: dismissalRequest) { presented = false }
            .onChange(of: isEnabled) { if !isEnabled { presented = false } }
    }

    private var panel: some View {
        ViewThatFits(in: .vertical) {
            panelContent.fixedSize(horizontal: false, vertical: true)
            ScrollView { panelContent }
        }
        .frame(maxWidth: 390)
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .background {
            RoundedRectangle(cornerRadius: UMCRadius.value16)
                .fill(UMCColor.Custom.backgroundSurface)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value16)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                .allowsHitTesting(false)
        }
        .task {
            await Task.yield()
            guard !Task.isCancelled else { return }
            closeFocused = true
            accessibleFocus = .close
        }
        .onExitCommand(perform: dismiss)
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            HStack {
                Text(title).umcTypography(.title4Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("닫기", systemImage: "xmark", action: dismiss)
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
                    .focusable()
                    .focused($closeFocused)
                    .accessibilityFocused($accessibleFocus, equals: .close)
                    .keyboardShortcut(.cancelAction)
            }
            Text(description).umcTypography(.bodyRegular).foregroundStyle(.secondary)
            actions { presented = false }
            HStack {
                Text("상단 도구 버튼으로 다시 열 수 있어요")
                Spacer()
                Text("Esc")
            }
            .umcTypography(.captionRegular)
            .foregroundStyle(.secondary)
        }
        .padding(UMCSpacing.value20)
    }

    private func dismiss() {
        presented = false
        Task { @MainActor in
            await Task.yield()
            guard !presented, triggerFocus.focus() else { return }
            accessibleFocus = .trigger
        }
    }
}


/// A toolbar control remains in the native window key loop after its panel disappears.
private struct ToolsTrigger: NSViewRepresentable {
    let title: String
    let presented: Bool
    let findShortcut: Bool
    let focus: UMCWindowButtonFocus
    let activate: () -> Void

    func makeNSView(context: Context) -> Control {
        let button = Control()
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .accessoryBarAction
        button.imagePosition = .imageOnly
        button.target = button
        button.action = #selector(Control.toggleTools)
        return button
    }

    func updateNSView(_ button: Control, context: Context) {
        focus.control = button
        button.activate = activate
        let symbol = presented ? "sidebar.right.fill" : "sidebar.right"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.setAccessibilityValue(presented ? "열림" : "닫힘")
        button.setAccessibilityIdentifier(symbol)
        button.keyEquivalent = findShortcut ? "f" : ""
        button.keyEquivalentModifierMask = .command
    }

    final class Control: NSButton {
        var activate: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override var canBecomeKeyView: Bool { !isHiddenOrHasHiddenAncestor && isEnabled }

        @objc func toggleTools() { activate?() }

        override func keyDown(with event: NSEvent) {
            let modifiers = event.modifierFlags.intersection([.command, .shift, .control, .option])
            if modifiers.isEmpty, [" ", "\r"].contains(event.charactersIgnoringModifiers ?? "") {
                performClick(nil)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
