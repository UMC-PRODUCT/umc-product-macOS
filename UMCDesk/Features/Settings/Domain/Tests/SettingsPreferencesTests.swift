//
//  SettingsPreferencesTests.swift
//  SettingsDomainTests
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Testing
@testable import SettingsDomain

@Suite("Local settings")
@MainActor
struct SettingsPreferencesTests {
    @Test("Defaults are restored after rebuilding preferences")
    func persistsPreferences() throws {
        let name = "settings.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = SettingsPreferences(defaults: defaults)
        #expect(preferences.theme == .system)
        #expect(preferences.showsMenuBar)
        #expect(!preferences.showsNotificationContent)
        preferences.theme = .dark
        preferences.bodyTextSize = .extraLarge
        preferences.launchPage = .myPage
        preferences.showsMenuBar = false
        preferences.noticeNotifications = false
        preferences.showsNotificationContent = true
        let restored = SettingsPreferences(defaults: defaults)
        #expect(restored.theme == .dark)
        #expect(restored.bodyTextSize.scale == 1.3)
        #expect(restored.launchPage == .myPage)
        #expect(!restored.showsMenuBar)
        #expect(!restored.noticeNotifications)
        #expect(restored.showsNotificationContent)
        defaults.set("invalid", forKey: "settings.theme")
        #expect(SettingsPreferences(defaults: defaults).theme == .system)
    }
}
