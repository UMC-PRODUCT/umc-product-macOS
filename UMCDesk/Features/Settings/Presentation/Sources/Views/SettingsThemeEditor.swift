//
//  SettingsThemeEditor.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/24/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsThemeEditor: View {
    @Bindable var preferences: SettingsPreferences
    @Environment(\.settingsThemeMode) private var colorScheme
    @State private var showsThemes = false
    @State private var showsDuplicate = false
    @State private var showsDelete = false
    @State private var themeName = ""

    private var theme: SettingsColorTheme { preferences.selectedColorTheme }
    private var colors: SettingsThemeColors { theme.colors(for: colorScheme) }
    private var hasLowContrast: Bool {
        colors.sidebar.contrast < 4.5 || colors.content.contrast < 4.5
    }

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                SettingsRow(title: "테마", description: "프리셋과 나만의 테마를 선택해요.") {
                    Button { showsThemes = true } label: {
                        HStack(spacing: UMCSpacing.value8) {
                            SettingsThemeSwatch(colors: colors).frame(width: 44, height: 30)
                            Text(theme.name).lineLimit(1)
                            Image(systemName: "chevron.down")
                        }
                        .frame(maxWidth: 220)
                    }
                    .popover(isPresented: $showsThemes) {
                        themePicker
                    }
                    .accessibilityLabel("테마 선택, \(theme.name)")
                }
                SettingsDivider()
                HStack {
                    Text(colorScheme == .dark ? "다크 모드 색상" : "라이트 모드 색상")
                        .umcTypography(.headlineBold)
                    Spacer()
                    Text("다른 모드의 색상은 유지돼요")
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                }
                colorRow("사이드바", background: \.sidebar.background,
                    foreground: \.sidebar.foreground)
                SettingsDivider()
                colorRow("콘텐츠", background: \.content.background, foreground: \.content.foreground)
                if hasLowContrast {
                    HStack(alignment: .top, spacing: UMCSpacing.value8) {
                        Label("글자와 배경의 대비가 낮아요.", systemImage: "exclamationmark.triangle")
                            .umcTypography(.bodyRegular)
                        Spacer()
                        Button("읽기 쉬운 글자색 적용") { improveContrast() }
                    }
                    .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
                }
                SettingsDivider()
                HStack {
                    Text(preferences.isCustomColorTheme ? "변경 사항을 자동으로 저장해요." :
                        "색상을 바꾸면 사용자 테마로 자동 저장해요.")
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                    Spacer(minLength: UMCSpacing.value8)
                    Button("복제하여 저장…") {
                        themeName = String((theme.name + " 복사본").prefix(40))
                        showsDuplicate = true
                    }
                    if preferences.isCustomColorTheme {
                        Button("삭제…", role: .destructive) { showsDelete = true }
                    }
                }
            }
        }
        // Identical custom colors must not hide the controls needed to recover.
        .environment(\.settingsAppearancePalette, SettingsAppearancePalette())
        .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
        .tint(UMCColor.Semantic.textBrandDefault)
        .alert("테마 복제", isPresented: $showsDuplicate) {
            TextField("테마 이름", text: $themeName)
            Button("취소", role: .cancel) {}
            Button("저장") {
                preferences.duplicateColorTheme(name: themeName,
                    light: theme.colors(for: .light), dark: theme.colors(for: .dark))
            }
            .disabled(themeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("라이트·다크 색상을 함께 저장해요. 이름은 40자까지 사용할 수 있어요.")
        }
        .confirmationDialog("‘\(theme.name)’ 테마를 삭제할까요?", isPresented: $showsDelete) {
            Button("테마 삭제", role: .destructive) { preferences.deleteSelectedColorTheme() }
        } message: {
            Text("삭제하면 UMC 테마로 돌아가요.")
        }
    }

    private var themePicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                presetSection("프리셋", themes: SettingsColorTheme.presets)
                if !preferences.customColorThemes.isEmpty {
                    Divider()
                    presetSection("사용자 테마", themes: preferences.customColorThemes)
                }
            }
            .padding(UMCSpacing.value20)
        }
        .frame(width: 380, height: 360)
    }

    private func presetSection(_ title: String, themes: [SettingsColorTheme]) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(title).umcTypography(.headlineBold).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(themes) { item in
                    Button {
                        preferences.selectedColorThemeID = item.id
                        showsThemes = false
                    } label: {
                        VStack(spacing: UMCSpacing.value8) {
                            SettingsThemeSwatch(colors: item.colors(for: colorScheme))
                                .frame(height: 60)
                                .overlay {
                                    RoundedRectangle(cornerRadius: UMCRadius.value8)
                                        .strokeBorder(theme.id == item.id ?
                                            UMCColor.Semantic.borderPrimaryStrong500 : .clear,
                                            lineWidth: 3)
                                }
                            Text(item.name).umcTypography(.bodyRegular).lineLimit(2)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.name)
                    .accessibilityAddTraits(theme.id == item.id ? .isSelected : [])
                }
            }
        }
    }

    private func colorRow(
        _ title: String, background: WritableKeyPath<SettingsThemeColors, SettingsThemeColor>,
        foreground: WritableKeyPath<SettingsThemeColors, SettingsThemeColor>
    ) -> some View {
        SettingsRow(title: title, description: "") {
            HStack(spacing: UMCSpacing.value16) {
                ColorPicker("배경", selection: colorBinding(background), supportsOpacity: false)
                    .accessibilityLabel("\(title) 배경색")
                ColorPicker("글자", selection: colorBinding(foreground), supportsOpacity: false)
                    .accessibilityLabel("\(title) 글자색")
            }
            .fixedSize()
        }
    }

    private func colorBinding(
        _ keyPath: WritableKeyPath<SettingsThemeColors, SettingsThemeColor>
    ) -> Binding<Color> {
        Binding(get: { colors[keyPath: keyPath].color }, set: { color in
            var updated = colors
            updated[keyPath: keyPath] = SettingsThemeColor(color, scheme: colorScheme)
            save(updated)
        })
    }

    private func improveContrast() {
        var updated = colors
        if updated.sidebar.contrast < 4.5 {
            updated.sidebar.foreground = updated.sidebar.readableForeground
        }
        if updated.content.contrast < 4.5 {
            updated.content.foreground = updated.content.readableForeground
        }
        save(updated)
    }

    private func save(_ colors: SettingsThemeColors) {
        preferences.updateColorTheme(
            light: colorScheme == .light ? colors : theme.colors(for: .light),
            dark: colorScheme == .dark ? colors : theme.colors(for: .dark))
    }
}

private struct SettingsThemeSwatch: View {
    let colors: SettingsThemeColors

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Capsule().fill(colors.sidebar.foreground.color).frame(height: 3)
                Capsule().fill(colors.sidebar.foreground.color.opacity(0.5)).frame(height: 3)
                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: 32, maxHeight: .infinity)
            .background(colors.sidebar.background.color)
            VStack(alignment: .leading, spacing: 5) {
                Capsule().fill(colors.content.foreground.color).frame(height: 4)
                Capsule().fill(colors.content.foreground.color.opacity(0.5)).frame(height: 3)
                Capsule().fill(colors.content.foreground.color.opacity(0.3)).frame(height: 3)
                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.content.background.color)
        }
        .clipShape(.rect(cornerRadius: UMCRadius.value8))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value8)
                .strokeBorder(.gray.opacity(0.3), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
