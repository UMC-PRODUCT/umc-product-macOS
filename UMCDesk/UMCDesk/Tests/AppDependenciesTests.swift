//
//  AppDependenciesTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Testing
import SettingsDomain
@testable import SettingsPresentation
import CoreNetwork
@testable import UMCDesk

@Suite("App-wide dependency lifetime")
@MainActor
struct AppDependenciesTests {
    #if DEBUG
    @Test("A session reset clears the shared Settings account")
    func sessionResetClearsSettingsAccount() async throws {
        let preferences = AppDependencies.makeSettingsPreferences(arguments: ["--settings-preview"])
        let viewModel = try #require(SettingsDesignPreview.makeViewModel(
            id: "757:12600", preferences: preferences
        ))
        #expect(viewModel.profile != nil)
        let relay = AppSessionResetRelay()
        relay.settingsViewModel = viewModel
        await relay.reset()
        #expect(viewModel.profile == nil)
        #expect(preferences.showsMenuBar)
    }

    @Test("Missing or invalid preview arguments show all parts and roles in isolation")
    func invalidPreviewIsIsolated() throws {
        for arguments in [
            ["--settings-preview", "typo"],
            ["--settings-preview", "--settings-theme", "dark"],
            ["--settings-preview"]
        ] {
            let preferences = AppDependencies.makeSettingsPreferences(arguments: arguments)
            let preview = try #require(AppDependencies.makeSettingsPreview(
                arguments: arguments, preferences: preferences
            ))
            #expect(preview.isDesignPreview)
            let profile = try #require(preview.profile)
            #expect(profile.activities.count == 12)
            #expect(Set(profile.activities.map(\.part)).count == 10)
            #expect(Set(profile.activities.flatMap(\.roles)).count == 12)
        }
    }

    @Test("Menu previews isolate account state and restore their sample on re-entry")
    func menuPreviewIsIsolated() async throws {
        let dependencies = AppDependencies()
        let live = dependencies.settingsViewModel
        let preview = dependencies.previewSettingsViewModel
        let livePage = live.page
        let liveProfile = live.profile
        let liveTheme = live.preferences.theme
        let originalTheme = UserDefaults.standard.string(forKey: "settings.theme")
        let sample = try #require(preview.profile)
        #expect(preview !== live)
        #expect(preview.preferences !== dependencies.settingsPreferences)
        #expect(preview.onOpenLogin == nil)
        #expect(preview.onLogout == nil)
        #expect(sample.activities.count == 12)
        #expect(Set(sample.activities.map(\.part)).count == 10)
        preview.preferences.theme = liveTheme == .dark ? .light : .dark
        preview.editLinks()
        #expect(preview.dialog != nil)
        SettingsDesignPreview.prepareViewModel(preview, page: .general)
        #expect(preview.page == .general)
        #expect(preview.dialog == nil)
        SettingsDesignPreview.prepareViewModel(preview, page: .myPage)
        #expect(preview.page == .myPage)
        await preview.logout()
        #expect(preview.profile == nil)
        SettingsDesignPreview.prepareViewModel(preview, page: .myPage)
        #expect(preview.profile == sample)
        #expect(preview.toast == nil)
        SettingsDesignPreview.prepareViewModel(live, page: .myPage)
        #expect(live.page == livePage)
        #expect(live.profile == liveProfile)
        #expect(live.preferences.theme == liveTheme)
        #expect(UserDefaults.standard.string(forKey: "settings.theme") == originalTheme)
    }

    @Test("Settings previews isolate preferences from the real app")
    func previewPreferencesAreIsolated() {
        let originalTheme = UserDefaults.standard.string(forKey: "settings.theme")
        let preferences = AppDependencies.makeSettingsPreferences(arguments: [
            "UMC Desk", "--settings-preview", "807:13303", "--settings-theme", "dark"
        ])
        #expect(preferences.theme == .dark)
        preferences.showsMenuBar = false
        preferences.theme = .light
        let fresh = AppDependencies.makeSettingsPreferences(arguments: ["--settings-preview"])
        #expect(fresh.theme == .system)
        #expect(fresh.showsMenuBar)
        #expect(UserDefaults.standard.string(forKey: "settings.theme") == originalTheme)
    }
    #endif

    @Test("Settings consumers share preferences and view model after session cache reset")
    func settingsStateIsShared() {
        let dependencies = AppDependencies()
        dependencies.container.resetCache()
        #expect(dependencies.settingsPreferences === dependencies.container.resolve(
            SettingsPreferences.self
        ))
        #expect(dependencies.settingsViewModel === dependencies.container.resolve(
            SettingsViewModel.self
        ))
    }

    @Test("마지막 창을 닫을 때 메뉴 막대 표시와 무관하게 창 닫기 설정을 따른다", arguments:
        [true, false], SettingsWindowCloseBehavior.allCases)
    func closingWindowReadsCurrentPreference(
        showsMenuBar: Bool, behavior: SettingsWindowCloseBehavior
    ) throws {
        let name = "settings.lifecycle.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = SettingsPreferences(defaults: defaults)
        let lifecycle = AppLifecycleDelegate()
        lifecycle.preferences = preferences
        preferences.showsMenuBar = showsMenuBar
        preferences.windowCloseBehavior = behavior
        #expect(lifecycle.applicationShouldTerminateAfterLastWindowClosed(.shared) ==
            (behavior == .quit))
        #expect(AppNavigation(launchPage: .login).showsSettings == false)
        #expect(AppNavigation(launchPage: .myPage).showsSettings)
    }

    @Test("Window consumers share transport after session cache reset")
    func sharedTransportSurvivesSessionReset() throws {
        let dependencies = AppDependencies()
        let client = dependencies.container.resolve(NetworkClient.self)
        let store = try #require(
            dependencies.container.resolve(TokenStore.self) as? KeychainTokenStore
        )
        dependencies.container.resetCache()
        #expect(client === dependencies.container.resolve(NetworkClient.self))
        let resolvedStore = try #require(
            dependencies.container.resolve(TokenStore.self) as? KeychainTokenStore
        )
        #expect(store === resolvedStore)
    }
}
