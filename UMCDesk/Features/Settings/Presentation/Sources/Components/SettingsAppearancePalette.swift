//
//  SettingsAppearancePalette.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/24/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsAppearancePalette: Equatable {
    var colors: SettingsThemePalette?

    var colorScheme: ColorScheme? {
        guard let colors else { return nil }
        return colors.background.luminance > 0.179 ? .light : .dark
    }

    private var foreground: Color { colors?.foreground.color ?? .primary }
    private var background: Color { colors?.background.color ?? .clear }

    var borderPrimaryStrong500: Color {
        colors == nil ? UMCColor.Semantic.borderPrimaryStrong500 :
            foreground
    }
    var backgroundDefault: Color { colors == nil ? UMCColor.Custom.backgroundDefault : background }
    var backgroundSurfaceWhite: Color {
        colors == nil ? UMCColor.Custom.backgroundSurfaceWhite :
            background
    }
    var backgroundSurfaceGreyWeaker: Color {
        colors == nil ? UMCColor.Custom.backgroundSurfaceGreyWeaker :
            background
    }
    var backgroundSurfaceGreyWeak: Color {
        colors == nil ? UMCColor.Custom.backgroundSurfaceGreyWeak :
            foreground.opacity(0.08)
    }
    var backgroundTagGrey: Color {
        colors == nil ? UMCColor.Custom.backgroundTagGrey :
            foreground.opacity(0.08)
    }
    var fillNeutralMedium100: Color {
        colors == nil ? UMCColor.Semantic.fillNeutralMedium100 :
            foreground.opacity(0.08)
    }
    var fillNeutralWeakerHoverPressed: Color {
        colors == nil ? UMCColor.Semantic.fillNeutralWeakerHoverPressed :
            foreground.opacity(0.08)
    }
    var surfaceNeutralMedium: Color {
        colors == nil ? UMCColor.Semantic.surfaceNeutralMedium :
            foreground.opacity(0.08)
    }
    var backgroundBrandWeak: Color {
        colors == nil ? UMCColor.Semantic.backgroundBrandWeak :
            foreground.opacity(0.08)
    }
    var fillPrimaryWeak75: Color {
        colors == nil ? UMCColor.Semantic.fillPrimaryWeak75 :
            foreground.opacity(0.08)
    }
    var fillPrimaryWeakHoverPressed: Color {
        colors == nil ? UMCColor.Semantic.fillPrimaryWeakHoverPressed :
            foreground.opacity(0.08)
    }
    var borderNeutralMedium300: Color {
        colors == nil ? UMCColor.Semantic.borderNeutralMedium300 :
            foreground.opacity(0.22)
    }
    var borderNeutralWeak200: Color {
        colors == nil ? UMCColor.Semantic.borderNeutralWeak200 :
            foreground.opacity(0.22)
    }
    var textNeutralDefault: Color {
        colors == nil ? UMCColor.Semantic.textNeutralDefault :
            foreground
    }
    var textNeutralStrong800: Color {
        colors == nil ? UMCColor.Semantic.textNeutralStrong800 :
            foreground
    }
    var textNeutralMedium600: Color {
        colors == nil ? UMCColor.Semantic.textNeutralMedium600 :
            foreground
    }
    var textNeutralWeak500: Color {
        colors == nil ? UMCColor.Semantic.textNeutralWeak500 :
            foreground
    }
    var textBrandDefault: Color { colors == nil ? UMCColor.Semantic.textBrandDefault : foreground }
    var iconBrandStrong600: Color {
        colors == nil ? UMCColor.Semantic.iconBrandStrong600 :
            foreground
    }
    var iconNeutralMedium500: Color {
        colors == nil ? UMCColor.Semantic.iconNeutralMedium500 :
            foreground
    }
}

extension EnvironmentValues {
    @Entry var settingsThemeMode: ColorScheme = .light
    @Entry var settingsAppearancePalette = SettingsAppearancePalette()
}

extension SettingsThemeColor {
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    init(_ color: Color, scheme: ColorScheme) {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let resolved = color.resolve(in: environment)
        self.init(red: Double(resolved.red), green: Double(resolved.green),
            blue: Double(resolved.blue))
    }
}

extension SettingsColorTheme {
    func colors(for scheme: ColorScheme) -> SettingsThemeColors {
        if let colors = scheme == .dark ? dark : light { return colors }
        return .init(sidebar: .init(
            background: .init(UMCColor.Custom.backgroundSurfaceGreyWeaker, scheme: scheme),
            foreground: .init(UMCColor.Semantic.textNeutralStrong800, scheme: scheme)),
            content: .init(background: .init(UMCColor.Custom.backgroundDefault, scheme: scheme),
                foreground: .init(UMCColor.Semantic.textNeutralStrong800, scheme: scheme)))
    }
}
