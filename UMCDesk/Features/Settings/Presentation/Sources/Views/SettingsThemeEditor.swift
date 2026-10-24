//
//  SettingsThemeEditor.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/24/26.
//

import UMCFoundation
import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsThemeEditor: View {
    @Bindable var preferences: SettingsPreferences
    @Environment(\.settingsThemeMode) private var colorScheme
    @Environment(\.settingsAppearancePalette) private var palette
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
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            SettingsRow(title: AppLocalization.string("테마"), description: "") {
                Button { showsThemes = true } label: {
                    SettingsSelectionField {
                        selectionSwatch
                        Text(theme.name).lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .controlSize(.regular)
                .popover(isPresented: $showsThemes) {
                    themePicker
                }
                .accessibilityLabel(AppLocalization.string("테마 선택, \(theme.name)"))
            }
            SettingsDivider()
            DisclosureGroup {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                        Text(
                            colorScheme == .dark
                                ? AppLocalization.string("다크 모드 색상")
                                : AppLocalization.string("라이트 모드 색상")
                        )
                            .umcTypography(.headlineBold)
                        Text(AppLocalization.string("다른 모드의 색상은 유지돼요"))
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(palette.textNeutralMedium600)
                    }
                    Grid(horizontalSpacing: UMCSpacing.value16,
                        verticalSpacing: UMCSpacing.value12) {
                        GridRow {
                            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            Text(AppLocalization.string("배경")).frame(width: 126)
                            Text(AppLocalization.string("글자")).frame(width: 126)
                        }
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(palette.textNeutralMedium600)
                        .accessibilityHidden(true)
                        colorRow(AppLocalization.string("사이드바"), background: \.sidebar.background,
                            foreground: \.sidebar.foreground)
                        SettingsDivider().gridCellColumns(3)
                        colorRow(AppLocalization.string("콘텐츠"), background: \.content.background,
                            foreground: \.content.foreground)
                    }
                    HStack {
                        Text(
                            preferences.isCustomColorTheme
                                ? AppLocalization.string("변경 사항을 자동으로 저장해요.")
                                :
                            AppLocalization.string("색상을 바꾸면 사용자 테마로 자동 저장해요."))
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(palette.textNeutralMedium600)
                        Spacer(minLength: UMCSpacing.value8)
                        Button(AppLocalization.string("복제하여 저장…")) {
                            themeName = String(
                                (AppLocalization.string("\(theme.name) 복사본")).prefix(40))
                            showsDuplicate = true
                        }
                        if preferences.isCustomColorTheme {
                            Button(AppLocalization.string("삭제…"), role: .destructive) {
                                showsDelete = true
                            }
                        }
                    }
                }
                .padding(.top, UMCSpacing.value12)
            } label: {
                Text(AppLocalization.string("색상 세부 조정"))
                    .umcTypography(.headlineRegular)
            }
            .disclosureGroupStyle(SettingsColorDisclosureStyle())
            if hasLowContrast {
                HStack(alignment: .top, spacing: UMCSpacing.value8) {
                    Label(
                        AppLocalization.string("글자와 배경의 대비가 낮아요."),
                        systemImage: "exclamationmark.triangle"
                    )
                        .umcTypography(.bodyRegular)
                    Spacer()
                    Button(AppLocalization.string("읽기 쉬운 글자색 적용")) { improveContrast() }
                }
                .foregroundStyle(palette.textNeutralStrong800)
            }
        }
        .foregroundStyle(palette.textNeutralStrong800)
        .tint(palette.textBrandDefault)
        .alert(AppLocalization.string("테마 복제"), isPresented: $showsDuplicate) {
            TextField(AppLocalization.string("테마 이름"), text: $themeName)
            Button(AppLocalization.string("취소"), role: .cancel) {}
            Button(AppLocalization.string("저장")) {
                preferences.duplicateColorTheme(name: themeName,
                    light: theme.colors(for: .light), dark: theme.colors(for: .dark))
            }
            .disabled(themeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text(AppLocalization.string("라이트·다크 색상을 함께 저장해요. 이름은 40자까지 사용할 수 있어요."))
        }
        .confirmationDialog(
            AppLocalization.string("‘\(theme.name)’ 테마를 삭제할까요?"), isPresented: $showsDelete
        ) {
            Button(AppLocalization.string("테마 삭제"), role: .destructive) {
                preferences.deleteSelectedColorTheme()
            }
        } message: {
            Text(AppLocalization.string("삭제하면 UMC 테마로 돌아가요."))
        }
    }

    private var selectionSwatch: some View {
        HStack(spacing: 0) {
            colors.sidebar.background.color
                .overlay {
                    Capsule().fill(colors.sidebar.foreground.color).frame(width: 6, height: 2)
                }
            colors.content.background.color
                .overlay {
                    Capsule().fill(colors.content.foreground.color).frame(width: 6, height: 2)
                }
        }
        .frame(width: 28, height: 20)
        .clipShape(.rect(cornerRadius: UMCRadius.value4))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value4)
                .strokeBorder(palette.borderNeutralWeak200, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var themePicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                presetSection(AppLocalization.string("프리셋"), themes: SettingsColorTheme.presets)
                if !preferences.customColorThemes.isEmpty {
                    Divider()
                    presetSection(
                        AppLocalization.string("사용자 테마"), themes: preferences.customColorThemes)
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
        GridRow {
            Text(title)
                .umcTypography(.headlineRegular)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            ColorPicker(
                AppLocalization.string("\(title) 배경색"), selection: colorBinding(background),
                supportsOpacity: false)
                .labelsHidden()
                .frame(width: 126)
            ColorPicker(
                AppLocalization.string("\(title) 글자색"), selection: colorBinding(foreground),
                supportsOpacity: false)
                .labelsHidden()
                .frame(width: 126)
        }
        .controlSize(.large)
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

/// A full-width native disclosure action with the standard expanded-state semantics.
private struct SettingsColorDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                configuration.isExpanded.toggle()
            } label: {
                HStack(spacing: UMCSpacing.value8) {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 12)
                    configuration.label
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(SettingsPlainButtonStyle())
            .accessibilityRepresentation {
                DisclosureGroup(isExpanded: configuration.$isExpanded) {
                    EmptyView()
                } label: {
                    configuration.label
                }
                .disclosureGroupStyle(.automatic)
            }
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
