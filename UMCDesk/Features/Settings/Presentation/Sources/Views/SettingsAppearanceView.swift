//
//  SettingsAppearanceView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import AppKit
import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsAppearanceView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        @Bindable var preferences = viewModel.preferences
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsSection(title: "화면 스타일") {
                SettingsCard {
                    SettingsRow(title: "앱 모드", description: "선택한 테마의 라이트·다크 색상에 적용돼요.") {
                        HStack(spacing: UMCSpacing.value8) {
                            modeButton(.system, title: "시스템", image: "settingsThemeSystem")
                            modeButton(.light, title: "라이트", image: "settingsThemeLight")
                            modeButton(.dark, title: "다크", image: "settingsThemeDark")
                        }
                    }
                }
                SettingsThemeEditor(preferences: preferences)
            }
            SettingsSection(title: "텍스트") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        SettingsRow(title: "글꼴", description: "앱의 제목·본문·사이드바에 적용해요.") {
                            SettingsFontPicker(preferences: preferences)
                        }
                        SettingsDivider()
                        SettingsRow(title: "본문 크기", description: "앱 본문과 설명의 크기예요.") {
                            Picker("본문 크기", selection: $preferences.bodyTextSize) {
                                Text("기본").tag(SettingsBodyTextSize.standard)
                                Text("크게").tag(SettingsBodyTextSize.large)
                                Text("더 크게").tag(SettingsBodyTextSize.extraLarge)
                            }
                            .labelsHidden()
                            .frame(width: 180)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            HStack {
                Text("변경 사항은 바로 적용되고 이 Mac에 저장돼요.")
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                Spacer(minLength: UMCSpacing.value16)
                SettingsActionButton(title: "모양 기본값으로 복원", kind: .quiet) {
                    viewModel.resetAppearance()
                }
                .disabled(viewModel.isDefaultAppearance)
            }
            SettingsSection(title: "시스템 접근성") {
                SettingsCard {
                    SettingsRow(title: "동작 줄이기 · 투명도 줄이기",
                        description: "macOS의 접근성 설정을 그대로 따라요.") {
                        SettingsActionButton(title: "macOS 설정 열기") {
                            viewModel.openSystemSettings(.accessibility)
                        }
                    }
                }
            }
        }
    }

    private func modeButton(_ theme: SettingsTheme, title: String, image: String) -> some View {
        let isSelected = viewModel.preferences.theme == theme
        return Button { viewModel.preferences.theme = theme } label: {
            VStack(spacing: UMCSpacing.value4) {
                Image(image, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 50)
                    .padding(UMCSpacing.value4)
                    .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                        in: .rect(cornerRadius: UMCRadius.value8))
                    .overlay {
                        RoundedRectangle(cornerRadius: UMCRadius.value8)
                            .strokeBorder(isSelected ? UMCColor.Semantic.borderPrimaryStrong500 :
                                UMCColor.Semantic.borderNeutralWeak200,
                                lineWidth: isSelected ? 2 : 1)
                    }
                    .accessibilityHidden(true)
                HStack(spacing: UMCSpacing.value4) {
                    Text(title).umcTypography(.bodyRegular)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .accessibilityHidden(true)
                    }
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(SettingsPlainButtonStyle(cornerRadius: UMCRadius.value8))
        .foregroundStyle(isSelected ? UMCColor.Semantic.textBrandDefault :
            UMCColor.Semantic.textNeutralStrong800)
        .accessibilityLabel("\(title) 앱 모드")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public extension SettingsFont {
    var design: Font.Design? {
        switch self {
        case .pretendard: nil
        case .system: .default
        case .rounded: .rounded
        case .serif: .serif
        }
    }
}

@MainActor
public extension SettingsPreferences {
    var availableFontFamily: String? {
        guard let fontFamily, NSFontManager.shared.availableFontFamilies.contains(fontFamily)
        else { return nil }
        return fontFamily
    }
}

private struct SettingsFontPicker: View {
    @Bindable var preferences: SettingsPreferences
    @State private var families = NSFontManager.shared.availableFontFamilies.sorted()

    private var selection: Binding<String> {
        Binding(get: {
            if let family = preferences.availableFontFamily { return "family:" + family }
            return "builtin:" + preferences.font.rawValue
        }, set: { value in
            if value.hasPrefix("family:") {
                preferences.fontFamily = String(value.dropFirst(7))
                preferences.font = .pretendard
            } else {
                preferences.fontFamily = nil
                preferences.font = SettingsFont(rawValue: String(value.dropFirst(8))) ?? .pretendard
            }
        })
    }

    var body: some View {
        Picker("글꼴", selection: selection) {
            Text("Pretendard · 기본").tag("builtin:pretendard")
            Text("시스템 기본").tag("builtin:system")
            Text("시스템 둥근 글꼴").tag("builtin:rounded")
            Text("시스템 세리프").tag("builtin:serif")
            Section("Mac에 설치된 글꼴") {
                ForEach(families, id: \.self) { family in
                    Text(family).tag("family:" + family)
                }
            }
        }
        .labelsHidden()
        .frame(width: 180)
        .help("선택한 글꼴에 없는 문자는 macOS의 대체 글꼴로 표시해요.")
    }
}
