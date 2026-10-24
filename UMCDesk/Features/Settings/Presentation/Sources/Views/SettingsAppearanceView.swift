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
import UMCFoundation

struct SettingsAppearanceView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.settingsAppearancePalette) private var palette

    var body: some View {
        @Bindable var preferences = viewModel.preferences
        VStack(alignment: .leading, spacing: UMCSpacing.value20) {
            SettingsSection(title: AppLocalization.string("화면 스타일")) {
                SettingsCard(contentPadding: UMCSpacing.value20) {
                    VStack(spacing: UMCSpacing.value16) {
                        SettingsRow(title: AppLocalization.string("앱 모드"), description: "") {
                            HStack(spacing: UMCSpacing.value8) {
                                modeButton(
                                    .system, title: AppLocalization.string("시스템"),
                                    image: "settingsThemeSystem")
                                modeButton(
                                    .light, title: AppLocalization.string("라이트"),
                                    image: "settingsThemeLight")
                                modeButton(
                                    .dark, title: AppLocalization.string("다크"),
                                    image: "settingsThemeDark")
                            }
                        }
                        SettingsDivider()
                        SettingsThemeEditor(preferences: preferences)
                    }
                }
                // Keep theme recovery controls readable even with identical custom colors.
                .environment(\.settingsAppearancePalette,
                    (palette.colors?.contrast ?? 21) < 4.5 ? SettingsAppearancePalette() : palette)
            }
            SettingsSection(title: AppLocalization.string("언어 및 텍스트")) {
                SettingsCard(contentPadding: UMCSpacing.value20) {
                    VStack(spacing: UMCSpacing.value8) {
                        SettingsRow(title: AppLocalization.string("앱 언어"), description: "") {
                            Menu {
                                Picker(
                                    AppLocalization.string("앱 언어"),
                                    selection: Binding(
                                        get: { preferences.language },
                                    set: { language in
                                        preferences.language = language
                                        preferences.restoreSupportedFont()
                                    })) {
                                    Text("한국어").tag(AppLanguage.korean)
                                    Text("English").tag(AppLanguage.english)
                                }
                            } label: {
                                SettingsSelectionLabel(title: preferences.language == .korean ?
                                    "한국어" : "English")
                            }
                            .toggleStyle(.automatic)
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .menuIndicator(.hidden)
                            .fixedSize()
                            .accessibilityLabel(AppLocalization.string("앱 언어"))
                            .accessibilityValue(
                                preferences.language == .korean ? "한국어" : "English")
                        }
                        SettingsDivider()
                        SettingsRow(title: AppLocalization.string("글꼴"), description: "") {
                            SettingsFontPicker(preferences: preferences)
                        }
                        SettingsDivider()
                        SettingsRow(title: AppLocalization.string("본문 크기"), description: "") {
                            Menu {
                                Picker(
                                    AppLocalization.string("본문 크기"),
                                    selection: $preferences.bodyTextSize
                                ) {
                                    Text(AppLocalization.string("기본")).tag(
                                        SettingsBodyTextSize.standard)
                                    Text(AppLocalization.string("크게")).tag(
                                        SettingsBodyTextSize.large)
                                    Text(AppLocalization.string("더 크게")).tag(
                                        SettingsBodyTextSize.extraLarge)
                                }
                            } label: {
                                SettingsSelectionLabel(title: bodyTextSizeTitle)
                            }
                            .toggleStyle(.automatic)
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .menuIndicator(.hidden)
                            .fixedSize()
                            .accessibilityLabel(AppLocalization.string("본문 크기"))
                            .accessibilityValue(bodyTextSizeTitle)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            SettingsRow(
                title: AppLocalization.string("접근성"),
                description: AppLocalization.string("동작과 투명도는 macOS 설정을 따라요.")
            ) {
                Button(AppLocalization.string("macOS 설정 열기")) {
                    viewModel.openSystemSettings(.accessibility)
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, UMCSpacing.value20)
            SettingsDivider()
            HStack {
                Text(AppLocalization.string("변경 사항은 바로 적용되고 이 Mac에 저장돼요."))
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                Spacer(minLength: UMCSpacing.value16)
                SettingsActionButton(title: AppLocalization.string("모양 기본값으로 복원"), kind: .quiet) {
                    viewModel.resetAppearance()
                }
                .disabled(viewModel.isDefaultAppearance)
            }
            .padding(.horizontal, UMCSpacing.value20)
        }
    }

    private var bodyTextSizeTitle: String {
        switch viewModel.preferences.bodyTextSize {
        case .standard: AppLocalization.string("기본")
        case .large: AppLocalization.string("크게")
        case .extraLarge: AppLocalization.string("더 크게")
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
                Text(title).umcTypography(.bodyRegular)
            }
            .contentShape(.rect)
        }
        .buttonStyle(SettingsPlainButtonStyle(cornerRadius: UMCRadius.value8))
        .foregroundStyle(isSelected ? UMCColor.Semantic.textBrandDefault :
            UMCColor.Semantic.textNeutralStrong800)
        .accessibilityLabel(AppLocalization.string("\(title) 앱 모드"))
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

private struct SettingsFontPicker: View {
    @Bindable var preferences: SettingsPreferences
    @State private var families: [String] = []

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
                    preferences.font =
                        SettingsFont(rawValue: String(value.dropFirst(8))) ?? .pretendard
            }
            preferences.restoreSupportedFont()
        })
    }

    var body: some View {
        Menu {
            Picker(AppLocalization.string("글꼴"), selection: selection) {
            Text(AppLocalization.string("Pretendard · 기본")).tag("builtin:pretendard")
            Text(AppLocalization.string("시스템 기본")).tag("builtin:system")
            Text(AppLocalization.string("시스템 둥근 글꼴")).tag("builtin:rounded")
            Text(AppLocalization.string("시스템 세리프")).tag("builtin:serif")
            Section(AppLocalization.string("Mac에 설치된 글꼴")) {
                ForEach(families, id: \.self) { family in
                    Text(family).tag("family:" + family)
                }
            }
            }
        } label: {
            SettingsSelectionLabel(title: title)
        }
        .toggleStyle(.automatic)
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(AppLocalization.string("글꼴"))
        .accessibilityValue(title)
        .task(id: preferences.language) {
            let language = preferences.language
            families = []
            let supported = await Task.detached(priority: .userInitiated) {
                SettingsFontSupport.families(for: language)
            }.value
            guard !Task.isCancelled else { return }
            families = supported
        }
        .help(AppLocalization.string("선택한 글꼴에 없는 문자는 macOS의 대체 글꼴로 표시해요."))
    }

    private var title: String {
        if let family = preferences.availableFontFamily { return family }
        switch preferences.font {
        case .pretendard: return AppLocalization.string("Pretendard · 기본")
        case .system: return AppLocalization.string("시스템 기본")
        case .rounded: return AppLocalization.string("시스템 둥근 글꼴")
        case .serif: return AppLocalization.string("시스템 세리프")
        }
    }
}

private struct SettingsSelectionLabel: View {
    let title: String

    var body: some View {
        SettingsSelectionField {
            Text(title).lineLimit(1)
        }
    }
}
