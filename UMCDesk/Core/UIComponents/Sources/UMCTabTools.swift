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

public enum UMCToolPanelWidth: CGFloat {
    case standard = 300
    case wide = 390
}

private extension EnvironmentValues {
    @Entry var hostsTabTools = false
    @Entry var toolSearchFocusRequest: Int?
}

private struct ToolPanelPreference: PreferenceKey {
    static var defaultValue: AnyView? { nil }

    static func reduce(value: inout AnyView?, nextValue: () -> AnyView?) {
        if let next = nextValue() { value = next }
    }
}

public extension View {
    /// Place at the window workspace root so the dismissal layer also covers its sidebar.
    func umcTabToolsHost() -> some View {
        environment(\.hostsTabTools, true)
            .overlayPreferenceValue(ToolPanelPreference.self, alignment: .topTrailing) { $0 }
    }

    /// Focus a tool panel's search field when its window handles Find.
    func umcToolSearchFocus(_ focus: FocusState<Bool>.Binding? = nil) -> some View {
        modifier(ToolSearchFocus(binding: focus))
    }

    /// Hosts the active feature's commands beneath its trailing window toolbar button.
    func umcTabTools<Actions: View>(
        _ title: String, width: UMCToolPanelWidth = .standard, findShortcut: Bool = false,
        isPresented: Binding<Bool>? = nil, inlineTrigger: Bool = false,
        @ViewBuilder actions: @escaping (@escaping () -> Void) -> Actions
    ) -> some View {
        modifier(TabTools(title: title, width: width, findShortcut: findShortcut,
                          externalPresentation: isPresented, inlineTrigger: inlineTrigger,
                          actions: actions))
    }
}

private struct ToolSearchFocus: ViewModifier {
    @Environment(\.toolSearchFocusRequest) private var request
    @FocusState private var localFocus: Bool
    let binding: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        let focus = binding ?? $localFocus
        content
            .focused(focus)
            .task(id: request) {
                guard request != nil else { return }
                await Task.yield()
                if !Task.isCancelled { focus.wrappedValue = true }
            }
    }
}

private struct TabTools<Actions: View>: ViewModifier {
    let title: String
    let width: UMCToolPanelWidth
    let findShortcut: Bool
    let externalPresentation: Binding<Bool>?
    let inlineTrigger: Bool
    let actions: (@escaping () -> Void) -> Actions
    @Environment(\.tabToolsDismissalRequest) private var dismissalRequest
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.hostsTabTools) private var hasHost
    @Environment(\.self) private var environment
    @State private var presented = false
    @State private var searchFocusRequest = 0
    @State private var triggerFocus = UMCWindowButtonFocus()
    @AccessibilityFocusState private var triggerAccessible: Bool
    @FocusState private var panelFocused: Bool

    private var presentation: Binding<Bool> { externalPresentation ?? $presented }

    func body(content: Content) -> some View {
        Group {
            if inlineTrigger {
                VStack(alignment: .trailing, spacing: 0) {
                    trigger
                        .padding(.horizontal, UMCSpacing.value16)
                        .frame(maxWidth: .infinity, minHeight: 36, alignment: .trailing)
                        .background {
                            Color.clear.contentShape(.rect)
                                .onTapGesture { presentation.wrappedValue = false }
                        }
                    content.overlay(alignment: .topTrailing) {
                        if presentation.wrappedValue { panel }
                    }
                }
                .background(UMCColor.Custom.backgroundDefault, in: .rect(cornerRadius: 24))
            } else if hasHost {
                feature(content)
            } else {
                feature(content).umcTabToolsHost()
            }
        }
        .onDisappear { presentation.wrappedValue = false }
        .onChange(of: dismissalRequest) { presentation.wrappedValue = false }
        .onChange(of: isEnabled) { if !isEnabled { presentation.wrappedValue = false } }
    }

    private func feature(_ content: Content) -> some View {
        content
            .preference(
                key: ToolPanelPreference.self,
                value: presentation.wrappedValue
                    ? AnyView(panel.environment(\.self, environment)) : nil
            )
            .toolbar {
                ToolbarSpacer(.flexible, placement: .primaryAction)
                ToolbarItem(placement: .primaryAction) { trigger }
                    .sharedBackgroundVisibility(.hidden)
            }
    }

    private var trigger: some View {
        ToolsTrigger(
            title: title, presented: presentation.wrappedValue, findShortcut: findShortcut,
            isEnabled: isEnabled, focus: triggerFocus, dismiss: dismissFromKeyboard,
            find: {
                if presentation.wrappedValue { searchFocusRequest += 1 }
                presentation.wrappedValue = true
            },
            activate: { if isEnabled { presentation.wrappedValue.toggle() } }
        )
        .frame(width: 32, height: 28)
        .accessibilityLabel(title)
        .accessibilityValue(presentation.wrappedValue ? "열림" : "닫힘")
        .accessibilityFocused($triggerAccessible)
    }

    private var panel: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { presentation.wrappedValue = false }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                HStack {
                    Text(title)
                        .umcTypography(.title4Bold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button("닫기", systemImage: "xmark", action: dismissFromKeyboard)
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 32, minHeight: 32)
                        .focused($panelFocused)
                }
                ViewThatFits(in: .vertical) {
                    commands.fixedSize(horizontal: false, vertical: true)
                    ScrollView { commands }
                        .scrollBounceBehavior(.basedOnSize)
                }
            }
            .padding(UMCSpacing.value20)
            .frame(maxWidth: width.rawValue, alignment: .leading)
            .background(UMCColor.Custom.backgroundSurfaceWhite,
                        in: .rect(cornerRadius: UMCRadius.value16))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
            .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
            .focusSection()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isModal)
            .onAppear { if !findShortcut { panelFocused = true } }
            .padding(UMCSpacing.value16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var commands: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            actions { presentation.wrappedValue = false }
        }
        .environment(\.toolSearchFocusRequest, findShortcut ? searchFocusRequest : nil)
        .buttonStyle(TabToolsButtonStyle())
        .controlSize(.small)
        .labelStyle(.titleAndIcon)
    }

    private func dismissFromKeyboard() {
        presentation.wrappedValue = false
        Task { @MainActor in
            await Task.yield()
            if triggerFocus.focus() { triggerAccessible = true }
        }
    }

}

