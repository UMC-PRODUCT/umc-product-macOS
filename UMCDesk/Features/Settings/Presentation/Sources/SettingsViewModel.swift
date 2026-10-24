//
//  SettingsViewModel.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Observation
import SettingsDomain
import UMCFoundation

enum SettingsDialog: String, Identifiable {
    case editLinks, addPermission, logout, clearCache, licenses
    var id: String { rawValue }
}

enum SettingsCodeStep { case entry, registeredNeedsRefresh, complete }

struct SettingsToast: Identifiable {
    let id = UUID()
    let message: String
    var isError = false
}

@MainActor
@Observable
public final class SettingsViewModel {
    // MARK: - Property

    public let useCase: any SettingsUseCase
    public let preferences: SettingsPreferences
    public let systemActions: any SettingsSystemActions
    public var onOpenLogin: (() -> Void)?
    public var onLogout: (() -> Void)?
    public private(set) var page: SettingsPage = .general
    public private(set) var profile: SettingsProfile?
    var profileState: Loadable<SettingsProfile> = .idle
    var searchText = "" { didSet { searchResults = SettingsPage.search(searchText) } }
    private(set) var searchResults: [SettingsSearchResult] = []
    private(set) var recentSearchItems: [SettingsSearchResult] = []
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var dialog: SettingsDialog?
    var dialogMessage: String?
    private(set) var linkEditorFocus: SettingsLinkKind = .github
    var linkDraft = SettingsProfileLinks()
    var linkErrors: [SettingsLinkKind: String] = [:]
    var challengerCode = "" { didSet { if codeStep == .entry { dialogMessage = nil } } }
    var codeStep: SettingsCodeStep = .entry
    var registeredActivities: [SettingsActivity] = []
    var toast: SettingsToast?
    private(set) var isRefreshing = false
    private(set) var isSaving = false
    private(set) var isRegistering = false
    private(set) var isLoggingOut = false
    private(set) var systemStatus = SettingsSystemStatus()
    private(set) var isChangingLoginItem = false
    private(set) var isRequestingNotifications = false
    private(set) var cacheBytes: Int64?
    private(set) var isClearingCache = false
    private(set) var isRefreshingCache = false
    private(set) var cacheLoadFailed = false
    private(set) var isCheckingRelease = false
    private(set) var release: SettingsRelease?
    private(set) var releaseCheckedAt: Date?
    private(set) var releaseMessage: String?
    private(set) var releaseFailed = false
    @ObservationIgnored private var history: [SettingsPage] = [.general]
    private(set) var historyIndex = 0
    @ObservationIgnored private var accountGeneration = 0
    @ObservationIgnored private var hasLoaded = false
    #if DEBUG || UMC_PRERELEASE
    var isDesignPreview = false
    var previewShowsProfileMenu = false
    #else
    var isDesignPreview: Bool { false }
    #endif

    public init(
        useCase: any SettingsUseCase,
        preferences: SettingsPreferences,
        systemActions: any SettingsSystemActions
    ) {
        self.useCase = useCase
        self.preferences = preferences
        self.systemActions = systemActions
    }

