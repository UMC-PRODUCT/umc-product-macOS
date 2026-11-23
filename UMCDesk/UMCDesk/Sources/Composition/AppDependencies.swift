//
//  AppDependencies.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import CoreRouting
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
    let loginRepository: LiveEmailLoginRepository
    let container: DIContainer
    let userSession: UserSessionManager
    let settingsPreferences: SettingsPreferences
    let settingsViewModel: SettingsViewModel
    let windowSettingsViewModel: SettingsViewModel
    let navigation: AppNavigation
    let environment: NetworkEnvironment
    private let client: NetworkClient
    private let arguments: [String]
    private var restoration: Task<Void, Never>?
    private var hasRestored = false
    #if DEBUG || UMC_PRERELEASE
    let previewSettingsViewModel: SettingsViewModel
    #endif

    var isSettingsPreview: Bool {
        #if DEBUG
        arguments.contains("--settings-preview")
        #else
        false
        #endif
    }

    init(arguments: [String] = ProcessInfo.processInfo.arguments, session: URLSession = .shared) {
        self.arguments = arguments
        let container = DIContainer()
        let userSession = UserSessionManager()
        let tokenStore: any TokenStore
        #if DEBUG
        let fixturePort = Self.fixturePort(arguments: arguments)
        let previewArguments = ["--settings-preview", "--auth-preview", "--matching-preview"]
        let isIsolated = fixturePort != nil || previewArguments.contains {
            arguments.contains($0)
        }
        tokenStore = isIsolated ? FixtureTokenStore() : KeychainTokenStore()
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
            session: session,
            sessionResetter: SessionResetHandler {
                userSession.reset()
                container.resetCache()
                await resetRelay.reset()
            }
        )
        self.environment = environment
        self.client = client
        let adapter = MoyaNetworkAdapter(networkClient: client)
        self.loginRepository = LiveEmailLoginRepository(
            client: client, adapter: adapter, environment: environment
        )
        self.container = container
        self.userSession = userSession
        #if DEBUG
        let preferences = Self.makeSettingsPreferences(
            arguments: arguments
        )
        #else
        let preferences = SettingsPreferences()
        #endif
        AppLocalization.shared.language = preferences.language
        preferences.restoreSupportedFont()
        let useCase = DefaultSettingsUseCase(repository: LiveSettingsRepository(
            adapter: adapter, client: client, environment: environment
        ))
        #if DEBUG
        let systemActions: any SettingsSystemActions = isIsolated
            ? SettingsDesignPreview.isolatedSystemActions() : MacSettingsSystemActions()
        #else
        let systemActions = MacSettingsSystemActions()
        #endif
        let liveSettings = SettingsViewModel(
            useCase: useCase, preferences: preferences, systemActions: systemActions
        )
        self.settingsPreferences = preferences
        self.navigation = AppNavigation(launchPage: preferences.launchPage)
        #if DEBUG
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
        try await refreshAccount()
    }

    func refreshAccount() async throws {
        let accountClient = try await client.boundToCurrentAccount()
        // Token storage has committed. Closing the login window must let account setup finish.
        try await Task { @MainActor in
            try await completeAccountSetup(using: accountClient)
        }.value
    }

    private func completeAccountSetup(using accountClient: NetworkClient) async throws {
        _ = try await accountClient.currentAccessToken()
        await settingsViewModel.refreshSignedInAccount()
        _ = try await accountClient.currentAccessToken()
        await windowSettingsViewModel.refreshSignedInAccount()
        _ = try await accountClient.currentAccessToken()
        guard let id = settingsViewModel.profile?.id, windowSettingsViewModel.profile?.id == id else {
            hasRestored = false
            throw NetworkError.invalidResponse
        }
        navigation.account = FeatureAccount(memberID: id, boundClient: accountClient, environment: environment)
        navigation.section = navigation.pendingSection
        navigation.pendingSection = nil
        hasRestored = true
        settingsViewModel.showProfile()
        navigation.showsSettings = true
    }

    func restoreSession() async {
        if let restoration {
            await restoration.value
            return
        }
        guard !hasRestored else { return }
        let task = Task { @MainActor in
            defer { restoration = nil }
            #if DEBUG || UMC_PRERELEASE
            if arguments.contains("--auth-preview") {
                navigation.showsSettings = false
                hasRestored = true
                return
            }
            #endif
            guard !isSettingsPreview, await client.isLoggedIn() else {
                hasRestored = true
                return
            }
            guard let accountClient = try? await client.boundToCurrentAccount() else { return }
            await settingsViewModel.refreshProfile(showsToast: false)
            if settingsViewModel.profile == nil, await client.isLoggedIn() {
                try? await Task.sleep(for: .milliseconds(500))
                await settingsViewModel.refreshProfile(showsToast: false)
            }
            guard let id = settingsViewModel.profile?.id else { return }
            await windowSettingsViewModel.refreshProfile(showsToast: false)
            guard windowSettingsViewModel.profile?.id == id,
                  (try? await accountClient.currentAccessToken()) != nil else { return }
            navigation.account = FeatureAccount(memberID: id, boundClient: accountClient, environment: environment)
            navigation.section = navigation.pendingSection
            navigation.pendingSection = nil
            hasRestored = true
            if settingsPreferences.launchPage != .settings { settingsViewModel.showProfile() }
            navigation.showsSettings = true
        }
        restoration = task
        await task.value
    }

    func selectSection(_ section: DeskSection?) {
        guard section == nil || navigation.account != nil else {
            navigation.pendingSection = section
            navigation.showsSettings = false
            return
        }
        navigation.section = section
        navigation.showsSettings = true
    }

    func signOut() async throws { try await client.logout() }

    var featureDefaults: UserDefaults {
        #if DEBUG
        if let port = Self.fixturePort(arguments: arguments) {
            return UserDefaults(suiteName: "com.umc.product.macos.local-api.\(port)")!
        }
        #endif
        return .standard
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
        let initialTheme = arguments.firstIndex(of: "--settings-theme").flatMap { index in
            arguments.indices.contains(index + 1) ? SettingsTheme(rawValue: arguments[index + 1]) : nil
        }
        if let port = fixturePort(arguments: arguments) {
            let name = "com.umc.product.macos.local-api.\(port)"
            return SettingsPreferences(defaults: UserDefaults(suiteName: name)!, initialTheme: initialTheme)
        }
        let suite: String
        if arguments.contains("--auth-preview") || arguments.contains("--matching-preview") {
            suite = "com.umc.product.macos.isolated-design-preview"
        } else if arguments.contains("--settings-preview") {
            suite = "com.umc.product.macos.settings-preview"
        } else {
            return SettingsPreferences()
        }
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return SettingsPreferences(defaults: defaults, initialTheme: initialTheme)
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
