//
//  UMCDeskApp.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import UMCFoundation
import CoreRouting
import SwiftUI
import AppKit
import ActivityPresentation
import CommunityPresentation
import HomePresentation
import NoticePresentation
import ProjectWorkspaceData
import ProjectWorkspacePresentation
import AuthPresentation
import CoreDesignSystem
import CoreUIComponents
import MatchingDomain
import MatchingPresentation
import SettingsDomain
import SettingsPresentation

@main
struct UMCDeskApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var lifecycle
    private let dependencies = AppDependencies()
    #if DEBUG || UMC_PRERELEASE
    @State private var typographyPreview = UMCTypographyPreview()
    #endif

    private func publishedDocument(_ document: SettingsPublishedDocument,
                                   close: @escaping () -> Void) -> AnyView {
        AnyView(AuthPublishedTermsView(repository: dependencies.loginRepository,
                                       requested: document == .service ? .service : .privacy,
                                       onClose: close))
    }

    var body: some Scene {
        @Bindable var preferences = dependencies.settingsPreferences
        #if DEBUG || UMC_PRERELEASE
        @Bindable var previewPreferences = dependencies.previewSettingsViewModel.preferences
        #endif

        Window("UMC Desk", id: "main") {
            AppRootView(dependencies: dependencies)
                .environment(\.settingsPublishedDocument, publishedDocument)
                .toggleStyle(UMCCheckboxStyle())
                .environment(\.locale, AppLocalization.shared.language.locale)
                .onChange(of: preferences.language) {
                    dependencies.restoreSupportedFonts()
                }
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .environment(\.umcFontDesign, preferences.font.design)
                .environment(\.umcFontFamily, preferences.availableFontFamily)
                .frame(minWidth: 1040, minHeight: 720)
                #if DEBUG || UMC_PRERELEASE
                .environment(\.umcTypographyPreview, typographyPreview)
                #endif
                .onAppear { lifecycle.preferences = preferences }
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .commands {
            AppSettingsCommands(dependencies: dependencies)
            #if DEBUG || UMC_PRERELEASE
            AuthPreviewCommands()
            #endif
        }

        Window("업데이트 확인", id: DeskWindow.updates) {
            UpdateWindow()
                .preferredColorScheme(preferences.theme.colorScheme)
        }
        .defaultSize(width: 640, height: 440)

        Window(AppLocalization.string("고객센터"), id: DeskWindow.support) {
            SupportView()
                .environment(\.locale, AppLocalization.shared.language.locale)
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .environment(\.umcFontDesign, preferences.font.design)
                .environment(\.umcFontFamily, preferences.availableFontFamily)
        }
        .defaultSize(width: 980, height: 720)
        .windowToolbarStyle(.unifiedCompact)

        WindowGroup("스레드", for: ThreadWindowKey.self) { $key in
            if let key, let account = dependencies.navigation.account, key.accountID == account.memberID {
                ThreadWindowContent(key: key, repository: account.threads,
                                    conversations: account.conversations, management: account.members,
                                    defaults: dependencies.featureDefaults)
                    .id(key)
                    .preferredColorScheme(preferences.theme.colorScheme)
                    .defaultAppStorage(dependencies.featureDefaults)
            } else {
                ContentUnavailableView("대화를 열 수 없습니다", systemImage: "bubble.left",
                                       description: Text("이 대화에 참여한 계정으로 로그인해 주세요."))
            }
        }
        .defaultSize(width: 760, height: 640)

        Settings {
            SettingsSceneView(dependencies: dependencies)
                .environment(\.settingsPublishedDocument, publishedDocument)
                .toggleStyle(UMCCheckboxStyle())
                .environment(\.locale, AppLocalization.shared.language.locale)
                .onChange(of: preferences.language) {
                    dependencies.restoreSupportedFonts()
                }
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .environment(\.umcFontDesign, preferences.font.design)
                .environment(\.umcFontFamily, preferences.availableFontFamily)
                .frame(minWidth: 1040, minHeight: 720)
                #if DEBUG || UMC_PRERELEASE
                .environment(\.umcTypographyPreview, typographyPreview)
                #endif
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        #if DEBUG || UMC_PRERELEASE
        Window(AppLocalization.string("마이페이지·설정 프리뷰"), id: "settings-design-preview") {
            SettingsView(viewModel: dependencies.previewSettingsViewModel)
                .toggleStyle(UMCCheckboxStyle())
                .environment(\.locale, AppLocalization.shared.language.locale)
                .onChange(of: preferences.language) {
                    dependencies.restoreSupportedFonts()
                }
                .preferredColorScheme(previewPreferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, previewPreferences.bodyTextSize.scale)
                .environment(\.umcFontDesign, previewPreferences.font.design)
                .environment(\.umcFontFamily, previewPreferences.availableFontFamily)
                .environment(\.umcTypographyPreview, typographyPreview)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        Window(AppLocalization.string("타이포그래피 조절"), id: "typography-preview") {
            AppTypographyPreviewControls(settings: $typographyPreview)
        }
        .windowResizability(.contentSize)
        #endif

        MenuBarExtra(
            "UMC Desk", systemImage: "square.grid.2x2", isInserted: $preferences.showsMenuBar
        ) {
            AppMenuBarContent(dependencies: dependencies)
                .environment(\.locale, AppLocalization.shared.language.locale)
                .onChange(of: preferences.language) {
                    dependencies.restoreSupportedFonts()
                }
        }
    }
}

private struct UpdateWindow: View {
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        AuthUpdateCheckView(onClose: { dismissWindow(id: DeskWindow.updates) })
    }
}

private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--matching-preview") {
                let args = ProcessInfo.processInfo.arguments
                let pages: [(String, MatchingDestination)] = [
                    ("--matching-applications", .applications), ("--matching-schedule", .schedule),
                    ("--matching-management", .management), ("--matching-status", .status)
                ]
                let page = pages.first { args.contains($0.0) }?.1 ?? .explore
                SettingsView(
                    viewModel: dependencies.previewSettingsViewModel,
                    featureContent: AnyView(MatchingDesignPreview.view(
                        destination: page, showsDetail: args.contains("--matching-detail")
                    ))
                )
                .environment(\.colorScheme, args.contains("--matching-dark") ? .dark : .light)
            } else {
                liveRoot
            }
            #else
            liveRoot
            #endif
        }
        .task { await dependencies.restoreSession() }
        .onAppear {
            configureLoginAction()
            dependencies.matchingProgress.openApplications = {
                dependencies.openMatching(.applications)
                openWindow(id: "main")
                NSApplication.shared.activate()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await dependencies.restoreSession() } }
        }
        .onChange(of: dependencies.verifiedMatchingMemberId) { old, current in
            if old != nil { dependencies.navigation.matchingDestination = nil }
            if current != nil, let pending = dependencies.navigation.pendingMatching {
                dependencies.openMatching(pending)
            }
        }
        .onChange(of: progressAccount, initial: true) {
            dependencies.matchingProgress.setAccount(progressAccount)
        }
    }

    @ViewBuilder private var liveRoot: some View {
        if dependencies.navigation.showsSettings {
            SettingsView(
                viewModel: dependencies.settingsViewModel,
                section: dependencies.navigation.section,
                featureContent: dependencies.navigation.matchingDestination.map { destination in
                    AnyView(MatchingWorkspace(
                        repository: dependencies.matchingUseCase, destination: destination,
                        memberId: dependencies.settingsViewModel.profile?.id,
                        activities: dependencies.settingsViewModel.profile?.activities ?? []
                    )
                    .id(dependencies.navigation.matchingNavigationID)
                    .id(dependencies.settingsViewModel.profile?.id))
                } ?? featureContent, onOpenMatching: { dependencies.openMatching() },
                onSelectSection: dependencies.selectSection
            )
        } else {
            AuthView(login: dependencies.login, repository: dependencies.loginRepository,
                     entry: dependencies.navigation.authEntry, onSignOut: dependencies.signOut,
                     onMemberRefresh: dependencies.refreshAccount, onCloseAccount: {
                         dependencies.navigation.authEntry = .login
                         dependencies.navigation.showsSettings = dependencies.navigation.account != nil
                     })
                .id(dependencies.navigation.authEntry)
        }
    }

    private var progressAccount: String? {
        guard dependencies.navigation.showsSettings, dependencies.settingsPreferences.showsMenuBar,
              !dependencies.isSettingsPreview else { return nil }
        return dependencies.settingsViewModel.profile?.id
    }

    private var featureContent: AnyView? {
        guard let account = dependencies.navigation.account,
              let section = dependencies.navigation.section else { return nil }
        return AnyView(feature(section, account: account)
            .defaultAppStorage(dependencies.featureDefaults)
            .id(account.memberID))
    }

    @ViewBuilder
    private func feature(_ section: DeskSection, account: FeatureAccount) -> some View {
        switch section {
        case .home:
            HomeView(repository: account.home, memberID: account.memberID,
                     defaults: dependencies.featureDefaults) { destination in
                switch destination {
                case .activity: dependencies.selectSection(.activity)
                case .notice: dependencies.selectSection(.notice)
                case .project: dependencies.selectSection(.projects)
                }
            }
        case .notice:
            NoticeBoardView(repository: account.notices)
        case .activity:
            ActivityView(repository: account.activity)
        case .community:
            CommunityPostBoardView(accountID: account.memberID, repository: account.posts)
        case .threads:
            CommunityThreadsView(accountID: account.memberID, repository: account.threads,
                                 conversations: account.conversations, management: account.members,
                                    defaults: dependencies.featureDefaults)
        case .projects:
            ProjectWorkspaceView(accountID: account.memberID, loadProjects: account.projects,
                                 loadGitHub: WorkspaceGitHubClient.recentWork(repository:),
                                 openMatching: { dependencies.openMatching() })
        }
    }

    private func configureLoginAction() {
        dependencies.settingsViewModel.onOpenLogin = {
            dependencies.navigation.authEntry = .login
            dependencies.navigation.showsSettings = false
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
    }
}

