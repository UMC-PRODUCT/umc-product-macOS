//
//  SettingsAppearanceView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsAppearanceView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveredTheme: SettingsTheme?

    var body: some View {
        @Bindable var preferences = viewModel.preferences
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsCard {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    Text("테마")
                        .umcTypography(.headlineBold)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: UMCSpacing.value16) {
                        themeButton(.system, title: "시스템", image: "settingsThemeSystem")
                        themeButton(.light, title: "라이트", image: "settingsThemeLight")
                        themeButton(.dark, title: "다크", image: "settingsThemeDark")
                    }
                    Text("시스템을 선택하면 macOS의 밝은 화면 · 어두운 화면 설정을 따를 수 있어요.")
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                }
            }
            SettingsSection(title: "읽기 편하게") {
                SettingsCard {
                    VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                        SettingsRow(title: "본문 크기", description: "앱 본문과 설명의 크기예요.") {
                            Picker("본문 크기", selection: $preferences.bodyTextSize) {
                                Text("기본").tag(SettingsBodyTextSize.standard)
                                Text("크게").tag(SettingsBodyTextSize.large)
                                Text("더 크게").tag(SettingsBodyTextSize.extraLarge)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 160, alignment: .trailing)
                        }
                        SettingsDivider()
                        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                            Text("본문 크기 미리보기").umcTypography(.headlineRegular)
                            Text("공지와 활동 안내를 편하게 읽어 보세요.")
                                .umcTypography(.bodyRegular)
                                .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                        }
                    }
                }
            }
            SettingsCard {
                SettingsRow(title: "모양 기본값으로 복원",
                    description: "테마는 시스템, 본문 크기는 기본으로 되돌려요.") {
                    SettingsActionButton(title: "복원") { viewModel.resetAppearance() }
                        .disabled(viewModel.isDefaultAppearance)
                }
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

    private func themeButton(_ theme: SettingsTheme, title: String, image: String) -> some View {
        let isSelected = viewModel.preferences.theme == theme
        let isHovered = hoveredTheme == theme
        return Button { viewModel.preferences.theme = theme } label: {
            VStack(spacing: UMCSpacing.value12) {
                Image(image, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 214)
                    .accessibilityHidden(true)
                HStack(spacing: UMCSpacing.value8) {
                    Text(title).umcTypography(.headlineRegular)
                    Image(systemName: "checkmark.circle.fill")
                        .opacity(isSelected ? 1 : 0)
                        .accessibilityHidden(true)
                }
            }
            .padding(UMCSpacing.value16)
            .frame(maxWidth: .infinity)
            .background(isSelected ? UMCColor.Semantic.fillPrimaryWeak75 :
                (isHovered ? UMCColor.Semantic.fillNeutralWeakerHoverPressed :
                    UMCColor.Custom.backgroundSurfaceWhite),
                in: .rect(cornerRadius: UMCRadius.value16))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(isSelected || isHovered ?
                        UMCColor.Semantic.borderPrimaryStrong500 :
                        UMCColor.Semantic.borderNeutralWeak200, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                hoveredTheme = hovering ? theme : nil
            }
        }
        .foregroundStyle(isSelected ? UMCColor.Semantic.textBrandDefault :
            UMCColor.Semantic.textNeutralStrong800)
        .accessibilityLabel("\(title) 테마")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
