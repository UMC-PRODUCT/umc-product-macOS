//
//  SettingsPreferencesTests.swift
//  SettingsDomainTests
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Testing
import UMCFoundation
@testable import SettingsDomain

@Suite("Local settings")
@MainActor
struct SettingsPreferencesTests {
    @Test("Preview language shares persisted app preferences without sharing appearance")
    func sharesOnlyLanguageWithPreview() throws {
        let appName = "settings.language.app.\(UUID().uuidString)"
        let previewName = "settings.language.preview.\(UUID().uuidString)"
        let appDefaults = try #require(UserDefaults(suiteName: appName))
        let previewDefaults = try #require(UserDefaults(suiteName: previewName))
        let original = AppLocalization.shared.language
        defer {
            appDefaults.removePersistentDomain(forName: appName)
            previewDefaults.removePersistentDomain(forName: previewName)
            AppLocalization.shared.language = original
        }
        let app = SettingsPreferences(defaults: appDefaults)
        let preview = SettingsPreferences(
            defaults: previewDefaults, languagePreferences: app
        )
        preview.language = .english
        preview.theme = .dark
        #expect(app.language == .english)
        #expect(AppLocalization.shared.language == .english)
        #expect(SettingsPreferences(defaults: appDefaults).language == .english)
        #expect(app.theme == .system)
        #expect(preview.theme == .dark)
        #expect(previewDefaults.object(forKey: "settings.language") == nil)
        app.language = .korean
        #expect(preview.language == .korean)
        #expect(SettingsPreferences(defaults: appDefaults).language == .korean)
    }

    @Test("Defaults are restored after rebuilding preferences")
    func persistsPreferences() throws {
        let name = "settings.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = SettingsPreferences(defaults: defaults)
        #expect(preferences.theme == .system)
        #expect(preferences.showsMenuBar)
        #expect(preferences.windowCloseBehavior == .keepRunning)
        #expect(!preferences.showsNotificationContent)
        preferences.theme = .dark
        preferences.selectedColorThemeID = "paper"
        preferences.fontFamily = "Arial"
        preferences.font = .serif
        preferences.bodyTextSize = .extraLarge
        preferences.launchPage = .myPage
        preferences.showsMenuBar = false
        preferences.noticeNotifications = false
        preferences.showsNotificationContent = true
        let restored = SettingsPreferences(defaults: defaults)
        #expect(restored.theme == .dark)
        #expect(restored.selectedColorThemeID == "paper")
        #expect(restored.fontFamily == "Arial")
        #expect(restored.font == .serif)
        #expect(restored.bodyTextSize.scale == 1.3)
        #expect(restored.launchPage == .myPage)
        #expect(!restored.showsMenuBar)
        #expect(!restored.noticeNotifications)
        #expect(restored.showsNotificationContent)
        for key in ["colorThemeID", "font"] {
            defaults.set("invalid", forKey: "settings.\(key)")
        }
        let fallback = SettingsPreferences(defaults: defaults)
        #expect(fallback.selectedColorTheme == .standard)
        #expect(fallback.font == .pretendard)
        defaults.set("invalid", forKey: "settings.theme")
        #expect(SettingsPreferences(defaults: defaults).theme == .system)
    }

    @Test("기존 메뉴 막대 설정을 한 번 이전하면 창 닫기 동작이 독립적으로 유지된다", arguments: [true, false])
    func migratesWindowCloseBehavior(showsMenuBar: Bool) throws {
        let name = "settings.migration.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(showsMenuBar, forKey: "settings.showsMenuBar")
        let expected: SettingsWindowCloseBehavior = showsMenuBar ? .keepRunning : .quit
        let preferences = SettingsPreferences(defaults: defaults)
        #expect(preferences.windowCloseBehavior == expected)
        #expect(defaults.string(forKey: "settings.windowCloseBehavior") == expected.rawValue)
        preferences.showsMenuBar.toggle()
        #expect(preferences.windowCloseBehavior == expected)
        #expect(SettingsPreferences(defaults: defaults).windowCloseBehavior == expected)
        preferences.windowCloseBehavior = expected == .quit ? .keepRunning : .quit
        let restored = SettingsPreferences(defaults: defaults)
        #expect(restored.windowCloseBehavior == preferences.windowCloseBehavior)
        #expect(restored.showsMenuBar == !showsMenuBar)
    }

