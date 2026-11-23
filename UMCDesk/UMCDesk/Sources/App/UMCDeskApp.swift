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
import CommunityPresentation
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

    var body: some Scene {
        @Bindable var preferences = dependencies.settingsPreferences
        #if DEBUG || UMC_PRERELEASE
        @Bindable var previewPreferences = dependencies.previewSettingsViewModel.preferences
        #endif

        Window("UMC Desk", id: "main") {
            AppRootView(dependencies: dependencies)
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

        Settings {
            SettingsSceneView(dependencies: dependencies)
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
                    onOpenMatching: {},
                    matchingContent: AnyView(MatchingDesignPreview.view(
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
                onOpenMatching: { dependencies.openMatching() },
                onOpenSettingsPage: { dependencies.navigation.matchingDestination = nil },
                matchingContent: dependencies.navigation.matchingDestination.map { destination in
                    AnyView(MatchingWorkspace(
                        repository: dependencies.matchingUseCase, destination: destination,
                        memberId: dependencies.settingsViewModel.profile?.id,
                        activities: dependencies.settingsViewModel.profile?.activities ?? []
                    )
                    .id(dependencies.navigation.matchingNavigationID)
                    .id(dependencies.settingsViewModel.profile?.id))
                }, threadContent: { AnyView(CommunityThreadsView(repository: dependencies.communityRepository)) }
            )
        } else {
            AuthView(login: dependencies.login)
        }
    }

    private var progressAccount: String? {
        guard dependencies.navigation.showsSettings, dependencies.settingsPreferences.showsMenuBar,
              !dependencies.isSettingsPreview else { return nil }
        return dependencies.settingsViewModel.profile?.id
    }

    private func configureLoginAction() {
        dependencies.settingsViewModel.onOpenLogin = {
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
        })
            .background(SettingsWindowToolbar())
            .onAppear {
                dependencies.windowSettingsViewModel.showSettings()
                dependencies.windowSettingsViewModel.onOpenLogin = {
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
            dependencies.navigation.matchingDestination = nil
            dependencies.settingsViewModel.showProfile()
            dependencies.navigation.showsSettings = true
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button(AppLocalization.string("설정…")) {
            dependencies.windowSettingsViewModel.showSettings()
            openSettings()
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
    #if DEBUG || UMC_PRERELEASE
    @Environment(\.openWindow) private var openWindow
    #endif

    var body: some Commands {
        @Bindable var preferences = dependencies.settingsPreferences

        CommandGroup(replacing: .appSettings) {
            Button(AppLocalization.string("설정…")) {
                dependencies.windowSettingsViewModel.showSettings()
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
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
