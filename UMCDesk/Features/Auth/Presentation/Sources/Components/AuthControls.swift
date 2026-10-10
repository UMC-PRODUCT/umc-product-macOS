//
//  AuthControls.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

enum AuthButtonKind {
    case primary, secondary, brand, destructive, destructiveQuiet, tertiary
}

struct AuthButton: View {
    let title: String
    var kind: AuthButtonKind = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .umcTypography(.title3Regular)
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(.capsule)
        }
        .buttonStyle(AuthButtonStyle(kind: kind))
    }
}

private struct AuthButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let kind: AuthButtonKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background, in: .capsule)
            .overlay {
                Capsule().strokeBorder(
                    kind == .secondary ? UMCColor.Semantic.borderNeutralWeaker100 : .clear,
                    lineWidth: 1
                )
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var foreground: Color {
        guard isEnabled else { return UMCColor.Semantic.textInverse }
        switch kind {
        case .primary, .destructive: return UMCColor.Semantic.textInverse
        case .brand: return UMCColor.Semantic.textBrandDefault
        case .destructiveQuiet: return UMCColor.Semantic.textError
        case .tertiary: return UMCColor.Semantic.textNeutralWeak500
        case .secondary: return UMCColor.Semantic.textNeutralDefault
        }
    }

    private var background: Color {
        guard isEnabled else { return UMCColor.Primitives.tealGrey400 }
        switch kind {
        case .primary: return UMCColor.Primitives.black
        case .secondary, .tertiary: return .clear
        case .brand: return UMCColor.Semantic.fillPrimaryWeaker50
        case .destructive: return UMCColor.Semantic.fillErrorStrong500
        case .destructiveQuiet: return UMCColor.Semantic.fillErrorWeak50
        }
    }
}

struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: AuthField
    let focus: FocusState<AuthField?>.Binding
    var isSecure = false
    @Binding var showsValue: Bool
    var isDisabled = false
    var isInvalid = false
    var showsClear = false

    init(
        _ title: String,
        placeholder: String,
        text: Binding<String>,
        field: AuthField,
        focus: FocusState<AuthField?>.Binding,
        isSecure: Bool = false,
        showsValue: Binding<Bool> = .constant(false),
        isDisabled: Bool = false,
        isInvalid: Bool = false,
        showsClear: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.field = field
        self.focus = focus
        self.isSecure = isSecure
        _showsValue = showsValue
        self.isDisabled = isDisabled
        self.isInvalid = isInvalid
        self.showsClear = showsClear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title)
                .umcTypography(.title3Regular)
                .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
            HStack(spacing: UMCSpacing.value8) {
                Group {
                    if isSecure && !showsValue {
                        SecureField("", text: $text, prompt: prompt)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                    }
                }
                .textFieldStyle(.plain)
                .umcTypography(.headlineRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                .focused(focus, equals: field)
                .accessibilityLabel(title)
                .disabled(isDisabled)

                if isSecure {
                    Button {
                        showsValue.toggle()
                        focus.wrappedValue = field
                    } label: {
                        Image(systemName: showsValue ? "eye.slash" : "eye")
                            .font(.system(size: 18))
                            .frame(width: 32, height: 40)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
                    .accessibilityLabel("\(title) \(showsValue ? "가리기" : "보기")")
                    .disabled(isDisabled)
                } else if showsClear && !text.isEmpty {
                    Button {
                        text = ""
                        focus.wrappedValue = field
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .frame(width: 32, height: 40)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
                    .accessibilityLabel("\(title) 지우기")
                }
            }
            .padding(.leading, UMCSpacing.value16)
            .padding(.trailing, UMCSpacing.value12)
            .frame(minHeight: 48)
            .background(
                isDisabled ? UMCColor.Primitives.tealGrey75 : UMCColor.Semantic.surfaceDefault,
                in: .rect(cornerRadius: UMCRadius.value12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundColor(UMCColor.Primitives.tealGrey400)
    }

    private var borderColor: Color {
        if isInvalid { return UMCColor.Semantic.borderErrorStrong500 }
        if focus.wrappedValue == field { return UMCColor.Semantic.borderPrimaryStrong500 }
        return UMCColor.Semantic.borderNeutralMedium300
    }
}

struct AuthHeading: View {
    let title: String
    let subtitle: String
    var isLeading = false
    var icon: String?

    var body: some View {
        VStack(alignment: isLeading ? .leading : .center, spacing: UMCSpacing.value24) {
            if let icon {
                Image(icon, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
            }
            VStack(alignment: isLeading ? .leading : .center, spacing: UMCSpacing.value12) {
                Text(title)
                    .umcTypography(.largeTitle2Bold)
                    .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                    .accessibilityAddTraits(.isHeader)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .umcTypography(.title3Regular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                }
            }
            .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .center)
        }
        .multilineTextAlignment(isLeading ? .leading : .center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct AuthBanner: View {
    let title: String
    var message = ""
    var isError = false
    var isBrand = false
    var symbol: String?

    var body: some View {
        HStack(alignment: symbol == nil ? .top : .center, spacing: UMCSpacing.value8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                Text(title)
                    .umcTypography(symbol == nil ? .bodyRegular : .headlineRegular)
                    .foregroundStyle(
                        isError ? UMCColor.Semantic.textError :
                            isBrand ? UMCColor.Semantic.textBrandDefault :
                            symbol == nil ? UMCColor.Semantic.textNeutralDefault :
                            UMCColor.Semantic.textNeutralWeak500
                    )
                if !message.isEmpty {
                    Text(message)
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
        .padding(.horizontal, symbol == nil ? UMCSpacing.value16 : UMCSpacing.value12)
        .padding(.vertical, symbol == nil ? UMCSpacing.value16 : UMCSpacing.value8)
        .background(
            isBrand ? UMCColor.Semantic.backgroundBrandWeak :
                UMCColor.Semantic.backgroundNeutralMedium,
            in: .rect(cornerRadius: UMCRadius.value12)
        )
        .accessibilityElement(children: .combine)
    }
}

struct AuthSteps: View {
    let titles: [String]
    var completedCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            ForEach(Array(titles.enumerated()), id: \.element) { index, title in
                HStack(spacing: UMCSpacing.value8) {
                    Image(systemName: symbol(at: index))
                        .font(.system(size: index < completedCount ? 24 :
                            index == completedCount ? 18 : 12))
                        .frame(width: 48, height: 46)
                        .overlay(alignment: .top) {
                            if index < titles.count - 1 {
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: 0, y: 40))
                                }
                                .stroke(
                                    UMCColor.Semantic.borderPrimaryWeaker100,
                                    style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                                )
                                .frame(width: 1, height: 40)
                                .offset(y: 34)
                            }
                        }
                        .accessibilityHidden(true)
                    Text(title)
                        .umcTypography(index < completedCount ? .title3Bold : .title3Regular)
                }
                .foregroundStyle(
                    index <= completedCount ? UMCColor.Semantic.textBrandDefault :
                        UMCColor.Primitives.teal300
                )
                .accessibilityLabel("\(title), \(index < completedCount ? "완료" : "대기 중")")
            }
        }
        .padding(UMCSpacing.value12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UMCColor.Semantic.backgroundBrandWeak,
            in: .rect(cornerRadius: UMCRadius.value12)
        )
    }

    private func symbol(at index: Int) -> String {
        if index < completedCount { return "checkmark.circle.fill" }
        return index == completedCount ? "circle.dotted" : "circle.fill"
    }
}
