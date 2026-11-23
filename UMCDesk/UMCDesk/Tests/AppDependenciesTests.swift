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

    @Test("A session reset clears the shared Settings account")
    func sessionResetClearsSettingsAccount() async throws {
        let preferences = AppDependencies.makeSettingsPreferences(arguments: ["--settings-preview"])
        let viewModel = try #require(SettingsDesignPreview.makeViewModel(
            id: "757:12600", preferences: preferences
        ))
        #expect(viewModel.profile != nil)
        let relay = AppSessionResetRelay()
        let navigation = AppNavigation(launchPage: .myPage)
        navigation.openMatching(.applications, memberId: nil)
        #expect(navigation.pendingMatching == .applications)
        #expect(!navigation.showsSettings)
        #expect(navigation.matchingDestination == nil)
        navigation.openMatching(.applications, memberId: viewModel.profile?.id)
        #expect(navigation.matchingDestination == .applications)
        relay.navigation = navigation
        relay.settingsViewModel = viewModel
        await relay.reset()
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
