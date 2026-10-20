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
        model.editLinks()
        model.linkDraft.github = "https://github.com/edited"
        model.dismissDialog()
        model.editLinks()
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
        await model.retryRegisteredProfile()
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
    func status() async -> SettingsSystemStatus { .init() }
    func setLaunchAtLogin(_ enabled: Bool) async throws {}
    func requestNotificationAuthorization() async throws {}
    func openSystemSettings(_ destination: SettingsSystemDestination) -> Bool { true }
    func cacheSize() async throws -> Int64 { 0 }
    func clearCache() async throws {}
    func latestRelease() async throws -> SettingsRelease? {
        if releaseFails { throw TestSettingsFailure.unavailable }
        return releaseValue
    }
    func clearAccountNotifications() async { didClearNotifications = true }
}
