//
//  SettingsViewModelTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import SettingsDomain
import Testing
@testable import SettingsPresentation

@MainActor
struct SettingsViewModelTests {
    @Test("Search updates immediately and preserves navigation history and query")
    func liveSearchNavigation() throws {
        let model = makeModel(useCase: ControlledSettingsUseCase())
        model.showSettings()
        #expect(!model.isSearching)
        model.searchText = "다크"
        #expect(model.isSearching)
        let result = try #require(model.searchResults.first)
        #expect(result.title == "테마")
        model.selectSearchResult(result)
        #expect(model.page == .appearance)
        #expect(model.searchText == "다크")
        model.goBack()
        #expect(model.page == .general)
        model.goForward()
        #expect(model.page == .appearance)
        model.searchText = "위치"
        #expect(model.searchResults.map(\.title) == ["위치 접근"])
        model.searchText = "없는 검색 결과"
        #expect(model.isSearching)
        #expect(model.searchResults.isEmpty)
        model.searchText = "  \n"
        #expect(!model.isSearching)
        #expect(model.searchResults.isEmpty)
        model.searchText = ""
        #expect(!model.isSearching)
        #expect(model.page == .appearance)
    }

    @Test("Recent search items record actual selections, deduplicate and keep five newest")
    func recentSearchSelections() throws {
        let model = makeModel(useCase: ControlledSettingsUseCase())
        #expect(model.recentSearchItems.isEmpty)
        let items = Array(SettingsSearchResult.items.prefix(6))
        for item in items { model.selectSearchResult(item) }
        #expect(model.recentSearchItems.map(\.id) == items.suffix(5).reversed().map(\.id))
        let samePage = try #require(SettingsSearchResult.items.first { $0.id == "bodyTextSize" })
        model.selectSearchResult(samePage)
        #expect(model.page == .appearance)
        #expect(model.recentSearchItems.first?.id == samePage.id)
        model.selectSearchResult(items[5])
        #expect(model.recentSearchItems.prefix(2).map(\.id) == [items[5].id, samePage.id])
        #expect(model.recentSearchItems.count == 5)
        #expect(Set(model.recentSearchItems.map(\.id)).count == 5)
        model.searchText = "  \n"
        #expect(!model.isSearching)
        #expect(model.recentSearchItems.count == 5)
        #expect(makeModel(useCase: ControlledSettingsUseCase()).recentSearchItems.isEmpty)
    }

