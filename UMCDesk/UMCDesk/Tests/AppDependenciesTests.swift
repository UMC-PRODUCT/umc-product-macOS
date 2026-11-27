//
//  AppDependenciesTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import MatchingDomain
import Synchronization
import Testing
import SettingsDomain
@testable import SettingsPresentation
import CoreNetwork
@testable import UMCDesk

@Suite("App-wide dependency lifetime")
@MainActor
struct AppDependenciesTests {
    #if DEBUG
    @Test("미리보기 재진입과 종료는 로그아웃 경로와 로그인한 계정의 토큰·현재 탭을 보존한다")
    func dataPreviewRestoresOriginalAccount() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LogoutLifecycleProtocol.self]
        let transport = URLSession(configuration: config)
        defer { transport.invalidateAndCancel() }
        let app = AppDependencies(arguments: ["--local-api-port", "19620"], session: transport)
        let client = app.container.resolve(NetworkClient.self)
        let tokens = app.container.resolve(TokenStore.self)
        let preview = DataPreviewMode()
        app.selectSection(.projects)
        preview.select(.feature(.threads))
        preview.end()
        #expect(preview.session == nil)
        #expect(app.navigation.pendingSection == .projects)
        #expect(app.navigation.account == nil)
        #expect(await tokens.getAccessToken() == nil)

        try await client.signIn { TokenPair(accessToken: "second", refreshToken: "second-refresh") }
        try await app.refreshAccount()
        app.selectSection(.activity)
        preview.select(.settings)
        let workspace = try #require(preview.session)
        for destination in DataPreviewDestination.all { preview.select(destination) }
        let isolated = workspace.settings.preferences
        let theme = app.settingsPreferences.theme
        isolated.theme = theme == .dark ? .light : .dark
        #expect(app.settingsPreferences.theme == theme)
        #expect(workspace.account.memberID != app.navigation.account?.memberID)
        await workspace.settings.logout()
        #expect(preview.session == nil)
        #expect(app.navigation.account?.memberID == "202")
        #expect(app.navigation.section == .activity)
        #expect(await tokens.getAccessToken() == "second")
        #expect(await tokens.getRefreshToken() == "second-refresh")
        preview.select(.profile)
        #expect(preview.session !== workspace)
        preview.end()
    }

    @Test("로그인 대기 중 탭을 바꾸면 마지막으로 선택한 목적지만 남는다")
    func latestTabReplacesPendingDestination() {
        let navigation = AppNavigation(launchPage: .login)
        navigation.authEntry = .withdrawal
        navigation.openMatching(.applications, memberId: nil)
        #expect(navigation.authEntry == .login)

        navigation.selectFeature(.activity)
        #expect(navigation.pendingMatching == nil)
        #expect(navigation.pendingSection == .activity)
        #expect(!navigation.showsSettings)

        navigation.openMatching(.explore, memberId: nil)
        #expect(navigation.pendingSection == nil)
        #expect(navigation.pendingMatching == .explore)

        navigation.selectFeature(nil)
        #expect(navigation.pendingMatching == nil)
        #expect(navigation.pendingSection == nil)
        #expect(navigation.showsSettings)
    }

    @Test("로그인 창이 토큰 저장 후 닫혀도 두 프로필을 확인한 뒤 보호 화면으로 복귀한다")
    func loginCompletionSurvivesCallerCancellation() async throws {
        let barrier = ProfileResponseBarrier()
        AccountCompletionProtocol.barrier.withLock { $0 = barrier }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AccountCompletionProtocol.self]
        let session = URLSession(configuration: config)
        defer {
            barrier.release.signal()
            session.invalidateAndCancel()
            AccountCompletionProtocol.barrier.withLock { $0 = nil }
        }
        let dependencies = AppDependencies(
            arguments: ["--local-api-port", "19451"], session: session
        )
        let store = dependencies.container.resolve(TokenStore.self)
        dependencies.selectSection(.projects)
        let caller = Task {
            defer { barrier.arrival.continuation.finish() }
            try await dependencies.login(email: "member@example.test", password: "fixture-only")
        }

        var requests = barrier.arrival.stream.makeAsyncIterator()
        _ = try #require(await requests.next())
        #expect(await store.getAccessToken() == "fixture-access")
        #expect(await store.getRefreshToken() == "fixture-refresh")
        #expect(dependencies.settingsViewModel.profile == nil)
        #expect(dependencies.windowSettingsViewModel.profile == nil)
        #expect(dependencies.navigation.account == nil)
        #expect(dependencies.navigation.pendingSection == .projects)
        #expect(!dependencies.navigation.showsSettings)

        caller.cancel()
        barrier.release.signal()
        try await caller.value

        let account = try #require(dependencies.navigation.account)
        #expect(account.memberID == "101")
        #expect(dependencies.settingsViewModel.profile?.id == account.memberID)
        #expect(dependencies.windowSettingsViewModel.profile?.id == account.memberID)
        #expect(dependencies.navigation.pendingSection == nil)
        #expect(dependencies.navigation.section == .projects)
        #expect(dependencies.navigation.showsSettings)
        #expect(try await account.client.currentAccessToken() == "fixture-access")
        #expect(await store.getRefreshToken() == "fixture-refresh")
        #expect(barrier.profileCount.withLock { $0 } == 2)
    }

    @Test func matchingRestorationPreservesTheExplicitEntryIdentifier() {
        let navigation = AppNavigation(launchPage: .login)
        navigation.openMatching(.explore, memberId: "101")
        let first = navigation.matchingNavigationID
        navigation.openMatching(.explore, memberId: "101")
        let second = navigation.matchingNavigationID
        #expect(first != second)
        navigation.openMatching(.applications, memberId: "101", isRestoring: true)
        #expect(navigation.matchingNavigationID == second)
        #expect(navigation.matchingDestination == .applications)
    }

    @Test("두 설정 창의 로그아웃은 갱신 대기 중 이전 계정을 숨기고 늦은 철회 응답에서 새 계정을 보호한다")
    func settingsLogoutHidesBothWindowsBeforeCredentialCleanup() async throws {
        for separateWindow in [false, true] {
            let requests = AsyncStream<PendingLogoutResponse>.makeStream()
            LogoutLifecycleProtocol.pending.withLock { $0 = requests.continuation }
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [LogoutLifecycleProtocol.self]
            let session = URLSession(configuration: config)
            defer {
                requests.continuation.finish()
                LogoutLifecycleProtocol.pending.withLock { $0 = nil }
                session.invalidateAndCancel()
            }
            let dependencies = AppDependencies(
                arguments: ["--local-api-port", "19452"], session: session
            )
            let client = dependencies.container.resolve(NetworkClient.self)
            try await client.signIn { TokenPair(accessToken: "first", refreshToken: "first-r") }
            try await dependencies.refreshAccount()
            dependencies.selectSection(.projects)
            let first = try #require(dependencies.navigation.account)
            #expect(first.memberID == "101")
            dependencies.openMatching(.applications)
            dependencies.matchingProgress.setAccount(first.memberID)
            let refresh = Task { try await client.forceRefreshToken() }
            var arrivals = requests.stream.makeAsyncIterator()
            let renewal = try #require(await arrivals.next())
            try #require(renewal.path == "renew")
            let settings = separateWindow
                ? dependencies.windowSettingsViewModel : dependencies.settingsViewModel
            let logout = Task {
                defer { requests.continuation.finish() }
                await settings.logout()
            }

            // Keep renewal outstanding while the main actor processes logout.
            let deadline = ContinuousClock.now + .seconds(5)
            while dependencies.navigation.account != nil, ContinuousClock.now < deadline {
                await Task.yield()
            }
            #expect(dependencies.navigation.account == nil)
            #expect(dependencies.navigation.section == nil)
            #expect(dependencies.navigation.matchingDestination == nil)
            #expect(!dependencies.matchingProgress.isSignedIn)
            #expect(!dependencies.navigation.showsSettings)
            #expect(dependencies.settingsViewModel.profile == nil)
            #expect(dependencies.windowSettingsViewModel.profile == nil)
            await #expect(throws: CancellationError.self) { _ = try await first.client.currentAccessToken() }
            await #expect(throws: CancellationError.self) {
                try await client.signIn { TokenPair(accessToken: "second", refreshToken: "second-r") }
            }

            renewal.respond(#"{"accessToken":"rotated","refreshToken":"rotated-r"}"#)
            _ = await refresh.result
            let revoke = try #require(await arrivals.next())
            try #require(revoke.path == "logout")
            try await client.signIn { TokenPair(accessToken: "second", refreshToken: "second-r") }
            try await dependencies.refreshAccount()
            dependencies.selectSection(.projects)
            revoke.respond("{}")
            await logout.value
            #expect(dependencies.navigation.account?.memberID == "202")
            #expect(dependencies.navigation.section == .projects)
            #expect(dependencies.settingsViewModel.profile?.id == "202")
            #expect(dependencies.windowSettingsViewModel.profile?.id == "202")
        }
    }

    @Test("A session reset clears the shared Settings account")
    func sessionResetClearsSettingsAccount() async throws {
        let preferences = AppDependencies.makeSettingsPreferences(arguments: ["--settings-preview"])
        let viewModel = try #require(SettingsDesignPreview.makeViewModel(
            id: "757:12600", preferences: preferences
        ))
        #expect(viewModel.profile != nil)
        let relay = AppSessionResetRelay {}
        let navigation = AppNavigation(launchPage: .myPage)
        navigation.openMatching(.applications, memberId: nil)
        #expect(navigation.pendingMatching == .applications)
        #expect(!navigation.showsSettings)
        #expect(navigation.matchingDestination == nil)
        navigation.openMatching(.applications, memberId: viewModel.profile?.id)
        #expect(navigation.matchingDestination == .applications)
        relay.navigation = navigation
        relay.settingsViewModel = viewModel
        relay.logoutWillBegin()
        #expect(viewModel.profile == nil)
        #expect(navigation.matchingDestination == nil)
        #expect(preferences.showsMenuBar)
    }

    @Test("Elapsed publication time and stale responses never reveal a personal decision")
    func progressRequiresFreshPersonalResult() {
        let now = Date()
        let round = MatchingRound(
            id: "7", name: "1차", type: "PLAN_DESIGN", phase: "FIRST", chapterId: "2",
            startsAt: "2020-01-01T00:00:00Z", endsAt: "2020-01-02T00:00:00Z",
            decisionDeadline: "2020-01-03T00:00:00Z", resultPublishAt: "2020-01-04T00:00:00Z"
        )
        func progress(status: String?, unavailable: Bool = false) -> MatchingProgressStage {
            let card = MatchingApplication(
                applicationId: "15", projectId: "9", project: nil, matchingRound: nil, status: status
            )
            return .init(signedIn: true, unavailable: unavailable, lastChecked: now,
                         card: card, round: round, now: now)
        }
        #expect(progress(status: nil).title == "발표 대기")
        #expect(progress(status: nil).next == nil)
        #expect(progress(status: "APPROVED").title == "합격")
        #expect(progress(status: "APPROVED", unavailable: true).title == "연결 확인 중")
    }

    @Test("Published team membership overrides a past rejection even without a stored round")
    func legacyAssignedMember() {
        let assigned = MatchingApplication(
            applicationId: nil, projectId: "9", project: nil, matchingRound: nil, status: "APPROVED"
        )
        let rejected = MatchingApplication(
            applicationId: "15", projectId: "2", project: nil,
            matchingRound: .init(id: "7", type: "PLAN_DESIGN", phase: "THIRD"), status: "REJECTED"
        )
        let round = MatchingRound(
            id: "7", name: "3차", type: "PLAN_DESIGN", phase: "THIRD", chapterId: "2",
            startsAt: "2026-11-01T00:00:00Z", endsAt: "2026-11-02T00:00:00Z",
            decisionDeadline: nil, resultPublishAt: nil
        )
        #expect(MatchingProgressController.currentCard(
            [rejected, assigned], rounds: ["7": round]
        ) == assigned)
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

    @Test("Explicit fixture appearance applies without replacing the saved port preference")
    func fixtureThemeIsTransient() {
        let arguments = ["--local-api-port", "58174", "--settings-preview", "765:15045"]
        let previous = AppDependencies.makeSettingsPreferences(arguments: arguments).theme
        for theme in [SettingsTheme.dark, .light, .system] {
            let preferences = AppDependencies.makeSettingsPreferences(
                arguments: arguments + ["--settings-theme", theme.rawValue]
            )
            #expect(preferences.theme == theme)
            #expect(AppDependencies.makeSettingsPreferences(arguments: arguments).theme == previous)
        }
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

#if DEBUG
private struct PendingLogoutResponse: Sendable {
    let path: String
    let respond: @Sendable (String) -> Void
}

private final class LogoutLifecycleProtocol: URLProtocol, @unchecked Sendable {
    static let pending = Mutex<AsyncStream<PendingLogoutResponse>.Continuation?>(nil)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.lastPathComponent ?? ""
        switch path {
        case "me":
            let token = request.value(forHTTPHeaderField: "Authorization")
            let id = token == "Bearer first" ? "101" : "202"
            respond(result: #"{"id":"\#(id)","name":"테스트","nickname":"회원"}"#)
        case "renew", "logout":
            let request = PendingLogoutResponse(path: path) { result in
                self.respond(result: result)
            }
            let continuation = Self.pending.withLock { $0 }
            continuation?.yield(request)
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
        }
    }

    func respond(result: String) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                            headerFields: ["Content-Type": "application/json"])
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"success":true,"result":\#(result)}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class ProfileResponseBarrier: Sendable {
    let arrival = AsyncStream<Void>.makeStream()
    let release = DispatchSemaphore(value: 0)
    let profileCount = Mutex(0)
}

private final class AccountCompletionProtocol: URLProtocol, @unchecked Sendable {
    static let barrier = Mutex<ProfileResponseBarrier?>(nil)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let barrier = Self.barrier.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let result: String
        switch (request.httpMethod, url.path) {
        case ("POST", "/api/v1/auth/login/email"):
            result = """
                {"memberId":"101","accessToken":"fixture-access","refreshToken":"fixture-refresh"}
                """
        case ("GET", "/api/v1/member/me"):
            let authorization = request.value(forHTTPHeaderField: "Authorization")
            guard authorization == "Bearer fixture-access" else {
                client?.urlProtocol(self, didFailWithError: URLError(.userAuthenticationRequired))
                return
            }
            let first = barrier.profileCount.withLock {
                $0 += 1
                return $0 == 1
            }
            if first {
                barrier.arrival.continuation.yield()
                guard barrier.release.wait(timeout: .now() + 10) == .success else {
                    client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
                    return
                }
            }
            result = #"{"id":"101","name":"합성회원","nickname":"테스트"}"#
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"success":true,"result":\#(result)}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
#endif