public struct UMCToolPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .umcTypography(.headlineBold)
            .foregroundStyle(UMCColor.Semantic.textInverse)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                configuration.isPressed ? UMCColor.Semantic.fillPrimaryInverseStrongHoverPressed
                    : UMCColor.Semantic.fillPrimaryInverseStrong500,
                in: .rect(cornerRadius: UMCRadius.value8)
            )
            .contentShape(.rect)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

public struct UMCToolGroupHeading: View {
    private let title: String

    public init(_ title: String) { self.title = title }

    public var body: some View {
        Text(title)
            .umcTypography(.bodyRegular)
            .foregroundStyle(.secondary)
            .padding(.horizontal, UMCSpacing.value8)
            .padding(.top, UMCSpacing.value4)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct TabToolsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration)
    }

    private struct Row: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled
        @State private var hovering = false

        var body: some View {
            configuration.label
                .umcTypography(.headlineRegular)
                .padding(.horizontal, UMCSpacing.value12)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .contentShape(.rect)
                .background {
                    if isEnabled && (hovering || configuration.isPressed) {
                        RoundedRectangle(cornerRadius: UMCRadius.value6)
                            .fill(.primary.opacity(configuration.isPressed ? 0.15 : 0.08))
                    }
                }
                .opacity(isEnabled ? 1 : 0.5)
                .onHover { hovering = $0 }
        }
    }
}

/// A toolbar control remains in the native window key loop after its panel disappears.
private struct ToolsTrigger: NSViewRepresentable {
    let title: String
    let presented: Bool
    let findShortcut: Bool
    let isEnabled: Bool
    let focus: UMCWindowButtonFocus
    let dismiss: () -> Void
    let find: () -> Void
    let activate: () -> Void

    func makeNSView(context: Context) -> Control {
        let button = Control()
        button.setButtonType(.toggle)
        button.isBordered = false
        button.focusRingType = .none
        if let cell = button.cell as? NSButtonCell {
            cell.highlightsBy = []
            cell.showsStateBy = []
        }
        button.imagePosition = .imageOnly
        button.target = button
        button.action = #selector(Control.toggleTools)
        return button
    }