    @Test("Refresh failure preserves the last profile")
    func refreshPreservesProfile() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await model.refreshProfile()
        await useCase.failNextFetch()
        await model.refreshProfile()
        #expect(model.profile?.nickname == "유엠")
        #expect(model.toast?.isError == true)
    }

    @Test("Cancel discards edits, while a failed save preserves the draft")
    func editDraftLifecycle() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await model.refreshProfile()
        model.editLinks(focusing: .blog)
        #expect(model.linkEditorFocus == .blog)
        #expect(model.dialog == .editLinks)
        model.linkDraft.github = "https://github.com/edited"
        model.dismissDialog()
        model.editLinks()
        #expect(model.linkEditorFocus == .github)
        #expect(model.linkDraft.github == "https://github.com/original")
        model.linkDraft.github = "https://github.com/edited"
        await useCase.failNextSave()
        await model.saveLinks()
        #expect(model.dialog == .editLinks)
        #expect(model.linkDraft.github == "https://github.com/edited")
        #expect(model.profile?.links.github == "https://github.com/original")
    }

    @Test("Invalid links show a field error before a request can mutate the profile")
    func invalidLinkStaysInEditor() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await model.refreshProfile()
        model.editLinks()
        model.linkDraft.github = "javascript:alert(1)"
        await model.saveLinks()
        #expect(model.linkErrors[.github] != nil)
        #expect(model.profile?.links.github == "https://github.com/original")
    }

    @Test("A consumed code is not posted again when profile refresh fails")
    func consumedCodeRetriesOnlyFetch() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await model.refreshProfile()
        model.addPermission()
        model.challengerCode = "a7B2c9"
        await useCase.failNextFetch()
        await model.submitChallengerCode()
        #expect(model.codeStep == .registeredNeedsRefresh)
        #expect(model.dialogMessage != nil)
        await useCase.holdNextFetch()
        let pending = Task { await model.retryRegisteredProfile() }
        await useCase.waitForHeldFetch()
        #expect(model.dialogMessage == nil)
        #expect(model.isRegistering)
        model.dismissDialog()
        #expect(model.dialog == .addPermission)
        await model.submitChallengerCode()
        #expect(await useCase.registeredCodes == ["a7B2c9"])
        await useCase.releaseFetch()
        await pending.value
        #expect(!model.isRegistering)
        #expect(model.codeStep == .complete)
        #expect(await useCase.registeredCodes == ["a7B2c9"])
    }

    @Test("A slow profile response cannot restore the account after logout")
    func logoutRejectsLateResponse() async {
        let useCase = ControlledSettingsUseCase()
        let system = TestSettingsSystemActions()
        let model = makeModel(useCase: useCase, system: system)
        await model.refreshProfile()
        await useCase.holdNextFetch()
        let pending = Task { await model.refreshProfile() }
        await useCase.waitForHeldFetch()
        await model.logout()
        await useCase.releaseFetch()
        await pending.value
        #expect(model.profile == nil)
        #expect(model.dialog == nil)
        #expect(system.didClearNotifications)
    }

    @Test("Navigation moves through real history and truncates forward history")
    func navigationHistory() {
        let model = makeModel(useCase: ControlledSettingsUseCase())
        model.navigate(to: .appearance)
        model.navigate(to: .privacy)
        model.goBack()
        #expect(model.page == .appearance)
        model.navigate(to: .about)
        #expect(!model.canGoForward)
        model.goBack()
        #expect(model.page == .appearance)
    }

    @Test("A refresh started before saving cannot overwrite the saved links")
    func savedLinksRejectStaleRefresh() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await model.refreshProfile()
        await useCase.holdNextFetch()
        let pending = Task { await model.refreshProfile() }
        await useCase.waitForHeldFetch()
        model.editLinks()
        model.linkDraft.github = "https://github.com/edited"
        await model.saveLinks()
        await useCase.releaseFetch()
        await pending.value
        #expect(model.profile?.links.github == "https://github.com/edited")
        #expect(!model.isRefreshing)
    }

    @Test("A cancelled initial load can be retried when a settings window reopens")
    func cancelledInitialLoadRetries() async {
        let useCase = ControlledSettingsUseCase()
        let model = makeModel(useCase: useCase)
        await useCase.holdNextFetch()
        let pending = Task { await model.load() }
        await useCase.waitForHeldFetch()
        pending.cancel()
        await useCase.releaseFetch()
        await pending.value
        #expect(model.profile == nil)
        #expect(!model.isRefreshing)
        await model.load()
        #expect(model.profile?.nickname == "유엠")
    }

    @Test("A release query failure stays an error after an earlier successful query")
    func releaseFailureAfterSuccess() async {
        let system = TestSettingsSystemActions()
        system.releaseValue = .init(tag: "0.0.1",
            url: URL(string: "https://github.com/UMC-PRODUCT/umc-product-macOS/releases")!)
        let model = makeModel(useCase: ControlledSettingsUseCase(), system: system)
        await model.checkRelease()
        #expect(!model.releaseFailed)
        system.releaseFails = true
        await model.checkRelease()
        #expect(model.releaseFailed)
        #expect(model.releaseMessage != nil)
        #expect(model.release?.tag == "0.0.1")
    }

    @Test("Authentication failure removes account drafts and pending notifications")
    func authenticationFailureClearsAccount() async {
        let useCase = ControlledSettingsUseCase()
        let system = TestSettingsSystemActions()
        let model = makeModel(useCase: useCase, system: system)
        await model.refreshProfile()
        model.editLinks()
        model.linkDraft.github = "https://github.com/private-draft"
        await useCase.requireAuthentication()
        await model.refreshProfile()
        #expect(model.profile == nil)
        #expect(model.dialog == nil)
        #expect(model.linkDraft.github.isEmpty)
        #expect(model.toast == nil)
        #expect(system.didClearNotifications)
    }

    @Test("브라우저 설정 열기는 대상을 전달하고 열기 실패를 알린다")
    func browserSettingsAction() {
        let system = TestSettingsSystemActions()
        let model = makeModel(useCase: ControlledSettingsUseCase(), system: system)
        model.openSystemSettings(.defaultBrowser)
        #expect(system.openedDestination == .defaultBrowser)
        #expect(model.toast == nil)
        system.canOpenSettings = false
        model.openSystemSettings(.defaultBrowser)
        #expect(model.toast?.isError == true)
    }

    @Test("모양을 복원하면 테마와 본문 크기만 기본값으로 바뀐다")
    func appearanceResetPreservesOtherPreferences() {
        let model = makeModel(useCase: ControlledSettingsUseCase())
        model.preferences.theme = .dark
        model.preferences.bodyTextSize = .extraLarge
        model.preferences.launchPage = .myPage
        model.preferences.windowCloseBehavior = .quit
        model.preferences.showsMenuBar = false
        model.preferences.attendanceNotifications = false
        model.preferences.noticeNotifications = false
        model.preferences.threadNotifications = false
        model.preferences.showsNotificationContent = true
        #expect(!model.isDefaultAppearance)
        model.resetAppearance()
        #expect(model.isDefaultAppearance)
        #expect(model.preferences.launchPage == .myPage)
        #expect(model.preferences.windowCloseBehavior == .quit)
        #expect(!model.preferences.showsMenuBar)
        #expect(!model.preferences.attendanceNotifications)
        #expect(!model.preferences.noticeNotifications)
        #expect(!model.preferences.threadNotifications)
        #expect(model.preferences.showsNotificationContent)
    }

    @Test("캐시 조회 실패는 재시도할 수 있고 빈 캐시는 삭제할 수 없다")
    func cacheFailureRetryAndEmptyState() async {
        let system = TestSettingsSystemActions()
        let model = makeModel(useCase: ControlledSettingsUseCase(), system: system)
        #expect(model.cacheSizeText == "확인 전")
        system.cacheFails = true
        await model.refreshCacheSize()
        #expect(model.cacheSizeText == "확인 실패")
        #expect(!model.canClearCache)
        #expect(!model.isRefreshingCache)
        system.cacheFails = false
        system.cacheValue = 512
        await model.refreshCacheSize()
        #expect(model.cacheBytes == 512)
        #expect(model.canClearCache)
        model.dialog = .clearCache
        await model.clearCache()
        #expect(model.cacheBytes == 0)
        #expect(model.cacheSizeText == "0 KB")
        #expect(model.dialog == nil)
        #expect(!model.canClearCache)
        await model.clearCache()
        #expect(system.clearCalls == 1)
    }

    @Test("캐시 조회와 삭제가 진행 중이면 다른 조회와 삭제를 실행하지 않는다")
    func cacheOperationsDoNotOverlap() async {
        let system = TestSettingsSystemActions()
        system.cacheValue = 512
        let model = makeModel(useCase: ControlledSettingsUseCase(), system: system)
        await model.refreshCacheSize()
        system.holdsCache = true
        let lookup = Task { await model.refreshCacheSize() }
        while system.cacheContinuation == nil { await Task.yield() }
        #expect(model.cacheSizeText == "확인 중")
        #expect(!model.canClearCache)
        await model.refreshCacheSize()
        await model.clearCache()
        #expect(system.cacheCalls == 2)
        #expect(system.clearCalls == 0)
        system.releaseCache()
        await lookup.value
        system.holdsClear = true
        let deletion = Task { await model.clearCache() }
        while system.clearContinuation == nil { await Task.yield() }
        #expect(model.cacheSizeText == "삭제 중")
        await model.refreshCacheSize()
        await model.clearCache()
        #expect(system.cacheCalls == 2)
        #expect(system.clearCalls == 1)
        system.releaseClear()
        await deletion.value
        #expect(model.cacheBytes == 0)
        #expect(!model.isClearingCache)
    }

    @Test("캐시 삭제 실패는 확인창을 유지하고 삭제 후 조회 실패는 재시도할 수 있다")
    func cacheDeletionFailures() async {
        let system = TestSettingsSystemActions()
        system.cacheValue = 512
        let model = makeModel(useCase: ControlledSettingsUseCase(), system: system)
        await model.refreshCacheSize()
        model.dialog = .clearCache
        system.clearFails = true
        await model.clearCache()
        #expect(model.dialog == .clearCache)
        #expect(model.dialogMessage != nil)
        #expect(model.cacheBytes == 512)
        system.clearFails = false
        system.cacheFails = true
        await model.clearCache()
        #expect(model.dialog == nil)
        #expect(model.cacheSizeText == "확인 실패")
        #expect(!model.canClearCache)
        #expect(model.toast?.message.contains("삭제했지만") == true)
        system.cacheFails = false
        await model.refreshCacheSize()
        #expect(model.cacheBytes == 0)
        #expect(!model.cacheLoadFailed)
    }

    private func makeModel(
        useCase: ControlledSettingsUseCase,
        system: TestSettingsSystemActions = .init()
    ) -> SettingsViewModel {
        SettingsViewModel(useCase: useCase,
            preferences: SettingsPreferences(defaults: UserDefaults(suiteName:
                "SettingsPresentationTests.\(UUID().uuidString)")!), systemActions: system)
    }
}

