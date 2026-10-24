//
//  SettingsFontSupportTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/24/26.
//

import Foundation
import SettingsDomain
import Testing
import UMCFoundation
@testable import SettingsPresentation

@Suite("Language-aware fonts", .serialized)
@MainActor
struct SettingsFontSupportTests {
    @Test("Emoji and symbol fonts never qualify as interface text fonts",
        arguments: [AppLanguage.korean, .english])
    func rejectsDecorativeFonts(language: AppLanguage) {
        #expect(!SettingsFontSupport.supports("Apple Color Emoji", language: language))
        #expect(!SettingsFontSupport.supports("Apple Symbols", language: language))
        #expect(!SettingsFontSupport.supports("Missing Font Family", language: language))
    }

    @Test("Coverage uses the selected face rather than a fallback font")
    func checksActualCoverage() {
        #expect(SettingsFontSupport.supports("Arial", language: .english))
        #expect(!SettingsFontSupport.supports("Arial", language: .korean))
        #expect(SettingsFontSupport.supports("Apple SD Gothic Neo", language: .korean))
    }

    @Test("Changing to Korean persists a safe fallback for a Latin-only font")
    func restoresFontAfterLanguageChange() throws {
        let suite = "font-language.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let previousLanguage = AppLocalization.shared.language
        defer { AppLocalization.shared.language = previousLanguage }
        let preferences = SettingsPreferences(defaults: defaults)
        preferences.language = .english
        preferences.fontFamily = "Arial"
        #expect(preferences.availableFontFamily == "Arial")
        preferences.language = .korean
        preferences.restoreSupportedFont()
        #expect(preferences.fontFamily == nil)
        #expect(preferences.font == .pretendard)
        let restored = SettingsPreferences(defaults: defaults)
        #expect(restored.language == .korean)
        #expect(restored.fontFamily == nil)
        preferences.language = .english
        #expect(SettingsPreferences(defaults: defaults).language == .english)
    }

    @Test("An incompatible stored font is removed during startup validation")
    func restoresStoredFont() throws {
        let suite = "font-startup.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("Apple Color Emoji", forKey: "settings.fontFamily")
        defaults.set("en", forKey: "settings.language")
        let preferences = SettingsPreferences(defaults: defaults)
        preferences.restoreSupportedFont()
        #expect(preferences.fontFamily == nil)
        #expect(defaults.string(forKey: "settings.fontFamily") == nil)
    }
}