private struct MatchingWorkspace: View {
    let repository: any MatchingUseCase
    let destination: MatchingDestination
    let memberId: String?
    let activities: [SettingsActivity]
    @State private var gisuId: String?
    @State private var errorMessage: String?
    @State private var attempt = 0

    var body: some View {
        Group {
            if let gisuId {
                MatchingView(repository: repository, gisuId: gisuId,
                             initialDestination: destination, memberId: memberId,
                             applicantParts: activities.filter { $0.gisuId == gisuId }.map(\.part))
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("활동 기수를 불러올 수 없어요", systemImage: "calendar")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("다시 시도") { attempt += 1 }
                }
            } else {
                ProgressView("활동 기수 확인 중")
            }
        }
        .task(id: attempt) {
            errorMessage = nil
            do {
                let activeId = try await repository.activeGisuId()
                try Task.checkCancellation()
                gisuId = activeId
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }
}

private struct SettingsSceneView: View {
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        SettingsView(viewModel: dependencies.windowSettingsViewModel, onOpenMatching: {
            dependencies.openMatching()
            openWindow(id: "main")
            NSApplication.shared.activate()
        }, onSelectSection: { section in
            guard let section else { return }
            dependencies.selectSection(section)
            openWindow(id: "main")
            NSApplication.shared.activate()
        })
            .background(SettingsWindowToolbar())
            .onAppear {
                dependencies.windowSettingsViewModel.showSettings()
                dependencies.windowSettingsViewModel.onOpenLogin = {
                    dependencies.navigation.authEntry = .login
                    dependencies.navigation.showsSettings = false
                    openWindow(id: "main")
                    NSApplication.shared.activate()
                }
            }
    }
}