private enum TestSettingsFailure: Error { case unavailable }

private actor ControlledSettingsUseCase: SettingsUseCase {
    private var profile = SettingsProfile(id: "1", name: "김유엠", nickname: "유엠",
        links: SettingsProfileLinks(github: "https://github.com/original"))
    private var fetchFails = false
    private var saveFails = false
    private var holdsFetch = false
    private var requiresAuthentication = false
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var registeredCodes: [String] = []

    func failNextFetch() { fetchFails = true }
    func failNextSave() { saveFails = true }
    func holdNextFetch() { holdsFetch = true }
    func requireAuthentication() { requiresAuthentication = true }

    func waitForHeldFetch() async {
        while continuation == nil { await Task.yield() }
    }

    func releaseFetch() { continuation?.resume(); continuation = nil }

    func fetchProfile() async throws -> SettingsProfile {
        let snapshot = profile
        if holdsFetch {
            holdsFetch = false
            await withCheckedContinuation { continuation = $0 }
        }
        if fetchFails { fetchFails = false; throw TestSettingsFailure.unavailable }
        if requiresAuthentication { throw SettingsError.authenticationRequired }
        return snapshot
    }

    func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile {
        if saveFails { saveFails = false; throw TestSettingsFailure.unavailable }
        profile = SettingsProfile(id: profile.id, name: profile.name, nickname: profile.nickname,
            links: links)
        return profile
    }

    func registerChallenger(code: String) async throws { registeredCodes.append(code) }
    func logout() async throws {}
}

