//
//  UMCInputField.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/28/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

public extension View {
    /// Pass an existing editor's focus value when its caller owns keyboard navigation.
    func umcInputField(
        isFocused: Bool? = nil,
        isInvalid: Bool = false,
        minHeight: CGFloat = 36,
        background: Color = UMCColor.Custom.backgroundSurfaceWhite,
        border: Color = UMCColor.Semantic.borderNeutralMedium300,
        focusBorder: Color = UMCColor.Semantic.borderPrimaryStrong500
    ) -> some View {
        modifier(InputFieldStyle(
            externalFocus: isFocused, isInvalid: isInvalid, minHeight: minHeight,
            fill: background, border: border, focusBorder: focusBorder
        ))
    }
}

private struct InputFieldStyle: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var localFocus: Bool
    let externalFocus: Bool?
    let isInvalid: Bool
    let minHeight: CGFloat
    let fill: Color
    let border: Color
    let focusBorder: Color

    func body(content: Content) -> some View {
        Group {
            if externalFocus == nil {
                content.focused($localFocus).focusEffectDisabled()
            } else {
                content
            }
        }
        .textFieldStyle(.plain)
        .umcTypography(.headlineRegular)
        .padding(.horizontal, UMCSpacing.value12)
        .frame(minHeight: minHeight)
        .background(isEnabled ? fill : UMCColor.Semantic.fillNeutralDisabled,
                    in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(stroke, lineWidth: isInvalid && (externalFocus ?? localFocus) ? 2 : 1)
                .allowsHitTesting(false)
        }
    }

    private var stroke: Color {
        guard isEnabled else { return border }
        if isInvalid { return UMCColor.Semantic.borderErrorStrong500 }
        return (externalFocus ?? localFocus) ? focusBorder : border
    }
}

/// Shared search chrome. Custom editors keep their delegate, focus owner and submit behavior.
public struct UMCSearchField<Editor: View>: View {
    @Binding private var text: String
    @FocusState private var localFocus: Bool
    private var title = ""
    private var label: String?
    private var hint: String?
    private var externalFocus: Bool?
    private var onClear: (() -> Void)?
    private var editor: Editor?
    private var fill = UMCColor.Custom.backgroundSurfaceGreyWeak
    private var foreground = UMCColor.Semantic.textNeutralDefault
    private var focusBorder = UMCColor.Semantic.borderPrimaryStrong500

    public init(
        text: Binding<String>, isFocused: Bool,
        background: Color = UMCColor.Custom.backgroundSurfaceGreyWeak,
        foreground: Color = UMCColor.Semantic.textNeutralDefault,
        focusBorder: Color = UMCColor.Semantic.borderPrimaryStrong500,
        onClear: @escaping () -> Void, @ViewBuilder editor: () -> Editor
    ) {
        _text = text
        externalFocus = isFocused
        self.onClear = onClear
        self.editor = editor()
        fill = background
        self.foreground = foreground
        self.focusBorder = focusBorder
    }

    public init(
        _ title: String, text: Binding<String>,
        accessibilityLabel: String? = nil, accessibilityHint: String? = nil
    ) where Editor == EmptyView {
        _text = text
        self.title = title
        label = accessibilityLabel
        hint = accessibilityHint
    }

    public var body: some View {
        HStack(spacing: UMCSpacing.value8) {
            Image(systemName: "magnifyingglass").accessibilityHidden(true)
            if let editor {
                editor.focusEffectDisabled()
            } else {
                TextField(title, text: $text)
                    .umcToolSearchFocus($localFocus)
                    .focusEffectDisabled()
                    .accessibilityLabel(label ?? title)
                    .accessibilityHint(hint ?? "")
            }
            if !text.isEmpty {
                UMCFocusableButton(
                    AppLocalization.string("검색어 지우기"), cornerRadius: UMCRadius.value8,
                    action: clear
                ) { _ in
                    Image(systemName: "xmark.circle.fill")
                        .frame(minWidth: 24, minHeight: 28)
                }
            }
        }
        .textFieldStyle(.plain)
        .umcTypography(.headlineRegular)
        .foregroundStyle(foreground)
        .padding(.horizontal, UMCSpacing.value16)
        .frame(minHeight: 36)
        .background(fill, in: Capsule(style: .circular))
        .overlay {
            Capsule(style: .circular)
                .strokeBorder((externalFocus ?? localFocus) ? focusBorder : .clear)
                .allowsHitTesting(false)
        }
    }

    private func clear() {
        if let onClear {
            onClear()
        } else {
            text = ""
            localFocus = true
        }
    }
}
