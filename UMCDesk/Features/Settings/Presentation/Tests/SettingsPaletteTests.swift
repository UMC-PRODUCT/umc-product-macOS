//
//  SettingsPaletteTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/24/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI
import Testing
@testable import SettingsPresentation

@MainActor
struct SettingsPaletteTests {
    @Test("Preset sidebar, content, cards and controls retain separate surfaces",
        arguments: [ColorScheme.light, .dark])
    func presetSurfaces(scheme: ColorScheme) {
        for theme in SettingsColorTheme.presets where theme.id != "umc" {
            let colors = theme.colors(for: scheme)
            let sidebar = SettingsAppearancePalette(colors: colors.sidebar)
            let content = SettingsAppearancePalette(colors: colors.content)
            #expect(resolved(sidebar.backgroundDefault, scheme) ==
                resolved(colors.sidebar.background.color, scheme))
            #expect(resolved(content.backgroundDefault, scheme) ==
                resolved(colors.content.background.color, scheme))
            #expect(resolved(sidebar.backgroundDefault, scheme) !=
                resolved(content.backgroundDefault, scheme))
            #expect(resolved(content.backgroundSurfaceWhite, scheme) !=
                resolved(content.backgroundDefault, scheme))
            #expect(resolved(content.backgroundSurfaceGreyWeaker, scheme) !=
                resolved(content.backgroundSurfaceWhite, scheme))
        }
    }

    @Test("Custom surface derivation never replaces the user's selected background or text")
    func customColorsStayExact() {
        let colors = SettingsThemePalette(background: .init(hex: 0x304050),
            foreground: .init(hex: 0xF0F4F8))
        let palette = SettingsAppearancePalette(colors: colors)
        #expect(resolved(palette.backgroundDefault, .dark) ==
            resolved(colors.background.color, .dark))
        #expect(resolved(palette.textNeutralStrong800, .dark) ==
            resolved(colors.foreground.color, .dark))
        #expect(resolved(palette.backgroundSurfaceWhite, .dark) != colors.background)
    }

    @Test("UMC surfaces continue resolving the design-system tokens",
        arguments: [ColorScheme.light, .dark])
    func standardTheme(scheme: ColorScheme) {
        let palette = SettingsAppearancePalette()
        #expect(resolved(palette.backgroundDefault, scheme) ==
            resolved(UMCColor.Custom.backgroundDefault, scheme))
        #expect(resolved(palette.backgroundSurfaceWhite, scheme) ==
            resolved(UMCColor.Custom.backgroundSurfaceWhite, scheme))
    }

    @Test("Derived surfaces preserve readable custom text near the contrast threshold")
    func maintainsContrast() {
        let colors = SettingsThemePalette(background: .init(hex: 0x000000),
            foreground: .init(hex: 0x757575))
        let palette = SettingsAppearancePalette(colors: colors)
        #expect(colors.contrast >= 4.5)
        for surface in [palette.backgroundSurfaceWhite, palette.backgroundSurfaceGreyWeaker] {
            #expect(resolved(surface, .dark).contrast(with: colors.foreground) >= 4.5)
        }
    }

    private func resolved(_ color: Color, _ scheme: ColorScheme) -> SettingsThemeColor {
        SettingsThemeColor(color, scheme: scheme)
    }
}
