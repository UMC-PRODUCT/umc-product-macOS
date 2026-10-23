//
//  AppDependencies.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import CoreDI
import CoreDomain
import UMCFoundation
import CoreNetwork
import SettingsDomain
import SettingsData
import SettingsPresentation

/// One composition root for every window and app-level scene.
@MainActor
final class AppDependencies {
    let container: DIContainer
    let userSession: UserSessionManager
    let settingsPreferences: SettingsPreferences
    let settingsViewModel: SettingsViewModel
    let navigation: AppNavigation
    #if DEBUG || UMC_PRERELEASE
    let previewSettingsViewModel: SettingsViewModel
    #endif

    var isSettingsPreview: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--settings-preview")
        #else
        false
        #endif
    }

    init() {
        let container = DIContainer()
        let userSession = UserSessionManager()
        let tokenStore = KeychainTokenStore()
        let resetRelay = AppSessionResetRelay()
        let environment: NetworkEnvironment
        do {
            environment = NetworkEnvironment(baseURL: try APIConfig.baseURL())
        } catch {
            preconditionFailure("Missing or invalid app BASE_URL configuration")
        }
        let client = AuthSystemFactory.makeNetworkClient(
            environment: environment,
            tokenStore: tokenStore,
            sessionResetter: SessionResetHandler {
                userSession.reset()
                container.resetCache()
                await resetRelay.reset()
            }
        )
        let adapter = MoyaNetworkAdapter(networkClient: client)
        self.container = container
        self.userSession = userSession
        #if DEBUG
        let preferences = Self.makeSettingsPreferences(
            arguments: ProcessInfo.processInfo.arguments
        )
        #else
        let preferences = SettingsPreferences()
        #endif
        let useCase = DefaultSettingsUseCase(repository: LiveSettingsRepository(
            adapter: adapter, client: client, environment: environment
        ))
        let systemActions = MacSettingsSystemActions()
        let liveSettings = SettingsViewModel(
            useCase: useCase, preferences: preferences, systemActions: systemActions
        )
        self.settingsPreferences = preferences
        self.navigation = AppNavigation(launchPage: preferences.launchPage)
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let preview = Self.makeSettingsPreview(arguments: arguments, preferences: preferences) {
            self.settingsViewModel = preview
            self.navigation.showsSettings = true
        } else {
            self.settingsViewModel = liveSettings
        }
        #else
        self.settingsViewModel = liveSettings
        #endif
        #if DEBUG || UMC_PRERELEASE
        let previewSuite = "com.umc.product.macos.settings-design-preview"
        let previewDefaults = UserDefaults(suiteName: previewSuite)!
        previewDefaults.removePersistentDomain(forName: previewSuite)
        let previewPreferences = SettingsPreferences(defaults: previewDefaults)
        guard let preview = SettingsDesignPreview.makeViewModel(
            id: "activity_roles", preferences: previewPreferences
        ) else { preconditionFailure("The settings design preview must exist") }
        self.previewSettingsViewModel = preview
        #endif
        resetRelay.settingsViewModel = settingsViewModel
        if !isSettingsPreview, preferences.launchPage == .myPage {
            settingsViewModel.showProfile()
        }
        container.registerInstance(TokenStore.self, instance: tokenStore)
        container.registerInstance(NetworkClient.self, instance: client)
        container.registerInstance(MoyaNetworkAdapter.self, instance: adapter)
        container.registerInstance(UserSessionManager.self, instance: userSession)
        container.registerInstance(SettingsPreferences.self, instance: preferences)
        container.registerInstance(SettingsUseCase.self, instance: useCase)
        container.registerInstance(SettingsSystemActions.self, instance: systemActions)
        container.registerInstance(SettingsViewModel.self, instance: settingsViewModel)
    }

    #if DEBUG
    static func makeSettingsPreview(
        arguments: [String], preferences: SettingsPreferences
    ) -> SettingsViewModel? {
        guard let index = arguments.firstIndex(of: "--settings-preview") else { return nil }
        let requested = arguments.indices.contains(index + 1) ? arguments[index + 1] : ""
        let identifier = SettingsDesignPreview.ids.contains(requested) ? requested : "activity_roles"
        guard let preview = SettingsDesignPreview.makeViewModel(
            id: identifier, preferences: preferences
        ) else { preconditionFailure("The default settings preview must exist") }
        return preview
    }

    static func makeSettingsPreferences(arguments: [String]) -> SettingsPreferences {
        guard arguments.contains("--settings-preview") else { return SettingsPreferences() }
        let suite = "com.umc.product.macos.settings-preview"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let preferences = SettingsPreferences(defaults: defaults)
        if let index = arguments.firstIndex(of: "--settings-theme"),
           arguments.indices.contains(index + 1),
           let theme = SettingsTheme(rawValue: arguments[index + 1]) {
            preferences.theme = theme
        }
        return preferences
    }
    #endif
}
