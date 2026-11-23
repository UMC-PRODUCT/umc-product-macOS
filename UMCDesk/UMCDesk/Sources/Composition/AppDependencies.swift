//
//  AppDependencies.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import AuthData
import AuthDomain
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
    let loginRepository: any EmailLoginRepository
    let container: DIContainer
    let userSession: UserSessionManager
    let settingsPreferences: SettingsPreferences
    let settingsViewModel: SettingsViewModel
    let windowSettingsViewModel: SettingsViewModel
    let navigation: AppNavigation
    private let client: NetworkClient
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
        let tokenStore: any TokenStore
        #if DEBUG
        let fixturePort = Self.fixturePort(arguments: ProcessInfo.processInfo.arguments)
        tokenStore = fixturePort == nil ? KeychainTokenStore() : FixtureTokenStore()
        #else
        tokenStore = KeychainTokenStore()
        #endif
        let resetRelay = AppSessionResetRelay()
        let environment: NetworkEnvironment
        do {
            #if DEBUG
            if let fixturePort {
                environment = NetworkEnvironment(baseURL: URL(string: "http://127.0.0.1:\(fixturePort)")!)
            } else {
                environment = NetworkEnvironment(baseURL: try APIConfig.baseURL())
            }
            #else
            environment = NetworkEnvironment(baseURL: try APIConfig.baseURL())
            #endif
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
        self.client = client
        let adapter = MoyaNetworkAdapter(networkClient: client)
        self.loginRepository = LiveEmailLoginRepository(
            client: client, adapter: adapter, environment: environment
        )
        self.container = container
        self.userSession = userSession
        #if DEBUG
        let preferences = Self.makeSettingsPreferences(
            arguments: ProcessInfo.processInfo.arguments
        )
        #else
        let preferences = SettingsPreferences()
        #endif
        AppLocalization.shared.language = preferences.language
        preferences.restoreSupportedFont()
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
        let previewPreferences = SettingsPreferences(
            defaults: previewDefaults, languagePreferences: preferences
        )
        previewPreferences.restoreSupportedFont()
        guard let preview = SettingsDesignPreview.makeViewModel(
            id: "activity_roles", preferences: previewPreferences
        ) else { preconditionFailure("The settings design preview must exist") }
        self.previewSettingsViewModel = preview
        #endif
        #if DEBUG
        let separatePreview = Self.makeSettingsPreview(arguments: arguments, preferences: preferences)
        #else
        let separatePreview: SettingsViewModel? = nil
        #endif
        self.windowSettingsViewModel = separatePreview ?? SettingsViewModel(
            useCase: useCase, preferences: preferences, systemActions: systemActions
        )
        resetRelay.windowSettingsViewModel = windowSettingsViewModel
        resetRelay.navigation = navigation
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

    func login(email: String, password: String) async throws {
        try await loginRepository.login(email: email, password: password)
        await settingsViewModel.refreshProfile(showsToast: false)
        guard await client.isLoggedIn() else { throw NetworkError.unauthorized }
        settingsViewModel.showProfile()
        navigation.showsSettings = true
    }

    func restoreSession() async {
        guard !isSettingsPreview, await client.isLoggedIn() else { return }
        settingsViewModel.showProfile()
        navigation.showsSettings = true
    }

    func restoreSupportedFonts() {
        settingsPreferences.restoreSupportedFont()
        #if DEBUG || UMC_PRERELEASE
        previewSettingsViewModel.preferences.restoreSupportedFont()
        #endif
    }

    #if DEBUG
    static func fixturePort(arguments: [String]) -> UInt16? {
        guard let index = arguments.firstIndex(of: "--local-api-port") else { return nil }
        guard arguments.indices.contains(index + 1), let port = UInt16(arguments[index + 1]),
              port > 0 else { preconditionFailure("Invalid local fixture port") }
        return port
    }

    static func makeSettingsPreview(
        arguments: [String], preferences: SettingsPreferences
    ) -> SettingsViewModel? {
        guard let index = arguments.firstIndex(of: "--settings-preview") else { return nil }
        let requested = arguments.indices.contains(index + 1) ? arguments[index + 1] : ""
            let identifier =
                SettingsDesignPreview.ids.contains(requested) ? requested : "activity_roles"
        guard let preview = SettingsDesignPreview.makeViewModel(
            id: identifier, preferences: preferences
        ) else { preconditionFailure("The default settings preview must exist") }
        return preview
    }

    static func makeSettingsPreferences(arguments: [String]) -> SettingsPreferences {
        if let port = fixturePort(arguments: arguments) {
            let name = "com.umc.product.macos.local-api.\(port)"
            return SettingsPreferences(defaults: UserDefaults(suiteName: name)!)
        }
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


#if DEBUG
private actor FixtureTokenStore: TokenStore {
    private var tokens: TokenPair?
    func getAccessToken() -> String? { tokens?.accessToken }
    func getRefreshToken() -> String? { tokens?.refreshToken }
    func save(accessToken: String, refreshToken: String) {
        tokens = TokenPair(accessToken: accessToken, refreshToken: refreshToken)
    }
    func clear() { tokens = nil }
}
#endif