    #if DEBUG || UMC_PRERELEASE
    func seedDesignProfile(_ value: SettingsProfile) {
        profile = value
        profileState = .loaded(value)
        hasLoaded = true
        isDesignPreview = true
        systemStatus = .init(loginItem: .disabled, notifications: .authorized,
            location: .authorized)
        cacheBytes = 128_000_000
    }
    #endif

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex + 1 < history.count }
    var isAccountBusy: Bool { isSaving || isRegistering || isLoggingOut }
    var canSubmitCode: Bool {
        challengerCode.trimmingCharacters(in: .whitespacesAndNewlines).count == 6
            && !isRegistering && codeStep == .entry
    }
    var isDefaultAppearance: Bool {
        preferences.theme == .system && preferences.bodyTextSize == .standard
    }
    var canClearCache: Bool {
        (cacheBytes ?? 0) > 0 && !isRefreshingCache && !isClearingCache && !cacheLoadFailed
    }
    var cacheSizeText: String {
        if isRefreshingCache { return "확인 중" }
        if isClearingCache { return "삭제 중" }
        if cacheLoadFailed { return "확인 실패" }
        if cacheBytes == 0 { return "0 KB" }
        return cacheBytes.map {
            ByteCountFormatter.string(fromByteCount: $0, countStyle: .file)
        } ?? "확인 전"
    }

    // MARK: - Function

    public func showProfile() { navigate(to: .myPage) }
    public func showSettings() { navigate(to: .general) }

    public func invalidateAccount() async {
        guard !isLoggingOut else { return }
        clearAccount()
        await systemActions.clearAccountNotifications()
    }

    func selectSearchResult(_ result: SettingsSearchResult) {
        recentSearchItems.removeAll { $0.id == result.id }
        recentSearchItems.insert(result, at: 0)
        recentSearchItems = Array(recentSearchItems.prefix(5))
        navigate(to: result.page)
    }

    public func navigate(to destination: SettingsPage) {
        guard destination != page else { return }
        history = Array(history.prefix(historyIndex + 1))
        history.append(destination)
        historyIndex = history.count - 1
        page = destination
    }

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        page = history[historyIndex]
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        page = history[historyIndex]
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        defer { if Task.isCancelled { hasLoaded = false } }
        await refreshProfile(showsToast: false)
        await refreshSystemStatus()
        await refreshCacheSize()
    }

    func refreshProfile(showsToast: Bool = true) async {
        guard !isRefreshing, !isAccountBusy else { return }
        let generation = accountGeneration
        isRefreshing = true
        profileState = .loading
        defer { if generation == accountGeneration { isRefreshing = false } }
        do {
            let updated = try await useCase.fetchProfile()
            guard generation == accountGeneration else { return }
            guard !Task.isCancelled else {
                if profile == nil { profileState = .failed(CancellationError()) }
                return
            }
            profile = updated
            profileState = .loaded(updated)
            if showsToast { toast = .init(message: "최신 정보로 업데이트했어요.") }
        } catch {
            guard generation == accountGeneration else { return }
            if Task.isCancelled {
                if profile == nil { profileState = .failed(error) }
                return
            }
            if await handleAuthentication(error) { return }
            profileState = .failed(error)
            if showsToast {
                toast = .init(message: "새로고침하지 못했어요. 다시 시도해 주세요.", isError: true)
            }
        }
    }

    func editLinks(focusing kind: SettingsLinkKind = .github) {
        guard let profile, !isAccountBusy else { return }
        linkEditorFocus = kind
        linkDraft = profile.links
        linkErrors = [:]
        dialogMessage = nil
        dialog = .editLinks
    }

    func dismissDialog() {
        guard !isAccountBusy, !isClearingCache else { return }
        dialog = nil
        dialogMessage = nil
        linkDraft = .init()
        linkErrors = [:]
        challengerCode = ""
        registeredActivities = []
        codeStep = .entry
    }

    func saveLinks() async {
        guard profile != nil, !isAccountBusy else { return }
        linkErrors = [:]
        for kind in SettingsLinkKind.allCases {
            let value = linkDraft[kind].trimmingCharacters(in: .whitespacesAndNewlines)
            linkDraft[kind] = value
            if !value.isEmpty, DefaultSettingsUseCase.validatedWebURL(value) == nil {
                linkErrors[kind] = "https:// 또는 http://로 시작하는 링크를 입력해 주세요. "
                    + "로그인 정보가 포함된 주소는 사용할 수 없어요."
            }
        }
        guard linkErrors.isEmpty else { return }
        accountGeneration += 1
        isRefreshing = false
        let generation = accountGeneration
        isSaving = true
        dialogMessage = nil
        defer { if generation == accountGeneration { isSaving = false } }
        do {
            let updated = try await useCase.updateProfileLinks(linkDraft)
            guard generation == accountGeneration, !Task.isCancelled else { return }
            profile = updated
            profileState = .loaded(updated)
            dialog = nil
            linkDraft = .init()
            toast = .init(message: "프로필 링크를 저장했어요.")
        } catch {
            guard generation == accountGeneration, !Task.isCancelled else { return }
            if !(await handleAuthentication(error)) {
                dialogMessage = "저장하지 못했어요. 입력한 내용은 유지되니 다시 시도해 주세요."
            }
        }
    }

    func addPermission() {
        guard profile != nil, !isAccountBusy else { return }
        challengerCode = ""
        codeStep = .entry
        dialogMessage = nil
        registeredActivities = []
        dialog = .addPermission
    }

    func submitChallengerCode() async {
        guard canSubmitCode, profile != nil else { return }
        accountGeneration += 1
        isRefreshing = false
        let generation = accountGeneration
        isRegistering = true
        dialogMessage = nil
        defer { if generation == accountGeneration { isRegistering = false } }
        do {
            let code = challengerCode.trimmingCharacters(in: .whitespacesAndNewlines)
            try await useCase.registerChallenger(code: code)
            guard generation == accountGeneration else { return }
            codeStep = .registeredNeedsRefresh
            guard !Task.isCancelled else {
                dialogMessage = "코드는 등록됐어요. 활동 정보를 불러오지 못했어요. "
                    + "코드를 다시 등록할 필요 없이 다시 불러와 주세요."
                return
            }
            await fetchRegisteredProfile(generation: generation)
        } catch {
            guard generation == accountGeneration, !Task.isCancelled else { return }
            if !(await handleAuthentication(error)) {
                dialogMessage = codeErrorMessage(error)
            }
        }
    }

    func retryRegisteredProfile() async {
        guard codeStep == .registeredNeedsRefresh, !isRegistering else { return }
        dialogMessage = nil
        let generation = accountGeneration
        isRegistering = true
        defer { if generation == accountGeneration { isRegistering = false } }
        await fetchRegisteredProfile(generation: generation)
    }

    func logout() async {
        guard !isLoggingOut else { return }
        accountGeneration += 1
        let generation = accountGeneration
        isLoggingOut = true
        isRefreshing = false
        dialogMessage = nil
        defer { isLoggingOut = false }
        do {
            try await useCase.logout()
            guard generation == accountGeneration else { return }
            await finishLogout()
            toast = .init(message: "로그아웃했어요.")
        } catch SettingsError.serverLogoutFailed {
            guard generation == accountGeneration else { return }
            await finishLogout()
            toast = .init(message: SettingsError.serverLogoutFailed.localizedDescription,
                isError: true)
        } catch {
            guard generation == accountGeneration else { return }
            dialogMessage = "로그아웃하지 못했어요. 다시 시도해 주세요."
        }
    }

    func refreshSystemStatus() async {
        systemStatus = await systemActions.status()
    }

    func setLaunchAtLogin(_ enabled: Bool) async {
        guard !isChangingLoginItem else { return }
        isChangingLoginItem = true
        defer { isChangingLoginItem = false }
        do { try await systemActions.setLaunchAtLogin(enabled) }
        catch { toast = .init(message: "로그인 항목을 변경하지 못했어요.", isError: true) }
        await refreshSystemStatus()
    }

    func requestNotifications() async {
        guard systemStatus.notifications == .notDetermined, !isRequestingNotifications else {
            return
        }
        isRequestingNotifications = true
        defer { isRequestingNotifications = false }
        do { try await systemActions.requestNotificationAuthorization() }
        catch { toast = .init(message: "알림 권한을 요청하지 못했어요.", isError: true) }
        await refreshSystemStatus()
    }

    func openSystemSettings(_ destination: SettingsSystemDestination) {
        if !systemActions.openSystemSettings(destination) {
            toast = .init(message: "시스템 설정을 열지 못했어요.", isError: true)
        }
    }

    func resetAppearance() {
        preferences.theme = .system
        preferences.bodyTextSize = .standard
    }

    func refreshCacheSize() async {
        guard !isRefreshingCache, !isClearingCache else { return }
        isRefreshingCache = true
        cacheLoadFailed = false
        defer { isRefreshingCache = false }
        do { cacheBytes = try await systemActions.cacheSize() }
        catch {
            cacheBytes = nil
            cacheLoadFailed = true
        }
    }

    func clearCache() async {
        guard canClearCache else { return }
        isClearingCache = true
        dialogMessage = nil
        defer { isClearingCache = false }
        do {
            try await systemActions.clearCache()
        } catch {
            dialogMessage = "캐시를 정리하지 못했어요. 다시 시도해 주세요."
            return
        }
        dialog = nil
        do {
            cacheBytes = try await systemActions.cacheSize()
            cacheLoadFailed = false
            toast = .init(message: "임시 캐시를 삭제했어요.")
        } catch {
            cacheBytes = nil
            cacheLoadFailed = true
            toast = .init(message: "캐시를 삭제했지만 용량을 확인하지 못했어요. 다시 확인해 주세요.",
                isError: true)
        }
    }

    func checkRelease() async {
        guard !isCheckingRelease else { return }
        isCheckingRelease = true
        releaseMessage = nil
        releaseFailed = false
        defer { isCheckingRelease = false }
        do {
            release = try await systemActions.latestRelease()
            releaseCheckedAt = .now
            releaseMessage = release == nil ? "아직 게시된 릴리스가 없어요." : nil
        } catch {
            releaseFailed = true
            releaseMessage = "업데이트를 확인하지 못했어요. 다시 시도해 주세요."
        }
    }

    private func fetchRegisteredProfile(generation: Int) async {
        do {
            let updated = try await useCase.fetchProfile()
            guard generation == accountGeneration, !Task.isCancelled else { return }
            let previous = profile?.activities ?? []
            registeredActivities = updated.activities.filter { !previous.contains($0) }
            profile = updated
            profileState = .loaded(updated)
            codeStep = .complete
            challengerCode = ""
            dialogMessage = nil
        } catch {
            guard generation == accountGeneration, !Task.isCancelled else { return }
            if !(await handleAuthentication(error)) {
                dialogMessage = "코드는 등록됐어요. 활동 정보를 불러오지 못했어요. "
                    + "코드를 다시 등록할 필요 없이 다시 불러와 주세요."
            }
        }
    }

    private func handleAuthentication(_ error: any Error) async -> Bool {
        guard error as? SettingsError == .authenticationRequired else { return false }
        clearAccount()
        profileState = .failed(SettingsError.authenticationRequired)
        await systemActions.clearAccountNotifications()
        return true
    }

    private func finishLogout() async {
        clearAccount()
        await systemActions.clearAccountNotifications()
        onLogout?()
    }

    private func clearAccount() {
        accountGeneration += 1
        profile = nil
        profileState = .failed(SettingsError.authenticationRequired)
        dialog = nil
        dialogMessage = nil
        linkDraft = .init()
        linkErrors = [:]
        challengerCode = ""
        registeredActivities = []
        codeStep = .entry
        toast = nil
        isRefreshing = false
        isSaving = false
        isRegistering = false
    }

    private func codeErrorMessage(_ error: any Error) -> String {
        if let repositoryError = error as? RepositoryError { return repositoryError.userMessage }
        return "코드를 등록하지 못했어요. 코드를 확인한 뒤 다시 시도해 주세요."
    }
}