    @Test("알 수 없는 창 닫기 설정은 기존 메뉴 막대 설정에 맞게 복구된다", arguments: [true, false])
    func invalidWindowCloseBehavior(showsMenuBar: Bool) throws {
        let name = "settings.invalid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(showsMenuBar, forKey: "settings.showsMenuBar")
        defaults.set("invalid", forKey: "settings.windowCloseBehavior")
        let expected: SettingsWindowCloseBehavior = showsMenuBar ? .keepRunning : .quit
        #expect(SettingsPreferences(defaults: defaults).windowCloseBehavior == expected)
        #expect(defaults.string(forKey: "settings.windowCloseBehavior") == expected.rawValue)
    }

    @Test("테마 편집은 내장 프리셋을 보존하고 여러 사용자 테마와 양쪽 모드를 저장한다")
    func customThemesPersistIndependently() throws {
        let suite = "themes.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = SettingsPreferences(defaults: defaults)
        preferences.selectedColorThemeID = "paper"
        let preset = preferences.selectedColorTheme
        var light = try #require(preset.light)
        let dark = try #require(preset.dark)
        light.sidebar.background = .init(hex: 0x123456)
        preferences.updateColorTheme(light: light, dark: dark)
        let editedID = preferences.selectedColorThemeID
        #expect(preferences.isCustomColorTheme)
        #expect(preferences.customColorThemes.count == 1)
        #expect(SettingsColorTheme.presets.first { $0.id == "paper" } == preset)
        #expect(preferences.duplicateColorTheme(name: " 나의 테마 ", light: light, dark: dark))
        #expect(preferences.selectedColorThemeID != editedID)
        #expect(preferences.customColorThemes.count == 2)
        #expect(preferences.selectedColorTheme.name == "나의 테마")
        #expect(!preferences.duplicateColorTheme(name: "  ", light: light, dark: dark))
        let restored = SettingsPreferences(defaults: defaults)
        #expect(restored.customColorThemes == preferences.customColorThemes)
        #expect(restored.selectedColorTheme.light == light)
        #expect(restored.selectedColorTheme.dark == dark)
        restored.deleteSelectedColorTheme()
        #expect(restored.selectedColorTheme == .standard)
        #expect(restored.customColorThemes.map(\.id) == [editedID])
        #expect(SettingsPreferences(defaults: defaults).customColorThemes.count == 1)
        restored.deleteSelectedColorTheme()
        #expect(restored.customColorThemes.count == 1)
        let name = restored.customColorThemes[0].name
        restored.duplicateColorTheme(name: name, light: light, dark: dark)
        #expect(restored.selectedColorTheme.name == name + " (2)")
    }

    @Test("기존 모양 설정은 유지하고 손상된 테마 데이터는 기본값으로 복구한다")
    func legacyAndCorruptThemes() throws {
        let suite = "themes.legacy.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("dark", forKey: "settings.theme")
        defaults.set("large", forKey: "settings.bodyTextSize")
        defaults.set("missing", forKey: "settings.colorThemeID")
        defaults.set(Data("invalid JSON".utf8), forKey: "settings.colorThemes")
        let preferences = SettingsPreferences(defaults: defaults)
        #expect(preferences.theme == .dark)
        #expect(preferences.bodyTextSize == .large)
        #expect(preferences.selectedColorTheme == .standard)
        #expect(preferences.customColorThemes.isEmpty)
    }

    @Test("프리셋의 두 모드는 읽기 가능한 대비를 유지한다")
    func presetContrast() {
        for preset in SettingsColorTheme.presets.dropFirst() {
            for colors in [preset.light, preset.dark].compactMap({ $0 }) {
                #expect(colors.sidebar.contrast >= 4.5)
                #expect(colors.content.contrast >= 4.5)
            }
        }
        let white = SettingsThemeColor(hex: 0xFFFFFF)
        let black = SettingsThemeColor(hex: 0x000000)
        #expect(abs(white.contrast(with: black) - 21) < 0.001)
        let invisible = SettingsThemePalette(background: white, foreground: white)
        #expect(invisible.readableForeground == black)
    }

    @Test("저장된 색상은 범위를 검증하고 유효한 색상은 왕복한다")
    func validatesSavedColors() throws {
        let color = SettingsThemeColor(hex: 0x12ABEF)
        #expect(try JSONDecoder().decode(SettingsThemeColor.self,
            from: JSONEncoder().encode(color)) == color)
        let malformed = Data(#"{"red":2,"green":0,"blue":0}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SettingsThemeColor.self, from: malformed)
        }
    }

}