private struct SettingsWindowToolbar: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsToolbarView { SettingsToolbarView() }
    func updateNSView(_ view: SettingsToolbarView, context: Context) { view.configureWindow() }
}

private final class SettingsToolbarView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    func configureWindow() {
        // The Settings scene overrides its SwiftUI toolbar style with preference-window chrome.
        window?.toolbarStyle = .unifiedCompact
        window?.titleVisibility = .hidden
    }
}

private struct AppMenuBarContent: View {
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(AppLocalization.string("UMC Desk 열기")) {
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button("매칭 진행 현황") {
            dependencies.matchingProgress.showExpanded()
        }
        Button("내 매칭 지원") {
            dependencies.openMatching(.applications)
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button(AppLocalization.string("마이페이지")) {
            dependencies.selectSection(nil)
            dependencies.settingsViewModel.showProfile()
            dependencies.navigation.showsSettings = true
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button(AppLocalization.string("설정…")) {
            dependencies.windowSettingsViewModel.showSettings()
            openSettings()
        }
        if let account = dependencies.navigation.account {
            ActivityMenuContent(repository: account.activity) {
                dependencies.selectSection(.activity)
                openWindow(id: "main")
                NSApplication.shared.activate()
            }
        }
        Divider()
        Button(AppLocalization.string("UMC Desk 종료"), role: .destructive) {
            NSApplication.shared.terminate(nil)
        }
    }
}

private struct AppSettingsCommands: Commands {
    let dependencies: AppDependencies
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        @Bindable var preferences = dependencies.settingsPreferences

        CommandGroup(replacing: .appSettings) {
            Button(AppLocalization.string("설정…")) {
                dependencies.windowSettingsViewModel.showSettings()
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandMenu("계정") {
            Button("마이페이지") {
                dependencies.selectSection(nil)
                dependencies.settingsViewModel.showProfile()
                openWindow(id: "main")
            }
            Button("챌린저 연결…") { openAccount(.challenger) }
                .disabled(dependencies.navigation.account == nil)
            Button("회원 탈퇴…") { openAccount(.withdrawal) }
                .disabled(dependencies.navigation.account == nil)
        }
        #if DEBUG || UMC_PRERELEASE
        CommandGroup(after: .sidebar) {
            Button(AppLocalization.string("마이페이지 프리뷰…")) {
                SettingsDesignPreview.prepareViewModel(
                    dependencies.previewSettingsViewModel, page: .myPage
                )
                openWindow(id: "settings-design-preview")
            }
            Button(AppLocalization.string("설정 프리뷰…")) {
                SettingsDesignPreview.prepareViewModel(
                    dependencies.previewSettingsViewModel, page: .general
                )
                openWindow(id: "settings-design-preview")
            }
            Divider()
            Picker(AppLocalization.string("화면 모드"), selection: $preferences.theme) {
                Text(AppLocalization.string("시스템 설정")).tag(SettingsTheme.system)
                Text(AppLocalization.string("라이트")).tag(SettingsTheme.light)
                Text(AppLocalization.string("다크")).tag(SettingsTheme.dark)
            }
            Button(AppLocalization.string("타이포그래피 조절…")) { openWindow(id: "typography-preview") }
        }
        #endif
    }

    private func openAccount(_ entry: AuthEntry) {
        dependencies.navigation.authEntry = entry
        dependencies.navigation.showsSettings = false
        openWindow(id: "main")
        NSApplication.shared.activate()
    }

}

@MainActor
final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    var preferences: SettingsPreferences?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        preferences?.windowCloseBehavior == .quit
    }
}

private extension SettingsTheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
