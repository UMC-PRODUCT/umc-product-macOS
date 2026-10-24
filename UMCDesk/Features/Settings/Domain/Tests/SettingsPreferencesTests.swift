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
        #expect(preferences.windowCloseBehavior == .keepRunning)
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

}