    func updateNSView(_ button: Control, context: Context) {
        focus.control = button
        button.isEnabled = isEnabled
        button.activate = activate
        button.find = find
        button.observeEscape(when: presented, dismiss: dismiss)
        let symbol = "slider.horizontal.3"
        button.state = presented ? .on : .off
        button.toolTitle = title
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        button.symbolConfiguration = .init(pointSize: 16, weight: .medium)
        button.contentTintColor = .labelColor
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.setAccessibilityValue(presented ? "열림" : "닫힘")
        button.setAccessibilityIdentifier("sidebar.right")
        button.keyEquivalent = findShortcut ? "f" : ""
        button.keyEquivalentModifierMask = .command
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: Control, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    static func dismantleNSView(_ button: Control, coordinator: ()) {
        button.stopObservingEscape()
    }

    final class Control: NSButton {
        private var hoverArea: NSTrackingArea?
        private var hovering = false
        private var escapeMonitor: Any?
        private var dismiss: (() -> Void)?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let hoverArea { removeTrackingArea(hoverArea) }
            let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow,
                                                             .inVisibleRect], owner: self)
            addTrackingArea(area)
            hoverArea = area
            hovering = window.map { bounds.contains(convert($0.mouseLocationOutsideOfEventStream,
                                                             from: nil)) } ?? false
            needsDisplay = true
        }

        override func mouseEntered(with event: NSEvent) {
            super.mouseEntered(with: event)
            hovering = true
            needsDisplay = true
        }

        override func mouseExited(with event: NSEvent) {
            super.mouseExited(with: event)
            hovering = false
            needsDisplay = true
        }

        private var circleBounds: NSRect {
            let diameter = min(28, bounds.width, bounds.height)
            return NSRect(x: bounds.midX - diameter / 2, y: bounds.midY - diameter / 2,
                          width: diameter, height: diameter)
        }

        override func becomeFirstResponder() -> Bool {
            needsDisplay = true
            return super.becomeFirstResponder()
        }

        override func resignFirstResponder() -> Bool {
            needsDisplay = true
            return super.resignFirstResponder()
        }

        override func draw(_ dirtyRect: NSRect) {
            let activeHover = hovering && window?.isKeyWindow == true
            if isEnabled && (isHighlighted || state == .on || activeHover) {
                let opacity: CGFloat = isHighlighted ? 0.22 : (state == .on ? 0.16 : 0.10)
                NSColor.labelColor.withAlphaComponent(opacity).setFill()
                NSBezierPath(ovalIn: circleBounds).fill()
            }
            super.draw(dirtyRect)
            if isEnabled, window?.isKeyWindow == true, window?.firstResponder === self {
                NSColor.keyboardFocusIndicatorColor.setStroke()
                let ring = NSBezierPath(ovalIn: circleBounds.insetBy(dx: 1, dy: 1))
                ring.lineWidth = 2
                ring.stroke()
            }
        }

        func observeEscape(when presented: Bool, dismiss: @escaping () -> Void) {
            self.dismiss = dismiss
            guard presented else {
                stopObservingEscape()
                return
            }
            guard escapeMonitor == nil else { return }
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, let window, event.window === window, window.isKeyWindow,
                      window.attachedSheet == nil, event.keyCode == 53 else { return event }
                window.makeFirstResponder(self)
                self.dismiss?()
                return nil
            }
        }

        func stopObservingEscape() {
            if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
            escapeMonitor = nil
            dismiss = nil
        }

        var toolTitle = ""
        override func accessibilityLabel() -> String? { toolTitle }
        override func accessibilityTitle() -> String? { toolTitle }
        var activate: (() -> Void)?
        var find: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override var canBecomeKeyView: Bool { !isHiddenOrHasHiddenAncestor && isEnabled }

        @objc func toggleTools() {
            guard isEnabled else { return }
            if let event = NSApp.currentEvent, event.type == .keyDown,
               event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "f" {
                guard window?.isKeyWindow == true, window?.attachedSheet == nil else { return }
                find?()
            } else {
                activate?()
            }
        }

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

/// A document-level modal can cover the shared rail as well as the selected workspace.
@MainActor @Observable public final class UMCWorkspaceModalHost {
    public var content: AnyView?
    public init() {}
}

public extension EnvironmentValues {
    @Entry var umcWorkspaceModalHost: UMCWorkspaceModalHost?
}