@MainActor
final class TestSettingsSystemActions: SettingsSystemActions {
    var didClearNotifications = false
    var releaseValue: SettingsRelease?
    var releaseFails = false
    var openedDestination: SettingsSystemDestination?
    var canOpenSettings = true
    var cacheValue: Int64 = 0
    var cacheFails = false
    var clearFails = false
    var cacheCalls = 0
    var clearCalls = 0
    var holdsCache = false
    var holdsClear = false
    var cacheContinuation: CheckedContinuation<Void, Never>?
    var clearContinuation: CheckedContinuation<Void, Never>?

    func releaseCache() { cacheContinuation?.resume(); cacheContinuation = nil }
    func releaseClear() { clearContinuation?.resume(); clearContinuation = nil }

    func status() async -> SettingsSystemStatus { .init() }
    func setLaunchAtLogin(_ enabled: Bool) async throws {}
    func requestNotificationAuthorization() async throws {}
    func openSystemSettings(_ destination: SettingsSystemDestination) -> Bool {
        openedDestination = destination
        return canOpenSettings
    }
    func cacheSize() async throws -> Int64 {
        cacheCalls += 1
        if holdsCache {
            holdsCache = false
            await withCheckedContinuation { cacheContinuation = $0 }
        }
        if cacheFails { throw TestSettingsFailure.unavailable }
        return cacheValue
    }
    func clearCache() async throws {
        clearCalls += 1
        if holdsClear {
            holdsClear = false
            await withCheckedContinuation { clearContinuation = $0 }
        }
        if clearFails { throw TestSettingsFailure.unavailable }
        cacheValue = 0
    }
    func latestRelease() async throws -> SettingsRelease? {
        if releaseFails { throw TestSettingsFailure.unavailable }
        return releaseValue
    }
    func clearAccountNotifications() async { didClearNotifications = true }
}
